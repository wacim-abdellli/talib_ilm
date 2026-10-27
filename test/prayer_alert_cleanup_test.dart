import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:talib_ilm/core/services/adhan_service.dart';
import 'package:talib_ilm/core/services/adhan_settings_service.dart';
import 'package:talib_ilm/core/services/prayer_notification_details_builder.dart';
import 'package:talib_ilm/core/services/prayer_notification_scheduler.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('Prayer alert cleanup', () {
    test(
      'Android prayer alerts expire after the full Adhan duration window',
      () {
        for (final mode in [
          PrayerNotificationMode.adhan,
          PrayerNotificationMode.takbeer,
          PrayerNotificationMode.announcement,
          PrayerNotificationMode.tone,
          PrayerNotificationMode.silent,
        ]) {
          final details =
              PrayerNotificationDetailsBuilder.buildAndroidPrayerDetails(
                mode: mode,
                sound: AdhanSound.qatami,
                prayerName: 'الفجر',
              );
          expect(
            details.timeoutAfter,
            PrayerNotificationDetailsBuilder.prayerNotificationTimeoutMs,
          );
        }
      },
    );

    test('only active Adhan notifications in owned ID slots are eligible', () {
      ActiveNotification active(int id, String payload) =>
          ActiveNotification(id: id, payload: payload);

      expect(
        PrayerNotificationScheduler.isActiveAdhanNotification(
          active(1402, 'prayer_الظهر'),
        ),
        isTrue,
      );
      expect(
        PrayerNotificationScheduler.isActiveAdhanNotification(
          active(1002, 'prayer_الظهر'),
        ),
        isTrue,
      );
      expect(
        PrayerNotificationScheduler.isActiveAdhanNotification(
          active(2002, 'prayer_pre_الظهر'),
        ),
        isFalse,
      );
      expect(
        PrayerNotificationScheduler.isActiveAdhanNotification(
          active(8888, 'prayer_test_الفجر'),
        ),
        isFalse,
      );
      expect(
        PrayerNotificationScheduler.isActiveAdhanNotification(
          active(1702, 'prayer_الظهر'),
        ),
        isFalse,
      );
    });

    test('completed Adhan playback stops its media session', () async {
      final player = _FakeAudioPlayer();
      final service = AdhanService(player: player);

      player.emitCompleted();
      await player.stopCalled.future.timeout(const Duration(seconds: 1));

      expect(player.stopCalls, 1);
      await service.dispose();
    });
  });
}

class _FakeAudioPlayer extends AudioPlayer {
  final StreamController<PlayerState> _states =
      StreamController<PlayerState>.broadcast();
  final Completer<void> stopCalled = Completer<void>();
  ProcessingState _processingState = ProcessingState.idle;
  int stopCalls = 0;

  @override
  ProcessingState get processingState => _processingState;

  @override
  Stream<PlayerState> get playerStateStream => _states.stream;

  void emitCompleted() {
    _processingState = ProcessingState.completed;
    _states.add(PlayerState(true, ProcessingState.completed));
  }

  @override
  Future<void> stop() async {
    stopCalls++;
    _processingState = ProcessingState.idle;
    _states.add(PlayerState(false, ProcessingState.idle));
    if (!stopCalled.isCompleted) stopCalled.complete();
  }

  @override
  Future<void> dispose() async {
    await _states.close();
  }
}
