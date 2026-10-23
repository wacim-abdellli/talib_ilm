import 'package:flutter_test/flutter_test.dart';
import 'package:talib_ilm/features/adhkar/data/adhkar_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AthkarCatalog Authentic Sunnah Data Tests', () {
    final service = AthkarService();

    test('loads all 19 authentic Sunan categories from assets/data/adhkar.json', () async {
      final catalog = await service.loadCatalog();

      expect(catalog.categories.length, greaterThanOrEqualTo(19));

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
      final wuduTaharah = catalog.byId('wudu_taharah');
      final foodDrink = catalog.byId('food_drink');
      final prayerSunan = catalog.byId('prayer_sunan');
      final sicknessFunerals = catalog.byId('sickness_funerals');
      final natureWeather = catalog.byId('nature_weather');
      final socialManners = catalog.byId('social_manners');
      final fastingHajj = catalog.byId('fasting_hajj');
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
      expect(wuduFood, isNotNull, reason: 'Wudu food backward compatibility must exist');
      expect(wuduTaharah, isNotNull, reason: 'Wudu and Taharah category must exist');
      expect(foodDrink, isNotNull, reason: 'Food and Drink category must exist');
      expect(prayerSunan, isNotNull, reason: 'Prayer Sunan category must exist');
      expect(sicknessFunerals, isNotNull, reason: 'Sickness and funerals category must exist');
      expect(natureWeather, isNotNull, reason: 'Nature and weather category must exist');
      expect(socialManners, isNotNull, reason: 'Social manners category must exist');
      expect(fastingHajj, isNotNull, reason: 'Fasting and Hajj category must exist');
      expect(distress, isNotNull, reason: 'Distress and Ruqyah category must exist');
      expect(travel, isNotNull, reason: 'Travel category must exist');

      // Verify authentic counts across enriched catalog
      expect(prayerSunan!.items.length, greaterThanOrEqualTo(35));
      expect(morning!.items.length, greaterThanOrEqualTo(20));
      expect(evening!.items.length, greaterThanOrEqualTo(18));
      expect(afterPrayer!.items.length, greaterThanOrEqualTo(10));

      final totalItems = catalog.categories.fold<int>(0, (sum, c) => sum + c.items.length);
      expect(totalItems, greaterThanOrEqualTo(370));

      // Verify content integrity and title cleanliness (NO dots/ellipsis)
      for (final category in catalog.categories) {
        expect(category.title.endsWith('..'), isFalse, reason: 'Category title should not have trailing dots: ${category.title}');
        expect(category.title.contains('...'), isFalse, reason: 'Category title should not have ellipsis: ${category.title}');
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

    test('verifies all 28 scholarly categories and enriched Sunan structure', () async {
      final catalog = await service.loadCatalog();

      expect(catalog.categories.length, equals(28));

      // Granular Prayer stages
      final prayerOpening = catalog.byId('prayer_opening');
      final prayerRukuhSujud = catalog.byId('prayer_rukuh_sujud');
      final tashahhudSalat = catalog.byId('tashahhud_salat');
      final prayerBeforeSalam = catalog.byId('prayer_before_salam');
      final witrIstikharah = catalog.byId('witr_istikharah');

      expect(prayerOpening, isNotNull);
      expect(prayerRukuhSujud, isNotNull);
      expect(tashahhudSalat, isNotNull);
      expect(prayerBeforeSalam, isNotNull);
      expect(witrIstikharah, isNotNull);

      // Adhan and Mosque
      expect(catalog.byId('adhan_iqamah'), isNotNull);
      expect(catalog.byId('mosque_etiquette'), isNotNull);

      // Sickness and Funerals
      expect(catalog.byId('sickness_ruqyah'), isNotNull);
      expect(catalog.byId('funerals_graves'), isNotNull);

      // Fasting and Hajj
      expect(catalog.byId('fasting_adhkar'), isNotNull);
      expect(catalog.byId('hajj_umrah'), isNotNull);

      // Distress and Protection
      expect(catalog.byId('distress_relief'), isNotNull);
      expect(catalog.byId('protection_ruqyah'), isNotNull);

      // Quranic and Prophetic Duas
      expect(catalog.byId('quranic_duas'), isNotNull);
      expect(catalog.byId('prophetic_duas'), isNotNull);

      // Backward compatible synthesis works
      final compositePrayer = catalog.byId('prayer_sunan')!;
      expect(compositePrayer.items.length, greaterThanOrEqualTo(40));

      final compositeDuas = catalog.byId('duas')!;
      expect(compositeDuas.items.length, greaterThanOrEqualTo(30));
    });
  });
}
