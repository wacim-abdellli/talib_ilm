import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/theme/app_palette.dart';
import '../../../app/theme/app_ui.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_dialog.dart';
import '../../../shared/widgets/primary_app_bar.dart';
import '../data/models/quran_models.dart';
import '../data/services/edition_service.dart';
import '../data/services/quran_pack_install_service.dart';
import 'quran_pack_reader_page.dart';
import 'widgets/mushaf_page_viewer.dart';
import 'widgets/quran_riwayah_card.dart';

class QuranRiwayahDownloadsPage extends StatefulWidget {
  const QuranRiwayahDownloadsPage({super.key});

  @override
  State<QuranRiwayahDownloadsPage> createState() =>
      _QuranRiwayahDownloadsPageState();
}

class _QuranRiwayahDownloadsPageState extends State<QuranRiwayahDownloadsPage> {
  final Map<QuranRiwayahId, QuranPackInstallProgress> _progress = {};
  final Map<QuranRiwayahId, StreamSubscription<QuranPackInstallProgress>>
  _subscriptions = {};
  final Map<QuranRiwayahId, bool> _installed = {};
  final Map<QuranRiwayahId, int> _storageBytes = {};
  String _currentEdition = 'hafs';
  bool _loading = true;

  @visibleForTesting
  Future<void>? refreshFuture;

  @override
  void initState() {
    super.initState();
    refreshFuture = _refresh();
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions.values) {
      unawaited(subscription.cancel());
    }
    super.dispose();
  }

  Future<void> _refresh() async {
    final current = await EditionService.getCurrentEdition();
    final installed = <QuranRiwayahId, bool>{
      QuranRiwayahId.hafs: true,
      QuranRiwayahId.warsh: await QuranPackInstallService.isInstalled(
        QuranRiwayahId.warsh,
      ),
      QuranRiwayahId.qalun: await QuranPackInstallService.isInstalled(
        QuranRiwayahId.qalun,
      ),
    };
    final storage = <QuranRiwayahId, int>{
      QuranRiwayahId.warsh: await QuranPackInstallService.storageBytes(
        QuranRiwayahId.warsh,
      ),
      QuranRiwayahId.qalun: await QuranPackInstallService.storageBytes(
        QuranRiwayahId.qalun,
      ),
    };
    if (!mounted) return;
    setState(() {
      _currentEdition = current ?? '';
      _installed
        ..clear()
        ..addAll(installed);
      _storageBytes
        ..clear()
        ..addAll(storage);
      _loading = false;
    });
  }

  void _download(QuranRiwayahId edition) {
    if (_subscriptions.containsKey(edition)) return;
    setState(() {
      _progress[edition] = QuranPackInstallProgress(
        edition,
        0,
        'جارٍ بدء التنزيل',
      );
    });
    _subscriptions[edition] = QuranPackInstallService.install(edition).listen(
      (progress) {
        if (!mounted) return;
        setState(() => _progress[edition] = progress);
        if (progress.isError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(progress.status)));
        }
      },
      onError: (Object error) {
        if (mounted) {
          setState(() {
            _progress[edition] = QuranPackInstallProgress.failed(
              edition,
              'تعذر التنزيل: $error',
            );
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('تعذر تنزيل الرواية: $error')));
        }
      },
      onDone: () {
        _subscriptions.remove(edition);
        _refresh();
      },
    );
  }

  void _cancel(QuranRiwayahId edition) {
    QuranPackInstallService.cancel(edition);
    _subscriptions[edition]?.cancel();
    _subscriptions.remove(edition);
    setState(() {
      _progress.remove(edition);
    });
  }

  Future<void> _use(QuranRiwayahId edition) async {
    await EditionService.setCurrentEdition(edition.wireValue);
    if (!mounted) return;
    setState(() => _currentEdition = edition.wireValue);
    if (edition == QuranRiwayahId.hafs) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MushafPageViewer()),
      );
    } else {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => QuranPackReaderPage(editionId: edition),
        ),
      );
    }
    if (mounted) await _refresh();
  }

  Future<void> _confirmDelete(QuranRiwayahId edition) async {
    final meta = RiwayahScholarlyMetadata.of(edition);
    final bytes = _storageBytes[edition] ?? 0;
    final mb = (bytes / (1024 * 1024)).toStringAsFixed(2);
    final isCurrent = _currentEdition == edition.wireValue;

    final confirmed = await AppDialog.show<bool>(
      context: context,
      builder: (dialogContext) {
        final palette = dialogContext.palette;
        final textTheme = dialogContext.text;
        return AppDialog(
          icon: Icons.delete_outline_rounded,
          iconColor: palette.error,
          title: 'حذف ${meta.title}؟',
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'سيتم حذف بيانات الرواية والخط الرقمي من ذاكرة الجهاز لتوفير $mb م.ب.',
                style: textTheme.body.copyWith(color: palette.text),
              ),
              if (isCurrent) ...[
                const SizedBox(height: AppSpace.sm),
                Text(
                  'ملاحظة: بما أن هذه هي الرواية المحددة حالياً، سيعود التطبيق تلقائياً إلى رواية حفص عن عاصم.',
                  style: textTheme.caption.copyWith(color: palette.gold),
                ),
              ],
              const SizedBox(height: AppSpace.sm),
              Text(
                'يمكنك إعادة تنزيل الرواية مجدداً في أي وقت دون قيود.',
                style: textTheme.caption.copyWith(color: palette.textMuted),
              ),
            ],
          ),
          actions: [
            AppButton.text(
              label: 'إلغاء',
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            const SizedBox(width: AppSpace.sm),
            AppButton(
              label: 'حذف الرواية',
              variant: AppButtonVariant.primary,
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _delete(edition);
    }
  }

  Future<void> _delete(QuranRiwayahId edition) async {
    if (_currentEdition == edition.wireValue) {
      await EditionService.setCurrentEdition(QuranRiwayahId.hafs.wireValue);
    }
    final deleted = await EditionService.deleteEdition(edition.wireValue);
    if (!mounted) return;
    if (!deleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر حذف الرواية من الجهاز')),
      );
      return;
    }
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final totalInstalledBytes = _storageBytes.values.fold<int>(
      0,
      (sum, b) => sum + b,
    );
    final totalInstalledMb = (totalInstalledBytes / (1024 * 1024))
        .toStringAsFixed(2);
    final installedCount = _installed.values.where((v) => v).length;

    return Scaffold(
      backgroundColor: palette.bg,
      appBar: const PrimaryAppBar(title: 'روايات المصحف الشريف', showBack: true),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: palette.gold))
          : ListView(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpace.lg,
                AppSpace.md,
                AppSpace.lg,
                AppSpace.xl,
              ),
              children: [
                _RiwayatOverviewHeader(
                  currentEdition: _currentEdition,
                  installedCount: installedCount,
                  totalStorageMb: totalInstalledMb,
                ),
                const SizedBox(height: AppSpace.lg),
                for (final edition in QuranRiwayahId.values)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      bottom: AppSpace.md,
                    ),
                    child: QuranRiwayahCard(
                      edition: edition,
                      isCurrent: _currentEdition == edition.wireValue,
                      isInstalled: _installed[edition] ?? false,
                      storageBytes: _storageBytes[edition] ?? 0,
                      progress: _progress[edition],
                      isDownloading: _subscriptions.containsKey(edition),
                      onUse: () => _use(edition),
                      onDownload: () => _download(edition),
                      onCancel: () => _cancel(edition),
                      onDelete: () => _confirmDelete(edition),
                    ),
                  ),
                const SizedBox(height: AppSpace.xs),
                const _AuthenticityFootnoteCard(),
              ],
            ),
    );
  }
}

/// Hero overview header displaying the scholarly title and live status metrics.
class _RiwayatOverviewHeader extends StatelessWidget {
  final String currentEdition;
  final int installedCount;
  final String totalStorageMb;

  const _RiwayatOverviewHeader({
    required this.currentEdition,
    required this.installedCount,
    required this.totalStorageMb,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    final activeEdition = QuranRiwayahId.values.firstWhere(
      (e) => e.wireValue == currentEdition,
      orElse: () => QuranRiwayahId.hafs,
    );

    return AppCard(
      padding: const EdgeInsetsDirectional.all(AppSpace.lg),
      color: palette.surface,
      borderRadius: AppRadius.lgRadius,
      border: Border.all(
        color: palette.border.withValues(alpha: 0.7),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: AppSize.tap,
                height: AppSize.tap,
                decoration: BoxDecoration(
                  color: palette.goldSoft,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: palette.gold.withValues(alpha: 0.35),
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.auto_stories_rounded,
                  color: palette.gold,
                  size: AppIcon.md,
                ),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الروايات القرآنية المتواترة',
                      style: textTheme.titleSmall.copyWith(
                        color: palette.text,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpace.xxs),
                    Text(
                      'القراءات العشر المتواترة المنقولة بالأسانيد المتصلة',
                      style: textTheme.caption.copyWith(
                        color: palette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          Text(
            'اختر الرواية التي تريد تلاوتها. بعد تنزيل حزمة الرواية، يمكنك قراءتها والبحث فيها بالكامل دون اتصال بالإنترنت.',
            style: textTheme.bodySmall.copyWith(
              color: palette.textMuted,
            ),
          ),
          const SizedBox(height: AppSpace.md),
          Divider(
            height: 1,
            thickness: 1,
            color: palette.border.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpace.md),
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.xs,
            children: [
              _MetricPill(
                icon: Icons.check_circle_rounded,
                iconColor: palette.gold,
                label: 'الرواية النشطة',
                value: activeEdition.nameArabic,
              ),
              _MetricPill(
                icon: Icons.download_done_rounded,
                iconColor: palette.primary,
                label: 'المثبتة',
                value: '$installedCount من 3',
              ),
              _MetricPill(
                icon: Icons.sd_storage_rounded,
                iconColor: palette.textMuted,
                label: 'المساحة المستخدمة',
                value: '$totalStorageMb م.ب',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A compact metric chip used in the overview header.
class _MetricPill extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _MetricPill({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpace.sm,
        vertical: AppSpace.xs,
      ),
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: AppRadius.smRadius,
        border: Border.all(
          color: palette.border.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppIcon.sm, color: iconColor),
          const SizedBox(width: AppSpace.xs),
          Text(
            '$label: ',
            style: textTheme.caption.copyWith(
              color: palette.textMuted,
            ),
          ),
          Text(
            value,
            style: textTheme.caption.copyWith(
              color: palette.text,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Scholarly footnote detailing the official digital Uthmani typography and verification provenance.
class _AuthenticityFootnoteCard extends StatelessWidget {
  const _AuthenticityFootnoteCard();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return Container(
      padding: const EdgeInsetsDirectional.all(AppSpace.md),
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: AppRadius.mdRadius,
        border: Border.all(color: palette.border.withValues(alpha: 0.7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.verified_user_outlined,
            size: AppIcon.md,
            color: palette.gold,
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'التوثيق الرقمي والرسم العثماني',
                  style: textTheme.caption.copyWith(
                    color: palette.text,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpace.xxs),
                Text(
                  'تعتمد الروايات على الخطوط الرقمية المعتمدة الصادرة عن مجمع الملك فهد لطباعة المصحف الشريف، مع توثيق وضبط فواصل الآيات ومواضع الأحزاب وبصمة تحقق رقمية (SHA-256).',
                  style: textTheme.caption.copyWith(
                    color: palette.textMuted,
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
