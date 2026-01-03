import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text.dart';
import '../../../../shared/widgets/pressable_card.dart';

class SharhCard extends StatelessWidget {
  final String title;
  final String scholar;
  final bool recommended;
  final bool isLastRead;
  final String? difficulty;
  final VoidCallback onTap;

  const SharhCard({
    super.key,
    required this.title,
    required this.scholar,
    required this.onTap,
    this.recommended = false,
    this.isLastRead = false,
    this.difficulty,
  });

  @override
  Widget build(BuildContext context) {
    final badge = _badgeText();
    final background = AppColors.surface;

    return PressableCard(
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      borderRadius: BorderRadius.circular(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppText.heading),
          const SizedBox(height: 4),
          Text(scholar, style: AppText.bodyMuted),
          if (badge != null || difficulty != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (badge != null) _Badge(text: badge),
                if (badge != null && difficulty != null)
                  const SizedBox(width: 8),
                if (difficulty != null)
                  _Badge(
                    text: difficulty!,
                    color: AppColors.textMuted,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String? _badgeText() {
    if (isLastRead) return 'آخر شرح قُرئ';
    if (recommended) return 'مقترح';
    return null;
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;

  const _Badge({
    required this.text,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: AppText.caption.copyWith(color: color),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
