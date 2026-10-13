import 'package:qcf_quran_plus/qcf_quran_plus.dart' as qcf;
import 'package:quran/quran.dart' as quran;

/// Model representing a single Quarter of a Hizb (Rub el Hizb - 1/4).
class HizbQuarter {
  final int globalQuarter; // 1 to 240
  final int quarterInHizb; // 1 to 4
  final int hizbNumber; // 1 to 60
  final int surah;
  final int ayah;
  final int page;
  final String titleArabic;
  final String firstVerseSnippet;

  const HizbQuarter({
    required this.globalQuarter,
    required this.quarterInHizb,
    required this.hizbNumber,
    required this.surah,
    required this.ayah,
    required this.page,
    required this.titleArabic,
    required this.firstVerseSnippet,
  });
}

/// Model representing a complete Hizb (60 Ahzab in the Holy Quran).
/// Sourced directly from the official King Fahd Complex for the Printing
/// of the Holy Quran (مجمع الملك فهد لطباعة المصحف الشريف - مصحف المدينة المنورة).
class HizbItem {
  final int hizbNumber; // 1 to 60
  final int juzNumber; // 1 to 30
  final String nameArabic; // e.g. "الحزب الأول"
  final int startSurah;
  final int startAyah;
  final int startPage;
  final String surahNameArabic;
  final String firstVerseSnippet;
  final List<HizbQuarter> quarters;

  const HizbItem({
    required this.hizbNumber,
    required this.juzNumber,
    required this.nameArabic,
    required this.startSurah,
    required this.startAyah,
    required this.startPage,
    required this.surahNameArabic,
    required this.firstVerseSnippet,
    required this.quarters,
  });
}

/// Canonical catalog of the 60 Ahzab and 240 Quarters of the Holy Quran.
class HizbCatalog {
  HizbCatalog._();

  static const List<String> _hizbNamesArabic = [
    'الأول',
    'الثاني',
    'الثالث',
    'الرابع',
    'الخامس',
    'السادس',
    'السابع',
    'الثامن',
    'التاسع',
    'العاشر',
    'الحادي عشر',
    'الثاني عشر',
    'الثالث عشر',
    'الرابع عشر',
    'الخامس عشر',
    'السادس عشر',
    'السابع عشر',
    'الثامن عشر',
    'التاسع عشر',
    'العشرون',
    'الحادي والعشرون',
    'الثاني والعشرون',
    'الثالث والعشرون',
    'الرابع والعشرون',
    'الخامس والعشرون',
    'السادس والعشرون',
    'السابع والعشرون',
    'الثامن والعشرون',
    'التاسع والعشرون',
    'الثلاثون',
    'الحادي والثلاثون',
    'الثاني والثلاثون',
    'الثالث والثلاثون',
    'الرابع والثلاثون',
    'الخامس والثلاثون',
    'السادس والثلاثون',
    'السابع والثلاثون',
    'الثامن والثلاثون',
    'التاسع والثلاثون',
    'الأربعون',
    'الحادي والأربعون',
    'الثاني والأربعون',
    'الثالث والأربعون',
    'الرابع والأربعون',
    'الخامس والأربعون',
    'السادس والأربعون',
    'السابع والأربعون',
    'الثامن والأربعون',
    'التاسع والأربعون',
    'الخمسون',
    'الحادي والخمسون',
    'الثاني والخمسون',
    'الثالث والخمسون',
    'الرابع والخمسون',
    'الخامس والخمسون',
    'السادس والخمسون',
    'السابع والخمسون',
    'الثامن والخمسون',
    'التاسع والخمسون',
    'الستون',
  ];

  static List<HizbItem>? _cachedHizbs;

  /// Returns the complete authentic list of 60 Ahzab with their 4 quarters each.
  static List<HizbItem> getAllHizbs() {
    if (_cachedHizbs != null) return _cachedHizbs!;

    final list = <HizbItem>[];
    final allQuarters = qcf.quarters;

    for (int h = 1; h <= 60; h++) {
      final startIndex = (h - 1) * 4;
      final quartersOfHizb = <HizbQuarter>[];

      for (int q = 0; q < 4; q++) {
        final qIdx = startIndex + q;
        if (qIdx < allQuarters.length) {
          final qData = allQuarters[qIdx];
          final sNum = qData['surah'] as int;
          final aNum = qData['ayah'] as int;
          final pageNum = quran.getPageNumber(sNum, aNum);
          final text = quran.getVerse(sNum, aNum, verseEndSymbol: false);

          String qTitle;
          if (q == 0) {
            qTitle = 'بداية الحزب $h';
          } else if (q == 1) {
            qTitle = 'ربع الحزب $h';
          } else if (q == 2) {
            qTitle = 'نصف الحزب $h';
          } else {
            qTitle = 'ثلاثة أرباع الحزب $h';
          }

          quartersOfHizb.add(
            HizbQuarter(
              globalQuarter: qIdx + 1,
              quarterInHizb: q + 1,
              hizbNumber: h,
              surah: sNum,
              ayah: aNum,
              page: pageNum,
              titleArabic: qTitle,
              firstVerseSnippet: text,
            ),
          );
        }
      }

      final firstQ = quartersOfHizb.first;
      final juzNum = ((h - 1) ~/ 2) + 1;
      final nameSuffix = (h - 1 < _hizbNamesArabic.length)
          ? _hizbNamesArabic[h - 1]
          : '$h';

      list.add(
        HizbItem(
          hizbNumber: h,
          juzNumber: juzNum,
          nameArabic: 'الحزب $nameSuffix',
          startSurah: firstQ.surah,
          startAyah: firstQ.ayah,
          startPage: firstQ.page,
          surahNameArabic: quran.getSurahNameArabic(firstQ.surah),
          firstVerseSnippet: firstQ.firstVerseSnippet,
          quarters: quartersOfHizb,
        ),
      );
    }

    _cachedHizbs = list;
    return list;
  }

  /// Get specific Hizb by its number (1 to 60)
  static HizbItem getHizb(int hizbNumber) {
    if (hizbNumber < 1 || hizbNumber > 60) {
      throw RangeError('Hizb number must be between 1 and 60 (got $hizbNumber)');
    }
    return getAllHizbs()[hizbNumber - 1];
  }
}
