import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quran/quran.dart' as quran;

import '../../../app/theme/app_ui.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../data/services/quran_audio_downloader.dart';
import '../data/services/quran_audio_service.dart';
import 'widgets/downloaded_reciters_list_view.dart';
import 'widgets/quran_audio_delete_dialog.dart';
import 'widgets/quran_audio_download_item.dart';
import 'widgets/quran_audio_player_bar.dart';
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
  Map<QuranReciter, List<DownloadedSurahItem>> _downloadedByReciter = {};
  bool _isLoading = false;
  bool _showOnlyDownloaded = false;

  @override
  void initState() {
    super.initState();
    _currentReciter = _audioService.selectedReciter;
    _refreshStorageAndStatus();
  }

  Future<void> _refreshStorageAndStatus({bool showLoading = false}) async {
    if (showLoading && _surahDownloadedStatus.isEmpty) {
      setState(() => _isLoading = true);
    }
    final byReciter = await QuranAudioDownloader.getDownloadedSurahsByReciter();

    int totalBytes = 0;
    for (final list in byReciter.values) {
      for (final item in list) {
        totalBytes += item.bytes;
      }
    }

    final statusMap = <int, bool>{};
    final bytesMap = <int, int>{};

    final currentReciterItems = byReciter[_currentReciter];
    if (currentReciterItems != null) {
      for (final item in currentReciterItems) {
        statusMap[item.surah] = true;
        bytesMap[item.surah] = item.bytes;
      }
    }

    if (mounted) {
      setState(() {
        _totalStorageBytes = totalBytes;
        _downloadedByReciter = byReciter;
        _surahDownloadedStatus.clear();
        _surahDownloadedStatus.addAll(statusMap);
        _surahBytesOnDisk.clear();
        _surahBytesOnDisk.addAll(bytesMap);
        _isLoading = false;
      });
    }
  }

  Future<void> _updateSingleSurahStatus(int surah) async {
    final isDownloaded = await QuranAudioDownloader.isSurahDownloaded(
      surah,
      reciter: _currentReciter,
    );
    final bytes = isDownloaded
        ? await QuranAudioDownloader.getSurahDownloadedBytes(
            surah,
            reciter: _currentReciter,
          )
        : 0;
    final byReciter = await QuranAudioDownloader.getDownloadedSurahsByReciter();

    int totalBytes = 0;
    for (final list in byReciter.values) {
      for (final item in list) {
        totalBytes += item.bytes;
      }
    }

    if (mounted) {
      setState(() {
        _surahDownloadedStatus[surah] = isDownloaded;
        _surahBytesOnDisk[surah] = bytes;
        _totalStorageBytes = totalBytes;
        _downloadedByReciter = byReciter;
      });
    }
  }

  Future<void> _startDownload(int surah) async {
    HapticFeedback.lightImpact();
    _downloader.downloadSurah(
      surah: surah,
      reciter: _currentReciter,
    ).then((_) {
      if (mounted) _updateSingleSurahStatus(surah);
    });
  }

  Future<void> _handlePlayDownloadedSurah(DownloadedSurahItem item) async {
    final isSameSurah = _audioService.activeSurahNotifier.value == item.surah;
    final isSameReciter = _audioService.selectedReciter.id == item.reciter.id;
    if (isSameSurah && isSameReciter) {
      if (_audioService.isPlayingNotifier.value) {
        await _audioService.pause();
      } else {
        await _audioService.resume();
      }
      return;
    }

    setState(() {
      _currentReciter = item.reciter;
      _audioService.setSelectedReciter(item.reciter);
    });
    await _audioService.playFullSurah(
      surah: item.surah,
      reciter: item.reciter,
    );
  }

  Future<void> _confirmDeleteSurah(int surah) async {
    final surahName = quran.getSurahNameArabic(surah);
    final confirmed = await QuranAudioDeleteDialog.show(
      context,
      title: 'حذف تلاوة سورة $surahName',
      content:
          'هل أنت متأكد من حذف الملفات الصوتية الخاصة بسورة $surahName للقارئ ${_currentReciter.name}؟',
    );

    if (confirmed == true) {
      await QuranAudioDownloader.deleteSurahAudio(
        surah,
        reciter: _currentReciter,
      );
      if (mounted) {
        AppSnackbar.success(context, 'تم حذف تلاوة سورة $surahName');
        _updateSingleSurahStatus(surah);
      }
    }
  }

  Future<void> _confirmDeleteDownloadedSurah(DownloadedSurahItem item) async {
    final confirmed = await QuranAudioDeleteDialog.show(
      context,
      title: 'حذف تلاوة سورة ${item.surahName}',
      content:
          'هل أنت متأكد من حذف سورة ${item.surahName} للقارئ ${item.reciter.name}؟',
    );

    if (confirmed == true) {
      await QuranAudioDownloader.deleteSurahAudio(
        item.surah,
        reciter: item.reciter,
      );
      if (mounted) {
        AppSnackbar.success(context, 'تم حذف تلاوة سورة ${item.surahName}');
        _refreshStorageAndStatus(showLoading: false);
      }
    }
  }

  Future<void> _confirmDeleteReciter(QuranReciter reciter) async {
    final confirmed = await QuranAudioDeleteDialog.show(
      context,
      title: 'حذف تلاوات ${reciter.name}',
      content:
          'هل أنت متأكد من حذف كافة السور المحملة للقارئ ${reciter.name}؟',
    );

    if (confirmed == true) {
      await QuranAudioDownloader.deleteReciterAudio(reciter);
      if (mounted) {
        AppSnackbar.success(context, 'تم حذف جميع تلاوات ${reciter.name}');
        _refreshStorageAndStatus(showLoading: false);
      }
    }
  }

  Future<void> _confirmDeleteAll() async {
    final confirmed = await QuranAudioDeleteDialog.show(
      context,
      title: 'حذف جميع التنزيلات الصوتية',
      content:
          'سيتم حذف جميع السور والتلاوات المحملة لكافة القراء وتحرير المساحة التخزينية بالكامل.',
    );

    if (confirmed == true) {
      await QuranAudioDownloader.deleteAllDownloadedAudio();
      if (mounted) {
        AppSnackbar.success(context, 'تم حذف جميع التنزيلات الصوتية بنجاح');
        _refreshStorageAndStatus(showLoading: false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    final downloadedCount =
        _surahDownloadedStatus.values.where((v) => v).length;
    final totalAllDownloadedCount = _downloadedByReciter.values.fold<int>(
      0,
      (sum, list) => sum + list.length,
    );

    final List<int> displaySurahs = List.generate(114, (i) => i + 1);

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
                  _refreshStorageAndStatus(showLoading: true);
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
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Padding(
                              padding: const EdgeInsetsDirectional.symmetric(
                                horizontal: AppSpace.xs,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
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
                                    padding:
                                        const EdgeInsetsDirectional.symmetric(
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
                      ),
                    ),

                    // Tab 2: Downloaded Only (All Reciters)
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
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Padding(
                              padding: const EdgeInsetsDirectional.symmetric(
                                horizontal: AppSpace.xs,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
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
                                    padding:
                                        const EdgeInsetsDirectional.symmetric(
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
                                      '$totalAllDownloadedCount',
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
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Surahs List or Grouped Downloaded Reciters ────────────────
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: palette.primary,
                        strokeWidth: 2,
                      ),
                    )
                  : _showOnlyDownloaded
                      ? DownloadedRecitersListView(
                          downloadedByReciter: _downloadedByReciter,
                          onRefresh: () =>
                              _refreshStorageAndStatus(showLoading: false),
                          onBrowseAll: () =>
                              setState(() => _showOnlyDownloaded = false),
                          onPlaySurah: _handlePlayDownloadedSurah,
                          onDeleteSurah: _confirmDeleteDownloadedSurah,
                          onDeleteReciter: _confirmDeleteReciter,
                        )
                      : AnimatedBuilder(
                          animation: Listenable.merge([
                            _audioService.activeSurahNotifier,
                            _audioService.isPlayingNotifier,
                          ]),
                          builder: (context, _) {
                            return ValueListenableBuilder<
                                Map<String, SurahDownloadProgress>>(
                              valueListenable:
                                  _downloader.downloadProgressNotifier,
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
                                    final surahName =
                                        quran.getSurahNameArabic(surah);
                                    final verseCount =
                                        quran.getVerseCount(surah);
                                    final isDownloaded =
                                        _surahDownloadedStatus[surah] ?? false;
                                    final downloadedBytes =
                                        _surahBytesOnDisk[surah] ?? 0;
                                    final downloadKey =
                                        '${_currentReciter.id}_$surah';
                                    final activeProgress =
                                        progressMap[downloadKey];
                                    final isCurrentPlaying = _audioService
                                                .activeSurahNotifier.value ==
                                            surah &&
                                        _audioService.selectedReciter ==
                                            _currentReciter &&
                                        _audioService.isPlayingNotifier.value;

                                    return QuranAudioDownloadItem(
                                      surah: surah,
                                      surahName: surahName,
                                      verseCount: verseCount,
                                      isDownloaded: isDownloaded,
                                      downloadedBytes: downloadedBytes,
                                      reciter: _currentReciter,
                                      progress: activeProgress,
                                      isPlaying: isCurrentPlaying,
                                      onPlay: isDownloaded
                                          ? () => _handlePlayDownloadedSurah(
                                                DownloadedSurahItem(
                                                  surah: surah,
                                                  reciter: _currentReciter,
                                                  bytes: downloadedBytes,
                                                  surahName: surahName,
                                                  verseCount: verseCount,
                                                ),
                                              )
                                          : null,
                                      onStartDownload: () =>
                                          _startDownload(surah),
                                      onPauseDownload: () =>
                                          _downloader.pauseDownload(
                                        surah,
                                        reciter: _currentReciter,
                                      ),
                                      onCancelDownload: () =>
                                          _downloader.cancelDownload(
                                        surah,
                                        reciter: _currentReciter,
                                      ),
                                      onDelete: () =>
                                          _confirmDeleteSurah(surah),
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AnimatedBuilder(
        animation: Listenable.merge([
          _audioService.activeSurahNotifier,
          _audioService.isPlayingNotifier,
        ]),
        builder: (context, _) {
          final activeSurah = _audioService.activeSurahNotifier.value;
          if (activeSurah == null) return const SizedBox.shrink();
          return SafeArea(
            top: false,
            child: QuranAudioPlayerBar(
              audioService: _audioService,
              onClose: () => _audioService.stop(),
            ),
          );
        },
      ),
    );
  }
}
