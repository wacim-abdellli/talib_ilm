import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:quran/quran.dart' as quran;

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../shared/navigation/fade_page_route.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../quran/data/services/quran_audio_downloader.dart';
import '../../../quran/data/services/quran_audio_service.dart';
import '../../../quran/presentation/quran_audio_downloads_page.dart';

class DownloadedSurahItem {
  final int surahNumber;
  final String surahName;
  final int totalAyahs;
  final int bytesOnDisk;

  const DownloadedSurahItem({
    required this.surahNumber,
    required this.surahName,
    required this.totalAyahs,
    required this.bytesOnDisk,
  });
}

/// Tab view presenting offline-ready Quran audio recitations stored on device.
class OfflineQuranAudioTabView extends StatefulWidget {
  final VoidCallback onStorageChanged;

  const OfflineQuranAudioTabView({
    super.key,
    required this.onStorageChanged,
  });

  @override
  State<OfflineQuranAudioTabView> createState() =>
      _OfflineQuranAudioTabViewState();
}

class _OfflineQuranAudioTabViewState extends State<OfflineQuranAudioTabView> {
  final QuranAudioService _audioService = QuranAudioService();

  List<DownloadedSurahItem> _downloadedSurahs = [];
  bool _isLoading = true;
  int _totalBytes = 0;

  @override
  void initState() {
    super.initState();
    _loadDownloadedSurahs();
  }

  Future<void> _loadDownloadedSurahs() async {
    setState(() => _isLoading = true);
    final reciter = _audioService.selectedReciter;
    final list = <DownloadedSurahItem>[];
    int total = 0;

    for (int s = 1; s <= 114; s++) {
      final isDownloaded = await QuranAudioDownloader.isSurahDownloaded(
        s,
        reciter: reciter,
      );
      if (isDownloaded) {
        final bytes = await QuranAudioDownloader.getSurahDownloadedBytes(
          s,
          reciter: reciter,
        );
        total += bytes;
        list.add(
          DownloadedSurahItem(
            surahNumber: s,
            surahName: quran.getSurahNameArabic(s),
            totalAyahs: quran.getVerseCount(s),
            bytesOnDisk: bytes,
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        _downloadedSurahs = list;
        _totalBytes = total;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteSurah(DownloadedSurahItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final palette = ctx.palette;
        final textTheme = ctx.text;
        return AlertDialog(
          backgroundColor: palette.surface,
          title: Text(
            'حذف تلاوة ${item.surahName}',
            style: textTheme.title.copyWith(color: palette.text),
          ),
          content: Text(
            'هل تريد حذف التلاوة الصوتية المحفوظة محلياً لسورة ${item.surahName} (${QuranAudioDownloader.formatBytes(item.bytesOnDisk)}) لتوفير المساحة؟',
            style: textTheme.body.copyWith(color: palette.textMuted),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text('إلغاء', style: textTheme.caption),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(
                'حذف',
                style: textTheme.caption.copyWith(color: palette.error),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      await QuranAudioDownloader.deleteSurahAudio(
        item.surahNumber,
        reciter: _audioService.selectedReciter,
      );
      if (mounted) {
        AppSnackbar.success(
          context,
          'تم حذف تلاوة سورة ${item.surahName} وتوفير المساحة',
        );
        await _loadDownloadedSurahs();
        widget.onStorageChanged();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(palette.primary),
        ),
      );
    }

    if (_downloadedSurahs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsetsDirectional.all(AppSpace.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              EmptyState(
                icon: Icons.headphones_outlined,
                title: 'لا توجد سور صوتية محملة',
                subtitle:
                    'يمكنك تحميل سور القرآن الكريم كاملة للاستماع إليها بجودة عالية في أي وقت بدون إنترنت.',
              ),
              const SizedBox(height: AppSpace.lg),
              ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: AppSize.tap * 3,
                  minHeight: AppSize.tap,
                ),
                child: Material(
                  color: palette.primary,
                  borderRadius: AppRadius.smRadius,
                  child: InkWell(
                    borderRadius: AppRadius.smRadius,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Navigator.push(
                        context,
                        buildFadeRoute(
                          page: const QuranAudioDownloadsPage(),
                        ),
                      ).then((_) => _loadDownloadedSurahs());
                    },
                    child: Padding(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: AppSpace.lg,
                        vertical: AppSpace.sm,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.download_rounded,
                            color: palette.bg,
                            size: AppIcon.sm,
                          ),
                          const SizedBox(width: AppSpace.xs),
                          Text(
                            'تنزيل سور القرآن',
                            style: textTheme.caption.copyWith(
                              color: palette.bg,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpace.lg,
          AppSpace.md,
          AppSpace.lg,
          AppSpace.xxl,
        ),
        children: [
          // ── Storage and Reciter Header ───────────────────────────────
          Container(
            padding: const EdgeInsetsDirectional.all(AppSpace.md),
            decoration: BoxDecoration(
              color: palette.surfaceRaised,
              borderRadius: AppRadius.mdRadius,
              border: Border.all(color: palette.border),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.folder_special_rounded,
                  color: palette.gold,
                  size: AppIcon.md,
                ),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'القارئ: ${_audioService.selectedReciter.name}',
                        style: textTheme.caption.copyWith(
                          color: palette.text,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${_downloadedSurahs.length} سورة محملة · المساحة: ${QuranAudioDownloader.formatBytes(_totalBytes)}',
                        style: textTheme.caption.copyWith(
                          color: palette.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.add_circle_outline_rounded,
                    color: palette.primary,
                    size: AppIcon.md,
                  ),
                  tooltip: 'تنزيل المزيد من السور',
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    Navigator.push(
                      context,
                      buildFadeRoute(
                        page: const QuranAudioDownloadsPage(),
                      ),
                    ).then((_) {
                      _loadDownloadedSurahs();
                      widget.onStorageChanged();
                    });
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpace.md),

          // ── Downloaded Surah Tiles ──────────────────────────────────
          ..._downloadedSurahs.map((surah) => _buildSurahTile(context, surah)),
        ],
      ),
    );
  }

  Widget _buildSurahTile(BuildContext context, DownloadedSurahItem item) {
    final palette = context.palette;
    final textTheme = context.text;

    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppSpace.xs),
      child: Container(
        decoration: BoxDecoration(
          color: palette.surfaceRaised,
          borderRadius: AppRadius.mdRadius,
          border: Border.all(color: palette.border),
        ),
        padding: const EdgeInsetsDirectional.all(AppSpace.sm),
        child: Row(
          children: [
            Container(
              width: AppSize.tap,
              height: AppSize.tap,
              decoration: BoxDecoration(
                color: palette.primarySoft,
                borderRadius: AppRadius.smRadius,
              ),
              alignment: Alignment.center,
              child: Text(
                '${item.surahNumber}',
                style: textTheme.caption.copyWith(
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
                    item.surahName,
                    style: textTheme.body.copyWith(
                      color: palette.text,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${item.totalAyahs} آية · ${QuranAudioDownloader.formatBytes(item.bytesOnDisk)}',
                    style: textTheme.caption.copyWith(
                      color: palette.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            StreamBuilder<PlayerState>(
              stream: _audioService.playerStateStream,
              builder: (context, snapshot) {
                final isPlaying = snapshot.data?.playing ?? false;
                final isThisSurahPlaying = isPlaying &&
                    _audioService.activeSurahNotifier.value == item.surahNumber;

                return IconButton(
                  icon: Icon(
                    isThisSurahPlaying
                        ? Icons.pause_circle_filled_rounded
                        : Icons.play_circle_fill_rounded,
                    color: isThisSurahPlaying ? palette.gold : palette.primary,
                    size: AppIcon.lg,
                  ),
                  tooltip: isThisSurahPlaying ? 'إيقاف مؤقت' : 'استماع الآن',
                  onPressed: () async {
                    HapticFeedback.selectionClick();
                    if (isThisSurahPlaying) {
                      await _audioService.pause();
                    } else {
                      await _audioService.playFullSurah(
                        surah: item.surahNumber,
                        reciter: _audioService.selectedReciter,
                      );
                    }
                  },
                );
              },
            ),
            IconButton(
              icon: Icon(
                Icons.delete_outline_rounded,
                color: palette.textMuted,
                size: AppIcon.sm,
              ),
              tooltip: 'حذف التلاوة',
              onPressed: () => _deleteSurah(item),
            ),
          ],
        ),
      ),
    );
  }
}
