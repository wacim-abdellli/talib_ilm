import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
                        // Celestial Header Banner
                        Container(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                          decoration: BoxDecoration(
                            color: context.surfaceColor,
                            border: Border(
                              bottom: BorderSide(
                                color: context.outlineColor.withValues(alpha: 0.1),
                              ),
                            ),
                          ),
                          child: SafeArea(
                            bottom: false,
                            child: Column(
                              children: [
                                // Top row: Title + Settings
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: context.primaryColor.withValues(alpha: 0.12),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.mosque_rounded,
                                            color: context.primaryColor,
                                            size: 22,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          'مواقيت الصلاة',
                                          style: TextStyle(
                                            fontFamily: 'Cairo',
                                            fontSize: 20,
                                            fontWeight: FontWeight.w800,
                                            color: context.textPrimaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.settings_outlined,
                                        color: context.textSecondaryColor,
                                        size: 22,
                                      ),
                                      tooltip: 'إعدادات الصلاة',
                                      onPressed: () => _openLocationSettings(context),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // Chips: City, Date, Qibla
                                Row(
                                  children: [
                                    // City Selector Chip
                                    Expanded(
                                      child: InkWell(
                                        onTap: () => _openLocationSettings(context),
                                        borderRadius: BorderRadius.circular(16),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            color: context.surfaceContainer,
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(
                                              color: context.outlineColor.withValues(alpha: 0.15),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.location_on_rounded,
                                                color: context.islamicGreenColor,
                                                size: 18,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  city,
                                                  style: TextStyle(
                                                    fontFamily: 'Cairo',
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: context.textPrimaryColor,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    // Date Chip
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: context.surfaceContainer,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: context.outlineColor.withValues(alpha: 0.15),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.calendar_today_rounded,
                                            color: context.textSecondaryColor,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            gregorianDate,
                                            style: TextStyle(
                                              fontFamily: 'Cairo',
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: context.textPrimaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    // Qibla Button
                                    InkWell(
                                      onTap: () => _openQibla(context),
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              context.goldColor.withValues(alpha: 0.2),
                                              context.goldColor.withValues(alpha: 0.08),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: context.goldColor.withValues(alpha: 0.35),
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.explore_rounded,
                                          color: context.goldColor,
                                          size: 22,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
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
                                _PrayerTimeCard(
                                  item: times[i],
                                  onBeforeAdhkar: () => _openDuas(context),
                                  onAfterAdhkar: () =>
                                      _openAfterPrayer(context, times[i].name),
                                ),
                                if (i != times.length - 1)
                                  SizedBox(height: responsive.smallGap),
                              ],
                              SizedBox(height: responsive.largeGap),
                              // Extra padding for nav bar
                              const SizedBox(height: 100),
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

  List<_PrayerTimeEntry> _buildPrayerTimes(
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
      return _PrayerTimeEntry(
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

class _PrayerTimeEntry {
  final String name;
  final String timeLabel;
  final bool isNext;
  final bool isCurrent;
  final bool isCompleted;

  const _PrayerTimeEntry({
    required this.name,
    required this.timeLabel,
    required this.isNext,
    required this.isCurrent,
    required this.isCompleted,
  });
}

class _PrayerTimeCard extends StatelessWidget {
  final _PrayerTimeEntry item;
  final VoidCallback? onBeforeAdhkar;
  final VoidCallback? onAfterAdhkar;

  const _PrayerTimeCard({
    required this.item,
    this.onBeforeAdhkar,
    this.onAfterAdhkar,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isCurrent = item.isCurrent;
    final isCompleted = item.isCompleted;
    final iconData = _iconFor(item.name);
    final iconColor = _colorFor(item.name, isDark);
    final statusIcon = _statusIcon(isCurrent, isCompleted);
    final statusColor = isCurrent
        ? context.goldColor
        : (isCompleted
            ? context.islamicGreenColor
            : context.textSecondaryColor.withValues(alpha: 0.6));

    final titleColor = context.textPrimaryColor;
    final timeColor = isCurrent ? context.goldColor : context.textPrimaryColor;

    final backgroundColor = isCurrent
        ? context.surfaceContainer
        : context.surfaceContainer;

    final borderColor = isCurrent
        ? context.goldColor.withValues(alpha: isDark ? 0.6 : 0.5)
        : context.outlineColor.withValues(alpha: isDark ? 0.12 : 0.08);

    final gradient = isCurrent
        ? LinearGradient(
            colors: isDark
                ? [
                    context.goldColor.withValues(alpha: 0.12),
                    context.surfaceContainer,
                  ]
                : [
                    context.goldColor.withValues(alpha: 0.08),
                    context.surfaceContainer,
                  ],
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
          )
        : null;

    final subtitle = isCurrent
        ? 'الآن'
        : (item.isNext ? AppStrings.prayerNext : AppStrings.prayerDayLabel);

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderColor,
          width: isCurrent ? 1.4 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isCurrent
                ? context.goldColor.withValues(alpha: isDark ? 0.12 : 0.08)
                : Colors.black.withValues(alpha: isDark ? 0.18 : 0.03),
            blurRadius: isCurrent ? 14 : 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Prayer Icon with Ornate circular container
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: isDark ? 0.16 : 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: iconColor.withValues(alpha: isCurrent ? 0.45 : 0.25),
                width: 1.2,
              ),
            ),
            child: Icon(
              iconData,
              size: 22,
              color: iconColor,
            ),
          ),
          const SizedBox(width: 14),

          // Prayer Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      item.name,
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isCurrent || item.isNext)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: context.goldColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          subtitle,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: context.goldColor,
                          ),
                        ),
                      ),
                  ],
                ),
                if (onBeforeAdhkar != null || onAfterAdhkar != null) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (onBeforeAdhkar != null)
                        _AdhkarLink(
                          label: AppStrings.beforePrayerDhikr,
                          onTap: onBeforeAdhkar,
                        ),
                      if (onAfterAdhkar != null)
                        _AdhkarLink(
                          label: AppStrings.afterPrayerDhikr,
                          onTap: onAfterAdhkar,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Prayer Time & Status Icon
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item.timeLabel,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: timeColor,
                ),
              ),
              const SizedBox(height: 4),
              Icon(
                statusIcon,
                size: 18,
                color: statusColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _iconFor(String name) {
    switch (name) {
      case AppStrings.prayerFajr:
        return Icons.wb_twilight_rounded;
      case AppStrings.prayerDhuhr:
        return Icons.wb_sunny_rounded;
      case AppStrings.prayerAsr:
        return Icons.wb_sunny_outlined;
      case AppStrings.prayerMaghrib:
        return Icons.nights_stay_rounded;
      case AppStrings.prayerIsha:
        return Icons.dark_mode_rounded;
    }
    return Icons.access_time_rounded;
  }

  Color _colorFor(String name, bool isDark) {
    switch (name) {
      case AppStrings.prayerFajr:
        return AppColors.fajr;
      case AppStrings.prayerDhuhr:
        return AppColors.gold;
      case AppStrings.prayerAsr:
        return AppColors.asr;
      case AppStrings.prayerMaghrib:
        return AppColors.maghrib;
      case AppStrings.prayerIsha:
        return AppColors.isha;
    }
    return isDark ? AppColors.darkGold : AppColors.primary;
  }

  IconData _statusIcon(bool isCurrent, bool isCompleted) {
    if (isCurrent) return Icons.notifications_active_rounded;
    if (isCompleted) return Icons.check_circle_rounded;
    return Icons.notifications_none_rounded;
  }
}

class _AdhkarLink extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _AdhkarLink({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final gold = context.goldColor;

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: gold.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: gold.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_stories_rounded,
              size: 11,
              color: gold,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: gold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
