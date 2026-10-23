import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quran/quran.dart' as quran;

import '../../../app/theme/app_ui.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../data/services/quran_audio_downloader.dart';
import '../data/services/quran_audio_service.dart';
import 'widgets/empty_downloaded_audio_state.dart';
import 'widgets/quran_audio_download_item.dart';
import 'widgets/quran_audio_storage_header.dart';

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
            QuranAudioStorageHeader(
              currentReciter: _currentReciter,
              reciters: QuranAudioService.reciters,
              onReciterChanged: (val) {
                if (val != null) {
                  setState(() => _currentReciter = val);
                  _audioService.setSelectedReciter(val);
                  _refreshStorageAndStatus();
                }
              },
              totalStorageBytes: _totalStorageBytes,
              downloadedCount: downloadedCount,
              onConfirmDeleteAll: _confirmDeleteAll,
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
                      ? EmptyDownloadedAudioState(
                          onBrowseAll: () {
                            setState(() => _showOnlyDownloaded = false);
                          },
                        )
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
}

