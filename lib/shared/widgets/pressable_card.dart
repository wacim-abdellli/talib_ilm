import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_ui.dart';
import '../../app/theme/app_spacing.dart';
import 'pressable_scale.dart';

class PressableCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final BoxDecoration decoration;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;

  const PressableCard({
    super.key,
    required this.child,
    required this.decoration,
    required this.padding,
    this.borderRadius = const BorderRadius.all(
      Radius.circular(AppUi.radiusSMPlus),
    ),
    this.onTap,
  });

  @override
  State<PressableCard> createState() => _PressableCardState();
}

class _PressableCardState extends State<PressableCard> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!mounted || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final shape = widget.decoration.shape;
    final borderRadius = shape == BoxShape.rectangle
        ? (widget.decoration.borderRadius ?? widget.borderRadius)
            .resolve(Directionality.of(context))
        : null;
    final fallbackBorder = Border.all(
      color: const Color(0xFFE5DED0),
      width: AppUi.dividerThickness,
    );
    final baseShadow = [
      BoxShadow(
        color: AppColors.primaryDark.withValues(alpha: 0.12),
        blurRadius: 18,
        offset: const Offset(0, 10),
      ),
    ];
    final pressedShadow = [
      BoxShadow(
        color: AppColors.primaryDark.withValues(alpha: 0.18),
        blurRadius: 24,
        offset: const Offset(0, 12),
      ),
    ];
    final fillColor = widget.decoration.color ??
        (widget.decoration.gradient == null ? AppColors.surface : null);
    final effectiveDecoration = BoxDecoration(
      color: fillColor,
      gradient: widget.decoration.gradient,
      image: widget.decoration.image,
      border: widget.decoration.border ?? fallbackBorder,
      borderRadius: borderRadius,
      boxShadow: widget.decoration.boxShadow ?? (_pressed ? pressedShadow : baseShadow),
      shape: shape,
      backgroundBlendMode: widget.decoration.backgroundBlendMode,
    );
    final rippleColor = AppColors.primary.withValues(alpha: 0.1);

    return PressableScale(
      enabled: widget.onTap != null,
      child: AnimatedContainer(
        duration: AppSpacing.animQuick,
        curve: Curves.easeOut,
        decoration: effectiveDecoration,
        child: Material(
          color: AppColors.clear,
          child: InkWell(
            borderRadius: borderRadius,
            splashColor: rippleColor,
            highlightColor: rippleColor,
            overlayColor: WidgetStatePropertyAll(rippleColor),
            onHighlightChanged: widget.onTap == null ? null : _setPressed,
            onTap: widget.onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: AppUi.buttonMinHeight,
              ),
              child: Padding(
                padding: widget.padding,
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
