import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon: 80 size, grey
            Icon(icon, size: 80, color: const Color(0xFFB8B8B8)),

            const SizedBox(height: 16),

            // Title: 20sp semi-bold, dark grey
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B6B6B),
              ),
            ),

            const SizedBox(height: 8),

            // Subtitle: 15sp, light grey, centered
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFFB8B8B8),
                  height: 1.5,
                ),
              ),
            ),

            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              // Action button: OutlinedButton, teal border/text
              SizedBox(
                height: 44,
                child: OutlinedButton(
                  onPressed: onAction,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0D9488),
                    side: const BorderSide(color: Color(0xFF0D9488)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                  ),
                  child: Text(
                    actionLabel!,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
