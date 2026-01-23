import 'package:flutter/material.dart';

import '../../../app/constants/app_strings.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text.dart';
import '../../../app/theme/app_ui.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/prayer_schedule_service.dart';
import '../../../core/services/prayer_time_service.dart';
import '../../../core/utils/prayer_countdown.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/navigation/fade_page_route.dart';

import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/pressable_card.dart';

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
      body: Container(
        color: isDark ? Colors.black : AppColors.background,
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
                          baseColor: isDark
                              ? const Color(0xFF1A1A1A)
                              : Colors.grey[300]!,
                          highlightColor: isDark
                              ? const Color(0xFF2A2A2A)
                              : Colors.grey[100]!,
                          child: Container(
                            height: 140,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF0A0A0A)
                                  : Colors.white,
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
                        // Header section
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF000000)
                                : const Color(0xFF6A9A9A),
                            border: isDark
                                ? const Border(
                                    bottom: BorderSide(
                                      color: Color(0xFF1F1F1F),
                                    ),
                                  )
                                : null,
                          ),
                          child: SafeArea(
                            bottom: false,
                            child: Column(
                              children: [
                                // Top row
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.menu_rounded,
                                        color: Colors.white,
                                        size: 26,
                                      ),
                                      onPressed: () {},
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.settings_outlined,
                                        color: Colors.white,
                                        size: 26,
                                      ),
                                      onPressed: () =>
                                          _openLocationSettings(context),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                // Title
                                const Text(
                                  'مواقيت الصلاة',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Location
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.location_on_rounded,
                                      color: Colors.white.withValues(
                                        alpha: 0.9,
                                      ),
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        city,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.white.withValues(
                                            alpha: 0.9,
                                          ),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),

                                // Time progress circle
                                Center(
                                  child: SizedBox(
                                    width: 200,
                                    height: 200,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        // Background circle
                                        SizedBox(
                                          width: 200,
                                          height: 200,
                                          child: CircularProgressIndicator(
                                            value: 1.0,
                                            strokeWidth: 12,
                                            color: const Color(0xFF1F1F1F),
                                          ),
                                        ),
                                        // Progress circle
                                        SizedBox(
                                          width: 200,
                                          height: 200,
                                          child: CircularProgressIndicator(
                                            value:
                                                0.4, // Calculate: time passed / total time
                                            strokeWidth: 12,
                                            color: const Color(0xFF00D9C0),
                                          ),
                                        ),
                                        // Center text
                                        Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'العصر',
                                              style: TextStyle(
                                                fontSize: 18,
                                                color: Colors.white70,
                                              ),
                                            ),
                                            Text(
                                              '00:37:39',
                                              style: TextStyle(
                                                fontSize: 32,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 20),
                                // Date and Qibla row
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? const Color(0xFF141414)
                                              : Colors.white.withValues(
                                                  alpha: 0.12,
                                                ),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color: isDark
                                                ? const Color(0xFF333333)
                                                : Colors.white.withValues(
                                                    alpha: 0.25,
                                                  ),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.calendar_today_rounded,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                            const SizedBox(width: 8),
                                            Flexible(
                                              child: Text(
                                                gregorianDate,
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    GestureDetector(
                                      onTap: () => _openQibla(context),
                                      child: Container(
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? const Color(0xFF141414)
                                              : Colors.white.withValues(
                                                  alpha: 0.12,
                                                ),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color: isDark
                                                ? const Color(0xFF333333)
                                                : Colors.white.withValues(
                                                    alpha: 0.25,
                                                  ),
                                            width: 1,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.explore_rounded,
                                          color: Colors.white,
                                          size: 24,
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
    final responsive = Responsive(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isCurrent = item.isCurrent;
    final isCompleted = item.isCompleted;
    final iconData = _iconFor(item.name);
    final iconColor = _colorFor(item.name, isDark);
    final statusIcon = _statusIcon(isCurrent, isCompleted);
    final statusColor = _statusColor(isCurrent, isCompleted, isDark);

    final titleColor = isDark
        ? Colors.white
        : (isCompleted ? AppColors.textSecondary : AppColors.textPrimary);

    final timeColor = isDark
        ? Colors.white
        : (isCurrent ? AppColors.primary : titleColor);

    // Dark mode logic matching PrayerTimeTile
    final backgroundColor = isDark
        ? (isCurrent ? const Color(0xFF0A0A0A) : const Color(0xFF0A0A0A))
        : (isCurrent
              ? const Color(0xFF6A9A9A).withValues(alpha: 0.08)
              : const Color(0xFFF5F3F0));

    final borderColor = isDark
        ? (isCurrent
              ? iconColor.withValues(alpha: 0.4)
              : const Color(0xFF1F1F1F))
        : (isCurrent
              ? const Color(0xFF6A9A9A).withValues(alpha: 0.2)
              : const Color(0xFFE8E6E3));

    // Active Gradient Overlay for Dark Mode
    final gradient = (isDark && isCurrent)
        ? LinearGradient(
            colors: [
              iconColor.withValues(alpha: 0.15),
              const Color(0xFF0A0A0A),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          )
        : null;

    final subtitle = isCurrent
        ? AppStrings.prayerCurrent
        : item.isNext
        ? AppStrings.prayerNext
        : AppStrings.prayerDayLabel;

    return PressableCard(
      onTap: null,
      padding: EdgeInsets.symmetric(
        horizontal: responsive.safeHorizontalPadding,
        vertical: responsive.hp(1.5),
      ),
      borderRadius: BorderRadius.circular(AppUi.radiusSMPlus),
      decoration: BoxDecoration(
        color: backgroundColor,
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppUi.radiusSMPlus),
        border: Border.all(
          color: borderColor,
          width: isDark && isCurrent ? 1.5 : AppUi.dividerThickness,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: responsive.sp(40),
            height: responsive.sp(40),
            decoration: BoxDecoration(
              color: isDark
                  ? iconColor.withValues(alpha: 0.15)
                  : iconColor.withValues(alpha: 0.18),
              shape: BoxShape.circle,
              // Add gradient for active icon in dark mode if needed
              gradient: (isDark && isCurrent)
                  ? LinearGradient(
                      colors: [
                        iconColor.withValues(alpha: 0.3),
                        iconColor.withValues(alpha: 0.15),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
            ),
            child: Icon(
              iconData,
              size: responsive.mediumIcon,
              color: iconColor,
            ),
          ),
          SizedBox(width: responsive.hp(1.2)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body.copyWith(
                    fontSize: responsive.sp(15),
                    fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w600,
                    color: titleColor,
                  ),
                ),
                SizedBox(height: responsive.hp(0.6)),
                Text(
                  subtitle,
                  style: AppText.caption.copyWith(
                    fontSize: responsive.sp(11),
                    color: isDark
                        ? const Color(0xFFA1A1A1)
                        : AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                if (onBeforeAdhkar != null || onAfterAdhkar != null) ...[
                  SizedBox(height: responsive.hp(0.8)),
                  Row(
                    children: [
                      if (onBeforeAdhkar != null)
                        Flexible(
                          child: _AdhkarLink(
                            label: AppStrings.beforePrayerDhikr,
                            onTap: onBeforeAdhkar,
                          ),
                        ),
                      if (onBeforeAdhkar != null && onAfterAdhkar != null)
                        SizedBox(width: responsive.smallGap),
                      if (onAfterAdhkar != null)
                        Flexible(
                          child: _AdhkarLink(
                            label: AppStrings.afterPrayerDhikr,
                            onTap: onAfterAdhkar,
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: responsive.mediumGap),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item.timeLabel,
                style: AppText.body.copyWith(
                  fontSize: responsive.sp(16),
                  fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w600,
                  color: timeColor,
                ),
              ),
              SizedBox(height: responsive.hp(0.6)),
              Icon(statusIcon, size: responsive.mediumIcon, color: statusColor),
            ],
          ),
        ],
      ),
    );
  }

  IconData _iconFor(String name) {
    switch (name) {
      case AppStrings.prayerFajr:
        return Icons.wb_twilight;
      case AppStrings.prayerDhuhr:
        return Icons.wb_sunny;
      case AppStrings.prayerAsr:
        return Icons.wb_sunny_outlined;
      case AppStrings.prayerMaghrib:
        return Icons.nights_stay;
      case AppStrings.prayerIsha:
        return Icons.dark_mode;
    }
    return Icons.access_time;
  }

  Color _colorFor(String name, bool isDark) {
    if (isDark) {
      switch (name) {
        case AppStrings.prayerFajr:
          return const Color(0xFF6366F1);
        case AppStrings.prayerDhuhr:
          return const Color(0xFF00D9C0);
        case AppStrings.prayerAsr:
          return const Color(0xFFFF8A3D);
        case AppStrings.prayerMaghrib:
          return const Color(0xFFFF4D9E);
        case AppStrings.prayerIsha:
          return const Color(0xFFA855F7);
      }
      return const Color(0xFF00D9C0);
    }

    switch (name) {
      case AppStrings.prayerFajr:
        return const Color(0xFFE8A87C);
      case AppStrings.prayerDhuhr:
        return const Color(0xFFD4AF37);
      case AppStrings.prayerAsr:
        return const Color(0xFFC19A6B);
      case AppStrings.prayerMaghrib:
        return const Color(0xFFCD853F);
      case AppStrings.prayerIsha:
        return const Color(0xFF6B7F99);
    }
    return AppColors.textSecondary;
  }

  IconData _statusIcon(bool isCurrent, bool isCompleted) {
    if (isCurrent) return Icons.notifications_active;
    if (isCompleted) return Icons.check_circle;
    return Icons.notifications_none;
  }

  Color _statusColor(bool isCurrent, bool isCompleted, bool isDark) {
    if (isCurrent) {
      return isDark ? const Color(0xFF00D9C0) : const Color(0xFF6A9A9A);
    }
    if (isCompleted) {
      return isDark ? const Color(0xFF666666) : const Color(0xFF85A885);
    }
    return isDark ? const Color(0xFF666666) : const Color(0xFF9A9A9A);
  }
}

class _AdhkarLink extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _AdhkarLink({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppUi.radiusXS),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: responsive.wp(1.4),
          vertical: responsive.hp(0.4),
        ),
        child: Text(
          label,
          style: AppText.caption.copyWith(
            fontSize: responsive.sp(11),
            color: isDark ? const Color(0xFFA1A1A1) : AppColors.textSecondary,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
    );
  }
}
