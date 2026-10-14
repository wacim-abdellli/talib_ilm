import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_sheet.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/icon_badge.dart';
import '../../../quran/data/services/bookmark_backup_service.dart';

/// Interactive Sheet for Exporting and Importing User Bookmarks & Notes.
class BackupRestoreSheet extends StatefulWidget {
  const BackupRestoreSheet({super.key});

  static Future<void> show(BuildContext context) {
    return AppSheet.show<void>(
      context: context,
      builder: (_) => const BackupRestoreSheet(),
    );
  }

  @override
  State<BackupRestoreSheet> createState() => _BackupRestoreSheetState();
}

class _BackupRestoreSheetState extends State<BackupRestoreSheet> {
  bool _isProcessing = false;

  Future<void> _handleExport() async {
    setState(() => _isProcessing = true);
    HapticFeedback.lightImpact();

    try {
      await BookmarkBackupService.exportAndShare(context);
      if (mounted) {
        Navigator.pop(context);
        AppSnackbar.success(context, 'تم تجهيز ملف النسخة الاحتياطية بنجاح');
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, 'تعذر تصدير النسخة الاحتياطية: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _handleImport() async {
    setState(() => _isProcessing = true);
    HapticFeedback.lightImpact();

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) {
        setState(() => _isProcessing = false);
        return;
      }

      final file = result.files.first;
      String content;

      if (file.bytes != null) {
        content = String.fromCharCodes(file.bytes!);
      } else if (file.path != null) {
        content = await File(file.path!).readAsString();
      } else {
        if (mounted) {
          AppSnackbar.error(context, 'تعذر قراءة الملف المحدد');
        }
        setState(() => _isProcessing = false);
        return;
      }

      final validation = BookmarkBackupService.validateAndParse(content);
      if (!validation.isValid) {
        if (mounted) {
          AppSnackbar.error(
            context,
            validation.errorMessage ?? 'ملف النسخة الاحتياطية غير صالح',
          );
        }
        setState(() => _isProcessing = false);
        return;
      }

      if (!mounted) return;

      // Ask confirmation about overwriting existing notes
      final bool? overwrite = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          final palette = ctx.palette;
          final textTheme = ctx.text;

          return AlertDialog(
            backgroundColor: palette.surfaceRaised,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.lgRadius),
            title: Text(
              'تأكيد استيراد المحفوظات',
              style: textTheme.titleSmall.copyWith(
                color: palette.text,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              'تم التحقق من الملف (${validation.bookmarks.length} علامة وملاحظة).\nهل ترغب في تحديث الملاحظات السابقة في حال تطابق الآيات، أم الاحتفاظ بها ودمج الجديد فقط؟',
              style: textTheme.body.copyWith(
                color: palette.textMuted,
                height: 1.5,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  'الاحتفاظ بالحالية ودمج الجديد',
                  style: textTheme.bodySmall.copyWith(
                    color: palette.text,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              AppButton(
                size: AppButtonSize.sm,
                label: 'تحديث الكل',
                onPressed: () => Navigator.pop(ctx, true),
              ),
            ],
          );
        },
      );

      if (overwrite == null) {
        setState(() => _isProcessing = false);
        return;
      }

      final mergeStats = await BookmarkBackupService.mergeBookmarks(
        importedBookmarks: validation.bookmarks,
        overwriteExistingNotes: overwrite,
        importedLastRead: validation.lastRead,
      );

      if (mounted) {
        Navigator.pop(context);
        AppSnackbar.success(
          context,
          'تم استيراد المحفوظات بنجاح (أُضيف: ${mergeStats.addedCount}، حُدّث: ${mergeStats.updatedCount})',
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, 'حدث خطأ أثناء استيراد الملف: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
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
        padding: const EdgeInsetsDirectional.only(
          top: AppSpace.md,
          bottom: AppSpace.xl,
          start: AppSpace.lg,
          end: AppSpace.lg,
        ),
        decoration: BoxDecoration(
          color: palette.surfaceRaised,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
          border: Border.all(color: palette.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: palette.border,
                  borderRadius: AppRadius.pillRadius,
                ),
              ),
            ),
            const SizedBox(height: AppSpace.md),

            Row(
              children: [
                const IconBadge(icon: Icons.cloud_sync_rounded),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'النسخ الاحتياطي والاستعادة',
                        style: textTheme.titleSmall.copyWith(
                          color: palette.text,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'تصدير واستيراد الفواصل والملاحظات الإيمانية محلياً',
                        style: textTheme.caption.copyWith(
                          color: palette.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                AppIconButton(
                  icon: Icons.close_rounded,
                  tooltip: 'إغلاق',
                  color: palette.textMuted,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            const SizedBox(height: AppSpace.xs),
            Divider(height: 1, color: palette.border),
            const SizedBox(height: AppSpace.md),

            // Option 1: Export to JSON
            AppCard(
              child: InkWell(
                borderRadius: AppRadius.mdRadius,
                onTap: _isProcessing ? null : _handleExport,
                child: Padding(
                  padding: const EdgeInsetsDirectional.all(AppSpace.xs),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: palette.primarySoft.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            Icons.upload_file_rounded,
                            color: palette.primary,
                            size: AppIcon.md,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpace.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'تصدير نسخة احتياطية (JSON)',
                              style: textTheme.body.copyWith(
                                color: palette.text,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'حفظ فواصل الآيات وملاحظاتك في ملف ومشاركته',
                              style: textTheme.caption.copyWith(
                                color: palette.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: palette.textMuted,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpace.md),

            // Option 2: Import from JSON
            AppCard(
              child: InkWell(
                borderRadius: AppRadius.mdRadius,
                onTap: _isProcessing ? null : _handleImport,
                child: Padding(
                  padding: const EdgeInsetsDirectional.all(AppSpace.xs),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: palette.goldSoft.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            Icons.download_rounded,
                            color: palette.gold,
                            size: AppIcon.md,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpace.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'استيراد من ملف خارجي',
                              style: textTheme.body.copyWith(
                                color: palette.text,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'استعادة المحفوظات من ملف JSON سابق مع منع التكرار',
                              style: textTheme.caption.copyWith(
                                color: palette.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: palette.textMuted,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            if (_isProcessing) ...[
              const SizedBox(height: AppSpace.md),
              Center(
                child: CircularProgressIndicator(color: palette.primary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
