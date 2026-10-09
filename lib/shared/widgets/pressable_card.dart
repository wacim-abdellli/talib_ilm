import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme/app_palette.dart';
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
    this.borderRadius = const BorderRadius.all(Radius.circular(AppRadius.lg)),
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
    final palette = context.palette;
    final shape = widget.decoration.shape;
    final borderRadius = shape == BoxShape.rectangle
        ? (widget.decoration.borderRadius ?? widget.borderRadius).resolve(
            Directionality.of(context),
          )
        : null;

    final defaultBorder = Border.all(
      color: palette.border,
      width: 1,
    );

    final fillColor = widget.decoration.color ??
        (widget.decoration.gradient == null ? palette.surface : null);

    final effectiveDecoration = BoxDecoration(
      color: fillColor,
      gradient: widget.decoration.gradient,
      image: widget.decoration.image,
      border: widget.decoration.border ?? defaultBorder,
      borderRadius: borderRadius,
      boxShadow: widget.decoration.boxShadow ?? palette.shadow,
      shape: shape,
      backgroundBlendMode: widget.decoration.backgroundBlendMode,
    );

    return PressableScale(
      enabled: widget.onTap != null,
      pressedScale: 0.98,
      duration: AppMotion.fast,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.easeOut,
        decoration: effectiveDecoration,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: borderRadius,
            onHighlightChanged: widget.onTap == null ? null : _setPressed,
            onTap: widget.onTap == null
                ? null
                : () {
                    HapticFeedback.lightImpact();
                    widget.onTap!();
                  },
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: AppSize.buttonH,
              ),
              child: Padding(padding: widget.padding, child: widget.child),
            ),
          ),
        ),
      ),
    );
  }
}
