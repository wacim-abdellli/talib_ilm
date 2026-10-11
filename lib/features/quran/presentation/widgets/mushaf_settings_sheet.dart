import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_sheet.dart';
import '../../../../shared/widgets/icon_badge.dart';

enum MushafThemeMode {
  white, // Classic White
  sepia, // Warm Cream / Parchment
  dark, // Twilight AMOLED Dark
}

class MushafSettingsSheet extends StatefulWidget {
  final MushafThemeMode currentTheme;
  final bool isTajweedEnabled;
  final double fontSize;
  final ValueChanged<MushafThemeMode> onThemeChanged;
  final ValueChanged<bool> onTajweedChanged;
  final ValueChanged<double> onFontSizeChanged;

  const MushafSettingsSheet({
    super.key,
    required this.currentTheme,
    required this.isTajweedEnabled,
    required this.fontSize,
    required this.onThemeChanged,
    required this.onTajweedChanged,
    required this.onFontSizeChanged,
  });

  static Future<void> show(
    BuildContext context, {
    required MushafThemeMode currentTheme,
    required bool isTajweedEnabled,
    required double fontSize,
    required ValueChanged<MushafThemeMode> onThemeChanged,
    required ValueChanged<bool> onTajweedChanged,
    required ValueChanged<double> onFontSizeChanged,
  }) {
    return AppSheet.show<void>(
      context: context,
      maxHeightFactor: 0.75,
      builder: (_) => MushafSettingsSheet(
        currentTheme: currentTheme,
        isTajweedEnabled: isTajweedEnabled,
        fontSize: fontSize,
        onThemeChanged: onThemeChanged,
        onTajweedChanged: onTajweedChanged,
        onFontSizeChanged: onFontSizeChanged,
      ),
    );
  }

  @override
  State<MushafSettingsSheet> createState() => _MushafSettingsSheetState();
}

class _MushafSettingsSheetState extends State<MushafSettingsSheet> {
  late MushafThemeMode _theme;
  late bool _tajweed;
  late double _fontSize;

  @override
  void initState() {
    super.initState();
    _theme = widget.currentTheme;
    _tajweed = widget.isTajweedEnabled;
    _fontSize = widget.fontSize;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return Container(
      padding: const EdgeInsetsDirectional.only(
        top: AppSpace.md,
        bottom: AppSpace.md,
      ),
      decoration: BoxDecoration(
        color: palette.surfaceRaised,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: palette.border,
                borderRadius: AppRadius.pillRadius,
              ),
            ),
          ),
          const SizedBox(height: AppSpace.md),

          // Header
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpace.xl),
            child: Row(
              children: [
                const IconBadge(icon: Icons.tune_rounded),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'إعدادات وتخصيص المصحف',
                        style: textTheme.titleSmall.copyWith(
                          color: palette.text,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'تحكم في ألوان المصحف وأحكام التجويد وحجم الخط',
                        style: textTheme.caption.copyWith(
                          color: palette.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                AppIconButton(
                  icon: Icons.close_rounded,
                  tooltip: 'إغلاق',
                  color: palette.textMuted,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpace.sm),
          Divider(height: 1, color: palette.border),

          Flexible(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(AppSpace.xl),
              children: [
                // 1. Reading Theme Selection (matching Screenshot 1)
                Text(
                  'لون صفحة المصحف',
                  style: textTheme.caption.copyWith(
                    color: palette.text,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpace.sm),
                Row(
                  children: [
                    _buildThemeCard(
                      label: 'أبيض ناصع',
                      color: MushafColors.whiteBg,
                      textColor: MushafColors.whiteText,
                      mode: MushafThemeMode.white,
                      palette: palette,
                      textTheme: textTheme,
                    ),
                    const SizedBox(width: AppSpace.sm),
                    _buildThemeCard(
                      label: 'ورقي بيج',
                      color: MushafColors.sepiaBg,
                      textColor: MushafColors.sepiaText,
                      mode: MushafThemeMode.sepia,
                      palette: palette,
                      textTheme: textTheme,
                    ),
                    const SizedBox(width: AppSpace.sm),
                    _buildThemeCard(
                      label: 'ليلي داكن',
                      color: MushafColors.darkBg,
                      textColor: MushafColors.darkText,
                      mode: MushafThemeMode.dark,
                      palette: palette,
                      textTheme: textTheme,
                    ),
                  ],
                ),

                const SizedBox(height: AppSpace.xl),

                // 2. Tajweed Toggle Card
                AppCard(
                  child: Row(
                    children: [
                      Icon(
                        Icons.palette_rounded,
                        color: palette.primary,
                        size: AppIcon.md,
                      ),
                      const SizedBox(width: AppSpace.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'تلوين أحكام التجويد',
                              style: textTheme.body.copyWith(
                                color: palette.text,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'تلوين الغنة، القلقلة، الإخفاء، والمدود بألوان المصحف',
                              style: textTheme.caption.copyWith(
                                color: palette.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: _tajweed,
                        activeColor: palette.primary,
                        onChanged: (val) {
                          HapticFeedback.selectionClick();
                          setState(() => _tajweed = val);
                          widget.onTajweedChanged(val);
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpace.lg),

                // 3. Font Size Slider
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'حجم الخط القرآني',
                            style: textTheme.body.copyWith(
                              color: palette.text,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${_fontSize.round()} sp',
                            style: textTheme.caption.copyWith(
                              color: palette.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpace.xs),
                      Slider.adaptive(
                        value: _fontSize,
                        min: 18.0,
                        max: 32.0,
                        divisions: 7,
                        activeColor: palette.primary,
                        inactiveColor: palette.border,
                        onChanged: (val) {
                          setState(() => _fontSize = val);
                          widget.onFontSizeChanged(val);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeCard({
    required String label,
    required Color color,
    required Color textColor,
    required MushafThemeMode mode,
    required AppPalette palette,
    required AppTextTheme textTheme,
  }) {
    final isSelected = _theme == mode;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _theme = mode);
            widget.onThemeChanged(mode);
          },
          borderRadius: AppRadius.mdRadius,
          child: Container(
            height: 72,
            padding: const EdgeInsets.all(AppSpace.xs),
            decoration: BoxDecoration(
              color: color,
              borderRadius: AppRadius.mdRadius,
              border: Border.all(
                color: isSelected ? palette.primary : palette.border,
                width: isSelected ? 2.5 : 1,
              ),
            ),
            child: Center(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: textTheme.caption.copyWith(
                  color: textColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
