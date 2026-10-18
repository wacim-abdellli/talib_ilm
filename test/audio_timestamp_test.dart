import 'package:flutter_test/flutter_test.dart';
import 'package:talib_ilm/features/ilm/data/catalogs/mutun_audio_catalog.dart';

void main() {
  group('MutunAudioCatalog Paragraph Timestamps Integrity Tests', () {
    test('All books with timestamps satisfy integrity assertions', () {
      final entriesWithTimestamps = <String, MatnAudioSource>{};

      for (final entry in MutunAudioCatalog.entries.values) {
        for (final source in entry.sources) {
          if (source.paragraphTimestamps != null) {
            entriesWithTimestamps['${entry.bookId}_${source.reciter.id}'] = source;
          }
        }
      }

      expect(
        entriesWithTimestamps.isNotEmpty,
        isTrue,
        reason: 'Catalog must contain books with paragraphTimestamps',
      );

      // Verify that the 3 priority books have timestamps
      expect(
        MutunAudioCatalog.getEntry('bk_arbaeen_nawawi')?.getSource()?.paragraphTimestamps,
        isNotNull,
      );
      expect(
        MutunAudioCatalog.getEntry('bk_wasitiyyah')?.getSource()?.paragraphTimestamps,
        isNotNull,
      );
      expect(
        MutunAudioCatalog.getEntry('bk_ajrumiyyah')?.getSource()?.paragraphTimestamps,
        isNotNull,
      );

      for (final MapEntry(key: bookKey, value: source) in entriesWithTimestamps.entries) {
        final timestamps = source.paragraphTimestamps!;

        // 1. Assert timestamps.first == 0
        expect(
          timestamps.first,
          equals(0),
          reason: '$bookKey: First timestamp must be 0 ms (audio start)',
        );

        // 2. Assert timestamps.length == totalParagraphs
        expect(
          timestamps.length,
          equals(source.totalParagraphs),
          reason: '$bookKey: Timestamps count (${timestamps.length}) must match totalParagraphs (${source.totalParagraphs}) exactly',
        );

        // 3. Assert timestamps is strictly ascending and no gap > 600,000 ms (10 minutes)
        for (int i = 0; i < timestamps.length - 1; i++) {
          final current = timestamps[i];
          final next = timestamps[i + 1];

          expect(
            current < next,
            isTrue,
            reason: '$bookKey: Timestamps must be strictly ascending: index $i ($current ms) < index ${i + 1} ($next ms)',
          );

          final gap = next - current;
          expect(
            gap <= 600000,
            isTrue,
            reason: '$bookKey: Gap between paragraph $i and ${i + 1} ($gap ms) must not exceed 600000 ms (10 minutes)',
          );
        }
      }
    });
  });
}
