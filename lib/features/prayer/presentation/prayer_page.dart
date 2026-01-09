import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import '../../../app/constants/app_strings.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text.dart';
import '../../../app/theme/app_ui.dart';
import '../../../core/services/prayer_schedule_service.dart';
import '../../../core/services/prayer_time_service.dart';
import '../../../core/utils/prayer_countdown.dart';
import '../../../shared/navigation/fade_page_route.dart';
import '../../adhkar/presentation/after_prayer_athkar_page.dart';
import '../../adhkar/presentation/duas_misc_page.dart';
import '../data/models/prayer_models.dart';
import 'models/prayer_time.dart';
import 'widgets/prayer_header.dart';
import 'widgets/prayer_time_tile.dart';
import 'qibla_page.dart';
import 'location_settings_sheet.dart';
import '../../../shared/widgets/primary_app_bar.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../shared/widgets/empty_state.dart';

class PrayerPage extends StatefulWidget {
  const PrayerPage({super.key});

  @override
  State<PrayerPage> createState() => _PrayerPageState();
}

class _PrayerPageState extends State<PrayerPage> {
  final PrayerTimeService _prayerTimeService = PrayerTimeService();
  final PrayerScheduleService _prayerScheduleService =
      PrayerScheduleService();
  late Future<PrayerTimesDay> _prayerFuture;
  PrayerCountdownController? _countdownController;
  PrayerTimesDay? _cachedDay;

  @override
  void initState() {
    super.initState();
    _loadPrayer();
  }

  @override
  void dispose() {
    _countdownController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppDrawer(),
      appBar: UnifiedAppBar(
        title: AppStrings.prayerTitle,
        showMenu: true,
        actions: [
          IconButton(
            tooltip: AppStrings.prayerLocationSettings,
            onPressed: () {
              if (!mounted) return;
              _openLocationSettings(context);
            },
            icon: const Icon(Icons.my_location_outlined),
          ),
        ],
      ),
      body: FutureBuilder<PrayerTimesDay>(
        future: _prayerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData) {
            return EmptyState(
              icon: Icons.access_time,
              title: AppStrings.prayerLoadErrorTitle,
              message: AppStrings.prayerLoadErrorMessage,
              actionLabel: AppStrings.actionRetry,
              onAction: _reloadPrayer,
            );
          }

          final data = snapshot.data!;
          _ensureCountdown(data);
          final nextName = _findNextPrayerName(data.prayers);
          final currentName = _findCurrentPrayerName(data.prayers, nextName);
          final times = _buildPrayerTimes(data, nextName, currentName);
          final hijriDate = _formatHijriDate(data.date);

          return ListView(
            padding: AppUi.screenPadding,
            children: [
              PrayerHeader(
                city: data.city,
                dayLabel: AppStrings.prayerDayLabel,
                hijriDate: hijriDate,
              ),
              const SizedBox(height: AppUi.gapXL),
              _buildCurrentPrayerCard(
                data: data,
                currentName: currentName,
                nextName: nextName,
              ),
              const SizedBox(height: AppUi.gapXL),
              ...times.map(
                (item) => PrayerTimeTile(
                  item: item,
                  onBeforeAdhkar: () => _openDuas(context),
                  onAfterAdhkar: () =>
                      _openAfterPrayer(context, item.name),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCurrentPrayerCard({
    required PrayerTimesDay data,
    required String? currentName,
    required String? nextName,
  }) {
    final controller = _countdownController;
    final label = currentName ?? nextName ?? data.nextPrayer;
    final subtitle =
        currentName == null ? AppStrings.prayerNext : AppStrings.prayerCurrent;

    if (controller == null) {
      final nextTime = data.prayers[data.nextPrayer] ?? DateTime.now();
      final remaining = nextTime.difference(DateTime.now());
      return _CurrentPrayerCard(
        title: label,
        subtitle: subtitle,
        countdown: _formatCountdown(remaining),
        onQiblaTap: () => _openQibla(context),
      );
    }

    return ValueListenableBuilder<PrayerCountdownState>(
      valueListenable: controller.state,
      builder: (context, state, _) {
        return _CurrentPrayerCard(
          title: label,
          subtitle: subtitle,
          countdown: _formatCountdown(state.remaining),
          onQiblaTap: () => _openQibla(context),
        );
      },
    );
  }

  List<PrayerTime> _buildPrayerTimes(
    PrayerTimesDay day,
    String? nextName,
    String? currentName,
  ) {
    const order = AppStrings.prayerOrder;
    return order
        .where(day.prayers.containsKey)
        .map(
          (name) => PrayerTime(
            name: name,
            time: _formatTime(day.prayers[name]!),
            isNext: nextName != null && name == nextName,
            isCurrent: currentName != null && name == currentName,
          ),
        )
        .toList();
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
      return order.lastWhere(
        prayers.containsKey,
        orElse: () => '',
      ).isEmpty
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
    setState(_loadPrayer);
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
    Navigator.push(
      context,
      buildFadeRoute(page: DuasMiscPage()),
    );
  }

  void _openQibla(BuildContext context) {
    Navigator.push(
      context,
      buildFadeRoute(page: const QiblaPage()),
    );
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
}

class _CurrentPrayerCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String countdown;
  final VoidCallback onQiblaTap;

  const _CurrentPrayerCard({
    required this.title,
    required this.subtitle,
    required this.countdown,
    required this.onQiblaTap,
  });

  @override
  Widget build(BuildContext context) {
    const secondary = AppColors.textSecondary;

    return Container(
      padding: AppUi.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppUi.radiusLG),
        boxShadow: AppUi.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subtitle, style: AppText.caption.copyWith(color: secondary)),
          const SizedBox(height: AppUi.gapSM),
          Text(
            title,
            style: AppText.headingXL.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppUi.gapSM),
          Text(
            AppStrings.prayerRemaining(countdown),
            style: AppText.body.copyWith(color: secondary),
          ),
          const SizedBox(height: AppUi.gapMD),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onQiblaTap,
              icon: const Icon(Icons.explore_outlined),
              label: const Text(AppStrings.qiblaTitle),
            ),
          ),
        ],
      ),
    );
  }
}
