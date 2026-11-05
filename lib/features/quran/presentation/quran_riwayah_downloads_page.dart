import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/theme/app_palette.dart';
import '../../../app/theme/app_ui.dart';
import '../../../shared/widgets/primary_app_bar.dart';
import '../data/models/quran_models.dart';
import '../data/services/edition_service.dart';
import '../data/services/quran_pack_install_service.dart';
import 'quran_pack_reader_page.dart';
import 'widgets/mushaf_page_viewer.dart';

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

  @override
  void initState() {
    super.initState();
    _refresh();
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
    return Scaffold(
      backgroundColor: palette.bg,
      appBar: const PrimaryAppBar(title: 'روايات المصحف', showBack: true),
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
                Text(
                  'اختر الرواية التي تريد قراءتها',
                  style: context.text.title.copyWith(color: palette.text),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: AppSpace.xs),
                Text(
                  'بعد تثبيت الرواية يمكنك قراءتها دون اتصال بالإنترنت.',
                  style: context.text.bodySmall.copyWith(
                    color: palette.textMuted,
                  ),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: AppSpace.lg),
                for (final edition in QuranRiwayahId.values)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      bottom: AppSpace.md,
                    ),
                    child: _editionCard(context, edition),
                  ),
                const SizedBox(height: AppSpace.xs),
                Container(
                  padding: const EdgeInsetsDirectional.all(AppSpace.md),
                  decoration: BoxDecoration(
                    color: palette.surfaceMuted,
                    borderRadius: AppRadius.mdRadius,
                    border: Border.all(color: palette.border),
                  ),
                  child: Text(
                    'مصدر بيانات ورش وقالون: نسخة GitHub مجتمعية مثبتة ببصمة تحقق. لم تُقارن هذه النسخة بعد بأرشيف المجمع الرسمي.',
                    style: context.text.caption.copyWith(
                      color: palette.textMuted,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _editionCard(BuildContext context, QuranRiwayahId edition) {
    final palette = context.palette;
    final installed = _installed[edition] ?? false;
    final isCurrent = _currentEdition == edition.wireValue;
    final progress = _progress[edition];
    final isDownloading = _subscriptions.containsKey(edition);
    final pin = QuranPackInstallService.sourcePin(edition);
    final data = pin['data'] as Map<String, dynamic>;
    final font = pin['font'] as Map<String, dynamic>;
    final transferBytes = (data['bytes'] as int) + (font['bytes'] as int);
    final transferMb = transferBytes / (1024 * 1024);

    return Container(
      padding: const EdgeInsetsDirectional.all(AppSpace.md),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(
          color: isCurrent ? palette.gold : palette.border,
          width: isCurrent ? 1.5 : 1,
        ),
        boxShadow: palette.shadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.menu_book_rounded, color: palette.gold),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      edition.nameArabic,
                      style: context.text.title.copyWith(
                        color: palette.text,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      edition.nameEnglish,
                      textDirection: TextDirection.ltr,
                      style: context.text.caption.copyWith(
                        color: palette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (isCurrent)
                Container(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpace.sm,
                    vertical: AppSpace.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: palette.goldSoft,
                    borderRadius: AppRadius.pillRadius,
                  ),
                  child: Text(
                    'المستخدمة',
                    style: context.text.caption.copyWith(color: palette.gold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            edition == QuranRiwayahId.hafs
                ? 'متاحة حالياً ضمن التطبيق'
                : installed
                ? 'مثبتة على الجهاز • الحجم ${((_storageBytes[edition] ?? 0) / (1024 * 1024)).toStringAsFixed(2)} م.ب'
                : 'حجم التنزيل ${transferMb.toStringAsFixed(2)} م.ب • تعمل دون اتصال بعد التثبيت',
            style: context.text.bodySmall.copyWith(color: palette.textMuted),
            textAlign: TextAlign.right,
          ),
          if (isDownloading && progress != null) ...[
            const SizedBox(height: AppSpace.sm),
            LinearProgressIndicator(
              value: progress.totalBytes == null
                  ? null
                  : progress.progress.clamp(0, 1),
              color: palette.gold,
              backgroundColor: palette.surfaceMuted,
            ),
            const SizedBox(height: AppSpace.xs),
            Text(
              progress.status,
              style: context.text.caption.copyWith(color: palette.textMuted),
              textAlign: TextAlign.right,
            ),
          ],
          const SizedBox(height: AppSpace.md),
          if (isDownloading)
            OutlinedButton.icon(
              onPressed: () => _cancel(edition),
              icon: const Icon(Icons.close_rounded),
              label: const Text('إلغاء التنزيل'),
            )
          else if (edition == QuranRiwayahId.hafs)
            FilledButton.icon(
              onPressed: () => _use(edition),
              icon: const Icon(Icons.menu_book_rounded),
              label: const Text('قراءة حفص'),
            )
          else if (installed)
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _use(edition),
                    icon: const Icon(Icons.menu_book_rounded),
                    label: Text(
                      isCurrent ? 'متابعة القراءة' : 'استخدام الرواية',
                    ),
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                IconButton(
                  tooltip: 'حذف الرواية من الجهاز',
                  onPressed: () => _delete(edition),
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: palette.error,
                  ),
                ),
              ],
            )
          else
            FilledButton.icon(
              onPressed: () => _download(edition),
              icon: const Icon(Icons.download_rounded),
              label: Text('تنزيل • ${transferMb.toStringAsFixed(2)} م.ب'),
            ),
        ],
      ),
    );
  }
}
