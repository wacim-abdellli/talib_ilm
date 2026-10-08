import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/theme_colors.dart';

/// QuickActionButton - INVITATION-DRIVEN
///
/// UX Philosophy:
/// - From access to invitation
/// - One action per day gets contextual emphasis
/// - Others remain calm
/// - Highlight relevance, not categories
class QuickActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final double? width;
  final bool isEmphasized;
  final Color? accentColor; // New: Custom accent color

  const QuickActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.width,
    this.isEmphasized = false,
    this.accentColor,
  });

  @override
  State<QuickActionButton> createState() => _QuickActionButtonState();
}

class _QuickActionButtonState extends State<QuickActionButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final effectiveAccent = widget.accentColor ?? context.primaryColor;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: Container(
          width: widget.width ?? 80,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? effectiveAccent.withValues(alpha: 0.2)
                  : context.outlineVariantColor,
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: effectiveAccent.withValues(
                    alpha: isDark ? 0.18 : 0.12,
                  ),
                  border: Border.all(
                    color: effectiveAccent.withValues(alpha: 0.25),
                    width: 1,
                  ),
                ),
                child: Icon(widget.icon, size: 22, color: effectiveAccent),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.textPrimaryColor,
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
