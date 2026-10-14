import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quran/quran.dart' as quran;

import '../../../app/theme/app_palette.dart';
import '../../../app/theme/app_ui.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/icon_badge.dart';
import '../data/services/quran_audio_downloader.dart';
import '../data/services/quran_audio_service.dart';

/// Screen for managing offline Holy Quran audio recitations, tracking
/// storage usage, downloading surahs per reciter with pause/resume, and deleting.
class QuranAudioDownloadsPage extends StatefulWidget {
  const QuranAudioDownloadsPage({super.key});

  @override
  State<QuranAudioDownloadsPage> createState() =>
      _QuranAudioDownloadsPageState();
}

class _QuranAudioDownloadsPageState extends State<QuranAudioDownloadsPage> {
  final QuranAudioService _audioService = QuranAudioService();
  final QuranAudioDownloader _downloader = QuranAudioDownloader();

  late QuranReciter _currentReciter;
  int _totalStorageBytes = 0;
  final Map<int, bool> _surahDownloadedStatus = {};
  final Map<int, int> _surahBytesOnDisk = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentReciter = _audioService.selectedReciter;
    _refreshStorageAndStatus();
  }

  Future<void> _refreshStorageAndStatus() async {
    setState(() => _isLoading = true);
    final totalBytes = await QuranAudioDownloader.getTotalStorageUsed();

    final statusMap = <int, bool>{};
    final bytesMap = <int, int>{};

    for (int s = 1; s <= 114; s++) {
      final isDownloaded = await QuranAudioDownloader.isSurahDownloaded(
        s,
        reciter: _currentReciter,
      );
      statusMap[s] = isDownloaded;
      if (isDownloaded) {
        bytesMap[s] = await QuranAudioDownloader.getSurahDownloadedBytes(
          s,
          reciter: _currentReciter,
        );
      }
    }

    if (mounted) {
      setState(() {
        _totalStorageBytes = totalBytes;
        _surahDownloadedStatus.clear();
        _surahDownloadedStatus.addAll(statusMap);
        _surahBytesOnDisk.clear();
        _surahBytesOnDisk.addAll(bytesMap);
        _isLoading = false;
      });
    }
  }

  Future<void> _startDownload(int surah) async {
    HapticFeedback.lightImpact();
    // Start background download
    _downloader.downloadSurah(
      surah: surah,
      reciter: _currentReciter,
    ).then((_) {
      if (mounted) _refreshStorageAndStatus();
    });
  }

  Future<void> _confirmDeleteSurah(int surah) async {
    final surahName = quran.getSurahNameArabic(surah);
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
            'حذف تلاوة سورة $surahName',
            style: textTheme.titleSmall.copyWith(
              color: palette.text,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'هل أنت متأكد من حذف الملفات الصوتية الخاصة بسورة $surahName للقارئ ${_currentReciter.name}؟',
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
              label: 'حذف',
              variant: AppButtonVariant.primary,
              onPressed: () => Navigator.pop(ctx, true),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await QuranAudioDownloader.deleteSurahAudio(
        surah,
        reciter: _currentReciter,
      );
      if (mounted) {
        AppSnackbar.success(context, 'تم حذف تلاوة سورة $surahName');
        _refreshStorageAndStatus();
      }
    }
  }

  Future<void> _confirmDeleteAll() async {
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
            'حذف جميع التنزيلات الصوتية',
            style: textTheme.titleSmall.copyWith(
              color: palette.text,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'سيتم حذف جميع السور والتلاوات المحملة لكافة القراء وتحرير المساحة التخزينية بالكامل.',
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
              label: 'حذف الكل',
              variant: AppButtonVariant.primary,
              onPressed: () => Navigator.pop(ctx, true),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await QuranAudioDownloader.deleteAllDownloadedAudio();
      if (mounted) {
        AppSnackbar.success(context, 'تم حذف جميع التنزيلات الصوتية بنجاح');
        _refreshStorageAndStatus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return Scaffold(
      backgroundColor: palette.bg,
      appBar: AppBar(
        backgroundColor: palette.bg,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'التنزيلات الصوتية',
          style: textTheme.title.copyWith(
            color: palette.text,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_totalStorageBytes > 0)
            IconButton(
              icon: Icon(Icons.delete_sweep_rounded, color: palette.error),
              tooltip: 'حذف جميع التنزيلات',
              onPressed: _confirmDeleteAll,
            ),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            // ── Reciter Selector & Storage Summary Banner ─────────────────
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.md,
                vertical: AppSpace.sm,
              ),
              decoration: BoxDecoration(
                color: palette.surface,
                border: Border(
                  bottom: BorderSide(color: palette.border, width: 1),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const IconBadge(icon: Icons.person_rounded),
                      const SizedBox(width: AppSpace.sm),
                      Expanded(
                        child: Text(
                          'القارئ الحالي:',
                          style: textTheme.body.copyWith(
                            color: palette.textMuted,
                          ),
                        ),
                      ),
                      DropdownButtonHideUnderline(
                        child: DropdownButton<QuranReciter>(
                          value: _currentReciter,
                          dropdownColor: palette.surface,
                          icon: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: palette.primary,
                          ),
                          items: QuranAudioService.reciters.map((r) {
                            return DropdownMenuItem<QuranReciter>(
                              value: r,
                              child: Text(
                                r.name,
                                style: textTheme.label.copyWith(
                                  color: palette.text,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _currentReciter = val);
                              _audioService.setSelectedReciter(val);
                              _refreshStorageAndStatus();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.xs),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.storage_rounded,
                            color: palette.gold,
                          ),
                          const SizedBox(width: AppSpace.xs),
                          Text(
                            'المساحة المستخدمة:',
                            style: textTheme.bodySmall.copyWith(
                              color: palette.textMuted,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        QuranAudioDownloader.formatBytes(_totalStorageBytes),
                        style: textTheme.label.copyWith(
                          color: palette.gold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Surah Download List ───────────────────────────────────────
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: palette.primary,
                        strokeWidth: 2,
                      ),
                    )
                  : ValueListenableBuilder<Map<String, SurahDownloadProgress>>(
                      valueListenable: _downloader.downloadProgressNotifier,
                      builder: (context, progressMap, _) {
                        return ListView.separated(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpace.md,
                            vertical: AppSpace.sm,
                          ),
                          itemCount: 114,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: AppSpace.xs),
                          itemBuilder: (context, index) {
                            final surah = index + 1;
                            final surahName = quran.getSurahNameArabic(surah);
                            final verseCount = quran.getVerseCount(surah);
                            final isDownloaded =
                                _surahDownloadedStatus[surah] ?? false;
                            final downloadedBytes =
                                _surahBytesOnDisk[surah] ?? 0;
                            final downloadKey =
                                '${_currentReciter.id}_$surah';
                            final activeProgress = progressMap[downloadKey];

                            final estMb = QuranAudioDownloader.estimateSurahSizeMb(
                              surah,
                              reciter: _currentReciter,
                            );

                            return AppCard(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpace.md,
                                vertical: AppSpace.sm,
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      // Surah Number Badge
                                      Container(
                                        width: 36,
                                        height: 36,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: palette.surfaceMuted,
                                          borderRadius: AppRadius.smRadius,
                                          border: Border.all(
                                            color: palette.border,
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          '$surah',
                                          style: textTheme.bodySmall.copyWith(
                                            color: palette.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: AppSpace.md),

                                      // Surah Details
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'سورة $surahName',
                                              style: textTheme.titleSmall.copyWith(
                                                color: palette.text,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              '$verseCount آيات • تقديري: ~${estMb.toStringAsFixed(1)} م.ب',
                                              style: textTheme.bodySmall.copyWith(
                                                color: palette.textMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Actions / State
                                      _buildTrailingAction(
                                        context: context,
                                        palette: palette,
                                        textTheme: textTheme,
                                        surah: surah,
                                        isDownloaded: isDownloaded,
                                        downloadedBytes: downloadedBytes,
                                        progress: activeProgress,
                                      ),
                                    ],
                                  ),

                                  // Active Download Progress Bar
                                  if (activeProgress != null &&
                                      (activeProgress.isDownloading ||
                                          activeProgress.isPaused)) ...[
                                    const SizedBox(height: AppSpace.xs),
                                    ClipRRect(
                                      borderRadius: AppRadius.pillRadius,
                                      child: LinearProgressIndicator(
                                        value: activeProgress.progressFraction,
                                        backgroundColor: palette.surfaceMuted,
                                        color: activeProgress.isPaused
                                            ? palette.gold
                                            : palette.primary,
                                        minHeight: 6,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpace.xxs),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          activeProgress.isPaused
                                              ? 'متوقف مؤقتاً'
                                              : 'جارٍ التنزيل: ${activeProgress.downloadedAyahs}/${activeProgress.totalAyahs} آية',
                                          style: textTheme.bodySmall.copyWith(
                                            color: palette.textMuted,
                                          ),
                                        ),
                                        Text(
                                          '${(activeProgress.progressFraction * 100).toInt()}%',
                                          style: textTheme.bodySmall.copyWith(
                                            color: palette.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],

                                  // Error notice
                                  if (activeProgress?.status ==
                                          SurahDownloadStatus.failed &&
                                      activeProgress?.errorMessage !=
                                          null) ...[
                                    const SizedBox(height: AppSpace.xxs),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.info_outline_rounded,
                                          size: AppIcon.xs,
                                          color: palette.error,
                                        ),
                                        const SizedBox(width: AppSpace.xs),
                                        Expanded(
                                          child: Text(
                                            activeProgress!.errorMessage!,
                                            style: textTheme.bodySmall.copyWith(
                                              color: palette.error,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrailingAction({
    required BuildContext context,
    required AppPalette palette,
    required AppTextTheme textTheme,
    required int surah,
    required bool isDownloaded,
    required int downloadedBytes,
    required SurahDownloadProgress? progress,
  }) {
    // 1. Surah is currently downloading
    if (progress != null && progress.isDownloading) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.pause_rounded, color: palette.gold),
            tooltip: 'إيقاف مؤقت',
            onPressed: () => _downloader.pauseDownload(
              surah,
              reciter: _currentReciter,
            ),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, color: palette.error),
            tooltip: 'إلغاء التنزيل',
            onPressed: () => _downloader.cancelDownload(
              surah,
              reciter: _currentReciter,
            ),
          ),
        ],
      );
    }

    // 2. Surah download is paused
    if (progress != null && progress.isPaused) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.play_arrow_rounded, color: palette.primary),
            tooltip: 'استئناف التنزيل',
            onPressed: () => _startDownload(surah),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, color: palette.error),
            tooltip: 'إلغاء التنزيل',
            onPressed: () => _downloader.cancelDownload(
              surah,
              reciter: _currentReciter,
            ),
          ),
        ],
      );
    }

    // 3. Surah is fully downloaded
    if (isDownloaded || progress?.isCompleted == true) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.sm,
              vertical: AppSpace.xxs,
            ),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: AppRadius.pillRadius,
              border: Border.all(color: palette.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_rounded, color: palette.primary),
                const SizedBox(width: AppSpace.xs),
                Text(
                  QuranAudioDownloader.formatBytes(downloadedBytes),
                  style: textTheme.bodySmall.copyWith(
                    color: palette.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.xs),
          IconButton(
            icon: Icon(Icons.delete_outline_rounded, color: palette.error),
            tooltip: 'حذف التلاوة',
            onPressed: () => _confirmDeleteSurah(surah),
          ),
        ],
      );
    }

    // 4. Surah download failed - allow Retry or Cancel
    if (progress != null && progress.status == SurahDownloadStatus.failed) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: palette.primary),
            tooltip: 'إعادة المحاولة',
            onPressed: () => _startDownload(surah),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, color: palette.textMuted),
            tooltip: 'إلغاء التنزيل',
            onPressed: () => _downloader.cancelDownload(
              surah,
              reciter: _currentReciter,
            ),
          ),
        ],
      );
    }

    // 5. Surah is idle (not downloaded)
    return IconButton(
      icon: Icon(Icons.download_rounded, color: palette.primary),
      tooltip: 'تنزيل السورة للاستماع بدون إنترنت',
      onPressed: () => _startDownload(surah),
    );
  }
}
