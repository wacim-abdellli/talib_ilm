import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../core/services/fasting_reminder_service.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_progress.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import 'white_day_tile.dart';

/// Interactive Sunnah Fasting & White Days (Ayyam al-Bid: 13, 14, 15) Tracker & Reminder.
/// Based on the authentic Prophetic Hadith:
/// «صيام ثلاثة أيام من كل شهر صيام الدهر، وأيام البيض: صبيحة ثلاث عشرة وأربع عشرة وخمس عشرة» (النسائي)
class SunnahFastingCard extends StatefulWidget {
  const SunnahFastingCard({super.key});

  @override
  State<SunnahFastingCard> createState() => _SunnahFastingCardState();
}

class _SunnahFastingCardState extends State<SunnahFastingCard> {
  final FastingReminderService _service = FastingReminderService();

  late WhiteDaysInfo _whiteDaysInfo;
  late NextSunnahFastInfo _sunnahFastInfo;

  bool _day13Done = false;
  bool _day14Done = false;
  bool _day15Done = false;
  bool _reminderEnabled = true;
  bool _isExpandedHadith = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final now = DateTime.now();
    final info = FastingReminderService.getWhiteDaysInfo(now);
    final fastInfo = FastingReminderService.getNextSunnahFast(now);

    final d13 = await FastingReminderService.isDayCompleted(info.hijriYear, info.hijriMonth, 13);
    final d14 = await FastingReminderService.isDayCompleted(info.hijriYear, info.hijriMonth, 14);
    final d15 = await FastingReminderService.isDayCompleted(info.hijriYear, info.hijriMonth, 15);
    final rem = await _service.isReminderEnabled();

    if (mounted) {
      setState(() {
        _whiteDaysInfo = info;
        _sunnahFastInfo = fastInfo;
        _day13Done = d13;
        _day14Done = d14;
        _day15Done = d15;
        _reminderEnabled = rem;
      });
    }
  }

  Future<void> _toggleDay(int day, bool currentVal) async {
    HapticFeedback.lightImpact();
    final newVal = await FastingReminderService.toggleDayCompleted(
      _whiteDaysInfo.hijriYear,
      _whiteDaysInfo.hijriMonth,
      day,
      currentVal,
    );

    if (mounted) {
      setState(() {
        if (day == 13) _day13Done = newVal;
        if (day == 14) _day14Done = newVal;
        if (day == 15) _day15Done = newVal;
      });
    }
  }

  Future<void> _toggleReminder() async {
    HapticFeedback.mediumImpact();
    final nextState = !_reminderEnabled;
    setState(() => _reminderEnabled = nextState);
    await _service.setReminderEnabled(nextState);

    if (mounted) {
      AppSnackbar.show(
        context,
        message: nextState
            ? 'تم تفعيل التذكير بصيام السنن والأيام البيض'
            : 'تم إيقاف تذكير صيام السنن',
        type: nextState ? AppSnackbarType.success : AppSnackbarType.info,
      );
    }
  }
  int get _completedCount {
    var count = 0;
    if (_day13Done) count++;
    if (_day14Done) count++;
    if (_day15Done) count++;
    return count;
  }

  static const _easternToWesternDigits = {
    '٠': '0',
    '١': '1',
    '٢': '2',
    '٣': '3',
    '٤': '4',
    '٥': '5',
    '٦': '6',
    '٧': '7',
    '٨': '8',
    '٩': '9',
  };

  static String _toArabicNumerals(String input) {
    var result = input;
    _easternToWesternDigits.forEach((eastern, western) {
      result = result.replaceAll(eastern, western);
    });
    return result;
  }

  String _formatGregorian(DateTime date) {
    try {
      final dayName = DateFormat('EEEE', 'ar').format(date);
      final monthName = DateFormat('MMMM', 'ar').format(date);
      return _toArabicNumerals('$dayName ${date.day} $monthName');
    } catch (_) {
      return '${date.day}/${date.month}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final total = _completedCount;
    final progress = (total / 3).clamp(0.0, 1.0);
    final isAllDone = total == 3;
    final now = DateTime.now();

    // In Ramadan, show special obligatory fasting card
    if (_whiteDaysInfo.isRamadan) {
      return _buildRamadanCard(context);
    }

    return AppCard(
      padding: const EdgeInsetsDirectional.all(AppSpace.lg),
      border: Border.all(
        color: isAllDone ? palette.gold : palette.border,
        width: isAllDone ? 1.5 : 1.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header: Icon + Title + Counter & Reminder Bell ──
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isAllDone ? palette.goldSoft : palette.surfaceMuted,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isAllDone
                        ? palette.gold.withValues(alpha: 0.4)
                        : palette.border,
                  ),
                ),
                child: Center(
                  child: Icon(
                    isAllDone
                        ? Icons.auto_awesome_rounded
                        : Icons.brightness_medium_rounded,
                    size: AppIcon.sm,
                    color: isAllDone ? palette.gold : palette.primary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'صيام السنن والأيام البيض',
                      style: context.text.titleSmall.copyWith(
                        color: palette.text,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpace.xs),
                    Text(
                      'شهر ${_whiteDaysInfo.monthName} (13 · 14 · 15)',
                      style: context.text.caption.copyWith(
                        color: palette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              // Counter chip
              Container(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpace.sm,
                  vertical: AppSpace.xs,
                ),
                decoration: BoxDecoration(
                  color: isAllDone ? palette.goldSoft : palette.surfaceMuted,
                  borderRadius: AppRadius.pillRadius,
                  border: Border.all(
                    color: isAllDone
                        ? palette.gold.withValues(alpha: 0.4)
                        : palette.border,
                  ),
                ),
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    '$total / 3',
                    style: context.text.captionHeavy.copyWith(
                      color: isAllDone ? palette.gold : palette.text,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpace.xs),
              // Reminder Bell Toggle (min 48dp tap target)
              Semantics(
                label: _reminderEnabled
                    ? 'إيقاف تذكير صيام السنن'
                    : 'تفعيل تذكير صيام السنن',
                button: true,
                child: Tooltip(
                  message: _reminderEnabled
                      ? 'تذكير ليلة الصيام: مفعل'
                      : 'تفعيل تذكير ليلة الصيام',
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _toggleReminder,
                      borderRadius: AppRadius.pillRadius,
                      child: Container(
                        width: AppSize.tap,
                        height: AppSize.tap,
                        alignment: AlignmentDirectional.center,
                        child: Icon(
                          _reminderEnabled
                              ? Icons.notifications_active_rounded
                              : Icons.notifications_none_rounded,
                          size: AppIcon.sm,
                          color: _reminderEnabled
                              ? palette.gold
                              : palette.textSubtle,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpace.md),

          // ── Progress Bar ──
          AppProgress(
            progress: progress,
            color: isAllDone ? palette.gold : palette.primary,
          ),

          const SizedBox(height: AppSpace.md),

          // ── Tashreeq Prohibitive Notice for 13 Dhu al-Hijjah ──
          if (_whiteDaysInfo.isDhuAlHijjah) ...[
            Container(
              padding: const EdgeInsetsDirectional.all(AppSpace.sm),
              decoration: BoxDecoration(
                color: palette.surfaceMuted,
                borderRadius: AppRadius.mdRadius,
                border: Border.all(color: palette.gold.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: AppIcon.sm,
                    color: palette.gold,
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: Text(
                      '13 ذو الحجة من أيام التشريق يحرم صيامه، فيُستحب صيام 14 و15 ويوم آخر بدلاً عنه.',
                      style: context.text.caption.copyWith(
                        color: palette.text,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.md),
          ],

          // ── White Days 13, 14, 15 Cards ──
          Row(
            children: [
              Expanded(
                child: WhiteDayTile(
                  hijriDay: 13,
                  gregorianDate: _whiteDaysInfo.day13,
                  dateStr: _formatGregorian(_whiteDaysInfo.day13),
                  isToday: _whiteDaysInfo.getWhiteDayNumber(now) == 13,
                  isDone: _day13Done,
                  isForbidden: _whiteDaysInfo.isDhuAlHijjah,
                  onTap: () => _toggleDay(13, _day13Done),
                ),
              ),
              const SizedBox(width: AppSpace.xs),
              Expanded(
                child: WhiteDayTile(
                  hijriDay: 14,
                  gregorianDate: _whiteDaysInfo.day14,
                  dateStr: _formatGregorian(_whiteDaysInfo.day14),
                  isToday: _whiteDaysInfo.getWhiteDayNumber(now) == 14,
                  isDone: _day14Done,
                  isForbidden: false,
                  onTap: () => _toggleDay(14, _day14Done),
                ),
              ),
              const SizedBox(width: AppSpace.xs),
              Expanded(
                child: WhiteDayTile(
                  hijriDay: 15,
                  gregorianDate: _whiteDaysInfo.day15,
                  dateStr: _formatGregorian(_whiteDaysInfo.day15),
                  isToday: _whiteDaysInfo.getWhiteDayNumber(now) == 15,
                  isDone: _day15Done,
                  isForbidden: false,
                  onTap: () => _toggleDay(15, _day15Done),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpace.md),

          // ── Monday & Thursday Indicator Strip ──
          Container(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpace.md,
              vertical: AppSpace.sm,
            ),
            decoration: BoxDecoration(
              color: _sunnahFastInfo.isTodaySunnah
                  ? palette.goldSoft
                  : palette.surfaceMuted,
              borderRadius: AppRadius.mdRadius,
              border: Border.all(
                color: _sunnahFastInfo.isTodaySunnah
                    ? palette.gold.withValues(alpha: 0.4)
                    : palette.border,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _sunnahFastInfo.isTodaySunnah
                      ? Icons.check_circle_rounded
                      : Icons.calendar_today_rounded,
                  size: AppIcon.sm,
                  color: _sunnahFastInfo.isTodaySunnah
                      ? palette.gold
                      : palette.primary,
                ),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: Text(
                    _sunnahFastInfo.isTodaySunnah
                        ? 'اليوم ${_sunnahFastInfo.todayName}: صيام مسنون — «تُعرَض الأعمالُ يومَ الاثنين والخميس»'
                        : _sunnahFastInfo.isTomorrowSunnah
                            ? 'غداً ${_sunnahFastInfo.nextDayName}: صيام مسنون — يُستحب تبييت النية'
                            : 'صيام السنن القادم: ${_sunnahFastInfo.nextDayName} (بعد ${_sunnahFastInfo.daysToNext} أيام)',
                    style: (_sunnahFastInfo.isTodaySunnah
                            ? context.text.captionHeavy
                            : context.text.caption)
                        .copyWith(
                      color: _sunnahFastInfo.isTodaySunnah
                          ? palette.gold
                          : palette.text,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpace.sm),

          // ── Expandable Prophetic Hadith ──
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => _isExpandedHadith = !_isExpandedHadith),
              borderRadius: AppRadius.mdRadius,
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpace.xs,
                  vertical: AppSpace.xs,
                ),
                child: Row(
                  children: [
                    Icon(
                      _isExpandedHadith
                          ? Icons.arrow_drop_up_rounded
                          : Icons.arrow_drop_down_rounded,
                      size: AppIcon.sm,
                      color: palette.gold,
                    ),
                    const SizedBox(width: AppSpace.xs),
                    Text(
                      'فضل صيام الأيام البيض من السنة النبوية',
                      style: context.text.caption.copyWith(
                        color: palette.gold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (_isExpandedHadith) ...[
            const SizedBox(height: AppSpace.xs),
            Container(
              padding: const EdgeInsetsDirectional.all(AppSpace.md),
              decoration: BoxDecoration(
                color: palette.surfaceMuted,
                borderRadius: AppRadius.mdRadius,
                border: Border.all(color: palette.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '«صِيَامُ ثَلاثَةِ أَيَّامٍ مِنْ كُلِّ شَهْرٍ صِيَامُ الدَّهْرِ، وَأَيَّامُ الْبِيضِ: صَبِيحَةُ ثَلاثَ عَشْرَةَ وَأَرْبَعَ عَشْرَةَ وَخَمْسَ عَشْرَةَ»',
                    style: context.text.captionBold.copyWith(
                      color: palette.text,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: AppSpace.xs),
                  Text(
                    'رواه النسائي وصححه الألباني · وسميت بيضاً لاكتمال ضياء القمر فيها ليلاً.',
                    style: context.text.caption.copyWith(
                      color: palette.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRamadanCard(BuildContext context) {
    final palette = context.palette;
    return AppCard(
      padding: const EdgeInsetsDirectional.all(AppSpace.lg),
      border: Border.all(color: palette.gold, width: 1.5),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: palette.goldSoft,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                Icons.nights_stay_rounded,
                size: AppIcon.md,
                color: palette.gold,
              ),
            ),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'شهر رمضان المبارك',
                  style: context.text.titleSmall.copyWith(
                    color: palette.gold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpace.xs),
                Text(
                  'فريضة الصيام قائمة طيلة الشهر المبارك · تقبل الله طاعاتكم',
                  style: context.text.caption.copyWith(
                    color: palette.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
