import 'package:flutter/material.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_progress.dart';
import '../../data/models/quran_models.dart';
import '../../data/services/quran_pack_install_service.dart';

/// Scholarly transmission metadata for canonical Quranic narrations.
class RiwayahScholarlyMetadata {
  final QuranRiwayahId id;
  final String emblemLetter;
  final String title;
  final String transmitter;
  final String imam;
  final String tariq;
  final String ayahCount;
  final String region;
  final String description;
  final bool isBundled;

  const RiwayahScholarlyMetadata({
    required this.id,
    required this.emblemLetter,
    required this.title,
    required this.transmitter,
    required this.imam,
    required this.tariq,
    required this.ayahCount,
    required this.region,
    required this.description,
    this.isBundled = false,
  });

  static const Map<QuranRiwayahId, RiwayahScholarlyMetadata> all = {
    QuranRiwayahId.hafs: RiwayahScholarlyMetadata(
      id: QuranRiwayahId.hafs,
      emblemLetter: 'ح',
      title: 'رواية حفص عن عاصم',
      transmitter: 'أبو عمرو حفص بن سليمان الكوفي',
      imam: 'عاصم بن أبي النَّجود الأسدي',
      tariq: 'طريق الشاطبية',
      ayahCount: 'العد الكوفي (6236 آية)',
      region: 'المشرق والعالم الإسلامي',
      description:
          'الرواية الأكثر انتشاراً في العالم الإسلامي، تمتاز بجلاء القواعد وتيسير النطق والأداء.',
      isBundled: true,
    ),
    QuranRiwayahId.warsh: RiwayahScholarlyMetadata(
      id: QuranRiwayahId.warsh,
      emblemLetter: 'و',
      title: 'رواية ورش عن نافع',
      transmitter: 'أبو سعيد عثمان بن سعيد المصري',
      imam: 'نافع بن عبد الرحمن المدني',
      tariq: 'طريق أبي يعقوب الأزرق',
      ayahCount: 'العد المدني الأخير (6214 آية)',
      region: 'المغرب العربي وغرب إفريقيا',
      description:
          'تتميز بترقيق الراءات وتغليظ اللامات وتسهيل الهمز والنقل، وهي المعتمدة في بلاد المغرب العربي.',
      isBundled: false,
    ),
    QuranRiwayahId.qalun: RiwayahScholarlyMetadata(
      id: QuranRiwayahId.qalun,
      emblemLetter: 'ق',
      title: 'رواية قالون عن نافع',
      transmitter: 'أبو موسى عيسى بن مينا المدني',
      imam: 'نافع بن عبد الرحمن المدني',
      tariq: 'طريق أبي نشيط المروزي',
      ayahCount: 'العد المدني الأول (6214 آية)',
      region: 'ليبيا وتونس وأجزاء من إفريقيا',
      description:
          'تتميز بإسكان ميم الجمع وصلتها وتسهيل الهمزتين من كلمة، وتعتمد في ليبيا وتونس.',
      isBundled: false,
    ),
  };

  static RiwayahScholarlyMetadata of(QuranRiwayahId id) => all[id]!;
}

/// An illuminated scholarly card presenting a canonical Quran narration,
/// its academic transmission metadata, offline status, and download controls.
class QuranRiwayahCard extends StatelessWidget {
  final QuranRiwayahId edition;
  final bool isCurrent;
  final bool isInstalled;
  final int storageBytes;
  final QuranPackInstallProgress? progress;
  final bool isDownloading;
  final VoidCallback onUse;
  final VoidCallback onDownload;
  final VoidCallback onCancel;
  final VoidCallback onDelete;

  const QuranRiwayahCard({
    super.key,
    required this.edition,
    required this.isCurrent,
    required this.isInstalled,
    required this.storageBytes,
    required this.progress,
    required this.isDownloading,
    required this.onUse,
    required this.onDownload,
    required this.onCancel,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final meta = RiwayahScholarlyMetadata.of(edition);
    final pin = QuranPackInstallService.sourcePin(edition);
    final data = pin['data'] as Map<String, dynamic>;
    final font = pin['font'] as Map<String, dynamic>;
    final transferBytes = (data['bytes'] as int) + (font['bytes'] as int);
    final transferMb = transferBytes / (1024 * 1024);
    final storageMb = storageBytes / (1024 * 1024);

    return AppCard(
      padding: const EdgeInsetsDirectional.all(AppSpace.md),
      color: isCurrent ? palette.surfaceRaised : palette.surface,
      borderRadius: AppRadius.lgRadius,
      border: Border.all(
        color: isCurrent ? palette.gold : palette.border.withValues(alpha: 0.7),
        width: isCurrent ? 1.5 : 1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row: Emblem Medallion, Title & Lineage, Status Tag
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Sacred Medallion (Sleek 38dp)
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isCurrent ? palette.goldSoft : palette.surfaceMuted,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCurrent ? palette.gold : palette.border.withValues(alpha: 0.6),
                    width: isCurrent ? 1.5 : 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  meta.emblemLetter,
                  style: context.text.titleSmall.copyWith(
                    color: isCurrent ? palette.gold : palette.text,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              // Titles & Lineage
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        edition.nameArabic,
                        style: context.text.titleSmall.copyWith(
                          color: palette.text,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(height: AppSpace.xxs),
                    Text(
                      '${meta.transmitter} • عن ${meta.imam}',
                      style: context.text.caption.copyWith(
                        color: palette.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpace.xs),
              _buildStatusBadge(context),
            ],
          ),

          const SizedBox(height: AppSpace.sm),

          // Scholarly Tags Wrap (Clean & Minimalist)
          Wrap(
            spacing: AppSpace.xs,
            runSpacing: AppSpace.xxs,
            children: [
              _ScholarlyTag(
                icon: Icons.alt_route_rounded,
                label: meta.tariq,
              ),
              _ScholarlyTag(
                icon: Icons.format_list_numbered_rounded,
                label: meta.ayahCount,
              ),
              _ScholarlyTag(
                icon: Icons.public_rounded,
                label: meta.region,
              ),
              const _ScholarlyTag(
                icon: Icons.verified_outlined,
                label: 'خط المجمع الرقمي',
              ),
            ],
          ),

          const SizedBox(height: AppSpace.sm),

          // Scholarly Brief Description
          Text(
            meta.description,
            style: context.text.bodySmall.copyWith(
              color: palette.textMuted,
              height: 1.35,
            ),
            textAlign: TextAlign.start,
          ),

          const SizedBox(height: AppSpace.sm),

          // Storage Info Label (Subtle single line without heavy divider)
          Row(
            children: [
              Icon(
                Icons.sd_storage_outlined,
                size: AppIcon.xs,
                color: palette.gold,
              ),
              const SizedBox(width: AppSpace.xs),
              Expanded(
                child: Text(
                  _storageDescription(transferMb, storageMb),
                  style: context.text.caption.copyWith(
                    color: palette.textMuted,
                  ),
                ),
              ),
            ],
          ),

          // Download Progress / Error (if active)
          if (progress != null &&
              (isDownloading || progress!.isError || progress!.isComplete)) ...[
            const SizedBox(height: AppSpace.sm),
            if (isDownloading) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      progress!.status,
                      style: context.text.caption.copyWith(
                        color: palette.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpace.xs),
                  Text(
                    '${(progress!.progress * 100).toInt()}%',
                    style: context.text.caption.copyWith(
                      color: palette.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.xs),
              AppProgress(
                progress: progress!.totalBytes == null ? 0.0 : progress!.progress,
                color: palette.gold,
              ),
            ],
            if (progress!.isError) ...[
              const SizedBox(height: AppSpace.xs),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: AppIcon.sm,
                    color: palette.error,
                  ),
                  const SizedBox(width: AppSpace.xs),
                  Expanded(
                    child: Text(
                      progress!.status,
                      style: context.text.caption.copyWith(
                        color: palette.error,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],

          const SizedBox(height: AppSpace.sm),

          // Action Buttons
          if (isDownloading)
            AppButton.outline(
              label: 'إلغاء التنزيل',
              icon: Icons.close_rounded,
              onPressed: onCancel,
            )
          else if (edition == QuranRiwayahId.hafs)
            AppButton(
              label: isCurrent ? 'متابعة قراءة حفص' : 'قراءة حفص عن عاصم',
              icon: Icons.auto_stories_rounded,
              onPressed: onUse,
            )
          else if (isInstalled)
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: isCurrent ? 'متابعة القراءة' : 'تفعيل وقراءة الرواية',
                    icon: Icons.auto_stories_rounded,
                    onPressed: onUse,
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                AppIconButton(
                  icon: Icons.delete_outline_rounded,
                  tooltip: 'حذف الرواية من الجهاز',
                  color: palette.error,
                  onPressed: onDelete,
                ),
              ],
            )
          else
            AppButton(
              label: 'تنزيل الرواية (${transferMb.toStringAsFixed(2)} م.ب)',
              icon: Icons.download_rounded,
              onPressed: onDownload,
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    final palette = context.palette;
    if (isCurrent) {
      return Container(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpace.sm,
          vertical: AppSpace.xxs,
        ),
        decoration: BoxDecoration(
          color: palette.goldSoft,
          borderRadius: AppRadius.pillRadius,
          border: Border.all(
            color: palette.gold.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_rounded,
              size: AppIcon.xs,
              color: palette.gold,
            ),
            const SizedBox(width: AppSpace.xxs),
            Text(
              'الرواية النشطة',
              style: context.text.caption.copyWith(
                color: palette.gold,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    if (isDownloading) {
      return Container(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpace.sm,
          vertical: AppSpace.xxs,
        ),
        decoration: BoxDecoration(
          color: palette.primarySoft,
          borderRadius: AppRadius.pillRadius,
        ),
        child: Text(
          'جارٍ التنزيل',
          style: context.text.caption.copyWith(
            color: palette.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    if (isInstalled) {
      return Container(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpace.sm,
          vertical: AppSpace.xxs,
        ),
        decoration: BoxDecoration(
          color: palette.success.withValues(alpha: 0.12),
          borderRadius: AppRadius.pillRadius,
        ),
        child: Text(
          'جاهزة للقراءة',
          style: context.text.caption.copyWith(
            color: palette.success,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpace.sm,
        vertical: AppSpace.xxs,
      ),
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: AppRadius.pillRadius,
      ),
      child: Text(
        'متاحة للتنزيل',
        style: context.text.caption.copyWith(
          color: palette.textMuted,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _storageDescription(double transferMb, double storageMb) {
    if (edition == QuranRiwayahId.hafs) {
      return 'مضمنة في التطبيق • لا تتطلب تنزيلاً إضافياً';
    }
    if (isInstalled) {
      return 'مثبتة على الجهاز • المساحة المستهلكة: ${storageMb.toStringAsFixed(2)} م.ب';
    }
    return 'حجم التنزيل: ${transferMb.toStringAsFixed(2)} م.ب • تعمل دون إنترنت بعد التثبيت';
  }
}

/// A compact scholarly tag pill.
class _ScholarlyTag extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ScholarlyTag({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpace.sm,
        vertical: AppSpace.xxs,
      ),
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: AppRadius.pillRadius,
        border: Border.all(
          color: palette.border.withValues(alpha: 0.4),
          width: 0.6,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: AppIcon.xs,
            color: palette.textMuted,
          ),
          const SizedBox(width: AppSpace.xs),
          Text(
            label,
            style: context.text.caption.copyWith(
              color: palette.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
