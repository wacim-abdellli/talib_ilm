import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../adhkar/data/adhkar_models.dart';

class DhikrOfTheDayCard extends StatefulWidget {
  final AthkarItem item;

  const DhikrOfTheDayCard({
    super.key,
    required this.item,
  });

  @override
  State<DhikrOfTheDayCard> createState() => _DhikrOfTheDayCardState();
}

class _DhikrOfTheDayCardState extends State<DhikrOfTheDayCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final text = widget.item.arabic;
    final showToggle = text.length > 140;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppUi.cardShadow,
      ),
      child: Align(
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'ذكر اليوم',
                style: AppText.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: GestureDetector(
                  onTap: showToggle
                      ? () => setState(() => _expanded = !_expanded)
                      : null,
                  child: Text(
                    text,
                    textAlign: TextAlign.center,
                    maxLines: _expanded ? null : 4,
                    overflow:
                        _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
                    style: AppText.body.copyWith(
                      color: AppColors.textPrimary,
                      height: 1.9,
                    ),
                  ),
                ),
              ),
              if (showToggle) ...[
                const SizedBox(height: 6),
                TextButton(
                  onPressed: () => setState(() => _expanded = !_expanded),
                  child: Text(
                    _expanded ? 'عرض أقل' : 'قراءة كاملة',
                    style: AppText.caption.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
