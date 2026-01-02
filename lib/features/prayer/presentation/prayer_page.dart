import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text.dart';
import '../../../core/services/prayer_schedule_service.dart';
import '../../../core/services/prayer_time_service.dart';
import '../../../core/utils/prayer_countdown.dart';
import '../../adhkar/data/adhkar_models.dart';
import '../../adhkar/presentation/adhkar_session_page.dart';
import '../data/models/prayer_models.dart';
import 'models/prayer_time.dart';
import 'widgets/prayer_header.dart';
import 'widgets/prayer_time_tile.dart';
import 'qibla_page.dart';
import '../../../shared/widgets/app_overflow_menu.dart';

class PrayerPage extends StatefulWidget {
  const PrayerPage({super.key});

  @override
  State<PrayerPage> createState() => _PrayerPageState();
}

class _PrayerPageState extends State<PrayerPage> {
  final PrayerTimeService _prayerTimeService = PrayerTimeService();
  final PrayerScheduleService _prayerScheduleService =
      PrayerScheduleService();
  late final Future<PrayerTimesDay> _prayerFuture;
  PrayerCountdownController? _countdownController;
  PrayerTimesDay? _cachedDay;

  @override
  void initState() {
    super.initState();
    _prayerFuture = _prayerTimeService.getPrayerTimesDay();
    _prayerFuture.then((day) async {
      if (!mounted) return;
      _ensureCountdown(day);
      await _prayerScheduleService.refreshSchedulesIfNeeded(day: day);
    });
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
      appBar: AppBar(
        title: Text('الصلاة', style: AppText.headingXL),
        actions: const [AppOverflowMenu()],
      ),
      body: FutureBuilder<PrayerTimesDay>(
        future: _prayerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData) {
            return const SizedBox.shrink();
          }

          final data = snapshot.data!;
          _ensureCountdown(data);
          final nextName = _findNextPrayerName(data.prayers);
          final currentName = _findCurrentPrayerName(data.prayers, nextName);
          final times = _buildPrayerTimes(data, nextName, currentName);
          final hijriDate = _formatHijriDate(data.date);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              PrayerHeader(
                city: data.city,
                dayLabel: 'اليوم',
                hijriDate: hijriDate,
              ),
              const SizedBox(height: 16),
              _buildCurrentPrayerCard(
                data: data,
                currentName: currentName,
                nextName: nextName,
              ),
              const SizedBox(height: 16),
              ...times.map(
                (item) => PrayerTimeTile(
                  item: item,
                  onBeforeAdhkar: () =>
                      _openAdhkar(context, AdhkarCategory.beforePrayer),
                  onAfterAdhkar: () =>
                      _openAdhkar(context, AdhkarCategory.afterPrayer),
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
    final subtitle = currentName == null ? 'الصلاة القادمة' : 'الصلاة الحالية';

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
    const order = ['الفجر', 'الظهر', 'العصر', 'المغرب', 'العشاء'];
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
    const order = ['الفجر', 'الظهر', 'العصر', 'المغرب', 'العشاء'];
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

  void _openAdhkar(BuildContext context, AdhkarCategory category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdhkarSessionPage(category: category),
      ),
    );
  }

  void _openQibla(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const QiblaPage(),
      ),
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
    final secondary = Theme.of(context).colorScheme.onSurface.withValues(
          alpha: 0.6,
        );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subtitle, style: AppText.caption.copyWith(color: secondary)),
          const SizedBox(height: 8),
          Text(
            title,
            style: AppText.headingXL.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'متبقي: $countdown',
            style: AppText.body.copyWith(color: secondary),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onQiblaTap,
              icon: const Icon(Icons.explore_outlined),
              label: const Text('اتجاه القبلة'),
            ),
          ),
        ],
      ),
    );
  }
}
