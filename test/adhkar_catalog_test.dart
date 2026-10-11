import 'package:flutter_test/flutter_test.dart';
import 'package:talib_ilm/features/adhkar/data/adhkar_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AthkarCatalog Authentic Sunnah Data Tests', () {
    final service = AthkarService();

    test('loads all 13 authentic categories from assets/data/adhkar.json', () async {
      final catalog = await service.loadCatalog();

      expect(catalog.categories.isNotEmpty, isTrue);

      final morning = catalog.byId('morning');
      final evening = catalog.byId('evening');
      final afterPrayer = catalog.byId('after_prayer');
      final sleeping = catalog.byId('sleeping');
      final duas = catalog.byId('duas');
      final tasbeeh = catalog.byId('tasbeeh');
      final istighfar = catalog.byId('istighfar');
      final waking = catalog.byId('waking');
      final home = catalog.byId('home');
      final mosqueAdhan = catalog.byId('mosque_adhan');
      final wuduFood = catalog.byId('wudu_food');
      final distress = catalog.byId('distress');
      final travel = catalog.byId('travel');

      expect(morning, isNotNull, reason: 'Morning adhkar category must exist');
      expect(evening, isNotNull, reason: 'Evening adhkar category must exist');
      expect(afterPrayer, isNotNull, reason: 'After prayer adhkar category must exist');
      expect(sleeping, isNotNull, reason: 'Sleeping adhkar category must exist');
      expect(duas, isNotNull, reason: 'Duas category must exist');
      expect(tasbeeh, isNotNull, reason: 'Tasbeeh category must exist');
      expect(istighfar, isNotNull, reason: 'Istighfar category must exist');
      expect(waking, isNotNull, reason: 'Waking adhkar category must exist');
      expect(home, isNotNull, reason: 'Home category must exist');
      expect(mosqueAdhan, isNotNull, reason: 'Mosque and Adhan category must exist');
      expect(wuduFood, isNotNull, reason: 'Wudu and food category must exist');
      expect(distress, isNotNull, reason: 'Distress and Ruqyah category must exist');
      expect(travel, isNotNull, reason: 'Travel category must exist');

      // Verify authentic counts
      expect(morning!.items.length, greaterThanOrEqualTo(20));
      expect(evening!.items.length, greaterThanOrEqualTo(18));
      expect(afterPrayer!.items.length, greaterThanOrEqualTo(10));
      expect(sleeping!.items.length, greaterThanOrEqualTo(10));
      expect(duas!.items.length, greaterThanOrEqualTo(10));
      expect(tasbeeh!.items.length, greaterThanOrEqualTo(5));
      expect(istighfar!.items.length, greaterThanOrEqualTo(5));
      expect(waking!.items.length, greaterThanOrEqualTo(4));
      expect(home!.items.length, greaterThanOrEqualTo(4));
      expect(mosqueAdhan!.items.length, greaterThanOrEqualTo(5));
      expect(wuduFood!.items.length, greaterThanOrEqualTo(4));
      expect(distress!.items.length, greaterThanOrEqualTo(5));
      expect(travel!.items.length, greaterThanOrEqualTo(3));

      // Verify content integrity
      for (final category in catalog.categories) {
        for (final item in category.items) {
          expect(item.id.isNotEmpty, isTrue, reason: 'Item ID must not be empty');
          expect(item.arabic.isNotEmpty, isTrue, reason: 'Item Arabic text must not be empty');
          expect(item.source.isNotEmpty, isTrue, reason: 'Item source takhrij must not be empty for: ${item.id}');
          expect(item.target, greaterThanOrEqualTo(0), reason: 'Target must be >= 0 for: ${item.id}');
        }
      }
    });

    test('verifies primary prophetic adhkar references in catalog', () async {
      final catalog = await service.loadCatalog();

      final morning = catalog.byId('morning')!;
      final morningIds = morning.items.map((i) => i.id).toSet();
      expect(morningIds.contains('morning_kursi'), isTrue);
      expect(morningIds.contains('morning_sayyid_istighfar'), isTrue);
      expect(morningIds.contains('morning_asbahna_wa_asbaha'), isTrue);

      final afterPrayer = catalog.byId('after_prayer')!;
      final afterIds = afterPrayer.items.map((i) => i.id).toSet();
      expect(afterIds.contains('after_istighfar_salam'), isTrue);
      expect(afterIds.contains('after_tasbeeh_33'), isTrue);
      expect(afterIds.contains('after_tamam_al_miah'), isTrue);

      final sleeping = catalog.byId('sleeping')!;
      final sleepingIds = sleeping.items.map((i) => i.id).toSet();
      expect(sleepingIds.contains('sleeping_kursi'), isTrue);
      expect(sleepingIds.contains('sleeping_bismika_rabbi'), isTrue);
      expect(sleepingIds.contains('sleeping_dua_al_fitrah'), isTrue);
    });
  });
}
