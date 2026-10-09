import 'package:flutter/material.dart';

import '../../../../app/constants/app_strings.dart';
import '../../../../app/theme/app_palette.dart';
import '../../../../core/services/last_activity_service.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/icon_badge.dart';
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

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Row(
        children: [
          const IconBadge(icon: Icons.history),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sharh.title,
                  style: context.text.titleSmall,
                ),
                const SizedBox(height: AppSpace.xs),
                Text(
                  pageLabel,
                  style: context.text.caption.copyWith(
                    color: context.palette.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
