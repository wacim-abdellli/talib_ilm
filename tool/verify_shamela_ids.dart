// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

import 'package:talib_ilm/features/ilm/data/catalogs/mutun_digital_catalog.dart';

String normalizeArabic(String input) {
  var text = input;
  // Remove content inside brackets / parentheses e.g. (زيادة المرء في دنياه نقصان) or (مطبوع ضمن...)
  text = text.replaceAll(RegExp(r'\([^)]*\)'), ' ');
  text = text.replaceAll(RegExp(r'\[[^\]]*\]'), ' ');
  // Remove HTML entities and tags
  text = text.replaceAll(RegExp(r'<[^>]+>'), ' ');
  text = text.replaceAll('&quot;', '"').replaceAll('&amp;', '&');
  // Strip tashkeel (harakat)
  text = text.replaceAll(RegExp(r'[\u064B-\u065F\u0670\u0640]'), '');
  // Normalize alefs
  text = text.replaceAll(RegExp(r'[أإآٱ]'), 'ا');
  // Normalize yaa / alef maksura
  text = text.replaceAll('ى', 'ي');
  // Normalize taa marbuta
  text = text.replaceAll('ة', 'ه');
  // Remove common prefix stop words
  text = text.replaceAll(RegExp(r'\b(كتاب|متن|منظومة|قصيدة|المقدمة|ديوان|شرح)\b'), ' ');
  // Remove non-alphanumeric/spaces
  text = text.replaceAll(RegExp(r'[^\w\s\u0621-\u064A]'), ' ');
  // Collapse whitespace
  text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  return text.toLowerCase();
}

String? extractTitle(String html) {
  // Try <h1>
  final h1Match = RegExp(r'<h1[^>]*>(.*?)</h1>', caseSensitive: false, dotAll: true).firstMatch(html);
  if (h1Match != null) {
    final title = h1Match.group(1)!.replaceAll(RegExp(r'<[^>]+>'), '').trim();
    if (title.isNotEmpty) return title;
  }

  // Try <title>
  final titleMatch = RegExp(r'<title[^>]*>(.*?)</title>', caseSensitive: false, dotAll: true).firstMatch(html);
  if (titleMatch != null) {
    var title = titleMatch.group(1)!.replaceAll(RegExp(r'<[^>]+>'), '').trim();
    if (title.contains('-')) {
      title = title.split('-').first.trim();
    }
    if (title.contains('•')) {
      title = title.split('•').first.trim();
    }
    return title;
  }

  return null;
}

Future<void> main() async {
  print('═══════════════════════════════════════════════════════════════');
  print('Verifying Shamela IDs for MutunDigitalCatalog (${MutunDigitalCatalog.entries.length} entries)');
  print('═══════════════════════════════════════════════════════════════');

  final client = HttpClient();
  client.userAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';
  client.connectionTimeout = const Duration(seconds: 15);

  int okCount = 0;
  int mismatchCount = 0;
  int errCount = 0;

  for (final entry in MutunDigitalCatalog.entries.values) {
    final url = Uri.parse('https://shamela.ws/book/${entry.shamelaId}');
    try {
      final request = await client.getUrl(url);
      final response = await request.close();

      if (response.statusCode != 200) {
        print('[${response.statusCode}] ${entry.id} (ID: ${entry.shamelaId}) -> HTTP ${response.statusCode}');
        errCount++;
        await response.drain();
        continue;
      }

      final body = await response.transform(utf8.decoder).join();
      final webTitle = extractTitle(body) ?? 'Unknown Title';
      final normCatalog = normalizeArabic(entry.title);
      final normWeb = normalizeArabic(webTitle);

      final catalogWords = normCatalog.split(' ').where((w) => w.length > 2).toList();
      final webWords = normWeb.split(' ').where((w) => w.length > 2).toSet();
      int matchWords = 0;
      for (final w in catalogWords) {
        if (webWords.contains(w) || normWeb.contains(w)) matchWords++;
      }

      final ratio = catalogWords.isEmpty ? 1.0 : matchWords / catalogWords.length;
      final isMatch = normWeb.contains(normCatalog) ||
          normCatalog.contains(normWeb) ||
          ratio >= 0.3 ||
          (catalogWords.isNotEmpty && webWords.any((w) => catalogWords.contains(w)));

      if (isMatch) {
        print('[OK] ${entry.id} (ID: ${entry.shamelaId})');
        print('     Catalog : "${entry.title}"');
        print('     Shamela : "$webTitle"');
        okCount++;
      } else {
        print('[MISMATCH] ${entry.id} (ID: ${entry.shamelaId})');
        print('     Catalog : "${entry.title}"');
        print('     Shamela : "$webTitle"');
        mismatchCount++;
      }
    } catch (e) {
      print('[ERR] ${entry.id} (ID: ${entry.shamelaId}): $e');
      errCount++;
    }
  }

  client.close();

  print('═══════════════════════════════════════════════════════════════');
  print('Summary: OK: $okCount | MISMATCH: $mismatchCount | ERR/404: $errCount');
  print('═══════════════════════════════════════════════════════════════');
}
