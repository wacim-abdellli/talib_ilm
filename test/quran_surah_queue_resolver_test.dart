import 'package:flutter_test/flutter_test.dart';
import 'package:talib_ilm/features/quran/data/models/hifdh_range_config.dart';
import 'package:talib_ilm/features/quran/data/models/quran_reciter.dart';
import 'package:talib_ilm/features/quran/data/services/quran_surah_queue_resolver.dart';

void main() {
  group('QuranSurahQueueResolver', () {
    final defaultReciter = QuranReciter.defaultReciters.first;

    test('resolves explicit playbackQueue forward and backward with infinite wrap', () async {
      final queue = [1, 18, 36, 112];

      expect(
        await QuranSurahQueueResolver.resolveAdjacentSurah(
          currentSurah: 1,
          step: 1,
          reciter: defaultReciter,
          playbackQueue: queue,
          downloadedQueueOnly: false,
          repeatMode: AudioRepeatMode.none,
        ),
        18,
      );

      expect(
        await QuranSurahQueueResolver.resolveAdjacentSurah(
          currentSurah: 112,
          step: 1,
          reciter: defaultReciter,
          playbackQueue: queue,
          downloadedQueueOnly: false,
          repeatMode: AudioRepeatMode.none,
        ),
        isNull,
      );

      expect(
        await QuranSurahQueueResolver.resolveAdjacentSurah(
          currentSurah: 112,
          step: 1,
          reciter: defaultReciter,
          playbackQueue: queue,
          downloadedQueueOnly: false,
          repeatMode: AudioRepeatMode.infinite,
        ),
        1,
      );

      expect(
        await QuranSurahQueueResolver.resolveAdjacentSurah(
          currentSurah: 1,
          step: -1,
          reciter: defaultReciter,
          playbackQueue: queue,
          downloadedQueueOnly: false,
          repeatMode: AudioRepeatMode.infinite,
        ),
        112,
      );

      expect(
        await QuranSurahQueueResolver.resolveAdjacentSurah(
          currentSurah: 36,
          step: -1,
          reciter: defaultReciter,
          playbackQueue: queue,
          downloadedQueueOnly: false,
          repeatMode: AudioRepeatMode.none,
        ),
        18,
      );
    });

    test('resolves limited-surah reciter and standard 1..114 boundaries cleanly', () async {
      final limited = QuranReciter.defaultReciters.firstWhere(
        (r) => r.isSurahBased && r.availableSurahs != null,
      );
      final sorted = limited.availableSurahs!.toList()..sort();

      expect(
        await QuranSurahQueueResolver.resolveAdjacentSurah(
          currentSurah: sorted.first,
          step: 1,
          reciter: limited,
          playbackQueue: null,
          downloadedQueueOnly: false,
          repeatMode: AudioRepeatMode.none,
        ),
        sorted[1],
      );

      expect(
        await QuranSurahQueueResolver.resolveAdjacentSurah(
          currentSurah: 114,
          step: 1,
          reciter: defaultReciter,
          playbackQueue: null,
          downloadedQueueOnly: false,
          repeatMode: AudioRepeatMode.infinite,
        ),
        1,
      );

      expect(
        await QuranSurahQueueResolver.resolveAdjacentSurah(
          currentSurah: 1,
          step: -1,
          reciter: defaultReciter,
          playbackQueue: null,
          downloadedQueueOnly: false,
          repeatMode: AudioRepeatMode.infinite,
        ),
        114,
      );
    });

    test('builds valid URLs and rejects invalid surah/ayah inputs', () {
      expect(
        QuranSurahQueueResolver.buildAudioUrl(1, 7, reciter: defaultReciter),
        endsWith('/001007.mp3'),
      );
      expect(
        () => QuranSurahQueueResolver.buildAudioUrl(0, 1, reciter: defaultReciter),
        throwsArgumentError,
      );
      expect(
        () => QuranSurahQueueResolver.buildAudioUrl(1, 99, reciter: defaultReciter),
        throwsArgumentError,
      );
    });
  });
}
