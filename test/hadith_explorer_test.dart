import 'package:flutter_test/flutter_test.dart';
import 'package:talib_ilm/features/hadith/data/services/hadith_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HadithService Collections & Categories Verification', () {
    final service = HadithService();

    test('getAllHadiths loads comprehensive collection of 2000+ hadiths', () async {
      final hadiths = await service.getAllHadiths();
      expect(hadiths.length, greaterThanOrEqualTo(2000));
    });

    test('Canonical collections include Bukhari, Muslim and Muttafaq', () async {
      final collections = await service.getCollections();
      expect(collections, contains('الكل'));
      expect(collections, contains('صحيح البخاري'));
      expect(collections, contains('صحيح مسلم'));
      expect(collections, contains('متفق عليه'));
      expect(collections, contains('رياض الصالحين'));
      expect(collections, contains('الأربعون النووية'));
      expect(collections, contains('الأحاديث القدسية'));
    });

    test('Collection filters return substantial numbers of hadiths', () async {
      final all = await service.getAllHadiths();

      final bukhariHadiths = service.filterByCollection(all, 'صحيح البخاري');
      expect(bukhariHadiths.length, greaterThanOrEqualTo(900));

      final muslimHadiths = service.filterByCollection(all, 'صحيح مسلم');
      expect(muslimHadiths.length, greaterThanOrEqualTo(1200));

      final muttafaqHadiths = service.filterByCollection(all, 'متفق عليه');
      expect(muttafaqHadiths.length, greaterThanOrEqualTo(680));
    });

    test('Target categories return multiple hadiths and never only 1', () async {
      final all = await service.getAllHadiths();

      // ousoul al a9ida (Creed & Faith)
      final aqida = all.where((h) => h.category == 'أصول العقيدة').toList();
      expect(aqida.length, greaterThan(10), reason: 'أصول العقيدة must have multiple hadiths');

      // i5las niya (Sincerity & Intention)
      final ikhlas = all.where((h) => h.category == 'الإخلاص والنية').toList();
      expect(ikhlas.length, greaterThan(15), reason: 'الإخلاص والنية must have multiple hadiths');

      // qadar wa qatha2 (Predestination & Decree)
      final qadar = all.where((h) => h.category == 'القضاء والقدر').toList();
      expect(qadar.length, greaterThan(10), reason: 'القضاء والقدر must have multiple hadiths');
    });

    test('Daily hadith and random hadith are functional', () async {
      final daily = await service.getDailyHadith();
      expect(daily, isNotNull);
      expect(daily!.matn, isNotEmpty);

      final random = await service.getRandomHadith(excludeId: daily.id);
      expect(random, isNotNull);
      expect(random!.id, isNot(daily.id));
    });

    test('Normalized Arabic search finds hadiths without tashkeel or hamza mismatch', () async {
      final search1 = await service.searchHadiths('الاعمال بالنيات');
      expect(search1, isNotEmpty);
      expect(search1.first.title, contains('النيات'));

      final search2 = await service.searchHadiths('مقادير الخلائق');
      expect(search2, isNotEmpty);
    });
  });
}
