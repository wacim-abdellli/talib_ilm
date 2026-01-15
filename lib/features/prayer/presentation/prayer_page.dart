import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
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
import '../../../shared/widgets/app_drawer.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/pressable_card.dart';
import '../../../shared/widgets/primary_app_bar.dart';
import '../../adhkar/presentation/after_prayer_athkar_page.dart';
import '../../adhkar/presentation/duas_misc_page.dart';
import '../data/models/prayer_models.dart';
import 'location_settings_sheet.dart';
import 'prayer_settings_sheet.dart';
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
    final manual = await _locationService.getManualLocation();
    final location = await _locationService.getLocation();
    return _LocationInfo(city: location.city, isManual: manual != null);
  }

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    final hasUnread = _hasUnread();
    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      appBar: PrimaryAppBar(
        title: AppStrings.prayerTitle,
        showMenu: true,
        onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
        actions: [
          IconButton(
            onPressed: () => _openAdhanSettings(context),
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  Icons.notifications_outlined,
                  color: AppColors.textSecondary,
                ),
                if (hasUnread)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppUi.gapSM),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openQibla(context),
        backgroundColor: AppColors.primary,
        child: Icon(
          Icons.explore,
          color: AppColors.surface,
          size: responsive.largeIcon,
        ),
      ),
      body: Container(
        color: AppColors.background,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: FutureBuilder<PrayerTimesDay>(
            future: _prayerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData) {
                return Padding(
                  padding: EdgeInsets.all(responsive.safePadding),
                  child: SizedBox(
                    width: responsive.wp(92),
                    child: EmptyState(
                      icon: Icons.access_time,
                      title: AppStrings.prayerLoadErrorTitle,
                      message: AppStrings.prayerLoadErrorMessage,
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
              final hijriDate = _formatHijriDate(data.date);
              final gregorianDate = _formatGregorianDate(data.date);

              return FutureBuilder<_LocationInfo>(
                future: _locationFuture,
                builder: (context, locationSnapshot) {
                  final location = locationSnapshot.data;
                  final city = location?.city ?? data.city;
                  final isManual = location?.isManual ?? false;

                  return SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: responsive.safeHorizontalPadding,
                      vertical: responsive.safeVerticalPadding,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _LocationCard(
                          city: city,
                          isManual: isManual,
                          hijriDate: hijriDate,
                          gregorianDate: gregorianDate,
                          onTap: () => _openLocationSettings(context),
                        ),
                        SizedBox(height: responsive.mediumGap),
                        _buildNextPrayerCard(data),
                        SizedBox(height: responsive.largeGap),
                        Text(
                          AppStrings.prayerDayLabel,
                          style: AppText.body.copyWith(
                            fontSize: responsive.sp(13),
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
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

  bool _hasUnread() => false;

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

  void _openAdhanSettings(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppUi.radiusMD),
        ),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: const PrayerSettingsSheet(),
        ),
      ),
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

  String _formatHijriDate(DateTime date) {
    HijriCalendar.setLocal('ar');
    final hijri = HijriCalendar.fromDate(date);
    return '${hijri.hDay} ${hijri.longMonthName} ${hijri.hYear}';
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

class _LocationCard extends StatelessWidget {
  final String city;
  final bool isManual;
  final String hijriDate;
  final String gregorianDate;
  final VoidCallback onTap;

  const _LocationCard({
    required this.city,
    required this.isManual,
    required this.hijriDate,
    required this.gregorianDate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    final badgeLabel = isManual ? 'يدوي' : 'تلقائي';
    final icon = isManual ? Icons.location_on : Icons.my_location;

    return PressableCard(
      onTap: onTap,
      padding: EdgeInsets.symmetric(
        horizontal: responsive.safeHorizontalPadding,
        vertical: responsive.smallGap,
      ),
      borderRadius: BorderRadius.circular(AppUi.radiusSMPlus),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppUi.radiusSMPlus),
        border: Border.all(
          color: AppColors.stroke,
          width: AppUi.dividerThickness,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.textSecondary,
            size: responsive.mediumIcon,
          ),
          SizedBox(width: responsive.smallGap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        city,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.body.copyWith(
                          fontSize: responsive.sp(14),
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    SizedBox(width: responsive.smallGap),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: responsive.wp(2.4),
                        vertical: responsive.hp(0.5),
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppUi.radiusPill),
                      ),
                      child: Text(
                        badgeLabel,
                        style: AppText.caption.copyWith(
                          fontSize: responsive.sp(11),
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: responsive.hp(0.6)),
                Text(
                  '$hijriDate • $gregorianDate',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.caption.copyWith(
                    fontSize: responsive.sp(11),
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: responsive.smallGap),
          Icon(
            Icons.chevron_left,
            color: AppColors.textSecondary,
            size: responsive.mediumIcon,
          ),
        ],
      ),
    );
  }
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
    final isCurrent = item.isCurrent;
    final isCompleted = item.isCompleted;
    final iconData = _iconFor(item.name);
    final iconColor = _colorFor(item.name);
    final statusIcon = _statusIcon(isCurrent, isCompleted);
    final statusColor = _statusColor(isCurrent, isCompleted);
    final titleColor = isCompleted
        ? AppColors.textSecondary
        : AppColors.textPrimary;
    final timeColor = isCurrent ? AppColors.primary : titleColor;
    final backgroundColor = isCurrent
        ? AppColors.primaryLight.withValues(alpha: 0.08)
        : AppColors.surface;
    final borderColor = isCurrent
        ? AppColors.primary.withValues(alpha: 0.25)
        : AppColors.stroke;
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
        borderRadius: BorderRadius.circular(AppUi.radiusSMPlus),
        border: Border.all(color: borderColor, width: AppUi.dividerThickness),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: responsive.sp(40),
            height: responsive.sp(40),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.18),
              shape: BoxShape.circle,
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
                    color: AppColors.textSecondary,
                  ),
                ),
                if (onBeforeAdhkar != null || onAfterAdhkar != null) ...[
                  SizedBox(height: responsive.hp(0.8)),
                  Row(
                    children: [
                      if (onBeforeAdhkar != null)
                        _AdhkarLink(
                          label: AppStrings.beforePrayerDhikr,
                          onTap: onBeforeAdhkar,
                        ),
                      if (onBeforeAdhkar != null && onAfterAdhkar != null)
                        SizedBox(width: responsive.mediumGap),
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

  Color _colorFor(String name) {
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

  Color _statusColor(bool isCurrent, bool isCompleted) {
    if (isCurrent) return AppColors.primary;
    if (isCompleted) return AppColors.success;
    return AppColors.textSecondary;
  }
}

class _AdhkarLink extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _AdhkarLink({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
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
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
