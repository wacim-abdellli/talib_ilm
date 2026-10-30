import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../data/catalogs/mutun_audio_catalog.dart';
import '../../data/services/mutun_audio_service.dart';
import '../services/book_audio_navigation_helper.dart';

/// Persistent floating Mini Player that docks cleanly above the bottom navigation bar
/// whenever book or matn audio is actively loaded or playing.
///
/// Features:
/// - Appears strictly when audio is active (playing or paused with an active book).
/// - Displays authentic book title, current chapter / مجلس, and sheikh / reciter.
/// - Live micro animated equalizer indicator when playing.
/// - Instant play/pause and stop/dismiss controls with >= 48dp touch targets.
/// - Integrated progress line tracking playback timestamp.
/// - Tapping anywhere on the bar immediately re-opens the exact book reader page
///   at the user's reading position with the audio HUD expanded.
class BookAudioMiniPlayer extends StatefulWidget {
  const BookAudioMiniPlayer({super.key});

  @override
  State<BookAudioMiniPlayer> createState() => _BookAudioMiniPlayerState();
}

class _BookAudioMiniPlayerState extends State<BookAudioMiniPlayer>
    with SingleTickerProviderStateMixin {
  late final MutunAudioService _audioService;
  late final AnimationController _equalizerController;

  @override
  void initState() {
    super.initState();
    _audioService = MutunAudioService();
    _equalizerController = AnimationController(
      vsync: this,
      duration: AppMotion.slow,
    );

    _audioService.isPlayingNotifier.addListener(_syncEqualizer);
    if (_audioService.isPlayingNotifier.value) {
      _equalizerController.repeat(reverse: true);
    }
  }

  void _syncEqualizer() {
    if (!mounted) return;
    if (_audioService.isPlayingNotifier.value) {
      if (!_equalizerController.isAnimating) {
        _equalizerController.repeat(reverse: true);
      }
    } else {
      if (_equalizerController.isAnimating) {
        _equalizerController.stop();
      }
    }
  }

  @override
  void dispose() {
    _audioService.isPlayingNotifier.removeListener(_syncEqualizer);
    _equalizerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _audioService.activeBookIdNotifier,
        _audioService.isPlayingNotifier,
        _audioService.isLoadingNotifier,
        _audioService.selectedReciterNotifier,
        _audioService.activeChapterIndexNotifier,
      ]),
      builder: (context, _) {
        final bookId = _audioService.activeBookIdNotifier.value;
        if (bookId == null) return const SizedBox.shrink();

        final isKeyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
        if (isKeyboardOpen) return const SizedBox.shrink();

        final palette = context.palette;
        final textTheme = context.text;
        final isPlaying = _audioService.isPlayingNotifier.value;
        final isLoading = _audioService.isLoadingNotifier.value;
        final reciter = _audioService.selectedReciterNotifier.value;
        final chapterIndex = _audioService.activeChapterIndexNotifier.value;

        final (title, subtitle) = _resolveTrackDetails(bookId, reciter, chapterIndex);

        return Semantics(
          container: true,
          label: 'مشغل الصوت المصغر: $title للمقرئ ${reciter.name}',
          child: Padding(
            padding: const EdgeInsetsDirectional.only(
              start: AppSize.navMargin,
              end: AppSize.navMargin,
              bottom: AppSpace.xs,
            ),
            child: Material(
              color: palette.surfaceRaised,
              elevation: 4,
              borderRadius: AppRadius.lgRadius,
              child: Container(
                decoration: BoxDecoration(
                  color: palette.surfaceRaised,
                  borderRadius: AppRadius.lgRadius,
                  border: Border.all(
                    color: palette.gold.withValues(alpha: 0.35),
                    width: 1.2,
                  ),
                  boxShadow: palette.shadow,
                ),
                child: ClipRRect(
                  borderRadius: AppRadius.lgRadius,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () => BookAudioNavigationHelper.returnToActiveBook(context),
                        borderRadius: AppRadius.lgRadius,
                        child: Padding(
                          padding: const EdgeInsetsDirectional.only(
                            start: AppSpace.sm,
                            end: AppSpace.xs,
                            top: AppSpace.xs,
                            bottom: AppSpace.xs,
                          ),
                          child: Row(
                            children: [
                              // ── 1. Equalizer / Disc Icon Badge ──────────
                              _buildLeadingBadge(palette, isPlaying),
                              const SizedBox(width: AppSpace.sm),

                              // ── 2. Track Title & Sheikh / Reciter ───────
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: textTheme.bodySmallBold.copyWith(
                                        color: palette.text,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpace.xxs),
                                    Text(
                                      subtitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: textTheme.caption.copyWith(
                                        color: palette.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // ── 3. Play / Pause Control Button ──────────
                              _buildPlayPauseButton(palette, isPlaying, isLoading),

                              // ── 4. Dismiss / Stop Button ────────────────
                              _buildDismissButton(palette),
                            ],
                          ),
                        ),
                      ),

                      // ── 5. Integrated Playback Progress Bar ─────────
                      _buildProgressBar(palette),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLeadingBadge(AppPalette palette, bool isPlaying) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: palette.gold.withValues(alpha: 0.12),
        borderRadius: AppRadius.mdRadius,
        border: Border.all(
          color: palette.gold.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Center(
        child: isPlaying
            ? AnimatedBuilder(
                animation: _equalizerController,
                builder: (context, _) => Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildEqualizerBar(palette, 6 + 10 * _equalizerController.value),
                    const SizedBox(width: AppSpace.xxs),
                    _buildEqualizerBar(palette, 16 - 8 * _equalizerController.value),
                    const SizedBox(width: AppSpace.xxs),
                    _buildEqualizerBar(palette, 8 + 8 * _equalizerController.value),
                  ],
                ),
              )
            : Icon(
                Icons.headphones_rounded,
                color: palette.gold,
                size: AppIcon.md,
              ),
      ),
    );
  }

  Widget _buildEqualizerBar(AppPalette palette, double height) {
    return Container(
      width: 3,
      height: height.clamp(4.0, 18.0),
      decoration: BoxDecoration(
        color: palette.gold,
        borderRadius: AppRadius.smRadius,
      ),
    );
  }

  Widget _buildPlayPauseButton(AppPalette palette, bool isPlaying, bool isLoading) {
    return Semantics(
      button: true,
      label: isPlaying ? 'إيقاف مؤقت' : 'استئناف الاستماع',
      child: Tooltip(
        message: isPlaying ? 'إيقاف مؤقت' : 'استئناف',
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            _audioService.togglePlayPause();
          },
          borderRadius: AppRadius.pillRadius,
          child: Container(
            width: AppSize.tap,
            height: AppSize.tap,
            alignment: Alignment.center,
            child: isLoading
                ? SizedBox(
                    width: AppIcon.md,
                    height: AppIcon.md,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: palette.gold,
                    ),
                  )
                : Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: palette.gold,
                    size: AppIcon.lg,
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildDismissButton(AppPalette palette) {
    return Semantics(
      button: true,
      label: 'إيقاف وإغلاق مشغل الصوت',
      child: Tooltip(
        message: 'إيقاف وإغلاق',
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            _audioService.stop();
          },
          borderRadius: AppRadius.pillRadius,
          child: Container(
            width: AppSize.tap,
            height: AppSize.tap,
            alignment: Alignment.center,
            child: Icon(
              Icons.close_rounded,
              color: palette.textMuted,
              size: AppIcon.md,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(AppPalette palette) {
    return ValueListenableBuilder<Duration>(
      valueListenable: _audioService.positionNotifier,
      builder: (context, pos, _) {
        final dur = _audioService.durationNotifier.value;
        final progress = dur > Duration.zero
            ? (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0)
            : 0.0;

        return SizedBox(
          height: 2.5,
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: palette.border,
            valueColor: AlwaysStoppedAnimation<Color>(palette.gold),
          ),
        );
      },
    );
  }

  (String, String) _resolveTrackDetails(
    String bookId,
    MutunReciter reciter,
    int chapterIndex,
  ) {
    final entry = MutunAudioCatalog.getEntry(bookId);
    final bookTitle = entry?.title ?? 'قراءة الكتاب';
    final chapters = MutunAudioCatalog.getChapters(bookId, reciterId: reciter.id);

    if (chapters != null &&
        chapters.isNotEmpty &&
        chapterIndex >= 0 &&
        chapterIndex < chapters.length) {
      final ch = chapters[chapterIndex];
      final cleanChapter = _cleanChapterTitle(ch.title);
      final fullTitle = cleanChapter.contains(bookTitle) || bookTitle.contains(cleanChapter)
          ? cleanChapter
          : '$bookTitle · $cleanChapter';
      return (fullTitle, reciter.name);
    }

    return (bookTitle, reciter.name);
  }

  String _cleanChapterTitle(String raw) {
    var text = raw.trim();
    text = text.replaceFirst(RegExp(r'^\d+[\.\-\s]+'), '');
    final match = RegExp(r'(المجلس\s+\d+|المجلس\s+[^\s\(\)]+)').firstMatch(text);
    if (match != null) {
      final council = match.group(0)!;
      if (text.startsWith(council)) return text;
      return '$council - $text';
    }
    return text;
  }
}
