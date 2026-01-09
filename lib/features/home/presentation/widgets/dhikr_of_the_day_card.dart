import 'package:flutter/material.dart';
import '../../../../app/constants/app_strings.dart';
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
      padding: AppUi.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppUi.radiusMD),
        boxShadow: AppUi.cardShadow,
      ),
      child: Align(
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppUi.maxContentWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                AppStrings.homeDhikrTitle,
                style: AppText.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppUi.gapSM),
              AnimatedSize(
                duration: AppUi.animationNormal,
                curve: Curves.easeOut,
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
                    ),
                  ),
                ),
              ),
                if (showToggle) ...[
                const SizedBox(height: AppUi.gapXSPlus),
                TextButton(
                  onPressed: () => setState(() => _expanded = !_expanded),
                  child: Text(
                    _expanded
                        ? AppStrings.actionShowLess
                        : AppStrings.actionReadFull,
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
