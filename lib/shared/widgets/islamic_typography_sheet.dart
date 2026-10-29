import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/theme/app_palette.dart';
import 'app_sheet.dart';

/// Modal sheet for custom font size and typography controls in Hadith & Durar sections.
class IslamicTypographySheet extends StatefulWidget {
  static const String hadithPrefKey = 'hadith_reader_font_scale';
  static const String durarPrefKey = 'durar_reader_font_scale';

  final double currentScale;
  final ValueChanged<double> onFontScaleChanged;
  final VoidCallback? onReset;
  final String prefKey;
  final String titleText;
  final String previewText;

  const IslamicTypographySheet({
    super.key,
    required this.currentScale,
    required this.onFontScaleChanged,
    required this.prefKey,
    this.onReset,
    this.titleText = 'حجم الخط وتنسيق القراءة',
    this.previewText = '«إِنَّمَا الأَعْمَالُ بِالنِّيَّاتِ، وَإِنَّمَا لِكُلِّ امْرِئٍ مَا نَوَى»',
  });

  static Future<double> loadSavedScale(String prefKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getDouble(prefKey) ?? 1.0;
    } catch (_) {
      return 1.0;
    }
  }

  static Future<void> saveScale(String prefKey, double scale) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(prefKey, scale);
    } catch (_) {}
  }

  static Future<void> show({
    required BuildContext context,
    required double currentScale,
    required String prefKey,
    required ValueChanged<double> onFontScaleChanged,
    VoidCallback? onReset,
    String? titleText,
    String? previewText,
  }) {
    HapticFeedback.lightImpact();
    return AppSheet.show<void>(
      context: context,
      builder: (ctx) {
        return IslamicTypographySheet(
          currentScale: currentScale,
          prefKey: prefKey,
          onFontScaleChanged: onFontScaleChanged,
          onReset: onReset,
          titleText: titleText ?? 'حجم الخط وتنسيق القراءة',
          previewText: previewText ??
              '«إِنَّمَا الأَعْمَالُ بِالنِّيَّاتِ، وَإِنَّمَا لِكُلِّ امْرِئٍ مَا نَوَى»',
        );
      },
    );
  }

  @override
  State<IslamicTypographySheet> createState() => _IslamicTypographySheetState();
}

class _IslamicTypographySheetState extends State<IslamicTypographySheet> {
  static const double _minScale = 0.85;
  static const double _maxScale = 1.45;
  static const double _step = 0.15;

  static const List<double> _presets = [0.85, 1.0, 1.15, 1.30, 1.45];
  static final Map<double, String> _presetLabels = {
    0.85: 'صغير',
    1.0: 'قياسي',
    1.15: 'متوسط',
    1.30: 'كبير',
    1.45: 'كبير جداً',
  };

  late double _scale;

  @override
  void initState() {
    super.initState();
    _scale = widget.currentScale;
  }

  void _applyScale(double newScale) {
    final clamped = (newScale.clamp(_minScale, _maxScale) * 100).round() / 100.0;
    HapticFeedback.selectionClick();
    setState(() => _scale = clamped);
    widget.onFontScaleChanged(clamped);
    IslamicTypographySheet.saveScale(widget.prefKey, clamped);
  }

  void _increase() {
    if (_scale < _maxScale - 0.01) {
      _applyScale(_scale + _step);
    }
  }

  void _decrease() {
    if (_scale > _minScale + 0.01) {
      _applyScale(_scale - _step);
    }
  }

  void _reset() {
    HapticFeedback.selectionClick();
    _applyScale(1.0);
    widget.onReset?.call();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    final percentLabel = '${(_scale * 100).round()}%';

    return AppSheet(
      titleText: widget.titleText,
      icon: Icons.format_size_rounded,
      padding: EdgeInsets.zero,
      child: SingleChildScrollView(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpace.lg,
          vertical: AppSpace.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Stepper Control Row (- / Percentage / +)
            Container(
              padding: const EdgeInsetsDirectional.all(AppSpace.sm),
              decoration: BoxDecoration(
                color: palette.surfaceMuted,
                borderRadius: AppRadius.lgRadius,
                border: Border.all(color: palette.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Decrease (-)
                  Tooltip(
                    message: 'تصغير الخط (-)',
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _scale > _minScale + 0.01 ? _decrease : null,
                        borderRadius: AppRadius.mdRadius,
                        child: Container(
                          width: AppSize.tap,
                          height: AppSize.tap,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: palette.surface,
                            borderRadius: AppRadius.mdRadius,
                            border: Border.all(color: palette.border),
                          ),
                          child: Icon(
                            Icons.remove_rounded,
                            size: AppIcon.md,
                            color: _scale > _minScale + 0.01
                                ? palette.text
                                : palette.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Center percentage indicator & Reset button
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        percentLabel,
                        style: textTheme.title.copyWith(
                          color: palette.gold,
                          fontWeight: AppFontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpace.xxs),
                      InkWell(
                        onTap: _reset,
                        borderRadius: AppRadius.pillRadius,
                        child: Padding(
                          padding: const EdgeInsetsDirectional.symmetric(
                            horizontal: AppSpace.xs,
                            vertical: AppSpace.xxs,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.refresh_rounded,
                                size: AppIcon.xs,
                                color: palette.textMuted,
                              ),
                              const SizedBox(width: AppSpace.xs),
                              Text(
                                'الافتراضي (100%)',
                                style: textTheme.captionBold.copyWith(
                                  color: palette.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Increase (+)
                  Tooltip(
                    message: 'تكبير الخط (+)',
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _scale < _maxScale - 0.01 ? _increase : null,
                        borderRadius: AppRadius.mdRadius,
                        child: Container(
                          width: AppSize.tap,
                          height: AppSize.tap,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: palette.surface,
                            borderRadius: AppRadius.mdRadius,
                            border: Border.all(color: palette.border),
                          ),
                          child: Icon(
                            Icons.add_rounded,
                            size: AppIcon.md,
                            color: _scale < _maxScale - 0.01
                                ? palette.text
                                : palette.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpace.md),

            // Quick Preset Scale Chips
            Wrap(
              spacing: AppSpace.xs,
              runSpacing: AppSpace.xs,
              alignment: WrapAlignment.center,
              children: _presets.map((preset) {
                final isSelected = (_scale - preset).abs() < 0.05;
                final label = '${(preset * 100).round()}%';
                final desc = _presetLabels[preset] ?? '';

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _applyScale(preset),
                    borderRadius: AppRadius.pillRadius,
                    child: Container(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: AppSpace.md,
                        vertical: AppSpace.xs,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? palette.goldSoft : palette.surfaceMuted,
                        borderRadius: AppRadius.pillRadius,
                        border: Border.all(
                          color: isSelected ? palette.gold : palette.border,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            label,
                            style: textTheme.captionBold.copyWith(
                              color: isSelected ? palette.gold : palette.text,
                              fontWeight: isSelected
                                  ? AppFontWeight.bold
                                  : AppFontWeight.medium,
                            ),
                          ),
                          if (desc.isNotEmpty) ...[
                            const SizedBox(width: AppSpace.xxs),
                            Text(
                              '($desc)',
                              style: textTheme.caption.copyWith(
                                color: isSelected ? palette.gold : palette.textMuted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: AppSpace.lg),

            // Live Text Preview Card
            Container(
              padding: const EdgeInsetsDirectional.all(AppSpace.md),
              decoration: BoxDecoration(
                color: palette.surfaceRaised,
                borderRadius: AppRadius.lgRadius,
                border: Border.all(color: palette.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.visibility_outlined,
                        size: AppIcon.sm,
                        color: palette.gold,
                      ),
                      const SizedBox(width: AppSpace.xs),
                      Text(
                        'معاينة حية للخط:',
                        style: textTheme.label.copyWith(
                          color: palette.gold,
                          fontWeight: AppFontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.sm),
                  Text(
                    widget.previewText,
                    style: textTheme.sacredSmall.copyWith(
                      color: palette.text,
                      height: 1.85,
                    ),
                    textScaler: TextScaler.linear(_scale),
                    textAlign: TextAlign.justify,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
