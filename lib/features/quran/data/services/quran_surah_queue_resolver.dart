import 'package:just_audio_background/just_audio_background.dart';
import 'package:quran/quran.dart' as quran;

import '../models/hifdh_range_config.dart';
import '../models/quran_reciter.dart';
import 'quran_audio_downloader.dart';

/// Pure helpers for Quran audio URL construction, media notifications, and queue progression.
class QuranSurahQueueResolver {
  const QuranSurahQueueResolver._();

  static final Uri _appIconUri = Uri.parse(
    'android.resource://com.talibilm.app/drawable/quran_artwork',
  );

  static bool isValidSurah(int surah) => surah >= 1 && surah <= 114;

  static bool isValidVerse(int surah, int ayah) {
    if (!isValidSurah(surah)) return false;
    return ayah >= 1 && ayah <= quran.getVerseCount(surah);
  }

  static String formatNumber(int n) => n.toString().padLeft(3, '0');

  /// Builds the streaming audio URL for a reciter and (surah, ayah) pair.
  static String buildAudioUrl(
    int surah,
    int ayah, {
    required QuranReciter reciter,
  }) {
    if (!isValidSurah(surah)) {
      throw ArgumentError('Invalid surah number: $surah. Must be 1..114');
    }
    if (!isValidVerse(surah, ayah)) {
      throw ArgumentError('Invalid ayah number: $ayah for surah $surah');
    }
    final effectiveReciter = (reciter.isSurahBased && !reciter.hasSurah(surah))
        ? QuranReciter.defaultReciters.first
        : reciter;
    final sStr = formatNumber(surah);
    if (effectiveReciter.isSurahBased) {
      return '${effectiveReciter.surahBaseUrl}$sStr.mp3';
    }
    final aStr = formatNumber(ayah);
    return 'https://everyayah.com/data/${effectiveReciter.subfolder}/$sStr$aStr.mp3';
  }

  static MediaItem buildSurahMediaItem(
    int surah,
    QuranReciter reciter,
    String surahName, [
    Duration? duration,
  ]) =>
      MediaItem(
        id: '${reciter.id}_surah_$surah',
        album: 'القرآن الكريم',
        title: 'سورة $surahName',
        artist: reciter.name,
        artUri: _appIconUri,
        duration: duration,
        displayTitle: 'سورة $surahName',
        displaySubtitle: reciter.name,
        displayDescription: 'تلاوة سورة $surahName كاملة · ${reciter.name}',
      );

  static MediaItem buildAyahMediaItem(
    int surah,
    int ayah,
    QuranReciter reciter,
    String surahName,
  ) =>
      MediaItem(
        id: '${reciter.id}_${surah}_$ayah',
        album: 'سورة $surahName',
        title: 'الآية $ayah - سورة $surahName',
        artist: reciter.name,
        artUri: _appIconUri,
        displayTitle: 'سورة $surahName',
        displaySubtitle: 'الآية $ayah · ${reciter.name}',
        displayDescription: 'تلاوة القرآن الكريم - طالب العلم',
      );

  /// Resolves the next (`step = 1`) or previous (`step = -1`) surah respecting
  /// active playlists, downloaded-only mode, limited reciters, and repeat mode.
  static Future<int?> resolveAdjacentSurah({
    required int currentSurah,
    required int step,
    required QuranReciter reciter,
    required List<int>? playbackQueue,
    required bool downloadedQueueOnly,
    required AudioRepeatMode repeatMode,
  }) async {
    final isForward = step >= 0;

    // 1. Explicit active queue (e.g. from downloaded playlist)
    if (playbackQueue != null && playbackQueue.isNotEmpty) {
      return _stepWithinList(
        playbackQueue,
        currentSurah,
        isForward: isForward,
        repeatMode: repeatMode,
        findGreaterWhenMissing: isForward,
      );
    }

    // 2. Downloaded-only mode (auto-advance strictly within downloaded surahs)
    if (downloadedQueueOnly) {
      final downloaded =
          await QuranAudioDownloader.getDownloadedSurahNumbers(reciter: reciter);
      if (downloaded.isNotEmpty) {
        return _stepWithinList(
          downloaded,
          currentSurah,
          isForward: isForward,
          repeatMode: repeatMode,
          findGreaterWhenMissing: isForward,
        );
      }
    }

    // 3. Reciter with limited available surahs (e.g. Omar Diya Al-Din)
    if (reciter.isSurahBased && reciter.availableSurahs != null) {
      final available = reciter.availableSurahs!.toList()..sort();
      return _stepWithinList(
        available,
        currentSurah,
        isForward: isForward,
        repeatMode: repeatMode,
        findGreaterWhenMissing: false,
      );
    }

    // 4. Standard sequential 1..114 progression
    if (isForward) {
      if (currentSurah < 114) return currentSurah + 1;
      return repeatMode == AudioRepeatMode.infinite ? 1 : null;
    } else {
      if (currentSurah > 1) return currentSurah - 1;
      return repeatMode == AudioRepeatMode.infinite ? 114 : null;
    }
  }

  static int? _stepWithinList(
    List<int> items,
    int currentSurah, {
    required bool isForward,
    required AudioRepeatMode repeatMode,
    required bool findGreaterWhenMissing,
  }) {
    if (items.isEmpty) return null;
    final idx = items.indexOf(currentSurah);
    final isInfinite = repeatMode == AudioRepeatMode.infinite;

    if (isForward) {
      if (idx != -1) {
        if (idx + 1 < items.length) return items[idx + 1];
        return isInfinite ? items.first : null;
      }
      if (findGreaterWhenMissing) {
        final next = items.cast<int?>().firstWhere(
              (s) => s != null && s > currentSurah,
              orElse: () => null,
            );
        if (next != null) return next;
      }
      return isInfinite ? items.first : null;
    } else {
      if (idx > 0) return items[idx - 1];
      return isInfinite ? items.last : null;
    }
  }
}
