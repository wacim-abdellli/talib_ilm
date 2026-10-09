import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/theme_colors.dart';

/// QuickActionButton - Luxury Spiritual Bento Action Tile with Radiant Jewel Badges
class QuickActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final double? width;
  final bool isEmphasized;
  final Color? accentColor;

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
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final effectiveAccent = widget.accentColor ?? context.primaryColor;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          HapticFeedback.lightImpact();
          widget.onTap();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed ? 0.94 : (_isHovered ? 1.03 : 1.0),
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: Container(
            width: widget.width ?? double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            decoration: BoxDecoration(
              color: context.surfaceContainer,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: effectiveAccent.withValues(
                  alpha: isDark ? (_isHovered ? 0.45 : 0.2) : (_isHovered ? 0.4 : 0.15),
                ),
                width: _isHovered ? 1.5 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.35)
                      : effectiveAccent.withValues(alpha: 0.08),
                  blurRadius: _isHovered ? 16 : 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Radiant Jewel Medallion Icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        effectiveAccent,
                        Color.lerp(effectiveAccent, Colors.black, isDark ? 0.22 : 0.14) ?? effectiveAccent,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: isDark ? 0.3 : 0.4),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: effectiveAccent.withValues(alpha: isDark ? 0.45 : 0.3),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    widget.icon,
                    size: 25,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 13,
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
      ),
    );
  }
}
