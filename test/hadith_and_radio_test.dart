import 'package:flutter_test/flutter_test.dart';
import 'package:talib_ilm/features/hadith/data/models/hadith_models.dart';
import 'package:talib_ilm/features/radio/data/models/quran_radio_model.dart';
import 'package:talib_ilm/features/quran/data/services/quran_tafsir_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Graded Hadith Model & Services', () {
    test('GradedHadith parses correctly from json', () {
      final json = {
        'id': 'test_1',
        'number': 1,
        'title': 'إنما الأعمال بالنيات',
        'collection': 'الأربعون النووية',
        'category': 'الإخلاص والنية',
        'grade': 'صحيح متفق عليه',
        'source': 'رواه البخاري ومسلم',
        'narrator': 'عمر بن الخطاب رضي الله عنه',
        'matn': 'إنما الأعمال بالنيات وإنما لكل امرئ ما نوى',
        'benefits': 'مدار الأعمال على النيات',
      };

      final hadith = GradedHadith.fromJson(json);
      expect(hadith.id, 'test_1');
      expect(hadith.number, 1);
      expect(hadith.isSahih, isTrue);
      expect(hadith.shortMatn, contains('إنما الأعمال'));

      final legacy = hadith.toLegacyHadith();
      expect(legacy.text, hadith.matn);
      expect(legacy.source, contains('صحيح متفق عليه'));
    });

    test('cleanTitle strips trailing dots and generic prefixes cleanly', () {
      final h1 = GradedHadith(
        id: '1',
        number: 1,
        title: 'الحياء من الإيمان...',
        collection: 'رياض الصالحين',
        category: 'باب الحياء',
        grade: 'صحيح',
        source: 'متفق عليه',
        narrator: 'أبو هريرة',
        matn: 'الحياء من الإيمان',
        benefits: '',
      );
      expect(h1.cleanTitle, 'الحياء من الإيمان');
      expect(h1.cleanTitle.contains('..'), isFalse);

      final h2 = GradedHadith(
        id: '2',
        number: 2,
        title: 'حديث من كتاب الأدب (1)',
        collection: 'رياض الصالحين',
        category: 'باب حسن الخلق',
        grade: 'صحيح',
        source: 'متفق عليه',
        narrator: 'أبو هريرة',
        matn: 'أكمل المؤمنين إيمانا أحسنهم خلقا',
        benefits: '',
      );
      expect(h2.cleanTitle, 'باب حسن الخلق');
      expect(h2.cleanTitle.startsWith('حديث من'), isFalse);
    });
  });

  group('Quran Radio Model', () {
    test('QuranRadioStation parses correctly from json', () {
      final json = {
        'id': 1,
        'name': 'محمود خليل الحصري (ورش عن نافع)',
        'rawName': 'محمود خليل الحصري - رواية ورش عن نافع',
        'url': 'https://backup.qurango.net/radio/mahmoud_khalil_alhussary_warsh',
        'category': 'رواية ورش',
      };

      final station = QuranRadioStation.fromJson(json);
      expect(station.id, 1);
      expect(station.name, contains('الحصري'));
      expect(station.category, 'رواية ورش');
      expect(station.url, startsWith('https://'));
    });
  });

  group('Resilient Tafsir Scholars', () {
    test('All Tafsir scholars have defined authors and names', () {
      for (final scholar in TafsirScholar.values) {
        expect(QuranTafsirService.getScholarName(scholar), isNotEmpty);
        expect(QuranTafsirService.getScholarAuthor(scholar), isNotEmpty);
      }
    });
  });
}
