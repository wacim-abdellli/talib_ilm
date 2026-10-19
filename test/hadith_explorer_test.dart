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

    test('All hadiths have meaningful authentic benefits without boilerplate templates', () async {
      final all = await service.getAllHadiths();
      expect(all, isNotEmpty);

      // Verify every hadith has populated benefits
      for (final h in all) {
        expect(h.benefits, isNotEmpty, reason: 'Hadith ${h.id} has empty benefits');
        expect(
          h.benefits.contains('حديث جليل من كتاب'),
          isFalse,
          reason: 'Hadith ${h.id} still contains generic book template: ${h.benefits}',
        );
      }

      // Verify riyad_1058 specifically (user-reported hadith)
      final h1058 = all.firstWhere((h) => h.id == 'riyad_1058');
      expect(h1058.benefits, contains('التقعر والتكلف في الكلام'));
    });

    test('Zero repeated Salawat and zero سلمى typos across all hadiths', () async {
      final all = await service.getAllHadiths();
      final repeatedRegex = RegExp(r'(?:صلى\s+)?الله\s+عليه\s+وسلم[ى]?\s+(?:صلى\s+)?الله\s+عليه\s+وسلم');

      for (final h in all) {
        expect(
          repeatedRegex.hasMatch(h.matn),
          isFalse,
          reason: 'Hadith ${h.id} has repeated salawat: ${h.matn}',
        );
        expect(
          h.matn.contains('وسلمى'),
          isFalse,
          reason: 'Hadith ${h.id} has وسلمى typo in matn',
        );
        expect(
          h.title.contains('وسلمى'),
          isFalse,
          reason: 'Hadith ${h.id} has وسلمى typo in title',
        );
      }
    });

    test('Narrator honorific gender and dual agreement are 100% accurate', () async {
      final all = await service.getAllHadiths();
      final femaleKeywords = [
        'عائشة', 'أم سلمة', 'حفصة', 'زينب', 'ميمونة', 'صفية', 'جويرية',
        'سودة', 'أم حبيبة', 'خديجة', 'فاطمة', 'أسماء', 'أم عطية', 'أم سليم'
      ];
      final dualKeywords = [
        'ابن عباس', 'ابن عمر', 'ابن عمرو', 'أسامة بن زيد', 'ابن الزبير',
        'عبد الله بن عباس', 'عبد الله بن عمر', 'عبد الله بن عمرو', 'عبد الله بن الزبير',
        'جابر بن عبد الله', 'النعمان بن بشير', 'البراء بن عازب'
      ];

      final anhRegex = RegExp(r'رضي\s+الله\s+عنه(?![ماهم])');

      for (final h in all) {
        // Female companions must have عنها
        for (final f in femaleKeywords) {
          if (h.narrator.contains(f)) {
            expect(
              anhRegex.hasMatch(h.narrator) && !h.narrator.contains('عنها'),
              isFalse,
              reason: 'Hadith ${h.id} has wrong gender for female narrator: ${h.narrator}',
            );
          }
        }

        // Dual companions must have عنهما
        for (final d in dualKeywords) {
          if (h.narrator.contains(d)) {
            expect(
              anhRegex.hasMatch(h.narrator) && !h.narrator.contains('عنهما') && !h.narrator.contains('عنهم'),
              isFalse,
              reason: 'Hadith ${h.id} has wrong dual honorific: ${h.narrator}',
            );
          }
        }
      }
    });

    test('User-reported hadiths (riyad_209, riyad_222, riyad_265) are fully pristine', () async {
      final all = await service.getAllHadiths();

      // riyad_209: Title was 'أفيلتزمه ويقبله؟فال'
      final h209 = all.firstWhere((h) => h.id == 'riyad_209');
      expect(h209.title, isNot(contains('؟فال')));
      expect(h209.title, isNot(contains('فال')));
      expect(h209.title, contains('أدب لقاء'));
      expect(h209.matn, contains('أينحني'));
      expect(h209.matn, contains('أفيلتزمه ويقبله؟ قال:'));

      // riyad_222: Had repeated salawat, وسلمى, عائشة رضي الله عنه, اشتكي, الأنسان, عيينه
      final h222 = all.firstWhere((h) => h.id == 'riyad_222');
      expect(h222.narrator, contains('رضي الله عنها'));
      expect(h222.matn, contains('اشتكى الإنسان'));
      expect(h222.matn, contains('سفيان بن عيينة'));
      expect(h222.matn.contains('وسلمى'), isFalse);
      expect(h222.matn.contains('صلى الله عليه وسلم الله عليه وسلم'), isFalse);

      // riyad_265: Title was 'الله عليه وسلمى الله عليه وسلم الله عليه وسلم يعوده فقال'
      final h265 = all.firstWhere((h) => h.id == 'riyad_265');
      expect(h265.title, contains('عيادة المريض'));
      expect(h265.matn.contains('وسلمى'), isFalse);
      expect(h265.matn, contains('لا أرى طلحة'));
    });
  });
}
