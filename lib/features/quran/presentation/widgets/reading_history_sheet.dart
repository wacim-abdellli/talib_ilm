import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:quran/quran.dart' as quran;

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_sheet.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/icon_badge.dart';
import '../../data/services/reading_history_service.dart';

/// Sheet displaying chronological reading history with luxury UI touches and clear confirmation.
class ReadingHistorySheet extends StatefulWidget {
  final ValueChanged<int> onOpenPage;

  const ReadingHistorySheet({
    super.key,
    required this.onOpenPage,
  });

  static Future<void> show(
    BuildContext context, {
    required ValueChanged<int> onOpenPage,
  }) {
    return AppSheet.show<void>(
      context: context,
      maxHeightFactor: 0.88,
      builder: (_) => ReadingHistorySheet(onOpenPage: onOpenPage),
    );
  }

  @override
  State<ReadingHistorySheet> createState() => _ReadingHistorySheetState();
}

class _ReadingHistorySheetState extends State<ReadingHistorySheet> {
  List<ReadingHistoryItem> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final list = await ReadingHistoryService.getHistory();
    if (mounted) {
      setState(() {
        _items = list;
        _isLoading = false;
      });
    }
  }

  String _formatRelativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} د';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} س';
    if (diff.inDays == 1) return 'أمس';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} أيام';
    return DateFormat('MM/dd').format(dt);
  }

  Future<void> _confirmClear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final palette = ctx.palette;
        final textTheme = ctx.text;

        return AlertDialog(
          backgroundColor: palette.surfaceRaised,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.xlRadius,
          ),
          title: Row(
            children: [
              Icon(Icons.delete_sweep_rounded, color: palette.error, size: AppIcon.md),
              const SizedBox(width: AppSpace.sm),
              Text(
                'مسح سجل القراءة',
                style: textTheme.titleSmall.copyWith(
                  color: palette.text,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            'هل أنت متأكد من مسح جميع المواضع المسجلة في تاريخ القراءة؟ لا يمكن التراجع عن هذا الإجراء.',
            style: textTheme.body.copyWith(
              color: palette.textMuted,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'إلغاء',
                style: textTheme.label.copyWith(color: palette.textMuted),
              ),
            ),
            AppButton(
              size: AppButtonSize.sm,
              label: 'تأكيد المسح',
              variant: AppButtonVariant.primary,
              onPressed: () => Navigator.pop(ctx, true),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await ReadingHistoryService.clearHistory();
      if (mounted) {
        setState(() => _items = []);
        AppSnackbar.success(context, 'تم مسح سجل القراءة والتلاوة بنجاح');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: BoxDecoration(
          color: palette.surfaceRaised,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
          border: Border.all(color: palette.border),
          boxShadow: palette.shadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsetsDirectional.only(
                  top: AppSpace.md,
                  bottom: AppSpace.xs,
                ),
                decoration: BoxDecoration(
                  color: palette.border,
                  borderRadius: AppRadius.pillRadius,
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsetsDirectional.only(
                start: AppSpace.lg,
                end: AppSpace.lg,
                top: AppSpace.sm,
                bottom: AppSpace.sm,
              ),
              child: Row(
                children: [
                  IconBadge(
                    icon: Icons.history_edu_rounded,
                    fg: palette.gold,
                    bg: palette.goldSoft,
                  ),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'سجل القراءة والتلاوة',
                              style: textTheme.titleSmall.copyWith(
                                color: palette.text,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_items.isNotEmpty) ...[
                              const SizedBox(width: AppSpace.xs),
                              Container(
                                padding: const EdgeInsetsDirectional.symmetric(
                                  horizontal: AppSpace.xs,
                                  vertical: AppSpace.xxs,
                                ),
                                decoration: BoxDecoration(
                                  color: palette.goldSoft,
                                  borderRadius: AppRadius.smRadius,
                                ),
                                child: Text(
                                  '${_items.length} مواضع',
                                  style: textTheme.captionBold.copyWith(
                                    color: palette.gold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: AppSpace.xxs),
                        Text(
                          'المواضع والآيات التي تلوتها مؤخراً بالمصحف',
                          style: textTheme.caption.copyWith(color: palette.textMuted),
                        ),
                      ],
                    ),
                  ),
                  if (_items.isNotEmpty)
                    TextButton.icon(
                      onPressed: _confirmClear,
                      icon: Icon(
                        Icons.delete_sweep_rounded,
                        color: palette.error,
                        size: AppIcon.sm,
                      ),
                      label: Text(
                        'مسح',
                        style: textTheme.caption.copyWith(
                          color: palette.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            Divider(color: palette.border, height: 1),

            // History List
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: palette.gold,
                        strokeWidth: 2,
                      ),
                    )
                  : _items.isEmpty
                      ? const SingleChildScrollView(
                          physics: BouncingScrollPhysics(),
                          padding: EdgeInsetsDirectional.all(AppSpace.lg),
                          child: EmptyState(
                            icon: Icons.auto_stories_outlined,
                            title: 'سجل القراءة فارغ',
                            subtitle:
                                'عند تلاوة أي صفحة في المصحف الشريف، سيتم حفظ موضعك هنا تلقائياً لسهولة الرجوع والاستئناف.',
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsetsDirectional.all(AppSpace.md),
                          physics: const BouncingScrollPhysics(),
                          itemCount: _items.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: AppSpace.sm),
                          itemBuilder: (context, index) {
                            final item = _items[index];
                            final surahName = quran.getSurahNameArabic(item.surah);
                            final juzNum = quran.getJuzNumber(item.surah, item.ayah);
                            final timeStr = _formatRelativeTime(item.timestamp);
                            final snippet = quran.getVerse(
                              item.surah,
                              item.ayah,
                              verseEndSymbol: false,
                            );

                            return AppCard(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                Navigator.pop(context);
                                widget.onOpenPage(item.page);
                              },
                              padding: const EdgeInsetsDirectional.all(AppSpace.md),
                              child: Row(
                                children: [
                                  // Page medallion badge
                                  Container(
                                    width: 44,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: palette.surfaceMuted,
                                      borderRadius: AppRadius.smRadius,
                                      border: Border.all(
                                        color: palette.gold.withValues(alpha: 0.35),
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'ص',
                                          style: textTheme.captionBold.copyWith(
                                            color: palette.gold,
                                          ),
                                        ),
                                        Text(
                                          '${item.page}',
                                          style: textTheme.label.copyWith(
                                            color: palette.text,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: AppSpace.md),

                                  // Details & snippet
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                'سورة $surahName',
                                                style: textTheme.titleSmall.copyWith(
                                                  color: palette.text,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            // Relative time chip
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.access_time_rounded,
                                                  size: AppIcon.xs,
                                                  color: palette.textMuted,
                                                ),
                                                const SizedBox(width: AppSpace.xxs),
                                                Text(
                                                  timeStr,
                                                  style: textTheme.caption.copyWith(
                                                    color: palette.textMuted,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: AppSpace.xxs),
                                        Text(
                                          'الآية ${item.ayah} • الجزء $juzNum',
                                          style: textTheme.captionBold.copyWith(
                                            color: palette.primary,
                                          ),
                                        ),
                                        const SizedBox(height: AppSpace.xs),
                                        Text(
                                          '﴿$snippet﴾',
                                          style: textTheme.sacred.copyWith(
                                            color: palette.textMuted,
                                            height: 1.4,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: AppSpace.xs),

                                  // Trailing action chevron
                                  Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: AppIcon.xs,
                                    color: palette.textMuted,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
