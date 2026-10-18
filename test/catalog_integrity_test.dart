import 'package:flutter_test/flutter_test.dart';
import 'package:talib_ilm/features/ilm/data/catalogs/mutun_digital_catalog.dart';

void main() {
  group('MutunDigitalCatalog Integrity Tests', () {
    test('All digital mutun entries have unique syllabus IDs', () {
      final ids = MutunDigitalCatalog.entries.keys.toList();
      final uniqueIds = ids.toSet();
      expect(ids.length, uniqueIds.length, reason: 'Duplicate syllabus book IDs found');
      expect(ids.length, greaterThanOrEqualTo(16), reason: 'At least 16 mutun expected');
    });

    test('All digital mutun entries have unique Shamela IDs', () {
      final shamelaIds = MutunDigitalCatalog.entries.values.map((e) => e.shamelaId).toList();
      final uniqueShamelaIds = shamelaIds.toSet();

      // Verify no duplicates
      expect(
        shamelaIds.length,
        uniqueShamelaIds.length,
        reason: 'Duplicate shamelaIds found in MutunDigitalCatalog: $shamelaIds',
      );
    });

    test('All totalPages values are strictly > 0', () {
      for (final entry in MutunDigitalCatalog.entries.values) {
        expect(
          entry.totalPages,
          greaterThan(0),
          reason: '${entry.id} (${entry.title}) has invalid totalPages: ${entry.totalPages}',
        );
      }
    });

    test('All shamelaIds are strictly > 0', () {
      for (final entry in MutunDigitalCatalog.entries.values) {
        expect(
          entry.shamelaId,
          greaterThan(0),
          reason: '${entry.id} (${entry.title}) has invalid shamelaId: ${entry.shamelaId}',
        );
      }
    });

    test('bk_shuroot_salah has correct verified Shamela ID and does not collide with bk_usul_thalatha', () {
      final shurootSalah = MutunDigitalCatalog.getEntry('bk_shuroot_salah');
      final usulThalatha = MutunDigitalCatalog.getEntry('bk_usul_thalatha');

      expect(shurootSalah, isNotNull);
      expect(usulThalatha, isNotNull);
      expect(shurootSalah!.shamelaId, 11266);
      expect(shurootSalah.totalPages, 10);
      expect(shurootSalah.shamelaId, isNot(equals(usulThalatha!.shamelaId)));
    });
  });
}
