import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../../data/services/quran_page_service.dart';
import 'ayah_context_menu.dart';
import '../../data/tajweed_rules.dart';

/// Surah names for headers
const List<String> surahNames = [
  '',
  'الفاتحة',
  'البقرة',
  'آل عمران',
  'النساء',
  'المائدة',
  'الأنعام',
  'الأعراف',
  'الأنفال',
  'التوبة',
  'يونس',
  'هود',
  'يوسف',
  'الرعد',
  'إبراهيم',
  'الحجر',
  'النحل',
  'الإسراء',
  'الكهف',
  'مريم',
  'طه',
  'الأنبياء',
  'الحج',
  'المؤمنون',
  'النور',
  'الفرقان',
  'الشعراء',
  'النمل',
  'القصص',
  'العنكبوت',
  'الروم',
  'لقمان',
  'السجدة',
  'الأحزاب',
  'سبأ',
  'فاطر',
  'يس',
  'الصافات',
  'ص',
  'الزمر',
  'غافر',
  'فصلت',
  'الشورى',
  'الزخرف',
  'الدخان',
  'الجاثية',
  'الأحقاف',
  'محمد',
  'الفتح',
  'الحجرات',
  'ق',
  'الذاريات',
  'الطور',
  'النجم',
  'القمر',
  'الرحمن',
  'الواقعة',
  'الحديد',
  'المجادلة',
  'الحشر',
  'الممتحنة',
  'الصف',
  'الجمعة',
  'المنافقون',
  'التغابن',
  'الطلاق',
  'التحريم',
  'الملك',
  'القلم',
  'الحاقة',
  'المعارج',
  'نوح',
  'الجن',
  'المزمل',
  'المدثر',
  'القيامة',
  'الإنسان',
  'المرسلات',
  'النبأ',
  'النازعات',
  'عبس',
  'التكوير',
  'الانفطار',
  'المطففين',
  'الانشقاق',
  'البروج',
  'الطارق',
  'الأعلى',
  'الغاشية',
  'الفجر',
  'البلد',
  'الشمس',
  'الليل',
  'الضحى',
  'الشرح',
  'التين',
  'العلق',
  'القدر',
  'البينة',
  'الزلزلة',
  'العاديات',
  'القارعة',
  'التكاثر',
  'العصر',
  'الهمزة',
  'الفيل',
  'قريش',
  'الماعون',
  'الكوثر',
  'الكافرون',
  'النصر',
  'المسد',
  'الإخلاص',
  'الفلق',
  'الناس',
];

/// Single Mushaf Page Widget
class MushafPageWidget extends StatelessWidget {
  final QuranPageData pageData;
  final double fontSize;
  final bool isDark;
  final bool useEnglishNumbers;
  final String fontFamily;
  final bool enableScroll;
  final bool showTajweed;

  const MushafPageWidget({
    super.key,
    required this.pageData,
    this.fontSize = 22,
    this.isDark = false,
    this.useEnglishNumbers = false,
    this.fontFamily = 'Amiri',
    this.enableScroll = true,
    this.showTajweed = false,
  });

  @override
  Widget build(BuildContext context) {
    // Warm paper tone for light, Deep charcoal for dark
    final textColor = isDark
        ? const Color(0xFFE0E0E0)
        : const Color(0xFF2D2D2D);
    final bgColor = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF7F3E8);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : const Color(0xFFD4A853).withValues(alpha: 0.2);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor, width: 1.5),
        borderRadius: BorderRadius.circular(8), // Softer corners
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Page Header
          _buildHeader(textColor, borderColor),

          // Main Content
          // Main Content
          if (enableScroll)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                child: _buildContent(context, textColor),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: _buildContent(context, textColor),
            ),

          // Page Footer
          _buildFooter(textColor, borderColor),
        ],
      ),
    );
  }

  Widget _buildHeader(Color textColor, Color borderColor) {
    final surahs = pageData.versesBySurah.keys.toList();
    final surahName = surahs.isNotEmpty && surahs.first <= 114
        ? surahNames[surahs.first]
        : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'الجزء ${useEnglishNumbers ? (pageData.juzNumber ?? 1) : _toArabicNumber(pageData.juzNumber ?? 1)}',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              color: textColor.withValues(alpha: 0.6),
            ),
          ),
          Text(
            surahName,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          Text(
            'الحزب ${useEnglishNumbers ? (pageData.hizbNumber ?? 1) : _toArabicNumber(pageData.hizbNumber ?? 1)}',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              color: textColor.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, Color textColor) {
    // Group verses and render with surah headers
    final versesBySurah = pageData.versesBySurah;
    final spans = <InlineSpan>[];

    for (final entry in versesBySurah.entries) {
      final surahNum = entry.key;
      final verses = entry.value;

      // Add surah header if first verse is ayah 1
      if (verses.isNotEmpty && verses.first.verseNumber == 1 && surahNum != 9) {
        spans.add(_buildSurahHeader(surahNum, textColor));
        spans.add(
          const WidgetSpan(child: SizedBox(height: 8, width: double.infinity)),
        );

        // Add Bismillah for non-Fatiha surahs
        // Add Bismillah for non-Fatiha surahs
        if (surahNum != 1) {
          spans.add(
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: fontFamily,
                    fontSize: fontSize * 1.0,
                    color: textColor,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          );
        }
      }

      // Add verses
      for (final verse in verses) {
        // Tappable verse text using TextSpan to allow proper wrapping
        if (showTajweed) {
          List<InlineSpan> tajweedSpans = [];
          final segments = TajweedParser.parse(verse.textUthmani);

          for (final segment in segments) {
            final color = segment.rule != TajweedRule.normal
                ? TajweedColors.getColor(
                    segment.rule,
                    nightMode: isDark,
                  ).withValues(
                    alpha: isDark ? 0.4 : 0.6,
                  ) // Slightly more opaque for readability
                : textColor;

            tajweedSpans.add(
              TextSpan(
                text: segment.text,
                style: TextStyle(
                  fontFamily: fontFamily,
                  fontSize: fontSize,
                  color: color,
                  height: 2.2,
                  letterSpacing: 0,
                  wordSpacing: 2,
                ),
              ),
            );
          }
          // Add space
          tajweedSpans.add(const TextSpan(text: ' '));

          spans.add(
            TextSpan(
              children: tajweedSpans,
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  AyahContextMenu.show(
                    context,
                    surah: surahNum,
                    ayah: verse.verseNumber,
                    ayahText: verse.textUthmani,
                    isDark: isDark,
                  );
                },
            ),
          );
        } else {
          spans.add(
            TextSpan(
              text: '${verse.textUthmani} ',
              style: TextStyle(
                fontFamily: fontFamily,
                fontSize: fontSize,
                color: textColor,
                height: 2.2,
                letterSpacing: 0,
                wordSpacing: 2,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  AyahContextMenu.show(
                    context,
                    surah: surahNum,
                    ayah: verse.verseNumber,
                    ayahText: verse.textUthmani,
                    isDark: isDark,
                  );
                },
            ),
          );
        }

        // Add verse number marker (tappable for menu)
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: _VerseMarker(
              surahNumber: surahNum,
              number: verse.verseNumber,
              verseText: verse.textUthmani,
              isDark: isDark,
              useEnglishNumbers: useEnglishNumbers,
            ),
          ),
        );

        spans.add(const TextSpan(text: ' '));
      }
    }

    return SingleChildScrollView(
      physics: enableScroll
          ? const ClampingScrollPhysics()
          : const NeverScrollableScrollPhysics(),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Text.rich(
          TextSpan(children: spans),
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
        ),
      ),
    );
  }

  WidgetSpan _buildSurahHeader(int surahNum, Color textColor) {
    final name = surahNum <= 114 ? surahNames[surahNum] : '';
    return WidgetSpan(
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF1A1A1A), const Color(0xFF252525)]
                : [
                    const Color(0xFFD4A853).withValues(alpha: 0.2),
                    const Color(0xFFE8C252).withValues(alpha: 0.1),
                  ],
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark
                ? Colors.white12
                : const Color(0xFFD4A853).withValues(alpha: 0.5),
          ),
        ),
        child: Text(
          'سُورَةُ $name',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: fontFamily,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF5A4A28),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(Color textColor, Color borderColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: borderColor, width: 1)),
      ),
      child: Center(
        child: Text(
          useEnglishNumbers
              ? '${pageData.pageNumber}'
              : _toArabicNumber(pageData.pageNumber),
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: textColor.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }

  String _toArabicNumber(int number) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number
        .toString()
        .split('')
        .map((d) => arabicDigits[int.parse(d)])
        .join();
  }
}

/// Verse Number Marker - Tappable for Tafsir
class _VerseMarker extends StatelessWidget {
  final int surahNumber;
  final int number;
  final String verseText;
  final bool isDark;
  final bool useEnglishNumbers;

  const _VerseMarker({
    required this.surahNumber,
    required this.number,
    required this.verseText,
    required this.isDark,
    this.useEnglishNumbers = false,
  });

  @override
  Widget build(BuildContext context) {
    const markerColor = Color(0xFFFFC107);

    return GestureDetector(
      onTap: () {
        AyahContextMenu.show(
          context,
          surah: surahNumber,
          ayah: number,
          ayahText: verseText,
          isDark: isDark,
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        width: 36,
        height: 36,
        child: CustomPaint(
          painter: _OrnamentalMarkerPainter(color: markerColor),
          child: Center(
            child: Text(
              _toArabicNumber(number),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Amiri',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: markerColor,
                height: 1.0,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _toArabicNumber(int number) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number
        .toString()
        .split('')
        .map((d) => arabicDigits[int.parse(d)])
        .join();
  }
}

/// Ornamental Marker Painter - Draws the decorative circle with crown
class _OrnamentalMarkerPainter extends CustomPainter {
  final Color color;

  _OrnamentalMarkerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..isAntiAlias = true;

    // 1. Outer circle
    canvas.drawCircle(center, radius * 0.88, paint);

    // 2. Inner circle (thinner)
    final innerPaint = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..isAntiAlias = true;
    canvas.drawCircle(center, radius * 0.70, innerPaint);

    // 3. Crown/Bow ornament at the top
    final topY = center.dy - (radius * 0.88);
    final crownPath = Path();

    // Left bow
    crownPath.moveTo(center.dx - 5, topY + 1);
    crownPath.quadraticBezierTo(center.dx - 3, topY - 4, center.dx, topY - 5);
    // Right bow
    crownPath.quadraticBezierTo(
      center.dx + 3,
      topY - 4,
      center.dx + 5,
      topY + 1,
    );

    canvas.drawPath(crownPath, paint);

    // 4. Small bottom dot
    final bottomY = center.dy + (radius * 0.88);
    canvas.drawCircle(
      Offset(center.dx, bottomY + 2),
      1.5,
      paint..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _OrnamentalMarkerPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

/// Tappable verse text with highlight effect
class _TappableVerse extends StatefulWidget {
  final String text;
  final int surahNumber;
  final int verseNumber;
  final bool isDark;
  final String fontFamily;
  final double fontSize;
  final Color textColor;

  const _TappableVerse({
    required this.text,
    required this.surahNumber,
    required this.verseNumber,
    required this.isDark,
    required this.fontFamily,
    required this.fontSize,
    required this.textColor,
  });

  @override
  State<_TappableVerse> createState() => _TappableVerseState();
}

class _TappableVerseState extends State<_TappableVerse> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final highlightColor = widget.isDark
        ? const Color(0xFF00D9C0).withValues(alpha: 0.2)
        : const Color(0xFFD4A853).withValues(alpha: 0.25);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        // Open context menu
        AyahContextMenu.show(
          context,
          surah: widget.surahNumber,
          ayah: widget.verseNumber,
          ayahText: widget.text,
          isDark: widget.isDark,
        );
      },
      onTapCancel: () => setState(() => _isPressed = false),
      onLongPress: () {
        setState(() => _isPressed = false);
        // Open context menu on long press too
        AyahContextMenu.show(
          context,
          surah: widget.surahNumber,
          ayah: widget.verseNumber,
          ayahText: widget.text,
          isDark: widget.isDark,
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        decoration: BoxDecoration(
          color: _isPressed ? highlightColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '${widget.text} ',
          style: TextStyle(
            fontFamily: widget.fontFamily,
            fontSize: widget.fontSize,
            color: widget.textColor,
            height: 2.2,
            letterSpacing: 0,
            wordSpacing: 2,
          ),
        ),
      ),
    );
  }
}

/// Loading Placeholder with Circular Progress
class MushafPageSkeleton extends StatelessWidget {
  final bool isDark;

  const MushafPageSkeleton({super.key, this.isDark = false});

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF7F3E8);
    final accentColor = isDark
        ? const Color(0xFFFFC107)
        : const Color(0xFFD4A853);

    return Container(
      color: bgColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ornamental circular progress
            SizedBox(
              width: 80,
              height: 80,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer decorative ring
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.2),
                        width: 3,
                      ),
                    ),
                  ),
                  // Animated progress indicator
                  SizedBox(
                    width: 70,
                    height: 70,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                      backgroundColor: accentColor.withValues(alpha: 0.1),
                    ),
                  ),
                  // Inner decorative circle
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accentColor.withValues(alpha: 0.1),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.menu_book_rounded,
                      color: accentColor,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Loading text
            Text(
              'جاري التحميل...',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white70 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'يرجى الانتظار',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                color: isDark ? Colors.white38 : Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
