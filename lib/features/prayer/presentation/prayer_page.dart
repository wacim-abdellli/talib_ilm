import 'package:flutter/material.dart';

import '../../../app/constants/app_strings.dart';
import '../../../app/theme/app_palette.dart';
import '../../../app/theme/app_ui.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/prayer_schedule_service.dart';
import '../../../core/services/prayer_time_service.dart';
import '../../../core/utils/prayer_countdown.dart';
import '../../../shared/navigation/fade_page_route.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_skeleton.dart';
import '../../../shared/widgets/app_states.dart';
import '../../adhkar/presentation/after_prayer_athkar_page.dart';
import '../../adhkar/presentation/duas_misc_page.dart';
import '../data/models/prayer_models.dart';
import 'location_settings_sheet.dart';
import 'qibla_page.dart';
import 'widgets/next_prayer_card.dart';
import 'widgets/prayer_header.dart';
import 'widgets/prayer_time_card.dart';

class PrayerPage extends StatefulWidget {
  const PrayerPage({super.key});

  @override
  State<PrayerPage> createState() => _PrayerPageState();
}

class _PrayerPageState extends State<PrayerPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final PrayerTimeService _prayerTimeService = PrayerTimeService();
  final PrayerScheduleService _prayerScheduleService = PrayerScheduleService();
  final LocationService _locationService = LocationService();
  late Future<PrayerTimesDay> _prayerFuture;
  late Future<_LocationInfo> _locationFuture;
  PrayerCountdownController? _countdownController;
  PrayerTimesDay? _cachedDay;

  @override
  void initState() {
    super.initState();
    _loadPrayer();
    _locationFuture = _loadLocation();
  }

  @override
  void dispose() {
    _countdownController?.dispose();
    super.dispose();
  }

  Future<_LocationInfo> _loadLocation() async {
    // Add small delay to prevent startup resource contention on emulators
    await Future.delayed(const Duration(milliseconds: 500));
    try {
      final manual = await _locationService.getManualLocation();
      final location = await _locationService.getLocation();
      return _LocationInfo(city: location.city, isManual: manual != null);
    } catch (e) {
      debugPrint('Error loading location: $e');
      // Return a safe default if location fails
      return const _LocationInfo(city: 'مكة المكرمة', isManual: false);
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
              if (snapshot.connectionState == ConnectionState.waiting) {
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

              if (!snapshot.hasData) {
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

              final data = snapshot.data!;
              _ensureCountdown(data);
              final nextName = _findNextPrayerName(data.prayers);
              final currentName = _findCurrentPrayerName(
                data.prayers,
                nextName,
              );
              final times = _buildPrayerTimes(data, nextName, currentName);
              final gregorianDate = _formatGregorianDate(data.date);

              return FutureBuilder<_LocationInfo>(
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
                              const SizedBox(height: AppSpace.lg),
                              Text(
                                AppStrings.prayerDayLabel,
                                style: context.text.titleSmall.copyWith(
                                  color: context.palette.text,
                                ),
                                textAlign: TextAlign.right,
                              ),
                              const SizedBox(height: AppSpace.md),
                              for (var i = 0; i < times.length; i++) ...[
                                PrayerTimeCard(
                                  item: times[i],
                                  onBeforeAdhkar: () => _openDuas(context),
                                  onAfterAdhkar: () =>
                                      _openAfterPrayer(context, times[i].name),
                                ),
                                if (i != times.length - 1)
                                  const SizedBox(height: AppSpace.sm),
                              ],
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
      final prayer = _buildNextPrayer(day);
      final nextTime = day.prayers[day.nextPrayer] ?? DateTime.now();
      final remaining = nextTime.difference(DateTime.now());
      final progress = _calculatePrayerProgress(
        day,
        day.nextPrayer,
        nextTime,
        remaining,
      );
      return NextPrayerCard(
        prayer: prayer,
        countdownText: _formatCountdown(remaining),
        progress: progress,
        onTap: () {},
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
        final progress = _calculatePrayerProgress(
          day,
          state.nextPrayerName,
          state.nextPrayerTime,
          state.remaining,
        );
        return NextPrayerCard(
          prayer: prayer,
          countdownText: _formatCountdown(state.remaining),
          progress: progress,
          onTap: () {},
        );
      },
    );
  }

  double _calculatePrayerProgress(
    PrayerTimesDay day,
    String nextPrayerLabel,
    DateTime nextTime,
    Duration remaining,
  ) {
    final order = AppStrings.prayerOrder;
    final index = order.indexOf(nextPrayerLabel);
    if (index == -1) return 0.0;
    final prevLabel = order[(index - 1 + order.length) % order.length];
    final prevTime = day.prayers[prevLabel];
    if (prevTime == null) return 0.0;
    var startTime = prevTime;
    if (startTime.isAfter(nextTime)) {
      startTime = startTime.subtract(const Duration(days: 1));
    }
    final totalSeconds = nextTime.difference(startTime).inSeconds;
    if (totalSeconds <= 0) return 0.0;
    final remainingSeconds = remaining.inSeconds;
    final progress = 1 - (remainingSeconds / totalSeconds);
    return progress.clamp(0.0, 1.0);
  }

  NextPrayer _buildNextPrayer(PrayerTimesDay day) {
    final now = DateTime.now();
    final time = day.prayers[day.nextPrayer] ?? now;
    final minutes = time.difference(now).inMinutes;
    return NextPrayer(
      prayer: prayerFromLabel(day.nextPrayer) ?? Prayer.fajr,
      time: time,
      minutesRemaining: minutes < 0 ? 0 : minutes,
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
      final isNext = nextName != null && name == nextName;
      return PrayerTimeEntry(
        name: name,
        timeLabel: _formatTime(time),
        isNext: isNext,
        isCurrent: isCurrent,
        isCompleted: !isCurrent && time.isBefore(now),
      );
    }).toList();
  }

  String? _findNextPrayerName(Map<String, DateTime> prayers) {
    final current = DateTime.now();
    final entries = prayers.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    for (final entry in entries) {
      if (!entry.value.isBefore(current)) {
        return entry.key;
      }
    }

    return null;
  }

  String? _findCurrentPrayerName(
    Map<String, DateTime> prayers,
    String? nextName,
  ) {
    const order = AppStrings.prayerOrder;
    if (prayers.isEmpty) return null;

    if (nextName == null) {
      return order.lastWhere(prayers.containsKey, orElse: () => '').isEmpty
          ? null
          : order.lastWhere(prayers.containsKey);
    }

    final nextIndex = order.indexOf(nextName);
    if (nextIndex <= 0) return null;
    for (var i = nextIndex - 1; i >= 0; i--) {
      final candidate = order[i];
      if (prayers.containsKey(candidate)) return candidate;
    }
    return null;
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
    _prayerFuture.then((day) async {
      if (!mounted) return;
      _ensureCountdown(day);
      await _prayerScheduleService.refreshSchedulesIfNeeded(day: day);
    });
  }

  void _reloadPrayer() {
    setState(() {
      _loadPrayer();
      _locationFuture = _loadLocation();
    });
  }

  void _openLocationSettings(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LocationSettingsSheet(onSaved: _reloadPrayer),
    );
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

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatCountdown(Duration duration) {
    final totalSeconds = duration.inSeconds;
    final hours = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  String _formatGregorianDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }
}

class _LocationInfo {
  final String city;
  final bool isManual;

  const _LocationInfo({required this.city, required this.isManual});
}
