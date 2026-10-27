import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talib_ilm/core/services/notification_delivery_health.dart';

void main() {
  group('NotificationDeliveryHealth', () {
    test('reports missing, blocked, and muted channels', () {
      final health = NotificationDeliveryHealth.fromAndroid(
        notificationsAllowed: true,
        exactAlarmsAllowed: true,
        channels: const [
          AndroidNotificationChannel(
            'prayer_blocked',
            'Prayer blocked',
            importance: Importance.none,
          ),
          AndroidNotificationChannel(
            'prayer_muted',
            'Prayer muted',
            playSound: false,
          ),
          AndroidNotificationChannel(
            'prayer_low',
            'Prayer low',
            importance: Importance.low,
          ),
        ],
        requiredChannelIds: const {
          'prayer_blocked',
          'prayer_muted',
          'prayer_low',
          'prayer_missing',
        },
        soundRequiredChannelIds: const {'prayer_muted', 'prayer_missing'},
      );

      expect(health.missingChannelIds, {'prayer_missing'});
      expect(health.blockedChannelIds, {'prayer_blocked'});
      expect(health.lowImportanceChannelIds, {'prayer_muted', 'prayer_low'});
      expect(health.silentChannelIds, {'prayer_muted'});
      expect(health.hasChannelProblems, isTrue);
      expect(health.isReady, isFalse);
    });

    test(
      'is ready only when permission, exact alarms, and channels are good',
      () {
        final health = NotificationDeliveryHealth.fromAndroid(
          notificationsAllowed: true,
          exactAlarmsAllowed: true,
          channels: const [
            AndroidNotificationChannel(
              'adhan',
              'Adhan',
              importance: Importance.high,
            ),
            AndroidNotificationChannel(
              'athkar',
              'Athkar',
              importance: Importance.high,
            ),
          ],
          requiredChannelIds: const {'adhan', 'athkar'},
          soundRequiredChannelIds: const {'adhan', 'athkar'},
        );

        expect(health.isReady, isTrue);
      },
    );

    test('does not call an inexact schedule fully ready', () {
      const health = NotificationDeliveryHealth(
        notificationsAllowed: true,
        exactAlarmsAllowed: false,
      );

      expect(health.isReady, isFalse);
    });
  });
}
