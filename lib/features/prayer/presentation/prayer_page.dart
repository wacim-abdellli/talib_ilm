import 'package:flutter/material.dart';

import '../../../app/constants/app_strings.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/theme_colors.dart';
import '../../../app/theme/app_text.dart';
import '../../../app/theme/app_ui.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/prayer_schedule_service.dart';
import '../../../core/services/prayer_time_service.dart';
import '../../../core/utils/prayer_countdown.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/navigation/fade_page_route.dart';

import '../../../shared/widgets/empty_state.dart';

import 'package:shimmer/shimmer.dart'; // Direct shimmer import if needed for extensions? No, wrapper used.
import '../../../shared/widgets/shimmer_loading.dart';
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
    final responsive = Responsive(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: context.backgroundColor,
      body: Container(
        color: context.backgroundColor,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: FutureBuilder<PrayerTimesDay>(
            future: _prayerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Padding(
                  padding: EdgeInsets.all(responsive.safePadding),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Shimmer.fromColors(
                          baseColor: context.shimmerBaseColor,
                          highlightColor: context.shimmerHighlightColor,
                          child: Container(
                            height: 140,
                            decoration: BoxDecoration(
                              color: context.surfaceColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                        SizedBox(height: responsive.largeGap),
                        const ShimmerPrayerList(count: 5),
                      ],
                    ),
                  ),
                );
              }

              if (!snapshot.hasData) {
                return Padding(
                  padding: EdgeInsets.all(responsive.safePadding),
                  child: SizedBox(
                    width: responsive.wp(92),
                    child: EmptyState(
                      icon: Icons.access_time,
                      title: AppStrings.prayerLoadErrorTitle,
                      subtitle: AppStrings.prayerLoadErrorMessage,
                      actionLabel: AppStrings.actionRetry,
                      onAction: _reloadPrayer,
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
                          padding: EdgeInsets.symmetric(
                            horizontal: responsive.safeHorizontalPadding,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(height: responsive.mediumGap),
                              _buildNextPrayerCard(data),
                              SizedBox(height: responsive.largeGap),
                              Text(
                                AppStrings.prayerDayLabel,
                                style: AppText.body.copyWith(
                                  fontSize: responsive.sp(13),
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                ),
                                textAlign: TextAlign.right,
                              ),
                              SizedBox(height: responsive.mediumGap),
                              for (var i = 0; i < times.length; i++) ...[
                                PrayerTimeCard(
                                  item: times[i],
                                  onBeforeAdhkar: () => _openDuas(context),
                                  onAfterAdhkar: () =>
                                      _openAfterPrayer(context, times[i].name),
                                ),
                                if (i != times.length - 1)
                                  SizedBox(height: responsive.smallGap),
                              ],
                              SizedBox(height: responsive.largeGap),
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppUi.radiusMD),
        ),
      ),
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

