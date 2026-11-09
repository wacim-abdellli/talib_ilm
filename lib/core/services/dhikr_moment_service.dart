import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/theme/app_palette.dart';
import 'notification_service.dart';

enum DhikrMomentContent { names, adhkar, mixed, duas, quran, hadith }

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
            ? (24 ~/ intervalHours).clamp(1, 12)
            : this.timesPerDay),
    startMinutes: startMinutes ?? this.startMinutes,
    endMinutes: endMinutes ?? this.endMinutes,
    content: content ?? this.content,
  );
}

class DhikrMomentService {
  static const maxAppearancesPerDay = 24;
  static bool get supportsFloatingOverlay => Platform.isAndroid;
  static const _overlayChannel = MethodChannel(
    'com.talibilm.app/dhikr_overlay',
  );
  static const _enabledKey = 'dhikr_moment_enabled';
  static const _timesKey = 'dhikr_moment_times_per_day';
  static const _startKey = 'dhikr_moment_start_minutes';
  static const _endKey = 'dhikr_moment_end_minutes';
  static const _contentKey = 'dhikr_moment_content';
  static const _notificationBaseId = 8300;
  static const _names = <String>[
    'الرَّحْمَنُ',
    'الرَّحِيمُ',
    'الْمَلِكُ',
    'الْقُدُّوسُ',
    'السَّلَامُ',
    'الْمُؤْمِنُ',
    'الْعَزِيزُ',
    'الْغَفَّارُ',
  ];
  static const _adhkar = <String>[
    'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
    'لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ',
    'أَسْتَغْفِرُ اللَّهَ وَأَتُوبُ إِلَيْهِ',
    'اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَى نَبِيِّنَا مُحَمَّدٍ',
  ];
  static const _duas = <String>[
    'اللَّهُمَّ أَعِنِّي عَلَى ذِكْرِكَ وَشُكْرِكَ وَحُسْنِ عِبَادَتِكَ',
    'رَبِّ اغْفِرْ لِي وَتُبْ عَلَيَّ إِنَّكَ أَنْتَ التَّوَّابُ الرَّحِيمُ',
    'اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ',
    'اللَّهُمَّ إِنَّكَ عَفُوٌّ تُحِبُّ الْعَفْوَ فَاعْفُ عَنِّي',
    'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ',
    'رَبِّ زِدْنِي عِلْمًا',
    'اللَّهُمَّ اهْدِنِي وَسَدِّدْنِي',
    'يَا حَيُّ يَا قَيُّومُ بِرَحْمَتِكَ أَسْتَغِيثُ',
  ];
  static const _quran = <String>[
    'فَاذْكُرُونِي أَذْكُرْكُمْ وَاشْكُرُوا لِي وَلَا تَكْفُرُونِ • البقرة ١٥٢',
    'أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ • الرعد ٢٨',
    'إِنَّ مَعَ الْعُسْرِ يُسْرًا • الشرح ٦',
    'وَهُوَ مَعَكُمْ أَيْنَ مَا كُنْتُمْ • الحديد ٤',
    'لَا تَقْنَطُوا مِنْ رَحْمَةِ اللَّهِ • الزمر ٥٣',
    'إِنَّ اللَّهَ مَعَ الصَّابِرِينَ • البقرة ١٥٣',
    'وَمَنْ يَتَوَكَّلْ عَلَى اللَّهِ فَهُوَ حَسْبُهُ • الطلاق ٣',
    'فَإِنِّي قَرِيبٌ أُجِيبُ دَعْوَةَ الدَّاعِ إِذَا دَعَانِ • البقرة ١٨٦',
  ];
  static const _hadith = <String>[
    'إِنَّمَا الْأَعْمَالُ بِالنِّيَّاتِ • البخاري ١',
    'الدِّينُ النَّصِيحَةُ • مسلم ٥٥',
    'مَنْ كَانَ يُؤْمِنُ بِاللَّهِ وَالْيَوْمِ الْآخِرِ فَلْيَقُلْ خَيْرًا أَوْ لِيَصْمُتْ • متفق عليه',
    'لَا يُؤْمِنُ أَحَدُكُمْ حَتَّى يُحِبَّ لِأَخِيهِ مَا يُحِبُّ لِنَفْسِهِ • متفق عليه',
  ];
  static final ValueNotifier<DhikrMomentSettings> settingsNotifier =
      ValueNotifier(const DhikrMomentSettings());
  static final ValueNotifier<String> cardTextNotifier = ValueNotifier(
    _adhkar[0],
  );
  static int _rotation = 0;

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

  static void rotate(DhikrMomentContent content) {
    final source = switch (content) {
      DhikrMomentContent.names => _names,
      DhikrMomentContent.adhkar => _adhkar,
      DhikrMomentContent.mixed => [
        ..._names,
        ..._adhkar,
        ..._duas,
        ..._quran,
        ..._hadith,
      ],
      DhikrMomentContent.duas => _duas,
      DhikrMomentContent.quran => _quran,
      DhikrMomentContent.hadith => _hadith,
    };
    cardTextNotifier.value = source[_rotation++ % source.length];
  }

  static List<int> scheduledMinutes(DhikrMomentSettings settings) {
    final span = settings.endMinutes - settings.startMinutes;
    if (span <= 0) return const [];
    return List<int>.generate(settings.timesPerDay, (index) {
      return settings.startMinutes +
          (span * (index + 1) / (settings.timesPerDay + 1)).round();
    });
  }

  static Future<bool> save(DhikrMomentSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, settings.enabled);
    await prefs.setInt(_timesKey, settings.timesPerDay);
    await prefs.setInt(_startKey, settings.startMinutes);
    await prefs.setInt(_endKey, settings.endMinutes);
    await prefs.setInt(_contentKey, settings.content.index);
    settingsNotifier.value = settings;
    return _schedule(settings);
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
      // Android users who decline overlay access still get the scheduled
      // notification version instead of a feature that silently does nothing.
    }
    return _scheduleNotifications(settings, notifications);
  }

  static Future<void> _cancelScheduled(
    NotificationService notifications,
  ) async {
    for (var i = 0; i < maxAppearancesPerDay; i++) {
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
    final content = switch (settings.content) {
      DhikrMomentContent.names => 'تذكير بأسماء الله الحسنى',
      DhikrMomentContent.adhkar => 'حان وقت الذكر؛ خذ لحظة لذكر الله',
      DhikrMomentContent.mixed => 'لحظة ذكر: ${cardTextNotifier.value}',
      DhikrMomentContent.duas => 'دعاء قصير تتدبر معناه',
      DhikrMomentContent.quran => 'آية قصيرة للتدبر',
      DhikrMomentContent.hadith => 'حديث نبوي قصير',
    };
    var index = 0;
    var allScheduled = true;
    final schedule = scheduledMinutes(settings);
    if (schedule.isEmpty) return false;
    for (; index < settings.timesPerDay; index++) {
      final totalMinute = schedule[index];
      final outcome = await notifications.scheduleDailyAdhkarNotification(
        id: _notificationBaseId + index,
        title: 'لحظة ذكر',
        body: content,
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
    if (!Platform.isAndroid) return false;
    try {
      return await _overlayChannel.invokeMethod<bool>('hasOverlayPermission') ??
          false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> requestOverlayPermission() async {
    if (!Platform.isAndroid) return;
    try {
      await _overlayChannel.invokeMethod<bool>('requestOverlayPermission');
    } catch (_) {}
  }

  static Future<bool> showOverlayTest() async {
    if (!Platform.isAndroid || !await hasOverlayPermission()) return false;
    try {
      return await _overlayChannel.invokeMethod<bool>('showOverlayTest') ??
          false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> syncOverlayService() async {
    if (!Platform.isAndroid) return;
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
    if (!Platform.isAndroid) return;
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
                title: ValueListenableBuilder<String>(
                  valueListenable: DhikrMomentService.cardTextNotifier,
                  builder: (_, text, _) =>
                      Text(text, textAlign: TextAlign.center),
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
