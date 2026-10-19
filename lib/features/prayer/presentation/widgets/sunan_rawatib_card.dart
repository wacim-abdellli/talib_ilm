import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_progress.dart';

/// Interactive Sunan Rawatib tracker (12 Rak'ahs daily) based on the authentic hadith:
/// «من صلى في يوم وليلة ثنتي عشرة ركعة بني له بيت في الجنة» (صحيح مسلم)
class SunanRawatibCard extends StatefulWidget {
  const SunanRawatibCard({super.key});

  @override
  State<SunanRawatibCard> createState() => _SunanRawatibCardState();
}

class _SunanRawatibCardState extends State<SunanRawatibCard> {
  static const String _prefix = 'rawatib_completed_';

  // State: Fajr (2), Dhuhr Before (4), Dhuhr After (2), Maghrib After (2), Isha After (2)
  bool _fajr = false;
  bool _dhuhrBefore = false;
  bool _dhuhrAfter = false;
  bool _maghrib = false;
  bool _isha = false;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  String get _todayKey {
    final now = DateTime.now();
    return '$_prefix${now.year}_${now.month}_${now.day}';
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final key = _todayKey;
    if (mounted) {
      setState(() {
        _fajr = prefs.getBool('${key}_fajr') ?? false;
        _dhuhrBefore = prefs.getBool('${key}_dhuhr_before') ?? false;
        _dhuhrAfter = prefs.getBool('${key}_dhuhr_after') ?? false;
        _maghrib = prefs.getBool('${key}_maghrib') ?? false;
        _isha = prefs.getBool('${key}_isha') ?? false;
      });
    }
  }

  Future<void> _toggle(String prayer, bool currentVal) async {
    HapticFeedback.lightImpact();
    final prefs = await SharedPreferences.getInstance();
    final key = _todayKey;
    final newVal = !currentVal;
    await prefs.setBool('${key}_$prayer', newVal);

    if (mounted) {
      setState(() {
        switch (prayer) {
          case 'fajr':
            _fajr = newVal;
            break;
          case 'dhuhr_before':
            _dhuhrBefore = newVal;
            break;
          case 'dhuhr_after':
            _dhuhrAfter = newVal;
            break;
          case 'maghrib':
            _maghrib = newVal;
            break;
          case 'isha':
            _isha = newVal;
            break;
        }
      });
    }
  }

  int get _completedRakahs {
    var count = 0;
    if (_fajr) count += 2;
    if (_dhuhrBefore) count += 4;
    if (_dhuhrAfter) count += 2;
    if (_maghrib) count += 2;
    if (_isha) count += 2;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final total = _completedRakahs;
    final progress = (total / 12).clamp(0.0, 1.0);
    final isAllDone = total == 12;

    return AppCard(
      padding: const EdgeInsetsDirectional.all(AppSpace.lg),
      border: Border.all(
        color: isAllDone ? palette.gold : palette.border,
        width: isAllDone ? 1.5 : 1.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header row with Icon, Title, and Rak'ah counter
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
                    isAllDone ? Icons.stars_rounded : Icons.mosque_rounded,
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
                      'السنن الرواتب (12 ركعة)',
                      style: context.text.titleSmall.copyWith(
                        color: palette.text,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '«بُنِيَ لَهُ بَيْتٌ فِي الْجَنَّةِ» — مسلم',
                      style: context.text.caption.copyWith(
                        color: palette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpace.md,
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
                child: Text(
                  '$total / 12',
                  style: context.text.caption.copyWith(
                    color: isAllDone ? palette.gold : palette.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpace.md),

          // Progress bar
          AppProgress(
            progress: progress,
            color: isAllDone ? palette.gold : palette.primary,
          ),

          const SizedBox(height: AppSpace.md),

          // Sunan Interactive Pills
          Wrap(
            spacing: AppSpace.xs,
            runSpacing: AppSpace.xs,
            children: [
              _SunnahPill(
                label: 'الفجر (2)',
                isDone: _fajr,
                onTap: () => _toggle('fajr', _fajr),
              ),
              _SunnahPill(
                label: 'قبل الظهر (4)',
                isDone: _dhuhrBefore,
                onTap: () => _toggle('dhuhr_before', _dhuhrBefore),
              ),
              _SunnahPill(
                label: 'بعد الظهر (2)',
                isDone: _dhuhrAfter,
                onTap: () => _toggle('dhuhr_after', _dhuhrAfter),
              ),
              _SunnahPill(
                label: 'بعد المغرب (2)',
                isDone: _maghrib,
                onTap: () => _toggle('maghrib', _maghrib),
              ),
              _SunnahPill(
                label: 'بعد العشاء (2)',
                isDone: _isha,
                onTap: () => _toggle('isha', _isha),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SunnahPill extends StatelessWidget {
  final String label;
  final bool isDone;
  final VoidCallback onTap;

  const _SunnahPill({
    required this.label,
    required this.isDone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.pillRadius,
        child: AnimatedContainer(
          duration: AppMotion.base,
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpace.sm,
            vertical: AppSpace.xs,
          ),
          decoration: BoxDecoration(
            color: isDone ? palette.primarySoft : palette.surfaceMuted,
            borderRadius: AppRadius.pillRadius,
            border: Border.all(
              color: isDone ? palette.primary : palette.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                size: AppIcon.sm,
                color: isDone ? palette.primary : palette.textSubtle,
              ),
              const SizedBox(width: AppSpace.xs),
              Text(
                label,
                style: context.text.caption.copyWith(
                  color: isDone ? palette.primary : palette.textMuted,
                  fontWeight: isDone ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
