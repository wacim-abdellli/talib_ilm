import 'package:flutter_test/flutter_test.dart';
import 'package:qcf_quran_plus/qcf_quran_plus.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('QCF Chunked XZ Font Loader Verification', () {
    test('Loads first, mid, chunk-boundary, and final Mushaf page fonts cleanly', () async {
      await QcfFontLoader.clearCache();

      for (final page in [1, 20, 21, 300, 600, 604]) {
        await QcfFontLoader.ensureFontLoaded(page);
        expect(QcfFontLoader.isFontLoaded(page), isTrue);
      }

      await QcfFontLoader.ensureNonTajweedLoaded(1);
      await QcfFontLoader.ensureNonTajweedLoaded(604);
    });
  });
}
