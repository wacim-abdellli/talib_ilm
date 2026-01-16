import 'package:flutter/material.dart';

class NotificationBadge extends StatefulWidget {
  final int count;
  final Widget child;
  final Color badgeColor;

  const NotificationBadge({
    super.key,
    required this.count,
    required this.child,
    this.badgeColor = Colors.red,
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
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.bounceOut,
    );
    _lastCount = widget.count;
    if (widget.count > 0) {
      _controller.value = 1.0; // Show immediately if initial count > 0
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
        // Pulse effect for increment? Or just update text.
        // For this task, we focus on appear/disappear.
        // We can do a quick discrete pulse.
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
    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,
        Positioned(
          top: -4,
          right: -4,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: widget.count == 0
                ? const SizedBox.shrink()
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    decoration: BoxDecoration(
                      color: widget.badgeColor,
                      shape:
                          BoxShape.circle, // Will deform to pill if wide width
                      // But constraints minWidth 18 minHeight 18 implies circle for small text.
                      // If text is large, we need borderRadius pill.
                      borderRadius: widget.count > 9
                          ? BorderRadius.circular(10)
                          : null,
                      border: Border.all(color: Colors.white, width: 2),
                      // if count <= 9, use shape circle. if > 9, box decoration with radius.
                      // Actually BoxDecoration 'shape' handles pure circles.
                      // Let's use conditional logic for shape vs borderRadius.
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      widget.count > 99 ? '99+' : '${widget.count}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        height: 1,
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
