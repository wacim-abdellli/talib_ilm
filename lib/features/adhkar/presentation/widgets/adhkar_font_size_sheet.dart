import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../shared/widgets/app_sheet.dart';

/// Opens the modal sheet for Adhkar font size and typography controls.
Future<void> showAdhkarFontSizeSheet({
  required BuildContext context,
  required double currentScale,
  required bool showTashkeel,
  required ValueChanged<double> onFontScaleChanged,
  required ValueChanged<bool> onToggleTashkeel,
  required VoidCallback onReset,
}) {
  return AppSheet.show<void>(
    context: context,
    builder: (context) {
      return AdhkarFontSizeSheet(
        currentScale: currentScale,
        showTashkeel: showTashkeel,
        onFontScaleChanged: onFontScaleChanged,
        onToggleTashkeel: onToggleTashkeel,
        onReset: onReset,
      );
    },
  );
}

/// Rich, interactive typography customization sheet for Adhkar sessions.
class AdhkarFontSizeSheet extends StatefulWidget {
  final double currentScale;
  final bool showTashkeel;
  final ValueChanged<double> onFontScaleChanged;
  final ValueChanged<bool> onToggleTashkeel;
  final VoidCallback onReset;

  const AdhkarFontSizeSheet({
    super.key,
    required this.currentScale,
    required this.showTashkeel,
    required this.onFontScaleChanged,
    required this.onToggleTashkeel,
    required this.onReset,
  });

  @override
  State<AdhkarFontSizeSheet> createState() => _AdhkarFontSizeSheetState();
}

class _AdhkarFontSizeSheetState extends State<AdhkarFontSizeSheet> {
  static const double _minScale = 0.85;
  static const double _maxScale = 1.60;
  static const double _step = 0.15;

  static const List<double> _presets = [0.85, 1.0, 1.15, 1.30, 1.45, 1.60];
  static final RegExp _tashkeelRegex = RegExp(r'[\u064B-\u0652\u0670\u0640]');

  late double _scale;
  late bool _showTashkeel;

  @override
  void initState() {
    super.initState();
    _scale = widget.currentScale;
    _showTashkeel = widget.showTashkeel;
  }

  void _applyScale(double newScale) {
    final clamped = (newScale.clamp(_minScale, _maxScale) * 100).round() / 100.0;
    HapticFeedback.selectionClick();
    setState(() => _scale = clamped);
    widget.onFontScaleChanged(clamped);
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
    setState(() => _scale = 1.0);
    widget.onReset();
  }

  void _toggleTashkeel() {
    HapticFeedback.selectionClick();
    final next = !_showTashkeel;
    setState(() => _showTashkeel = next);
    widget.onToggleTashkeel(next);
  }

  String _cleanTashkeel(String text) {
    if (_showTashkeel) return text;
    return text.replaceAll(_tashkeelRegex, '');
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    final previewArabic = _cleanTashkeel('سُبْحَانَ اللَّهِ وَبِحَمْدِهِ ، سُبْحَانَ اللَّهِ الْعَظِيمِ');
    final percentLabel = '${(_scale * 100).round()}%';

    return AppSheet(
      titleText: 'حجم الخط وتنسيق النص',
      icon: Icons.format_size_rounded,
      padding: EdgeInsets.zero,
      child: SingleChildScrollView(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpace.xl,
          vertical: AppSpace.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── 1. Stepper Bar: Minimize, Percentage Badge, Maximize ──────
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
                  // Minimize button (-)
                  Tooltip(
                    message: 'تصغير الخط (-)',
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _scale > _minScale + 0.01 ? _decrease : null,
                        borderRadius: AppRadius.mdRadius,
                        child: Container(
                          width: 48,
                          height: 48,
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
                                : palette.textMuted.withValues(alpha: 0.35),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Center percentage indicator and Reset button
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        percentLabel,
                        style: textTheme.title.copyWith(
                          color: palette.gold,
                          fontWeight: FontWeight.bold,
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

                  // Maximize button (+)
                  Tooltip(
                    message: 'تكبير الخط (+)',
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _scale < _maxScale - 0.01 ? _increase : null,
                        borderRadius: AppRadius.mdRadius,
                        child: Container(
                          width: 48,
                          height: 48,
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
                                : palette.textMuted.withValues(alpha: 0.35),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpace.md),

            // ── 2. Preset Quick-Select Chips ─────────────────────────────
            Wrap(
              spacing: AppSpace.xs,
              runSpacing: AppSpace.xs,
              alignment: WrapAlignment.center,
              children: _presets.map((preset) {
                final isSelected = (_scale - preset).abs() < 0.05;
                final label = '${(preset * 100).round()}%';

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _applyScale(preset),
                    borderRadius: AppRadius.pillRadius,
                    child: Container(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: AppSpace.md,
                        vertical: AppSpace.sm,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? palette.gold : palette.surfaceMuted,
                        borderRadius: AppRadius.pillRadius,
                        border: Border.all(
                          color: isSelected ? palette.gold : palette.border,
                        ),
                      ),
                      child: Text(
                        label,
                        style: (isSelected ? textTheme.captionHeavy : textTheme.captionBold).copyWith(
                          color: isSelected ? palette.onGold : palette.text,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: AppSpace.md),

            // ── 3. Tashkeel Toggle Switch Row ────────────────────────────
            Container(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpace.md,
                vertical: AppSpace.sm,
              ),
              decoration: BoxDecoration(
                color: palette.surfaceMuted,
                borderRadius: AppRadius.mdRadius,
                border: Border.all(color: palette.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.text_fields_rounded,
                        size: AppIcon.sm,
                        color: palette.gold,
                      ),
                      const SizedBox(width: AppSpace.sm),
                      Text(
                        'عرض التشكيل والحركات',
                        style: textTheme.bodyBold.copyWith(
                          color: palette.text,
                        ),
                      ),
                    ],
                  ),
                  Switch.adaptive(
                    value: _showTashkeel,
                    activeTrackColor: palette.gold,
                    activeThumbColor: palette.gold,
                    onChanged: (val) => _toggleTashkeel(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpace.md),

            // ── 4. Live Scholarly Preview Card ───────────────────────────
            Container(
              padding: const EdgeInsetsDirectional.all(AppSpace.md),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: AppRadius.lgRadius,
                border: Border.all(
                  color: palette.gold.withValues(alpha: 0.35),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      'معاينة حية لبطاقة الذكر:',
                      style: textTheme.caption.copyWith(
                        color: palette.textMuted,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpace.sm),

                  // Dhikr Main Text
                  Text(
                    previewArabic,
                    textAlign: TextAlign.center,
                    textScaler: TextScaler.linear(_scale),
                    style: textTheme.sacredLarge.copyWith(
                      color: palette.text,
                      fontWeight: FontWeight.bold,
                      height: 2.2,
                    ),
                  ),

                  const SizedBox(height: AppSpace.sm),

                  // Virtue Sample
                  Container(
                    padding: const EdgeInsetsDirectional.all(AppSpace.xs),
                    decoration: BoxDecoration(
                      color: palette.goldSoft,
                      borderRadius: AppRadius.smRadius,
                    ),
                    child: Text(
                      'كَلِمَتَانِ خَفِيفَتَانِ عَلَى اللِّسَانِ، ثَقِيلَتَانِ فِي الْمِيزَانِ',
                      textAlign: TextAlign.center,
                      textScaler: TextScaler.linear(_scale.clamp(0.85, 1.5)),
                      style: textTheme.captionBold.copyWith(
                        color: palette.gold,
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpace.xs),

                  // Source Sample
                  Text(
                    'رواه البخاري ومسلم',
                    textAlign: TextAlign.center,
                    textScaler: TextScaler.linear(_scale.clamp(0.85, 1.4)),
                    style: textTheme.captionBold.copyWith(
                      color: palette.textMuted,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpace.lg),

            // ── 5. Close Button ──────────────────────────────────────────
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: palette.gold,
                foregroundColor: palette.onGold,
                padding: const EdgeInsetsDirectional.symmetric(vertical: AppSpace.md),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
                elevation: 0,
              ),
              child: Text(
                'تم الاعتماد',
                style: textTheme.body.copyWith(
                  color: palette.onGold,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
