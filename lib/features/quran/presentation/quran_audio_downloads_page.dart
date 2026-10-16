import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quran/quran.dart' as quran;

import '../../../app/theme/app_ui.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../data/services/quran_audio_downloader.dart';
import '../data/services/quran_audio_service.dart';
import 'widgets/quran_audio_download_item.dart';

/// Screen for managing offline Holy Quran audio recitations, tracking
/// storage usage, downloading surahs per reciter with pause/resume, and offline listening.
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
  bool _showOnlyDownloaded = false;

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

    final downloadedCount =
        _surahDownloadedStatus.values.where((v) => v).length;

    // Filter surahs list based on active tab
    final List<int> displaySurahs = _showOnlyDownloaded
        ? List.generate(114, (i) => i + 1)
            .where((s) => _surahDownloadedStatus[s] == true)
            .toList()
        : List.generate(114, (i) => i + 1);

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
            // ── Reciter Selector & Storage Summary Card ─────────────────
            Padding(
              padding: const EdgeInsetsDirectional.only(
                top: AppSpace.sm,
                start: AppSpace.lg,
                end: AppSpace.lg,
                bottom: AppSpace.xs,
              ),
              child: AppCard(
                padding: const EdgeInsetsDirectional.all(AppSpace.md),
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
                          width: AppUi.iconBoxSize,
                          height: AppUi.iconBoxSize,
                          decoration: BoxDecoration(
                            color: palette.primarySoft,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.record_voice_over_rounded,
                            color: palette.primary,
                            size: AppIcon.md,
                          ),
                        ),
                        const SizedBox(width: AppSpace.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'القارئ الصوتي المختار',
                                style: textTheme.caption.copyWith(
                                  color: palette.textMuted,
                                ),
                              ),
                              DropdownButtonHideUnderline(
                                child: DropdownButton<QuranReciter>(
                                  value: _currentReciter,
                                  isDense: true,
                                  isExpanded: true,
                                  dropdownColor: palette.surface,
                                  icon: Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: palette.primary,
                                    size: AppIcon.md,
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
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpace.sm),
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: palette.border.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: AppSpace.sm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.sd_storage_rounded,
                              size: AppIcon.sm,
                              color: palette.gold,
                            ),
                            const SizedBox(width: AppSpace.xs),
                            Text(
                              'المساحة المستهلكة: ',
                              style: textTheme.caption.copyWith(
                                color: palette.textMuted,
                              ),
                            ),
                            Text(
                              QuranAudioDownloader.formatBytes(_totalStorageBytes),
                              style: textTheme.label.copyWith(
                                color: palette.gold,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (downloadedCount > 0) ...[
                              Text(
                                ' ($downloadedCount سورة)',
                                style: textTheme.caption.copyWith(
                                  color: palette.textMuted,
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (_totalStorageBytes > 0)
                          InkWell(
                            onTap: _confirmDeleteAll,
                            borderRadius: AppRadius.pillRadius,
                            child: Padding(
                              padding: const EdgeInsetsDirectional.symmetric(
                                horizontal: AppSpace.xs,
                                vertical: AppSpace.xxs,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete_sweep_outlined,
                                    size: AppIcon.sm,
                                    color: palette.error,
                                  ),
                                  const SizedBox(width: AppSpace.xxs),
                                  Text(
                                    'تفريغ الكل',
                                    style: textTheme.caption.copyWith(
                                      color: palette.error,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── Segment Filter: All Surahs vs Downloaded Only ─────────────
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpace.lg,
                vertical: AppSpace.xs,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: palette.surfaceMuted,
                  borderRadius: AppRadius.pillRadius,
                  border: Border.all(
                    color: palette.border.withValues(alpha: 0.6),
                  ),
                ),
                padding: const EdgeInsetsDirectional.all(AppSpace.xxs),
                child: Row(
                  children: [
                    // Tab 1: All Surahs
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          if (_showOnlyDownloaded) {
                            HapticFeedback.selectionClick();
                            setState(() => _showOnlyDownloaded = false);
                          }
                        },
                        borderRadius: AppRadius.pillRadius,
                        child: AnimatedContainer(
                          duration: AppMotion.fast,
                          padding: const EdgeInsetsDirectional.symmetric(
                            vertical: AppSpace.sm,
                          ),
                          decoration: BoxDecoration(
                            color: !_showOnlyDownloaded
                                ? palette.surface
                                : Colors.transparent,
                            borderRadius: AppRadius.pillRadius,
                            border: !_showOnlyDownloaded
                                ? Border.all(
                                    color: palette.border.withValues(alpha: 0.5),
                                  )
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'جميع السور',
                                style: textTheme.label.copyWith(
                                  color: !_showOnlyDownloaded
                                      ? palette.primary
                                      : palette.textMuted,
                                  fontWeight: !_showOnlyDownloaded
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              const SizedBox(width: AppSpace.xs),
                              Container(
                                padding: const EdgeInsetsDirectional.symmetric(
                                  horizontal: AppSpace.xs,
                                  vertical: AppSpace.xxs,
                                ),
                                decoration: BoxDecoration(
                                  color: !_showOnlyDownloaded
                                      ? palette.primarySoft
                                      : palette.surface,
                                  borderRadius: AppRadius.pillRadius,
                                ),
                                child: Text(
                                  '114',
                                  style: textTheme.caption.copyWith(
                                    color: !_showOnlyDownloaded
                                        ? palette.primary
                                        : palette.textMuted,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Tab 2: Downloaded Only
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          if (!_showOnlyDownloaded) {
                            HapticFeedback.selectionClick();
                            setState(() => _showOnlyDownloaded = true);
                          }
                        },
                        borderRadius: AppRadius.pillRadius,
                        child: AnimatedContainer(
                          duration: AppMotion.fast,
                          padding: const EdgeInsetsDirectional.symmetric(
                            vertical: AppSpace.sm,
                          ),
                          decoration: BoxDecoration(
                            color: _showOnlyDownloaded
                                ? palette.surface
                                : Colors.transparent,
                            borderRadius: AppRadius.pillRadius,
                            border: _showOnlyDownloaded
                                ? Border.all(
                                    color: palette.border.withValues(alpha: 0.5),
                                  )
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.offline_pin_rounded,
                                size: AppIcon.sm,
                                color: _showOnlyDownloaded
                                    ? palette.primary
                                    : palette.textMuted,
                              ),
                              const SizedBox(width: AppSpace.xs),
                              Text(
                                'المحمّلة فقط',
                                style: textTheme.label.copyWith(
                                  color: _showOnlyDownloaded
                                      ? palette.primary
                                      : palette.textMuted,
                                  fontWeight: _showOnlyDownloaded
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              const SizedBox(width: AppSpace.xs),
                              Container(
                                padding: const EdgeInsetsDirectional.symmetric(
                                  horizontal: AppSpace.xs,
                                  vertical: AppSpace.xxs,
                                ),
                                decoration: BoxDecoration(
                                  color: _showOnlyDownloaded
                                      ? palette.primarySoft
                                      : palette.surface,
                                  borderRadius: AppRadius.pillRadius,
                                ),
                                child: Text(
                                  '$downloadedCount',
                                  style: textTheme.caption.copyWith(
                                    color: _showOnlyDownloaded
                                        ? palette.primary
                                        : palette.textMuted,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Surahs List or Empty State ────────────────────────────────
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: palette.primary,
                        strokeWidth: 2,
                      ),
                    )
                  : _showOnlyDownloaded && displaySurahs.isEmpty
                      ? _buildEmptyDownloadedState(palette, textTheme)
                      : ValueListenableBuilder<Map<String, SurahDownloadProgress>>(
                          valueListenable: _downloader.downloadProgressNotifier,
                          builder: (context, progressMap, _) {
                            return ListView.separated(
                              padding: const EdgeInsetsDirectional.only(
                                start: AppSpace.lg,
                                end: AppSpace.lg,
                                top: AppSpace.xs,
                                bottom: AppSpace.xxl,
                              ),
                              itemCount: displaySurahs.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: AppSpace.sm),
                              itemBuilder: (context, index) {
                                final surah = displaySurahs[index];
                                final surahName = quran.getSurahNameArabic(surah);
                                final verseCount = quran.getVerseCount(surah);
                                final isDownloaded =
                                    _surahDownloadedStatus[surah] ?? false;
                                final downloadedBytes =
                                    _surahBytesOnDisk[surah] ?? 0;
                                final downloadKey =
                                    '${_currentReciter.id}_$surah';
                                final activeProgress = progressMap[downloadKey];

                                return QuranAudioDownloadItem(
                                  surah: surah,
                                  surahName: surahName,
                                  verseCount: verseCount,
                                  isDownloaded: isDownloaded,
                                  downloadedBytes: downloadedBytes,
                                  reciter: _currentReciter,
                                  progress: activeProgress,
                                  onStartDownload: () => _startDownload(surah),
                                  onPauseDownload: () => _downloader.pauseDownload(
                                    surah,
                                    reciter: _currentReciter,
                                  ),
                                  onCancelDownload: () => _downloader.cancelDownload(
                                    surah,
                                    reciter: _currentReciter,
                                  ),
                                  onDelete: () => _confirmDeleteSurah(surah),
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

  Widget _buildEmptyDownloadedState(AppPalette palette, AppTextTheme textTheme) {
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
                setState(() => _showOnlyDownloaded = false);
              },
            ),
          ],
        ),
      ),
    );
  }
}
