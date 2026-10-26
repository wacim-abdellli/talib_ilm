import 'package:flutter/material.dart';

import '../../../../app/constants/app_strings.dart';
import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../core/services/adhan_settings_service.dart';
import '../../../../core/services/iqama_timing_policy.dart';

/// Personal mosque interval controls. These are user-entered estimates, not
/// official or automatically sourced congregation schedules.
class IqamaIntervalSettings extends StatelessWidget {
  final AdhanSettings settings;
  final ValueChanged<AdhanSettings> onSettingsChanged;

  const IqamaIntervalSettings({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الفاصل من الأذان إلى الإقامة حسب مسجدك',
          style: textTheme.bodyBold.copyWith(color: palette.text),
        ),
        const SizedBox(height: AppSpace.xs),
        Text(
          'هذه إعدادات شخصية تقديرية وليست جدولاً رسمياً. اضبطها وفق مسجدك المحلي؛ والجمعة لها فاصل مستقل.',
          style: textTheme.caption.copyWith(color: palette.textMuted),
        ),
        const SizedBox(height: AppSpace.sm),
        for (final entry in [
          (AppStrings.prayerFajr, AppStrings.prayerFajr, false),
          (AppStrings.prayerDhuhr, AppStrings.prayerDhuhr, false),
          (AppStrings.prayerAsr, AppStrings.prayerAsr, false),
          (AppStrings.prayerMaghrib, AppStrings.prayerMaghrib, false),
          (AppStrings.prayerIsha, AppStrings.prayerIsha, false),
          ('الجمعة', AppStrings.prayerDhuhr, true),
        ])
          _IqamaOffsetRow(
            label: entry.$1,
            prayerName: entry.$2,
            isJumua: entry.$3,
            settings: settings,
            onSettingsChanged: onSettingsChanged,
          ),
      ],
    );
  }
}

class _IqamaOffsetRow extends StatelessWidget {
  final String label;
  final String prayerName;
  final bool isJumua;
  final AdhanSettings settings;
  final ValueChanged<AdhanSettings> onSettingsChanged;

  const _IqamaOffsetRow({
    required this.label,
    required this.prayerName,
    required this.isJumua,
    required this.settings,
    required this.onSettingsChanged,
  });

  @override
  Widget build(BuildContext context) {
    final offsets = settings.iqamaMinutesAfterAdhan;
    final minutes = IqamaTimingPolicy.minutesAfterAdhan(
      prayerName,
      isJumua: isJumua,
      configuredMinutes: offsets,
    );
    final key = isJumua ? IqamaTimingPolicy.jumuaKey : prayerName;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSize.tap),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: context.text.body.copyWith(color: context.palette.text),
            ),
          ),
          Semantics(
            label: 'الفاصل بين الأذان والإقامة لصلاة $label',
            value: '$minutes دقيقة',
            child: DropdownButton<int>(
              value: minutes,
              underline: const SizedBox.shrink(),
              items: [
                for (var value = 0; value <= 180; value++)
                  DropdownMenuItem<int>(
                    value: value,
                    child: Text('$value دقيقة'),
                  ),
              ],
              onChanged: (value) {
                if (value == null) return;
                final updated = Map<String, int>.of(offsets)..[key] = value;
                onSettingsChanged(
                  settings.copyWith(iqamaMinutesAfterAdhan: updated),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
