import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_sheet.dart';
import '../../data/models/shamela_models.dart';

/// Modal bottom sheet displaying all verified commentaries and explanations (شروح وحواشي)
/// attached to a foundational mother text (المتن الأصلي).
class ShamelaShuruhSheet extends StatelessWidget {
  final ShamelaBook parentBook;
  final List<ShamelaBook> shuruh;
  final Map<int, bool> downloadedMap;
  final Map<int, double> downloadProgress;
  final ValueChanged<ShamelaBook> onOpenSharh;
  final ValueChanged<ShamelaBook> onDownloadSharh;

  const ShamelaShuruhSheet({
    super.key,
    required this.parentBook,
    required this.shuruh,
    required this.downloadedMap,
    required this.downloadProgress,
    required this.onOpenSharh,
    required this.onDownloadSharh,
  });

  static Future<void> show({
    required BuildContext context,
    required ShamelaBook parentBook,
    required List<ShamelaBook> shuruh,
    required Map<int, bool> downloadedMap,
    required Map<int, double> downloadProgress,
    required ValueChanged<ShamelaBook> onOpenSharh,
    required ValueChanged<ShamelaBook> onDownloadSharh,
  }) {
    return AppSheet.show<void>(
      context: context,
      builder: (_) => AppSheet(
        titleText: 'شروح وحواشي المتن',
        icon: Icons.account_tree_rounded,
        showCloseButton: true,
        child: ShamelaShuruhSheet(
          parentBook: parentBook,
          shuruh: shuruh,
          downloadedMap: downloadedMap,
          downloadProgress: downloadProgress,
          onOpenSharh: onOpenSharh,
          onDownloadSharh: onDownloadSharh,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpace.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Mother Book Header Banner ───────────────────────────────
          Container(
            padding: const EdgeInsetsDirectional.all(AppSpace.md),
            decoration: BoxDecoration(
              color: palette.primarySoft,
              borderRadius: AppRadius.mdRadius,
              border: Border.all(color: palette.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: palette.surfaceRaised,
                    borderRadius: AppRadius.smRadius,
                    border: Border.all(color: palette.border),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.account_tree_rounded,
                    color: palette.primary,
                    size: AppIcon.md,
                  ),
                ),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsetsDirectional.symmetric(
                              horizontal: AppSpace.xs,
                              vertical: AppSpace.xxs,
                            ),
                            decoration: BoxDecoration(
                              color: palette.primary,
                              borderRadius: AppRadius.pillRadius,
                            ),
                            child: Text(
                              'المتن الأصلي',
                              style: textTheme.caption.copyWith(
                                color: palette.surface,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpace.xs),
                          Text(
                            '${shuruh.length} شروح معتمدة',
                            style: textTheme.caption.copyWith(
                              color: palette.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpace.xs),
                      Text(
                        parentBook.title,
                        style: textTheme.titleSmall.copyWith(
                          color: palette.text,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpace.xxs),
                      Text(
                        parentBook.author,
                        style: textTheme.caption.copyWith(
                          color: palette.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpace.md),

          // ── List of Commentaries ───────────────────────────────────
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.55,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              itemCount: shuruh.length,
              separatorBuilder: (_, index) => const SizedBox(height: AppSpace.sm),
              itemBuilder: (context, index) {
                final sharh = shuruh[index];
                final isDownloaded = downloadedMap[sharh.id] ?? false;
                final progress = downloadProgress[sharh.id];

                return AppCard(
                  padding: const EdgeInsetsDirectional.all(AppSpace.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    if (sharh.sharhType != null) ...[
                                      Container(
                                        padding: const EdgeInsetsDirectional.symmetric(
                                          horizontal: AppSpace.xs,
                                          vertical: AppSpace.xxs,
                                        ),
                                        decoration: BoxDecoration(
                                          color: palette.surfaceMuted,
                                          borderRadius: AppRadius.smRadius,
                                        ),
                                        child: Text(
                                          sharh.sharhType!,
                                          style: textTheme.caption.copyWith(
                                            color: palette.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: AppSpace.xs),
                                    ],
                                    Text(
                                      '${sharh.totalPages} صفحة',
                                      style: textTheme.caption.copyWith(
                                        color: palette.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpace.xs),
                                Text(
                                  sharh.title,
                                  style: textTheme.titleSmall.copyWith(
                                    color: palette.text,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: AppSpace.xxs),
                                Text.rich(
                                  TextSpan(
                                    text: 'الشارح: ${sharh.author}',
                                    style: textTheme.caption.copyWith(
                                      color: palette.text,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    children: [
                                      if (sharh.authorDeath != null) ...[
                                        const TextSpan(text: ' '),
                                        TextSpan(
                                          text: '(${sharh.authorDeath})',
                                          style: textTheme.caption.copyWith(
                                            color: palette.textMuted,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      if (sharh.description.isNotEmpty) ...[
                        const SizedBox(height: AppSpace.xs),
                        Text(
                          sharh.description,
                          style: textTheme.bodySmall.copyWith(
                            color: palette.textMuted,
                            height: 1.35,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      const SizedBox(height: AppSpace.sm),
                      Divider(color: palette.border, height: 1),
                      const SizedBox(height: AppSpace.xs),

                      // Actions: Download & Read
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (progress != null) ...[
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    value: progress,
                                    color: palette.primary,
                                    strokeWidth: 2,
                                  ),
                                ),
                                const SizedBox(width: AppSpace.xs),
                                Text(
                                  'جاري التحميل ${(progress * 100).toInt()}%',
                                  style: textTheme.caption.copyWith(color: palette.primary),
                                ),
                              ],
                            ),
                          ] else if (isDownloaded) ...[
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.offline_pin_rounded, color: palette.success, size: AppIcon.sm),
                                const SizedBox(width: AppSpace.xxs),
                                Text(
                                  'محمّل للمطالعة',
                                  style: textTheme.caption.copyWith(
                                    color: palette.success,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            IconButton(
                              icon: Icon(Icons.cloud_download_rounded, color: palette.primary, size: AppIcon.md),
                              tooltip: 'تحميل الشرح بدون إنترنت',
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                onDownloadSharh(sharh);
                              },
                            ),
                          ],
                          AppButton(
                            size: AppButtonSize.sm,
                            label: 'قراءة الشرح',
                            icon: Icons.menu_book_rounded,
                            onPressed: () {
                              Navigator.pop(context);
                              onOpenSharh(sharh);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: AppSpace.lg),
        ],
      ),
    );
  }
}
