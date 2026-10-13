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

/// Sheet displaying chronological reading history with clear confirmation.
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
      maxHeightFactor: 0.85,
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
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    if (diff.inDays == 1) return 'أمس';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} أيام';
    return DateFormat('yyyy/MM/dd').format(dt);
  }

  Future<void> _confirmClear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final palette = ctx.palette;
        final textTheme = ctx.text;

        return AlertDialog(
          backgroundColor: palette.surface,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.xlRadius,
          ),
          title: Text(
            'مسح سجل القراءة',
            style: textTheme.titleSmall.copyWith(
              color: palette.text,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'هل أنت متأكد من مسح جميع السجلات المحفوظة في تاريخ القراءة؟',
            style: textTheme.body.copyWith(color: palette.textMuted),
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
              label: 'مسح السجل',
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
        AppSnackbar.success(context, 'تم مسح سجل القراءة بنجاح');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsetsDirectional.only(top: AppSpace.sm),
              decoration: BoxDecoration(
                color: palette.border,
                borderRadius: AppRadius.pillRadius,
              ),
            ),
          ),
          const SizedBox(height: AppSpace.md),

          // Header
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpace.lg),
            child: Row(
              children: [
                const IconBadge(icon: Icons.history_rounded),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'سجل القراءة والتلاوة',
                        style: textTheme.titleSmall.copyWith(
                          color: palette.text,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'الصفحات والآيات التي تم الاطلاع عليها مؤخراً',
                        style: textTheme.caption.copyWith(color: palette.textMuted),
                      ),
                    ],
                  ),
                ),
                if (_items.isNotEmpty)
                  TextButton.icon(
                    onPressed: _confirmClear,
                    icon: Icon(Icons.delete_sweep_rounded, color: palette.error),
                    label: Text(
                      'مسح',
                      style: textTheme.label.copyWith(color: palette.error),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.md),
          Divider(color: palette.border, height: 1),

          // List content
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: palette.primary,
                      strokeWidth: 2,
                    ),
                  )
                : _items.isEmpty
                    ? const EmptyState(
                        icon: Icons.history_rounded,
                        title: 'سجل القراءة فارغ',
                        subtitle: 'الصفحات التي تقرأها في المصحف ستظهر هنا تلقائياً لسهولة الرجوع إليها.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsetsDirectional.all(AppSpace.md),
                        itemCount: _items.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: AppSpace.xs),
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          final surahName = quran.getSurahNameArabic(item.surah);
                          final timeStr = _formatRelativeTime(item.timestamp);

                          return AppCard(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              Navigator.pop(context);
                              widget.onOpenPage(item.page);
                            },
                            padding: const EdgeInsetsDirectional.symmetric(
                              horizontal: AppSpace.md,
                              vertical: AppSpace.sm,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: palette.surfaceMuted,
                                    borderRadius: AppRadius.smRadius,
                                    border: Border.all(color: palette.border),
                                  ),
                                  child: Text(
                                    '${item.page}',
                                    style: textTheme.label.copyWith(
                                      color: palette.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpace.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'سورة $surahName',
                                        style: textTheme.titleSmall.copyWith(
                                          color: palette.text,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'صفحة ${item.page} • الآية ${item.ayah}',
                                        style: textTheme.bodySmall.copyWith(
                                          color: palette.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsetsDirectional.symmetric(
                                    horizontal: AppSpace.sm,
                                    vertical: AppSpace.xxs,
                                  ),
                                  decoration: BoxDecoration(
                                    color: palette.surfaceMuted,
                                    borderRadius: AppRadius.pillRadius,
                                  ),
                                  child: Text(
                                    timeStr,
                                    style: textTheme.caption.copyWith(
                                      color: palette.textMuted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
