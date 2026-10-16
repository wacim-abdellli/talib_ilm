import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/constants/app_strings.dart';
import '../../../app/theme/app_palette.dart';
import '../../../app/theme/app_ui.dart';
import '../../../core/services/adhan_settings_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/prayer_schedule_service.dart';
import '../../../core/services/prayer_time_service.dart';
import '../../../core/utils/prayer_countdown.dart';
import '../../../shared/navigation/fade_page_route.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_skeleton.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/app_states.dart';
import '../../adhkar/presentation/after_prayer_athkar_page.dart';
import '../../adhkar/presentation/duas_misc_page.dart';
import '../data/models/prayer_models.dart';
import 'location_settings_sheet.dart';
import 'prayer_page_helpers.dart';
import 'prayer_settings_sheet.dart';
import 'qibla_page.dart';
import 'widgets/next_prayer_card.dart';
import 'widgets/prayer_dua_card.dart';
import 'widgets/prayer_header.dart';
import 'widgets/prayer_solar_stations_card.dart';
import 'widgets/prayer_time_card.dart';
import 'widgets/sunan_rawatib_card.dart';

class PrayerPage extends StatefulWidget {
  const PrayerPage({super.key});

  @override
  State<PrayerPage> createState() => _PrayerPageState();
}

class _PrayerPageState extends State<PrayerPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final PrayerTimeService _prayerTimeService = PrayerTimeService();
  final PrayerScheduleService _prayerScheduleService = PrayerScheduleService();
  final AdhanSettingsService _adhanSettingsService = AdhanSettingsService();
  final LocationService _locationService = LocationService();
  late Future<PrayerTimesDay> _prayerFuture;
  late Future<LocationInfo> _locationFuture;
  PrayerCountdownController? _countdownController;
  PrayerTimesDay? _cachedDay;
  AdhanSettings? _adhanSettings;

  @override
  void initState() {
    super.initState();
    LocationService.onLocationChanged.addListener(_onLocationChanged);
    _loadPrayer();
    _locationFuture = _loadLocation();
    _loadSettings();
  }

  void _onLocationChanged() {
    if (!mounted) return;
    final newLoc = LocationService.onLocationChanged.value;
    if (newLoc != null && _cachedDay != null && _cachedDay!.city == newLoc.city) {
      return;
    }
    PrayerTimeService.clearCache();
    setState(() {
      _loadPrayer();
      _locationFuture = _loadLocation();
    });
  }

  Future<void> _loadSettings() async {
    final settings = await _adhanSettingsService.getSettings();
    if (!mounted) return;
    setState(() {
      _adhanSettings = settings;
    });
  }

  @override
  void dispose() {
    LocationService.onLocationChanged.removeListener(_onLocationChanged);
    _countdownController?.dispose();
    super.dispose();
  }

  Future<LocationInfo> _loadLocation() async {
    await Future.delayed(AppMotion.debounce);
    try {
      final manual = await _locationService.getManualLocation();
      final location = await _locationService.getLocation();
      return LocationInfo(city: location.city, isManual: manual != null);
    } catch (e) {
      debugPrint('Error loading location: $e');
      return const LocationInfo(city: 'مكة المكرمة', isManual: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: context.palette.bg,
      body: ColoredBox(
        color: context.palette.bg,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: FutureBuilder<PrayerTimesDay>(
            future: _prayerFuture,
            builder: (context, snapshot) {
              final data = snapshot.data ?? _cachedDay;

              if (data == null && snapshot.connectionState == ConnectionState.waiting) {
                return Padding(
                  padding: const EdgeInsets.all(AppSpace.xl),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        AppSkeleton(
                          width: double.infinity,
                          height: 160,
                          borderRadius: AppRadius.lgRadius,
                        ),
                        const SizedBox(height: AppSpace.lg),
                        for (int i = 0; i < 5; i++) ...[
                          AppSkeleton(
                            width: double.infinity,
                            height: 56,
                            borderRadius: AppRadius.lgRadius,
                          ),
                          if (i < 4) const SizedBox(height: AppSpace.sm),
                        ],
                      ],
                    ),
                  ),
                );
              }

              if (data == null) {
                return Padding(
                  padding: const EdgeInsets.all(AppSpace.xl),
                  child: Center(
                    child: AppEmptyState(
                      icon: Icons.access_time,
                      title: AppStrings.prayerLoadErrorTitle,
                      subtitle: AppStrings.prayerLoadErrorMessage,
                      action: AppButton(
                        label: AppStrings.actionRetry,
                        onPressed: _reloadPrayer,
                      ),
                    ),
                  ),
                );
              }

              _ensureCountdown(data);
              final nextName = PrayerPageHelpers.findNextPrayerName(data.prayers);
              final currentName = PrayerPageHelpers.findCurrentPrayerName(data.prayers);
              final times = _buildPrayerTimes(data, nextName, currentName);
              final gregorianDate = PrayerPageHelpers.formatGregorianDate(data.date);

              return FutureBuilder<LocationInfo>(
                future: _locationFuture,
                builder: (context, locationSnapshot) {
                  final location = locationSnapshot.data;
                  final city = location?.city ?? data.city;

                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        PrayerHeader(
                          city: city,
                          gregorianDate: gregorianDate,
                          onOpenLocationSettings: () => _openLocationSettings(context),
                          onOpenPrayerSettings: () => _openPrayerSettings(context),
                          onOpenQibla: () => _openQibla(context),
                        ),

                        // Body
                        Padding(
                          padding: AppSpace.screenPadding,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: AppSpace.md),
                              _buildNextPrayerCard(data),
                              const SizedBox(height: AppSpace.sm),
                              PrayerSolarStationsCard(
                                sunrise: data.sunrise,
                                sunset: data.sunset,
                              ),
                              const SizedBox(height: AppSpace.lg),
                              Text(
                                AppStrings.prayerDayLabel,
                                style: context.text.titleSmall.copyWith(
                                  color: context.palette.text,
                                ),
                                textAlign: TextAlign.right,
                              ),
                              const SizedBox(height: AppSpace.md),
                              if (_countdownController != null)
                                ValueListenableBuilder<PrayerCountdownState>(
                                  valueListenable: _countdownController!.state,
                                  builder: (context, countdownState, _) {
                                    final dynamicCurrentName = countdownState.isInPrayerTime
                                        ? countdownState.nextPrayerName
                                        : null;
                                    final dynamicNextName = countdownState.isInPrayerTime
                                        ? null
                                        : countdownState.nextPrayerName;
                                    final dynamicTimes = _buildPrayerTimes(
                                      data,
                                      dynamicNextName,
                                      dynamicCurrentName,
                                    );
                                    return Column(
                                      children: [
                                        for (var i = 0; i < dynamicTimes.length; i++) ...[
                                          PrayerTimeCard(
                                            item: dynamicTimes[i],
                                            onBeforeAdhkar: () => _openDuas(context),
                                            onAfterAdhkar: () =>
                                                _openAfterPrayer(context, dynamicTimes[i].name),
                                            onTap: () =>
                                                _openAfterPrayer(context, dynamicTimes[i].name),
                                          ),
                                          if (i != dynamicTimes.length - 1)
                                            const SizedBox(height: AppSpace.sm),
                                        ],
                                      ],
                                    );
                                  },
                                )
                              else
                                for (var i = 0; i < times.length; i++) ...[
                                  PrayerTimeCard(
                                    item: times[i],
                                    onBeforeAdhkar: () => _openDuas(context),
                                    onAfterAdhkar: () =>
                                        _openAfterPrayer(context, times[i].name),
                                    onTap: () =>
                                        _openAfterPrayer(context, times[i].name),
                                  ),
                                  if (i != times.length - 1)
                                    const SizedBox(height: AppSpace.sm),
                                ],
                              const SizedBox(height: AppSpace.lg),
                              const SunanRawatibCard(),
                              const SizedBox(height: AppSpace.lg),
                              const PrayerDuaCard(),
                              const SizedBox(height: AppSpace.lg),
                              SizedBox(height: AppSize.navClearance(context)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildNextPrayerCard(PrayerTimesDay day) {
    final controller = _countdownController;
    if (controller == null) {
      final prayer = PrayerPageHelpers.buildNextPrayer(day);
      final nextTime = day.prayers[day.nextPrayer] ?? DateTime.now();
      final remaining = nextTime.difference(DateTime.now());
      final progress = PrayerPageHelpers.calculatePrayerProgress(
        day,
        day.nextPrayer,
        nextTime,
        remaining,
      );
      return NextPrayerCard(
        prayer: prayer,
        countdownText: PrayerPageHelpers.formatCountdown(remaining),
        progress: progress,
        onTap: () => _openPrayerSettings(context),
        onOpenQibla: () => _openQibla(context),
        onOpenAdhkar: () => _openDuas(context),
        onOpenSettings: () => _openPrayerSettings(context),
      );
    }

    return ValueListenableBuilder<PrayerCountdownState>(
      valueListenable: controller.state,
      builder: (context, state, _) {
        final prayer = NextPrayer(
          prayer: prayerFromLabel(state.nextPrayerName) ?? Prayer.fajr,
          time: state.nextPrayerTime,
          minutesRemaining: state.remaining.inMinutes,
        );
        final progress = PrayerPageHelpers.calculatePrayerProgress(
          day,
          state.nextPrayerName,
          state.nextPrayerTime,
          state.remaining,
        );
        final countdownText = state.isInPrayerTime
            ? 'رُفِع الأذان منذ ${state.elapsed.inMinutes} د'
            : PrayerPageHelpers.formatCountdown(state.remaining);
        return NextPrayerCard(
          prayer: prayer,
          countdownText: countdownText,
          progress: state.isInPrayerTime ? 1.0 : progress,
          onTap: () => _openPrayerSettings(context),
          onOpenQibla: () => _openQibla(context),
          onOpenAdhkar: () => _openDuas(context),
          onOpenSettings: () => _openPrayerSettings(context),
        );
      },
    );
  }

  List<PrayerTimeEntry> _buildPrayerTimes(
    PrayerTimesDay day,
    String? nextName,
    String? currentName,
  ) {
    const order = AppStrings.prayerOrder;
    final now = DateTime.now();
    return order.where(day.prayers.containsKey).map((name) {
      final time = day.prayers[name]!;
      final isCurrent = currentName != null && name == currentName;
      final isNext = !isCurrent && nextName != null && name == nextName;
      final isSunrise = name.contains('الشروق');
      final mode = isSunrise
          ? PrayerNotificationMode.off
          : (_adhanSettings?.modeForPrayer(name) ?? PrayerNotificationMode.adhan);

      return PrayerTimeEntry(
        name: name,
        timeLabel: formatPrayerTime12h(time),
        isNext: isNext,
        isCurrent: isCurrent,
        isCompleted: !isCurrent && time.isBefore(now),
        isNotificationEnabled: mode != PrayerNotificationMode.off,
        notificationMode: mode,
        onToggleNotification:
            isSunrise ? null : () => _togglePrayerNotification(name),
        onSelectMode: isSunrise
            ? null
            : (selectedMode) => _setPrayerNotificationMode(name, selectedMode),
      );
    }).toList();
  }

  void _setPrayerNotificationMode(
    String prayerName,
    PrayerNotificationMode newMode,
  ) {
    final currentSettings = _adhanSettings ??
        const AdhanSettings(
          enabled: true,
          sound: AdhanSound.qatami,
          silentNotifications: false,
          prayerToggles: {},
          calculationMethod: 'auto',
          volume: 1.0,
          notifyBeforeMinutes: 0,
          iqamaReminders: false,
          adjustments: {},
        );

    final updatedModes =
        Map<String, PrayerNotificationMode>.from(currentSettings.prayerModes);
    updatedModes[prayerName] = newMode;

    final updatedToggles =
        Map<String, bool>.from(currentSettings.prayerToggles);
    updatedToggles[prayerName] = newMode != PrayerNotificationMode.off;

    final updatedSettings = currentSettings.copyWith(
      enabled: true,
      prayerModes: updatedModes,
      prayerToggles: updatedToggles,
    );

    // Instant optimistic UI update: zero frame lag
    setState(() {
      _adhanSettings = updatedSettings;
    });

    HapticFeedback.selectionClick();
    final modeLabel = switch (newMode) {
      PrayerNotificationMode.adhan => 'أذان كامل',
      PrayerNotificationMode.takbeer => 'تكبيرات فقط',
      PrayerNotificationMode.announcement => 'نداء وقت الصلاة',
      PrayerNotificationMode.tone => 'نغمة تنبيه هادئة',
      PrayerNotificationMode.silent => 'إشعار صامت',
      PrayerNotificationMode.off => 'إيقاف التنبيه',
    };
    if (mounted) {
      AppSnackbar.success(
        context,
        '$prayerName: تم ضبط التنبيه إلى ($modeLabel)',
        duration: AppMotion.toastShort,
        hasNavBar: true,
      );
    }

    // Non-blocking asynchronous persistence and alarm scheduling
    unawaited(() async {
      try {
        await _adhanSettingsService.saveSettings(updatedSettings);
        await _prayerScheduleService.refreshSchedulesIfNeeded(
          day: _cachedDay,
          force: true,
        );
      } catch (e) {
        debugPrint('Error saving prayer notification mode: $e');
      }
    }());
  }

  void _togglePrayerNotification(String prayerName) {
    final currentSettings = _adhanSettings ??
        const AdhanSettings(
          enabled: true,
          sound: AdhanSound.qatami,
          silentNotifications: false,
          prayerToggles: {},
          calculationMethod: 'auto',
          volume: 1.0,
          notifyBeforeMinutes: 0,
          iqamaReminders: false,
          adjustments: {},
        );
    final currentMode = currentSettings.modeForPrayer(prayerName);

    // Cycle: adhan -> takbeer -> announcement -> tone -> silent -> off -> adhan
    final PrayerNotificationMode nextMode = switch (currentMode) {
      PrayerNotificationMode.adhan => PrayerNotificationMode.takbeer,
      PrayerNotificationMode.takbeer => PrayerNotificationMode.announcement,
      PrayerNotificationMode.announcement => PrayerNotificationMode.tone,
      PrayerNotificationMode.tone => PrayerNotificationMode.silent,
      PrayerNotificationMode.silent => PrayerNotificationMode.off,
      PrayerNotificationMode.off => PrayerNotificationMode.adhan,
    };

    final updatedModes =
        Map<String, PrayerNotificationMode>.from(currentSettings.prayerModes);
    updatedModes[prayerName] = nextMode;

    final updatedToggles =
        Map<String, bool>.from(currentSettings.prayerToggles);
    updatedToggles[prayerName] = nextMode != PrayerNotificationMode.off;

    final updatedSettings = currentSettings.copyWith(
      enabled: true,
      prayerModes: updatedModes,
      prayerToggles: updatedToggles,
    );

    // Instant optimistic UI update
    setState(() {
      _adhanSettings = updatedSettings;
    });

    HapticFeedback.selectionClick();
    if (mounted) {
      final String modeName = switch (nextMode) {
        PrayerNotificationMode.adhan => 'أذان كامل',
        PrayerNotificationMode.takbeer => 'تكبيرات فقط',
        PrayerNotificationMode.announcement => 'نداء وقت الصلاة',
        PrayerNotificationMode.tone => 'نغمة هادئة',
        PrayerNotificationMode.silent => 'إشعار صامت',
        PrayerNotificationMode.off => 'إيقاف التنبيه',
      };
      AppSnackbar.info(
        context,
        nextMode != PrayerNotificationMode.off
            ? 'تم ضبط تنبيه صلاة $prayerName: $modeName'
            : 'تم إيقاف تنبيه صلاة $prayerName',
        duration: AppMotion.toastShort,
        hasNavBar: true,
      );
    }

    // Non-blocking asynchronous persistence and alarm scheduling
    unawaited(() async {
      try {
        await _adhanSettingsService.saveSettings(updatedSettings);
        await _prayerScheduleService.refreshSchedulesIfNeeded(
          day: _cachedDay,
          force: true,
        );
      } catch (e) {
        debugPrint('Error toggling prayer notification mode: $e');
      }
    }());
  }

  void _ensureCountdown(PrayerTimesDay day) {
    if (_cachedDay?.date == day.date && _countdownController != null) {
      return;
    }

    _countdownController?.dispose();
    _cachedDay = day;
    _countdownController = PrayerCountdownController(
      day: day,
      prayerTimeService: _prayerTimeService,
    )..start();
  }

  void _loadPrayer() {
    _prayerFuture = _prayerTimeService.getPrayerTimesDay();
    _prayerFuture.then((day) {
      if (!mounted) return;
      _ensureCountdown(day);
      unawaited(_prayerScheduleService.refreshSchedulesIfNeeded(day: day));
    });
  }

  void _reloadPrayer() {
    setState(() {
      _loadPrayer();
      _locationFuture = _loadLocation();
      _loadSettings();
    });
  }

  void _openLocationSettings(BuildContext context) {
    AppSnackbar.dismiss();
    LocationSettingsSheet.show(context, onSaved: _reloadPrayer);
  }

  void _openPrayerSettings(BuildContext context) {
    AppSnackbar.dismiss();
    PrayerSettingsSheet.show(context, onSettingsChanged: _reloadPrayer);
  }

  void _openAfterPrayer(BuildContext context, String prayerName) {
    Navigator.push(
      context,
      buildFadeRoute(page: AfterPrayerAthkarPage(prayerName: prayerName)),
    );
  }

  void _openDuas(BuildContext context) {
    Navigator.push(context, buildFadeRoute(page: DuasMiscPage()));
  }

  void _openQibla(BuildContext context) {
    Navigator.push(context, buildFadeRoute(page: const QiblaPage()));
  }
}
