import 'package:qcf_quran_plus/qcf_quran_plus.dart';

/// Complete real isolate/font I/O before entering a widget test's fake clock.
/// Pages 1–7 cover the first three pages and the reader's adjacent-page preload.
Future<void> loadMushafTestAssets() async {
  await QuranRepository.instance.ensureLoaded(totalPagesCount);
  for (var page = 1; page <= 7; page++) {
    await QcfFontLoader.ensureFontLoaded(page);
  }
}
