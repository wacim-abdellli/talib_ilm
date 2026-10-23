import '../models/shamela_models.dart';

/// Specialized parser for Maktaba Shamela web pages and HTML sanitization.
class ShamelaHtmlParser {
  const ShamelaHtmlParser._();

  /// Parse raw Shamela HTML into clean structured Arabic text
  static ShamelaPage parsePageHtml(int bookId, int pageNumber, String html) {
    // Extract nass container
    final nassRegex = RegExp(
      r"""<div[^>]*class=["'][^"']*nass[^"']*["'][^>]*>(.*?)</div>""",
      dotAll: true,
    );
    final match = nassRegex.firstMatch(html);
    String rawBody = match != null ? match.group(1)! : html;

    // Check for printed page and volume
    int? partNum;
    final partMatch = RegExp(r'الجزء\s*:?\s*(\d+)').firstMatch(html);
    if (partMatch != null) {
      partNum = int.tryParse(partMatch.group(1)!);
    }

    // Extract active chapter title if available
    String? chapterTitle;
    final chapterMatch = RegExp(
      r'<h6>مسار الصفحة الحالية:</h6>.*?<a[^>]*>(.*?)</a>',
      dotAll: true,
    ).firstMatch(html);
    if (chapterMatch != null) {
      chapterTitle = cleanHtml(chapterMatch.group(1)!);
    }

    // Extract footnotes (hamesh)
    String? hamesh;
    final hameshRegex = RegExp(r'<hr\s*/?>\s*<p class="hamesh">(.*?)</p>', dotAll: true);
    final hameshMatch = hameshRegex.firstMatch(rawBody);
    if (hameshMatch != null) {
      hamesh = cleanHtml(hameshMatch.group(1)!);
      rawBody = rawBody.replaceRange(hameshMatch.start, hameshMatch.end, '');
    } else {
      // Split on separator line _________
      final sepIndex = rawBody.indexOf('_________');
      if (sepIndex != -1) {
        hamesh = cleanHtml(rawBody.substring(sepIndex + 9));
        rawBody = rawBody.substring(0, sepIndex);
      }
    }

    final cleanContent = cleanHtml(rawBody);
    final detectedTotal = extractTotalPagesFromHtml(bookId, html);

    return ShamelaPage(
      bookId: bookId,
      pageNumber: pageNumber,
      partNumber: partNum,
      chapterTitle: chapterTitle,
      content: cleanContent,
      hamesh: hamesh,
      detectedTotalPages: detectedTotal,
    );
  }

  /// Extract total pages dynamically from Maktaba Shamela page navigation HTML
  static int? extractTotalPagesFromHtml(int bookId, String html) {
    if (html.isEmpty) return null;

    final idStr = bookId.toString();

    // Direct regex for pagination links:
    // Matches: <a ... href=".../book/11126/12..." ...>...>>...</a>
    final lastLinkRegex = RegExp(
      r'''<a\s+[^>]*href=["'](?:https?://shamela\.ws)?/book/''' +
          idStr +
          r'''/(\d+)(?:#[^"']*)?["'][^>]*>(.*?)</a>''',
      caseSensitive: false,
      dotAll: true,
    );

    int? candidate;
    for (final m in lastLinkRegex.allMatches(html)) {
      final page = int.tryParse(m.group(1)!);
      if (page == null) continue;
      final fullTag = m.group(0) ?? '';
      final inner = m.group(2) ?? '';

      // High confidence: this link has >>, &gt;&gt;, », or says 'أخيرة' / 'last'
      if (inner.contains('>>') ||
          inner.contains('&gt;&gt;') ||
          inner.contains('»') ||
          fullTag.contains('أخيرة') ||
          fullTag.contains('last') ||
          fullTag.contains('الصفحة الأخيرة')) {
        return page;
      }

      // Track max page number linked
      if (candidate == null || page > candidate) {
        candidate = page;
      }
    }

    // Also check if there's any button/input with data-page or data-last
    final dataLastRegex = RegExp(
      r'''data-(?:last|total|max-page)=["'](\d+)["']''',
      caseSensitive: false,
    );
    final dataMatch = dataLastRegex.firstMatch(html);
    if (dataMatch != null) {
      final val = int.tryParse(dataMatch.group(1)!);
      if (val != null && val > 0) return val;
    }

    return candidate;
  }

  /// Clean HTML tags, brackets, and extra spaces
  static String cleanHtml(String html) {
    var text = sanitizeBookText(html)
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n\n')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();

    return sanitizeBookText(text);
  }

  /// Sanitize book content and footnotes by stripping email protection artifacts
  /// (e.g. Cloudflare [email&#160;protected], [email protected], etc.)
  static String sanitizeBookText(String text) {
    if (text.isEmpty) return text;
    return text
        .replaceAll(
          RegExp(
            r"""<a[^>]*class=["'][^"']*__cf_email__[^"']*["'][^>]*>.*?</a>""",
            caseSensitive: false,
            dotAll: true,
          ),
          '',
        )
        .replaceAll(
          RegExp(
            r"""<a[^>]*href=["'][^"']*/cdn-cgi/l/email-protection[^"']*["'][^>]*>.*?</a>""",
            caseSensitive: false,
            dotAll: true,
          ),
          '',
        )
        .replaceAll(
          RegExp(
            r'/cdn-cgi/l/email-protection#?[a-f0-9]*',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(
          RegExp(
            r'\[\s*email(?:\s*|&#\d+;|&nbsp;)*protected\s*\]',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(
          RegExp(r'\[\s*email[^\]]*\]', caseSensitive: false),
          '',
        )
        .replaceAll(
          RegExp(
            r'//<!\[CDATA\[\s*\(function\(.*?\)\(\);\s*//\]\]>',
            caseSensitive: false,
            dotAll: true,
          ),
          '',
        )
        .replaceAll(
          RegExp(
            r'/\* <\!\[CDATA\[ \*/.*?/\* \]\]> \*/',
            caseSensitive: false,
            dotAll: true,
          ),
          '',
        )
        .replaceAll(
          RegExp(
            r'<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>',
            caseSensitive: false,
          ),
          '',
        )
        .trim();
  }
}
