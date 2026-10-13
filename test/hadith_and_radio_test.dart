import 'package:flutter_test/flutter_test.dart';
import 'package:talib_ilm/features/hadith/data/models/hadith_models.dart';
import 'package:talib_ilm/features/hadith/data/services/hadith_service.dart';
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
