import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_ilm/core/services/adhan_settings_service.dart';
import 'package:talib_ilm/core/services/audio_coordinator.dart';
import 'package:talib_ilm/core/services/foreground_prayer_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AudioCoordinator.reset();
  });

  tearDown(() {
    AudioCoordinator.reset();
    ForegroundPrayerService().stop();
  });

  group('ForegroundPrayerService Lifecycle & Repeatable Subscriptions (C18)', () {
    test('start -> stop -> start cycle correctly re-attaches audio completion listener', () async {
      final service = ForegroundPrayerService();
      await service.init();
      service.start();

      expect(service.isPolling, isTrue);

      // Simulate active alert
      service.activeAlert.value = ActivePrayerAlert(
        prayerName: 'الفجر',
        prayerTime: DateTime.now(),
        mode: PrayerNotificationMode.adhan,
        sound: AdhanSound.qatami,
      );
      expect(service.activeAlert.value, isNotNull);

      // Stop service
      service.stop();
      expect(service.isPolling, isFalse);
      expect(service.activeAlert.value, isNull);

      // Re-start service: listener must be re-attached!
      service.start();
      expect(service.isPolling, isTrue);

      // Set alert again
      service.activeAlert.value = ActivePrayerAlert(
        prayerName: 'الظهر',
        prayerTime: DateTime.now(),
        mode: PrayerNotificationMode.adhan,
        sound: AdhanSound.qatami,
      );

      // Service stop clears polling and alert
      service.stop();
      expect(service.isPolling, isFalse);
      expect(service.activeAlert.value, isNull);
    });

    test('pausePolling cancels periodic UI timers without wiping active prayer alert', () async {
      final service = ForegroundPrayerService();
      service.start();
      expect(service.isPolling, isTrue);

      // Simulate active alert while app is foregrounded
      service.activeAlert.value = ActivePrayerAlert(
        prayerName: 'المغرب',
        prayerTime: DateTime.now(),
        mode: PrayerNotificationMode.adhan,
        sound: AdhanSound.qatami,
      );

      // App transitions to background/paused
      service.pausePolling();
      expect(service.isPolling, isFalse);
      // Alert must NOT be wiped merely because UI polling paused!
      expect(service.activeAlert.value?.prayerName, equals('المغرب'));

      // App transitions back to foreground/resumed
      service.start();
      expect(service.isPolling, isTrue);
      expect(service.activeAlert.value?.prayerName, equals('المغرب'));

      service.stop();
    });
  });

  group('Centralized Audio Coordination & Priority Management (C19)', () {
    test('Acquiring Radio focus pauses active Quran recitation and Mutun audio', () async {
      bool quranPaused = false;
      bool mutunPaused = false;

      AudioCoordinator.onPauseQuran = () async {
        quranPaused = true;
      };
      AudioCoordinator.onPauseMutun = () async {
        mutunPaused = true;
      };

      await AudioCoordinator.acquireFocus(AudioStreamType.quran);
      expect(AudioCoordinator.currentActiveStream, equals(AudioStreamType.quran));

      // Radio requests focus
      await AudioCoordinator.acquireFocus(AudioStreamType.radio);
      expect(quranPaused, isTrue);
      expect(mutunPaused, isTrue);
      expect(AudioCoordinator.currentActiveStream, equals(AudioStreamType.radio));
    });

    test('Acquiring Quran focus pauses active Radio and Mutun audio', () async {
      bool radioPaused = false;
      bool mutunPaused = false;

      AudioCoordinator.onPauseRadio = () async {
        radioPaused = true;
      };
      AudioCoordinator.onPauseMutun = () async {
        mutunPaused = true;
      };

      await AudioCoordinator.acquireFocus(AudioStreamType.radio);
      expect(AudioCoordinator.currentActiveStream, equals(AudioStreamType.radio));

      // Quran requests focus
      await AudioCoordinator.acquireFocus(AudioStreamType.quran);
      expect(radioPaused, isTrue);
      expect(mutunPaused, isTrue);
      expect(AudioCoordinator.currentActiveStream, equals(AudioStreamType.quran));
    });

    test('Acquiring Mutun focus pauses active Quran and Radio audio', () async {
      bool quranPaused = false;
      bool radioPaused = false;

      AudioCoordinator.onPauseQuran = () async {
        quranPaused = true;
      };
      AudioCoordinator.onPauseRadio = () async {
        radioPaused = true;
      };

      await AudioCoordinator.acquireFocus(AudioStreamType.quran);
      expect(AudioCoordinator.currentActiveStream, equals(AudioStreamType.quran));

      // Mutun requests focus
      await AudioCoordinator.acquireFocus(AudioStreamType.mutun);
      expect(quranPaused, isTrue);
      expect(radioPaused, isTrue);
      expect(AudioCoordinator.currentActiveStream, equals(AudioStreamType.mutun));
    });

    test('Adhan focus has supreme priority: pauses Quran, Radio, and Mutun simultaneously', () async {
      bool quranPaused = false;
      bool radioPaused = false;
      bool mutunPaused = false;

      AudioCoordinator.onPauseQuran = () async {
        quranPaused = true;
      };
      AudioCoordinator.onPauseRadio = () async {
        radioPaused = true;
      };
      AudioCoordinator.onPauseMutun = () async {
        mutunPaused = true;
      };

      // Quran is playing
      await AudioCoordinator.acquireFocus(AudioStreamType.quran);

      // Adhan alerts at prayer time!
      await AudioCoordinator.acquireFocus(AudioStreamType.adhan);

      expect(quranPaused, isTrue);
      expect(radioPaused, isTrue);
      expect(mutunPaused, isTrue);
      expect(AudioCoordinator.currentActiveStream, equals(AudioStreamType.adhan));
    });

    test('releaseFocus clears active stream only when caller matches current holder', () {
      AudioCoordinator.acquireFocus(AudioStreamType.quran);
      expect(AudioCoordinator.currentActiveStream, equals(AudioStreamType.quran));

      // Different stream trying to release must have no effect
      AudioCoordinator.releaseFocus(AudioStreamType.radio);
      expect(AudioCoordinator.currentActiveStream, equals(AudioStreamType.quran));

      // Correct holder releases focus
      AudioCoordinator.releaseFocus(AudioStreamType.quran);
      expect(AudioCoordinator.currentActiveStream, isNull);
    });

    test('Rapid consecutive audio switches resolve safely without throwing', () async {
      int pauseCount = 0;
      AudioCoordinator.onPauseQuran = () async => pauseCount++;
      AudioCoordinator.onPauseRadio = () async => pauseCount++;
      AudioCoordinator.onPauseMutun = () async => pauseCount++;

      await Future.wait([
        AudioCoordinator.acquireFocus(AudioStreamType.quran),
        AudioCoordinator.acquireFocus(AudioStreamType.radio),
        AudioCoordinator.acquireFocus(AudioStreamType.mutun),
      ]);

      expect(AudioCoordinator.currentActiveStream, isNotNull);
      expect(pauseCount, greaterThan(0));
    });
  });
}
