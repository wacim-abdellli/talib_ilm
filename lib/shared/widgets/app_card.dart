import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme/app_palette.dart';

class AppCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Border? border;
  final BorderRadius? borderRadius;
  final bool enableFeedback;

  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpace.lg),
    this.color,
    this.border,
    this.borderRadius,
    this.enableFeedback = true,
  });

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _pressed = false;

  void _onTapDown(TapDownDetails _) {
    if (widget.onTap != null) {
      setState(() => _pressed = true);
    }
  }

  void _onTapUp(TapUpDetails _) {
    if (_pressed) {
      setState(() => _pressed = false);
    }
  }

  void _onTapCancel() {
    if (_pressed) {
      setState(() => _pressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final r = widget.borderRadius ?? AppRadius.lgRadius;
    final effectiveBorder = widget.border ?? Border.all(color: palette.border, width: 1);
    final effectiveColor = widget.color ?? palette.surface;
    final isTappable = widget.onTap != null;

    final card = Container(
      decoration: BoxDecoration(
        color: effectiveColor,
        borderRadius: r,
        border: effectiveBorder,
        boxShadow: palette.shadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: isTappable
            ? InkWell(
                borderRadius: r,
                onTapDown: _onTapDown,
                onTapUp: _onTapUp,
                onTapCancel: _onTapCancel,
                onTap: () {
                  if (widget.enableFeedback) {
                    HapticFeedback.lightImpact();
                  }
                  widget.onTap!();
                },
                child: Padding(
                  padding: widget.padding,
                  child: widget.child,
                ),
              )
            : Padding(
                padding: widget.padding,
                child: widget.child,
              ),
      ),
    );

    if (isTappable) {
      return AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: AppMotion.fast,
        curve: AppMotion.easeOut,
        child: card,
      );
    }

    return card;
  }
}
