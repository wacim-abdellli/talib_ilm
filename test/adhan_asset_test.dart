import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('All adhan audio assets exist and can be loaded from bundle', () async {
    const assets = [
      'assets/audio/adhan_makkah.mp3',
      'assets/audio/adhan_madinah.mp3',
      'assets/audio/adhan_alafasy.mp3',
      'assets/audio/adhan_abdulbasit.mp3',
      'assets/audio/adhan_qatami.mp3',
      'assets/audio/adhan_aqsa.mp3',
      'assets/audio/adhan_takbeer.mp3',
      'assets/audio/adhan_announcement_fajr.mp3',
      'assets/audio/adhan_announcement_dhuhr.mp3',
      'assets/audio/adhan_announcement_asr.mp3',
      'assets/audio/adhan_announcement_maghrib.mp3',
      'assets/audio/adhan_announcement_isha.mp3',
      'assets/audio/adhan_announcement_general.mp3',
    ];

    for (final path in assets) {
      final data = await rootBundle.load(path);
      expect(
        data.lengthInBytes,
        greaterThan(1000),
        reason: '$path must be > 1000 bytes',
      );
    }
  });
}
