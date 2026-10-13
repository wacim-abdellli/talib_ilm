import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as quran;

import '../../presentation/widgets/mushaf_page_viewer.dart';
import '../models/hizb_catalog.dart';

/// Parsed result of a `talibilm://quran/...` deep link.
class QuranDeepLinkTarget {
  final bool isValid;
  final int? page;
  final int? surah;
  final int? ayah;
  final String? errorMessage;

  const QuranDeepLinkTarget({
    required this.isValid,
    this.page,
    this.surah,
    this.ayah,
    this.errorMessage,
  });

  const QuranDeepLinkTarget.invalid(String message)
      : isValid = false,
        page = null,
        surah = null,
        ayah = null,
        errorMessage = message;
}

/// Service parsing and validating deep links for the Holy Quran:
/// Supported URI patterns:
/// - `talibilm://quran/page/{page}` (1..604)
/// - `talibilm://quran/surah/{surah}` (1..114)
/// - `talibilm://quran/surah/{surah}/ayah/{ayah}` (1..114, 1..verseCount)
/// - `talibilm://quran/juz/{juz}` (1..30)
/// - `talibilm://quran/hizb/{hizb}` (1..60)
class QuranDeepLinkService {
  QuranDeepLinkService._();

  static const String scheme = 'talibilm';
  static const String host = 'quran';

  /// Parses and validates a deep link URI.
  static QuranDeepLinkTarget parse(Uri uri) {
    if (uri.scheme != scheme) {
      return const QuranDeepLinkTarget.invalid('المخطط غير صحيح (يجب أن يبدأ بـ talibilm://)');
    }

    if (uri.host != host) {
      return const QuranDeepLinkTarget.invalid('المسار غير صالح للقرآن الكريم');
    }

    final segments = uri.pathSegments;
    if (segments.isEmpty) {
      return const QuranDeepLinkTarget.invalid('مسار الرابط فارغ');
    }

    final first = segments[0].toLowerCase();

    // 1. /page/{page}
    if (first == 'page') {
      if (segments.length < 2) {
        return const QuranDeepLinkTarget.invalid('يرجى تحديد رقم الصفحة');
      }
      final pageNum = int.tryParse(segments[1]);
      if (pageNum == null || pageNum < 1 || pageNum > 604) {
        return const QuranDeepLinkTarget.invalid(
          'رقم الصفحة غير صالح (يجب أن يكون بين 1 و 604)',
        );
      }
      return QuranDeepLinkTarget(isValid: true, page: pageNum);
    }

    // 2. /surah/{surah} or /surah/{surah}/ayah/{ayah}
    if (first == 'surah') {
      if (segments.length < 2) {
        return const QuranDeepLinkTarget.invalid('يرجى تحديد رقم السورة');
      }
      final surahNum = int.tryParse(segments[1]);
      if (surahNum == null || surahNum < 1 || surahNum > 114) {
        return const QuranDeepLinkTarget.invalid(
          'رقم السورة غير صالح (يجب أن يكون بين 1 و 114)',
        );
      }

      int ayahNum = 1;
      if (segments.length >= 4 && segments[2].toLowerCase() == 'ayah') {
        final parsedAyah = int.tryParse(segments[3]);
        final maxVerses = quran.getVerseCount(surahNum);
        if (parsedAyah == null || parsedAyah < 1 || parsedAyah > maxVerses) {
          final surahName = quran.getSurahNameArabic(surahNum);
          return QuranDeepLinkTarget.invalid(
            'رقم الآية غير صالح لسورة $surahName (عدد آياتها $maxVerses)',
          );
        }
        ayahNum = parsedAyah;
      }

      final page = quran.getPageNumber(surahNum, ayahNum);
      return QuranDeepLinkTarget(
        isValid: true,
        page: page,
        surah: surahNum,
        ayah: ayahNum,
      );
    }

    // 3. /juz/{juz}
    if (first == 'juz') {
      if (segments.length < 2) {
        return const QuranDeepLinkTarget.invalid('يرجى تحديد رقم الجزء');
      }
      final juzNum = int.tryParse(segments[1]);
      if (juzNum == null || juzNum < 1 || juzNum > 30) {
        return const QuranDeepLinkTarget.invalid(
          'رقم الجزء غير صالح (يجب أن يكون بين 1 و 30)',
        );
      }
      final map = quran.getSurahAndVersesFromJuz(juzNum);
      final firstSurah = map.keys.first;
      final firstVerse = map[firstSurah]!.first;
      final page = quran.getPageNumber(firstSurah, firstVerse);
      return QuranDeepLinkTarget(
        isValid: true,
        page: page,
        surah: firstSurah,
        ayah: firstVerse,
      );
    }

    // 4. /hizb/{hizb}
    if (first == 'hizb') {
      if (segments.length < 2) {
        return const QuranDeepLinkTarget.invalid('يرجى تحديد رقم الحزب');
      }
      final hizbNum = int.tryParse(segments[1]);
      if (hizbNum == null || hizbNum < 1 || hizbNum > 60) {
        return const QuranDeepLinkTarget.invalid(
          'رقم الحزب غير صالح (يجب أن يكون بين 1 و 60)',
        );
      }
      final hizb = HizbCatalog.getHizb(hizbNum);
      return QuranDeepLinkTarget(
        isValid: true,
        page: hizb.startPage,
        surah: hizb.startSurah,
        ayah: hizb.startAyah,
      );
    }

    return QuranDeepLinkTarget.invalid('مسار الرابط غير معروف: /$first');
  }

  /// Opens the target in the Mushaf reader if valid.
  static Future<bool> openTarget(
    BuildContext context,
    QuranDeepLinkTarget target,
  ) async {
    if (!target.isValid || target.page == null) return false;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MushafPageViewer(
          initialPage: target.page!,
          initialSurah: target.surah,
          initialAyah: target.ayah,
        ),
      ),
    );
    return true;
  }
}
