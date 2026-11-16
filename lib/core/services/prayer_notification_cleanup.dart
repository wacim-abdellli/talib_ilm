part of 'prayer_notification_scheduler.dart';

bool _isActiveAdhanNotificationImpl(ActiveNotification notification) {
  final id = notification.id;
  final payload = notification.payload;
  if (id == null || payload == null || !payload.startsWith('prayer_')) {
    return false;
  }
  if (payload.startsWith('prayer_pre_') ||
      payload.startsWith('prayer_test_')) {
    return false;
  }

  final isInstantAlert = id >= 700 && id <= 710;
  final isLegacyAlert = id >= 100 && id <= 105;
  final scheduleOffset = id - 1000;
  final isScheduledAlert =
      scheduleOffset >= 0 &&
      scheduleOffset < 700 &&
      scheduleOffset % 100 <= 5;
  return isInstantAlert || isLegacyAlert || isScheduledAlert;
}

extension _PrayerNotificationCleanupHandlers on PrayerNotificationScheduler {
  Future<void> _showInstantPrayerAlertImpl({
    required int id,
    required String prayerName,
    required PrayerNotificationMode mode,
    AdhanSound sound = AdhanSound.qatami,
  }) async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) {
      return;
    }
    await _ensureInitialized();

    final details = PrayerNotificationDetailsBuilder.buildPrayerDetails(
      mode: mode,
      sound: sound,
      prayerName: prayerName,
    );
    final cleanPrayerName = prayerName.replaceAll('صلاة ', '').trim();
    final isJumua =
        cleanPrayerName == 'الجمعة' || cleanPrayerName.contains('جمعة');
    final title = isJumua
        ? 'حان الآن موعد أذان صلاة الجمعة'
        : 'حان الآن موعد أذان صلاة $cleanPrayerName';
    final body = cleanPrayerName.contains('فجر')
        ? 'الصلاة خيرٌ من النوم · حان وقت الصلاة'
        : 'حي على الصلاة · حي على الفلاح';

    await _plugin.show(
      id,
      title,
      body,
      details,
      payload: 'prayer_${prayerName.trim()}',
    );
  }

  Future<void> _showInstantTestNotificationImpl({
    required String prayerName,
    required PrayerNotificationMode mode,
    AdhanSound sound = AdhanSound.qatami,
  }) async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) {
      return;
    }
    await _ensureInitialized();
    await _requestPermissions();

    final details = PrayerNotificationDetailsBuilder.buildPrayerDetails(
      mode: mode,
      sound: sound,
      prayerName: prayerName,
    );
    final title = 'حان الآن وقت صلاة $prayerName (إشعار تجريبي)';
    final body = prayerName.contains('فجر')
        ? 'الصلاة خير من النوم (النمط: ${PrayerNotificationDetailsBuilder.modeLabel(mode)})'
        : 'حي على الصلاة.. حي على الفلاح (النمط: ${PrayerNotificationDetailsBuilder.modeLabel(mode)})';

    await _plugin.show(
      9999,
      title,
      body,
      details,
      payload: 'prayer_test_${prayerName.trim()}',
    );
  }

  Future<void> _cancelActivePrayerAlertsOnlyImpl() async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) {
      return;
    }
    for (int i = 700; i <= 710; i++) {
      await _plugin.cancel(i);
    }
    for (int i = 750; i <= 760; i++) {
      await _plugin.cancel(i);
    }

    // Scheduled alerts use IDs in the seven-day schedule namespace. Cancel
    // only IDs Android reports as already active, never pending alarms.
    try {
      final activeNotifications = await _plugin.getActiveNotifications();
      final activeAdhanIds =
          activeNotifications
              .where(PrayerNotificationScheduler.isActiveAdhanNotification)
              .map((notification) => notification.id)
              .whereType<int>()
              .toSet()
            ..removeWhere((id) => id >= 700 && id <= 710);
      for (final id in activeAdhanIds) {
        await _plugin.cancel(id);
      }
    } catch (error) {
      debugPrint('Unable to inspect active prayer notifications: $error');
    }
  }

  Future<void> _cancelPrayerNotificationsOnlyImpl({
    Set<int>? preserveIds,
  }) async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) {
      return;
    }
    for (var d = 0; d < 7; d++) {
      for (var i = 0; i <= 5; i++) {
        final adhanId = 1000 + (d * 100) + i;
        if (preserveIds == null || !preserveIds.contains(adhanId)) {
          await _plugin.cancel(adhanId);
        }
        final preId = 2000 + (d * 100) + i;
        if (preserveIds == null || !preserveIds.contains(preId)) {
          await _plugin.cancel(preId);
        }
        final iqamaId = 3000 + (d * 100) + i;
        if (preserveIds == null || !preserveIds.contains(iqamaId)) {
          await _plugin.cancel(iqamaId);
        }
      }
      final kahfId = 4000 + (d * 100);
      if (preserveIds == null || !preserveIds.contains(kahfId)) {
        await _plugin.cancel(kahfId);
      }
    }

    for (int i = 100; i <= 299; i++) {
      if (preserveIds != null && preserveIds.contains(i)) continue;
      await _plugin.cancel(i);
    }
    for (int i = 700; i <= 710; i++) {
      if (preserveIds != null && preserveIds.contains(i)) continue;
      await _plugin.cancel(i);
    }
    for (int i = 750; i <= 760; i++) {
      if (preserveIds != null && preserveIds.contains(i)) continue;
      await _plugin.cancel(i);
    }
  }
}
