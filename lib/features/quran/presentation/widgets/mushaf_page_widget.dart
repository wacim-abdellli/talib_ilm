import 'package:flutter/material.dart';
import '../../data/services/quran_page_service.dart';

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

  const MushafPageWidget({
    super.key,
    required this.pageData,
    this.fontSize = 22,
    this.isDark = false,
    this.useEnglishNumbers = false,
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
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: _buildContent(textColor),
            ),
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

  Widget _buildContent(Color textColor) {
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
                    fontFamily: 'Amiri',
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
        spans.add(
          TextSpan(
            text: '${verse.textUthmani} ',
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: fontSize,
              color: textColor,
              height: 2.2,
              letterSpacing: 0,
              wordSpacing: 2,
            ),
          ),
        );

        // Add verse number marker
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: _VerseMarker(
              number: verse.verseNumber,
              isDark: isDark,
              useEnglishNumbers: useEnglishNumbers,
            ),
          ),
        );

        spans.add(const TextSpan(text: ' '));
      }
    }

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Text.rich(
          TextSpan(children: spans),
          textAlign: TextAlign.justify,
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
            fontFamily: 'Amiri',
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

/// Verse Number Marker
class _VerseMarker extends StatelessWidget {
  final int number;
  final bool isDark;
  final bool useEnglishNumbers;

  const _VerseMarker({
    required this.number,
    required this.isDark,
    this.useEnglishNumbers = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDark ? const Color(0xFF00D9C0) : const Color(0xFFD4A853);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? color.withValues(alpha: 0.1) : Colors.white,
        border: Border.all(color: color, width: 1.5),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ]
            : [],
      ),
      alignment: Alignment.center,
      child: Text(
        useEnglishNumbers ? '$number' : _toArabicNumber(number),
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
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

/// Skeleton Loading Placeholder
class MushafPageSkeleton extends StatelessWidget {
  final bool isDark;

  const MushafPageSkeleton({super.key, this.isDark = false});

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF7F3E8);
    final shimmerColor = isDark
        ? Colors.white10
        : Colors.black.withValues(alpha: 0.05);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: shimmerColor, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Header skeleton
          Container(
            height: 40,
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: shimmerColor)),
            ),
          ),
          // Content skeleton
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: List.generate(
                  12,
                  (i) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Container(
                      height: 20,
                      decoration: BoxDecoration(
                        color: shimmerColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Footer skeleton
          Container(
            height: 40,
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: shimmerColor)),
            ),
          ),
        ],
      ),
    );
  }
}
