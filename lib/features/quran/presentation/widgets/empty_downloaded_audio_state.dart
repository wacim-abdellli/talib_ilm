import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_ui.dart';
import '../../../../shared/widgets/app_button.dart';

class EmptyDownloadedAudioState extends StatelessWidget {
  final VoidCallback onBrowseAll;

  const EmptyDownloadedAudioState({
    super.key,
    required this.onBrowseAll,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: AppUi.emptyIllustrationSize,
              height: AppUi.emptyIllustrationSize,
              decoration: BoxDecoration(
                color: palette.primarySoft,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.cloud_download_outlined,
                size: AppIcon.xl,
                color: palette.primary,
              ),
            ),
            const SizedBox(height: AppSpace.md),
            Text(
              'لا توجد سور محمّلة لهذا القارئ',
              style: textTheme.titleSmall.copyWith(
                color: palette.text,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpace.xs),
            Text(
              'يمكنك تنزيل السور التي ترغب في الاستماع إليها بدون إنترنت بالنقر على زر التنزيل في قائمة جميع السور.',
              textAlign: TextAlign.center,
              style: textTheme.bodySmall.copyWith(
                color: palette.textMuted,
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            AppButton(
              label: 'تصفح جميع السور للتنزيل',
              variant: AppButtonVariant.primary,
              icon: Icons.format_list_bulleted_rounded,
              onPressed: () {
                HapticFeedback.lightImpact();
                onBrowseAll();
              },
            ),
          ],
        ),
      ),
    );
  }
}
