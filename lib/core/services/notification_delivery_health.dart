import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Snapshot of the Android settings that can prevent prayer reminders from
/// being scheduled precisely or from making sound.
class NotificationDeliveryHealth {
  final bool? notificationsAllowed;
  final bool? exactAlarmsAllowed;
  final Set<String> missingChannelIds;
  final Set<String> blockedChannelIds;
  final Set<String> lowImportanceChannelIds;
  final Set<String> silentChannelIds;

  const NotificationDeliveryHealth({
    required this.notificationsAllowed,
    required this.exactAlarmsAllowed,
    this.missingChannelIds = const <String>{},
    this.blockedChannelIds = const <String>{},
    this.lowImportanceChannelIds = const <String>{},
    this.silentChannelIds = const <String>{},
  });

  factory NotificationDeliveryHealth.fromAndroid({
    required bool notificationsAllowed,
    required bool? exactAlarmsAllowed,
    required List<AndroidNotificationChannel> channels,
    required Set<String> requiredChannelIds,
    required Set<String> soundRequiredChannelIds,
  }) {
    final channelsById = <String, AndroidNotificationChannel>{
      for (final channel in channels) channel.id: channel,
    };
    final missing = requiredChannelIds.difference(channelsById.keys.toSet());
    final blocked = <String>{};
    final lowImportance = <String>{};
    final silent = <String>{};

    for (final id in requiredChannelIds) {
      final channel = channelsById[id];
      if (channel == null) continue;
      if (channel.importance == Importance.none) blocked.add(id);
      if (channel.importance != Importance.none &&
          channel.importance.index < Importance.high.index) {
        lowImportance.add(id);
      }
    }
    for (final id in soundRequiredChannelIds) {
      final channel = channelsById[id];
      if (channel != null && !channel.playSound) silent.add(id);
    }

    return NotificationDeliveryHealth(
      notificationsAllowed: notificationsAllowed,
      exactAlarmsAllowed: exactAlarmsAllowed,
      missingChannelIds: Set.unmodifiable(missing),
      blockedChannelIds: Set.unmodifiable(blocked),
      lowImportanceChannelIds: Set.unmodifiable(lowImportance),
      silentChannelIds: Set.unmodifiable(silent),
    );
  }

  bool get hasChannelProblems =>
      missingChannelIds.isNotEmpty ||
      blockedChannelIds.isNotEmpty ||
      lowImportanceChannelIds.isNotEmpty ||
      silentChannelIds.isNotEmpty;

  bool get isReady =>
      notificationsAllowed == true &&
      exactAlarmsAllowed == true &&
      !hasChannelProblems;
}
