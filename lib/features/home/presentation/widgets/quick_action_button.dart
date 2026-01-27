import 'package:flutter/material.dart';

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
    // Theme resolution now handled directly in widget tree with M3 roles

    // Determine colors
    final hasAccent = widget.accentColor != null;

    // Background
    final bgColor = hasAccent
        ? widget.accentColor!.withValues(alpha: 0.12) // Low tint
        : context.surfaceLowest;

    // Border
    final borderColor = hasAccent
        ? widget.accentColor!.withValues(alpha: 0.3)
        : (widget.isEmphasized
              ? context.primaryColor.withValues(alpha: 0.3)
              : context.outlineVariantColor);

    // Foreground
    final fgColor = hasAccent
        ? widget.accentColor!
        : (widget.isEmphasized
              ? context.primaryColor
              : context.textPrimaryColor);

    final labelColor = hasAccent
        ? widget.accentColor!
        : (widget.isEmphasized
              ? context.primaryColor
              : context.textSecondaryColor);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedOpacity(
          opacity: _isPressed ? 0.8 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: Container(
            width: widget.width ?? 80,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: 1.0),
              // No shadow for flat tiles in M3, just surface color diff
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, size: 26, color: fgColor),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 12,
                      color: labelColor,
                      fontFamily: 'Cairo',
                      fontWeight: (widget.isEmphasized || hasAccent)
                          ? FontWeight.w600
                          : FontWeight.w500,
                      height: 1.2,
                    ),
                    maxLines: 2,
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
