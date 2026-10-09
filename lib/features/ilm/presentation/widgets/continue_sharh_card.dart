import 'package:flutter/material.dart';

import '../../../../app/constants/app_strings.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../core/services/last_activity_service.dart';
import '../../../../shared/widgets/pressable_card.dart';
import '../../data/models/sharh_model.dart';

class ContinueSharhCard extends StatelessWidget {
  final Sharh sharh;
  final PdfPageInfo? pageInfo;
  final VoidCallback onTap;

  const ContinueSharhCard({
    super.key,
    required this.sharh,
    required this.pageInfo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final rawPage = pageInfo?.page;
    final rawTotal = pageInfo?.total ?? 0;
    final safeTotal = rawPage != null && rawTotal > 0 && rawTotal < rawPage
        ? rawPage
        : (rawTotal > 0 ? rawTotal : null);
    final safePage = rawPage != null && safeTotal != null
        ? rawPage.clamp(1, safeTotal)
        : rawPage;
    final pageLabel = pageInfo == null
        ? AppStrings.continueSharh
        : AppStrings.lastPage(safePage ?? 1, safeTotal);

    return PressableCard(
      onTap: onTap,
      padding: AppUi.cardPadding,
      borderRadius: BorderRadius.circular(AppUi.radiusMD),
      decoration: BoxDecoration(
        gradient: AppColors.surfaceElevatedGradient,
        borderRadius: BorderRadius.circular(AppUi.radiusMD),
      ),
      child: Row(
        children: [
          Icon(Icons.history, color: AppColors.primary),
          const SizedBox(width: AppUi.gapMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sharh.title, style: AppText.heading),
                const SizedBox(height: AppUi.gapXSPlus),
                Text(
                  pageLabel,
                  style: AppText.caption.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
