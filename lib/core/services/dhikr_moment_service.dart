import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/theme/app_palette.dart';
import 'dhikr_moment_content_data.dart';
import 'notification_service.dart';

enum DhikrMomentContent { names, adhkar, mixed, duas, quran, hadith }

class DhikrMomentItem {
  final String text;
  final String meaning;
  final String categoryLabel;

  const DhikrMomentItem({
    required this.text,
    required this.meaning,
    required this.categoryLabel,
  });

  String get notificationBody =>
      meaning.isNotEmpty ? '$text\n$meaning' : text;
}

class DhikrMomentSettings {
  final bool enabled;
  final int timesPerDay;
  final int startMinutes;
  final int endMinutes;
  final DhikrMomentContent content;

  const DhikrMomentSettings({
    this.enabled = false,
    this.timesPerDay = 20,
    this.startMinutes = 8 * 60,
    this.endMinutes = 22 * 60,
    this.content = DhikrMomentContent.mixed,
    int? intervalHours,
  });

  int get intervalHours =>
      timesPerDay > 0 ? (24 ~/ timesPerDay).clamp(1, 24) : 6;

  DhikrMomentSettings copyWith({
    bool? enabled,
    int? timesPerDay,
    int? intervalHours,
    int? startMinutes,
    int? endMinutes,
    DhikrMomentContent? content,
  }) => DhikrMomentSettings(
    enabled: enabled ?? this.enabled,
    timesPerDay:
        timesPerDay ??
        (intervalHours != null && intervalHours > 0
            ? (24 ~/ intervalHours).clamp(1, DhikrMomentService.maxAppearancesPerDay)
            : this.timesPerDay),
    startMinutes: startMinutes ?? this.startMinutes,
    endMinutes: endMinutes ?? this.endMinutes,
    content: content ?? this.content,
  );
}

class DhikrMomentService {
  static const maxAppearancesPerDay = 50;
  static bool? _supportsFloatingOverlayOverride;
  @visibleForTesting
  static set supportsFloatingOverlayOverride(bool? value) =>
      _supportsFloatingOverlayOverride = value;
  static bool get supportsFloatingOverlay =>
      _supportsFloatingOverlayOverride ?? Platform.isAndroid;
  static const _overlayChannel = MethodChannel(
    'com.talibilm.app/dhikr_overlay',
  );
  static const _enabledKey = 'dhikr_moment_enabled';
  static const _timesKey = 'dhikr_moment_times_per_day';
  static const _startKey = 'dhikr_moment_start_minutes';
  static const _endKey = 'dhikr_moment_end_minutes';
  static const _contentKey = 'dhikr_moment_content';
  static const _notificationBaseId = 8300;
  static const _lastCategoryKey = 'dhikr_moment_last_category_index';
  static const _lastItemTextKey = 'dhikr_moment_last_item_text';

  static int? _lastCategoryIndex;
  static String? _lastItemText;
  static final math.Random _random = math.Random();

  static const List<DhikrMomentContent> _concreteCategories = [
    DhikrMomentContent.names,
    DhikrMomentContent.adhkar,
    DhikrMomentContent.duas,
    DhikrMomentContent.quran,
    DhikrMomentContent.hadith,
  ];

  static List<DhikrMomentItem> itemsFor(DhikrMomentContent content) => switch (content) {
    DhikrMomentContent.names => DhikrMomentContentData.names,
    DhikrMomentContent.adhkar => DhikrMomentContentData.adhkar,
    DhikrMomentContent.duas => DhikrMomentContentData.duas,
    DhikrMomentContent.quran => DhikrMomentContentData.quran,
    DhikrMomentContent.hadith => DhikrMomentContentData.hadith,
    DhikrMomentContent.mixed => [
      ...DhikrMomentContentData.names,
      ...DhikrMomentContentData.adhkar,
      ...DhikrMomentContentData.duas,
      ...DhikrMomentContentData.quran,
      ...DhikrMomentContentData.hadith,
    ],
  };

  static final ValueNotifier<DhikrMomentSettings> settingsNotifier =
      ValueNotifier(const DhikrMomentSettings());
  static final ValueNotifier<DhikrMomentItem> cardItemNotifier = ValueNotifier(
    DhikrMomentContentData.adhkar[0],
  );
  static final ValueNotifier<String> cardTextNotifier = ValueNotifier(
    DhikrMomentContentData.adhkar[0].text,
  );
  static Future<bool>? _inFlightSchedule;

  /// Deterministic day slot rotation where consecutive slots are mathematically
  /// guaranteed to belong to different categories when in [DhikrMomentContent.mixed].
  static DhikrMomentItem getItemForSlot(
    DhikrMomentContent content,
    int slotIndex,
  ) {
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;

    if (content != DhikrMomentContent.mixed) {
      final list = itemsFor(content);
      if (list.isEmpty) return DhikrMomentContentData.adhkar[0];
      final index = (dayOfYear * 13 + slotIndex * 7) % list.length;
      return list[index];
    }

    const categorySequence = [
      DhikrMomentContent.adhkar,
      DhikrMomentContent.quran,
      DhikrMomentContent.duas,
      DhikrMomentContent.hadith,
      DhikrMomentContent.names,
    ];
    final cat = categorySequence[(dayOfYear + slotIndex) % categorySequence.length];
    final list = itemsFor(cat);
    final index = (dayOfYear * 11 + slotIndex * 5) % list.length;
    return list[index];
  }

  /// Picks the next random dhikr item ensuring:
  /// 1. In `mixed` mode: The section NEVER matches the previous section consecutively.
  /// 2. In any mode: The item text NEVER matches the previous item text consecutively.
  static DhikrMomentItem pickNextItem(DhikrMomentContent content) {
    DhikrMomentContent chosenCategory;
    if (content == DhikrMomentContent.mixed) {
      final candidates = _concreteCategories
          .where((c) => c.index != _lastCategoryIndex)
          .toList();
      chosenCategory = candidates.isNotEmpty
          ? candidates[_random.nextInt(candidates.length)]
          : _concreteCategories[_random.nextInt(_concreteCategories.length)];
    } else {
      chosenCategory = content;
    }

    final pool = itemsFor(chosenCategory);
    final itemCandidates = pool.where((i) => i.text != _lastItemText).toList();
    final item = (itemCandidates.isNotEmpty ? itemCandidates : pool)[
        _random.nextInt(itemCandidates.isNotEmpty ? itemCandidates.length : pool.length)];

    _lastCategoryIndex = chosenCategory.index;
    _lastItemText = item.text;
    _persistLastState(chosenCategory.index, item.text);

    return item;
  }

  static void _persistLastState(int categoryIndex, String itemText) {
    SharedPreferences.getInstance().then((prefs) {
      prefs.setInt(_lastCategoryKey, categoryIndex);
      prefs.setString(_lastItemTextKey, itemText);
    }).catchError((_) {});
  }

  static void rotate(DhikrMomentContent content) {
    final item = pickNextItem(content);
    cardItemNotifier.value = item;
    cardTextNotifier.value = item.text;
  }

  static Future<bool> scheduleTestNotification() async {
    final notifications = NotificationService();
    await notifications.init();
    await notifications.requestPermissions();
    if (!await notifications.arePermissionsGranted()) return false;
    final result = await notifications.scheduleAdhkarTestNotification(
      id: 8399,
      scheduledDate: DateTime.now().add(const Duration(minutes: 1)),
    );
    return result.status == ScheduleOutcomeStatus.exact ||
        result.status == ScheduleOutcomeStatus.inexactFallback;
  }

  static Future<DhikrMomentSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    _lastCategoryIndex = prefs.getInt(_lastCategoryKey);
    _lastItemText = prefs.getString(_lastItemTextKey);
    final rawContent =
        prefs.getInt(_contentKey) ?? DhikrMomentContent.mixed.index;
    final content =
        rawContent >= 0 && rawContent < DhikrMomentContent.values.length
        ? DhikrMomentContent.values[rawContent]
        : DhikrMomentContent.mixed;
    final settings = DhikrMomentSettings(
      enabled: prefs.getBool(_enabledKey) ?? false,
      timesPerDay: (prefs.getInt(_timesKey) ?? 20).clamp(
        1,
        maxAppearancesPerDay,
      ),
      startMinutes: (prefs.getInt(_startKey) ?? 480).clamp(0, 1439),
      endMinutes: (prefs.getInt(_endKey) ?? 1320).clamp(1, 1440),
      content: content,
    );
    settingsNotifier.value = settings;
    rotate(settings.content);
    return settings;
  }

  static List<int> scheduledMinutes(DhikrMomentSettings settings) {
    final span = settings.endMinutes - settings.startMinutes;
    if (span <= 0) return const [];
    final count = settings.timesPerDay.clamp(1, span);
    final uniqueMinutes = <int>{};
    for (var i = 0; i < count; i++) {
      final minute = settings.startMinutes +
          (span * (i + 1) / (count + 1)).round();
      uniqueMinutes.add(minute);
    }
    final list = uniqueMinutes.toList()..sort();
    return list;
  }

  static Future<bool> save(DhikrMomentSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, settings.enabled);
    await prefs.setInt(_timesKey, settings.timesPerDay);
    await prefs.setInt(_startKey, settings.startMinutes);
    await prefs.setInt(_endKey, settings.endMinutes);
    await prefs.setInt(_contentKey, settings.content.index);
    settingsNotifier.value = settings;

    while (_inFlightSchedule != null) {
      await _inFlightSchedule;
    }
    final completer = Completer<bool>();
    _inFlightSchedule = completer.future;
    try {
      final ready = await _schedule(settings);
      completer.complete(ready);
      return ready;
    } catch (e) {
      completer.complete(false);
      return false;
    } finally {
      _inFlightSchedule = null;
    }
  }

  static Future<bool> _schedule(DhikrMomentSettings settings) async {
    final notifications = NotificationService();
    await _cancelScheduled(notifications);
    if (!settings.enabled) {
      await _stopOverlay();
      return true;
    }
    if (Platform.isAndroid) {
      final permission = await hasOverlayPermission();
      if (permission) {
        return await _overlayChannel.invokeMethod<bool>(
              'startOverlayService',
            ) ??
            false;
      }
    }
    return _scheduleNotifications(settings, notifications);
  }

  static Future<void> _cancelScheduled(
    NotificationService notifications,
  ) async {
    await notifications.init();
    for (var i = 0; i < 100; i++) {
      await notifications.cancelNotification(_notificationBaseId + i);
    }
  }

  static Future<bool> _scheduleNotifications(
    DhikrMomentSettings settings,
    NotificationService notifications,
  ) async {
    await notifications.init();
    await notifications.requestPermissions();
    if (!await notifications.arePermissionsGranted()) return false;

    final schedule = scheduledMinutes(settings);
    if (schedule.isEmpty) return false;

    var allScheduled = true;
    for (var index = 0; index < schedule.length; index++) {
      final totalMinute = schedule[index];
      final item = getItemForSlot(settings.content, index);

      final outcome = await notifications.scheduleDailyAdhkarNotification(
        id: _notificationBaseId + index,
        title: 'لحظة ذكر',
        body: item.notificationBody,
        hour: totalMinute ~/ 60,
        minute: totalMinute % 60,
        payload: 'dhikr_moment',
      );
      allScheduled =
          allScheduled &&
          (outcome.status == ScheduleOutcomeStatus.exact ||
              outcome.status == ScheduleOutcomeStatus.inexactFallback);
    }
    return allScheduled;
  }

  static Future<bool> hasOverlayPermission() async {
    if (!supportsFloatingOverlay) return false;
    try {
      return await _overlayChannel.invokeMethod<bool>('hasOverlayPermission') ??
          false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> requestOverlayPermission() async {
    if (!supportsFloatingOverlay) return false;
    try {
      return await _overlayChannel.invokeMethod<bool>(
            'requestOverlayPermission',
          ) ??
          false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> showOverlayTest({
    String? categoryLabel,
    String? text,
    String? meaning,
  }) async {
    if (!supportsFloatingOverlay || !await hasOverlayPermission()) return false;
    try {
      return await _overlayChannel.invokeMethod<bool>('showOverlayTest', {
            if (categoryLabel != null) 'label': categoryLabel,
            if (text != null) 'text': text,
            if (meaning != null) 'meaning': meaning,
          }) ??
          false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> syncOverlayService() async {
    if (!supportsFloatingOverlay) return;
    final settings = settingsNotifier.value;
    try {
      if (settings.enabled && await hasOverlayPermission()) {
        final notifications = NotificationService();
        await _cancelScheduled(notifications);
        await _overlayChannel.invokeMethod<bool>('startOverlayService');
      }
    } catch (_) {}
  }

  static Future<void> _stopOverlay() async {
    if (!supportsFloatingOverlay) return;
    try {
      await _overlayChannel.invokeMethod<bool>('stopOverlayService');
    } catch (_) {}
  }
}

class DhikrMomentOverlay extends StatefulWidget {
  final Widget child;
  const DhikrMomentOverlay({super.key, required this.child});

  @override
  State<DhikrMomentOverlay> createState() => _DhikrMomentOverlayState();
}

class _DhikrMomentOverlayState extends State<DhikrMomentOverlay>
    with WidgetsBindingObserver {
  Timer? _timer;
  bool _visible = false;
  int? _lastShownMinuteKey;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    DhikrMomentService.settingsNotifier.addListener(_configureTimer);
    DhikrMomentService.load().then((_) {
      _configureTimer();
      unawaited(DhikrMomentService.syncOverlayService());
    });
  }

  void _configureTimer() {
    _timer?.cancel();
    final settings = DhikrMomentService.settingsNotifier.value;
    if (!settings.enabled) return;
    if (DhikrMomentService.scheduledMinutes(settings).isEmpty) return;
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted ||
          WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
        return;
      }
      final now = DateTime.now();
      final minute = now.hour * 60 + now.minute;
      final minuteKey =
          now.year * 100000000 + now.month * 1000000 + now.day * 10000 + minute;
      if (!DhikrMomentService.scheduledMinutes(settings).contains(minute) ||
          _lastShownMinuteKey == minuteKey) {
        return;
      }
      _lastShownMinuteKey = minuteKey;
      DhikrMomentService.rotate(settings.content);
      setState(() => _visible = true);
      Future<void>.delayed(const Duration(seconds: 18), () { // ui-lint: allow auto-dismiss timer
        if (mounted) setState(() => _visible = false);
      });
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(DhikrMomentService.syncOverlayService());
    }
    if (state != AppLifecycleState.resumed && mounted) {
      setState(() => _visible = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    DhikrMomentService.settingsNotifier.removeListener(_configureTimer);
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      widget.child,
      if (!Platform.isAndroid &&
          _visible &&
          DhikrMomentService.settingsNotifier.value.enabled)
        PositionedDirectional(
          start: AppSpace.lg,
          end: AppSpace.lg,
          bottom: AppSpace.xl,
          child: SafeArea(
            child: Material(
              elevation: 8,
              color: Theme.of(context).colorScheme.surface,
              borderRadius: AppRadius.lgRadius,
              child: ListTile(
                leading: const Icon(Icons.spa_rounded),
                title: ValueListenableBuilder<DhikrMomentItem>(
                  valueListenable: DhikrMomentService.cardItemNotifier,
                  builder: (_, item, _) => Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(item.text, textAlign: TextAlign.center),
                      if (item.meaning.isNotEmpty) ...[
                        const SizedBox(height: AppSpace.xxs),
                        Text(
                          item.meaning,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
                trailing: IconButton(
                  tooltip: 'إخفاء',
                  onPressed: () => setState(() => _visible = false),
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
            ),
          ),
        ),
    ],
  );
}
