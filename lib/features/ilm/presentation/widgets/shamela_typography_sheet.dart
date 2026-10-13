import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/app.dart';
import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';

enum ShamelaReaderSurface {
  normal,
  parchment,
  night,
}

class ShamelaTypographySheet extends StatefulWidget {
  final double fontSizeDelta;
  final String fontFamily;
  final double lineHeight;
  final ShamelaReaderSurface surface;
  final ValueChanged<double> onFontSizeChanged;
  final ValueChanged<String> onFontFamilyChanged;
  final ValueChanged<double> onLineHeightChanged;
  final ValueChanged<ShamelaReaderSurface> onSurfaceChanged;

  const ShamelaTypographySheet({
    super.key,
    required this.fontSizeDelta,
    required this.fontFamily,
    required this.lineHeight,
    required this.surface,
    required this.onFontSizeChanged,
    required this.onFontFamilyChanged,
    required this.onLineHeightChanged,
    required this.onSurfaceChanged,
  });

  @override
  State<ShamelaTypographySheet> createState() => _ShamelaTypographySheetState();
}

class _ShamelaTypographySheetState extends State<ShamelaTypographySheet> {
  late double _fontSizeDelta;
  late String _fontFamily;
  late double _lineHeight;
  late ShamelaReaderSurface _surface;

  @override
  void initState() {
    super.initState();
    _fontSizeDelta = widget.fontSizeDelta;
    _fontFamily = widget.fontFamily;
    _lineHeight = widget.lineHeight;
    _surface = widget.surface;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: const EdgeInsetsDirectional.all(AppSpace.lg),
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
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsetsDirectional.only(bottom: AppSpace.md),
                decoration: BoxDecoration(
                  color: palette.border,
                  borderRadius: AppRadius.pillRadius,
                ),
              ),
            ),
            Row(
              children: [
                Icon(Icons.format_size_rounded, color: palette.gold, size: AppIcon.md),
                const SizedBox(width: AppSpace.sm),
                Text(
                  'خيارات القراءة والخط',
                  style: textTheme.titleSmall.copyWith(
                    color: palette.text,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.lg),

            // ── Reading Surface Mode ──
            Text('بيئة القراءة', style: textTheme.body.copyWith(color: palette.text)),
            const SizedBox(height: AppSpace.xs),
            Row(
              children: [
                Expanded(
                  child: _buildSurfaceOption(
                    ShamelaReaderSurface.normal,
                    'الافتراضي',
                    palette.surface,
                    palette.text,
                    palette,
                    textTheme,
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: _buildSurfaceOption(
                    ShamelaReaderSurface.parchment,
                    'ورق الشاموا',
                    palette.goldSoft,
                    palette.onGold,
                    palette,
                    textTheme,
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: _buildSurfaceOption(
                    ShamelaReaderSurface.night,
                    'داكن هادئ',
                    palette.brandDark,
                    palette.surfaceRaised,
                    palette,
                    textTheme,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.md),

            // ── Font Size Controls ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('حجم الخط', style: textTheme.body.copyWith(color: palette.text)),
                Row(
                  children: [
                    IconButton(
                      onPressed: _fontSizeDelta > -2.0
                          ? () {
                              HapticFeedback.selectionClick();
                              setState(() => _fontSizeDelta -= 1.0);
                              widget.onFontSizeChanged(_fontSizeDelta);
                            }
                          : null,
                      tooltip: 'تصغير الخط',
                      icon: Icon(Icons.remove_circle_outline_rounded, color: palette.gold),
                    ),
                    Text(
                      '${18 + _fontSizeDelta.toInt()} نقطة',
                      style: textTheme.bodySmall.copyWith(
                        color: palette.text,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: _fontSizeDelta < 10.0
                          ? () {
                              HapticFeedback.selectionClick();
                              setState(() => _fontSizeDelta += 1.0);
                              widget.onFontSizeChanged(_fontSizeDelta);
                            }
                          : null,
                      tooltip: 'تكبير الخط',
                      icon: Icon(Icons.add_circle_outline_rounded, color: palette.gold),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpace.sm),

            // ── Font Family ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('نوع الخط', style: textTheme.body.copyWith(color: palette.text)),
                Row(
                  children: [
                    _buildFontOption('Amiri', 'الأميري (نسخ)', palette, textTheme),
                    const SizedBox(width: AppSpace.sm),
                    _buildFontOption('Cairo', 'القاهرة (رقعي)', palette, textTheme),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpace.sm),

            // ── Line Height ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('تباعد الأسطر', style: textTheme.body.copyWith(color: palette.text)),
                Row(
                  children: [
                    _buildLineOption(1.6, 'مضغوط', palette, textTheme),
                    const SizedBox(width: AppSpace.xs),
                    _buildLineOption(1.85, 'مريح', palette, textTheme),
                    const SizedBox(width: AppSpace.xs),
                    _buildLineOption(2.1, 'موسع', palette, textTheme),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSurfaceOption(
    ShamelaReaderSurface surface,
    String label,
    Color bg,
    Color fg,
    AppPalette palette,
    AppTextTheme textTheme,
  ) {
    final isSelected = _surface == surface;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadius.smRadius,
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _surface = surface);
          widget.onSurfaceChanged(surface);
          if (surface == ShamelaReaderSurface.night) {
            themeService.setThemeMode(ThemeMode.dark);
          } else if (surface == ShamelaReaderSurface.normal) {
            themeService.setThemeMode(ThemeMode.light);
          }
        },
        child: Container(
          padding: const EdgeInsetsDirectional.symmetric(
            vertical: AppSpace.sm,
            horizontal: AppSpace.xs,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: AppRadius.smRadius,
            border: Border.all(
              color: isSelected ? palette.gold : palette.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ب',
                style: textTheme.titleSmall.copyWith(
                  fontFamily: textTheme.sacred.fontFamily,
                  fontWeight: FontWeight.bold,
                  color: fg,
                ),
              ),
              const SizedBox(height: AppSpace.xxs),
              Text(
                label,
                style: textTheme.caption.copyWith(
                  color: fg,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFontOption(
    String family,
    String label,
    AppPalette palette,
    AppTextTheme textTheme,
  ) {
    final isSelected = _fontFamily == family;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadius.smRadius,
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _fontFamily = family);
          widget.onFontFamilyChanged(family);
        },
        child: Container(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpace.md,
            vertical: AppSpace.xs,
          ),
          decoration: BoxDecoration(
            color: isSelected ? palette.gold : palette.surfaceMuted,
            borderRadius: AppRadius.smRadius,
            border: Border.all(color: isSelected ? palette.gold : palette.border),
          ),
          child: Text(
            label,
            style: textTheme.caption.copyWith(
              color: isSelected ? palette.brandDark : palette.text,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLineOption(
    double height,
    String label,
    AppPalette palette,
    AppTextTheme textTheme,
  ) {
    final isSelected = _lineHeight == height;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadius.smRadius,
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _lineHeight = height);
          widget.onLineHeightChanged(height);
        },
        child: Container(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpace.sm,
            vertical: AppSpace.xs,
          ),
          decoration: BoxDecoration(
            color: isSelected ? palette.gold : palette.surfaceMuted,
            borderRadius: AppRadius.smRadius,
            border: Border.all(color: isSelected ? palette.gold : palette.border),
          ),
          child: Text(
            label,
            style: textTheme.caption.copyWith(
              color: isSelected ? palette.brandDark : palette.text,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
