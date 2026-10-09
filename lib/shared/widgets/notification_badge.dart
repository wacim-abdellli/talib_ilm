import 'package:flutter/material.dart';
import '../../app/theme/app_palette.dart';

class NotificationBadge extends StatefulWidget {
  final int count;
  final Widget child;
  final Color? badgeColor;

  const NotificationBadge({
    super.key,
    required this.count,
    required this.child,
    this.badgeColor,
  });

  @override
  State<NotificationBadge> createState() => _NotificationBadgeState();
}

class _NotificationBadgeState extends State<NotificationBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  int _lastCount = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.base,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.bounceOut,
    );
    _lastCount = widget.count;
    if (widget.count > 0) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(NotificationBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.count != _lastCount) {
      if (widget.count > 0 && _lastCount == 0) {
        _controller.forward(from: 0.0);
      } else if (widget.count == 0 && _lastCount > 0) {
        _controller.reverse();
      } else if (widget.count > _lastCount) {
        _controller.forward(from: 0.5);
      }
      _lastCount = widget.count;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    final effectiveBadgeColor = widget.badgeColor ?? palette.error;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,
        PositionedDirectional(
          top: -4,
          end: -4,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: widget.count == 0
                ? const SizedBox.shrink()
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    decoration: BoxDecoration(
                      color: effectiveBadgeColor,
                      borderRadius: AppRadius.pillRadius,
                      border: Border.all(color: palette.surfaceRaised, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      widget.count > 99 ? '99+' : '${widget.count}',
                      style: textTheme.caption.copyWith(
                        color: palette.onPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
