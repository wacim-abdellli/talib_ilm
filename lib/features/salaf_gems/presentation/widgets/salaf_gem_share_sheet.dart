import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/utils/app_share.dart';
import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../data/models/salaf_gem.dart';

class SalafGemShareSheet extends StatelessWidget {
  final SalafGem gem;

  const SalafGemShareSheet({
    super.key,
    required this.gem,
  });

  static Future<void> show(BuildContext context, SalafGem gem) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SalafGemShareSheet(gem: gem),
    );
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: gem.shareableText));
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'تم نسخ الأثر والمصدر إلى الحافظة',
          style: context.text.body.copyWith(
            color: context.palette.onPrimary,
          ),
        ),
        backgroundColor: context.palette.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _shareExternal(BuildContext context) {
    AppShare.share(
      context,
      gem.shareableText,
      subject: gem.topic.isNotEmpty ? gem.topic : gem.author,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: AppRadius.sheetTopRadius,
        border: Border.all(
          color: palette.border,
        ),
      ),
      padding: const EdgeInsetsDirectional.all(AppSpace.lg),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: AppSpace.xxl,
                  height: AppSpace.xs,
                  decoration: BoxDecoration(
                    color: palette.border,
                    borderRadius: AppRadius.pillRadius,
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.md),

              // Title Header
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    color: palette.gold,
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Text(
                    'بطاقة درر السلف',
                    style: textTheme.title.copyWith(
                      color: palette.text,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: palette.textMuted,
                    ),
                    tooltip: 'إغلاق',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.md),

              // Decorative Islamic Quote Preview Card
              Container(
                decoration: BoxDecoration(
                  color: palette.surfaceRaised,
                  borderRadius: AppRadius.lgRadius,
                  border: Border.all(
                    color: palette.primarySoft,
                  ),
                ),
                padding: const EdgeInsetsDirectional.all(AppSpace.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Badge: Category & Topic
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsetsDirectional.symmetric(
                            horizontal: AppSpace.sm,
                            vertical: AppSpace.xs,
                          ),
                          decoration: BoxDecoration(
                            color: palette.primarySoft,
                            borderRadius: AppRadius.pillRadius,
                          ),
                          child: Text(
                            gem.category,
                            style: textTheme.caption.copyWith(
                              color: palette.primary,
                            ),
                          ),
                        ),
                        if (gem.topic.isNotEmpty && gem.topic != gem.category) ...[
                          const SizedBox(width: AppSpace.xs),
                          Expanded(
                            child: Text(
                              gem.topic,
                              style: textTheme.caption.copyWith(
                                color: palette.textMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpace.md),

                    // Quote Text
                    Text(
                      gem.cleanText,
                      style: textTheme.sacredSmall.copyWith(
                        color: palette.text,
                        height: 1.8,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                    const SizedBox(height: AppSpace.lg),

                    // Author & Role
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: AppSpace.xs,
                          height: AppSpace.lg,
                          decoration: BoxDecoration(
                            color: palette.gold,
                            borderRadius: AppRadius.pillRadius,
                          ),
                        ),
                        const SizedBox(width: AppSpace.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                gem.author,
                                style: textTheme.titleSmall.copyWith(
                                  color: palette.text,
                                ),
                              ),
                              if (gem.role.isNotEmpty)
                                Text(
                                  gem.role,
                                  style: textTheme.caption.copyWith(
                                    color: palette.textSubtle,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Source Reference
                    if (gem.sourceRef.isNotEmpty) ...[
                      const SizedBox(height: AppSpace.md),
                      Container(
                        padding: const EdgeInsetsDirectional.all(AppSpace.sm),
                        decoration: BoxDecoration(
                          color: palette.surface,
                          borderRadius: AppRadius.smRadius,
                          border: Border.all(
                            color: palette.border,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.menu_book_rounded,
                              color: palette.textSubtle,
                            ),
                            const SizedBox(width: AppSpace.xs),
                            Expanded(
                              child: Text(
                                gem.sourceRef,
                                style: textTheme.caption.copyWith(
                                  color: palette.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.lg),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: palette.text,
                        side: BorderSide(color: palette.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.mdRadius,
                        ),
                        minimumSize: const Size(0, AppSize.tap),
                      ),
                      onPressed: () => _copyToClipboard(context),
                      icon: const Icon(Icons.copy_rounded),
                      label: Text(
                        'نسخ الأثر',
                        style: textTheme.label,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: palette.primary,
                        foregroundColor: palette.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.mdRadius,
                        ),
                        minimumSize: const Size(0, AppSize.tap),
                      ),
                      onPressed: () => _shareExternal(context),
                      icon: const Icon(Icons.share_rounded),
                      label: Text(
                        'مشاركة',
                        style: textTheme.label.copyWith(
                          color: palette.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
