import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_ilm/features/quran/data/models/quran_models.dart';
import 'package:talib_ilm/features/quran/data/services/quran_cache_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'uninstalled Warsh never reads the unscoped cached Hafs surah',
    () async {
      final hafsCacheFixture = Surah(
        number: 1,
        name: 'Hafs cache fixture',
        englishName: 'Synthetic fixture',
        englishNameTranslation: 'Cache isolation test',
        numberOfAyahs: 1,
        revelationType: 'Meccan',
        ayahs: const [
          Ayah(
            number: 1,
            text: 'synthetic cache fixture text',
            numberInSurah: 1,
            juz: 1,
            page: 1,
          ),
        ],
      );
      await QuranCacheService.cacheSurah(hafsCacheFixture);
      expect(await QuranCacheService.getCachedSurah(1), isNotNull);

      final progress = <String>[];
      final result = await QuranRepository.getSurah(
        1,
        editionId: 'warsh',
        onProgress: (status, _) => progress.add(status),
      );

      expect(result, isNull);
      expect(progress, contains('الرواية warsh غير مثبتة على الجهاز'));
    },
  );
}
