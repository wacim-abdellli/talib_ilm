import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quran/quran.dart' as quran;

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../data/models/quran_reader_index.dart';
import '../../data/services/bookmark_service.dart';
import '../../data/services/quran_audio_service.dart';
import '../../data/services/tajweed_service.dart';
import '../../data/services/tajweed_verse_service.dart';
import 'ayah_details_sheet.dart';
import 'quran_section_header.dart';

/// Gold-standard continuous vertical reader for all 6,236 verses across 114 Surahs (Mode B).
///
/// Features:
/// - Single seamless scroll across all Surahs without stopping or manual selection
/// - Medina-style Surah header banners, calligraphic Basmalah, and Juz entry dividers
/// - 6-rule Tajweed letter coloring with surah-scoped lazy memory caching
/// - Position sync with Mode A (Surah, Ayah, Page)
/// - Audio recitation highlight with auto-scroll
/// - Resilient to text scaling up to 2.0x without RenderFlex overflows
class QuranContinuousListView extends StatefulWidget {
  final int initialSurah;
  final int initialAyah;
  final bool isTajweedEnabled;
  final bool showTranslation;
  final double fontSize;
  final MushafThemeMode themeMode;
  final void Function(int surah, int ayah, int page)? onPositionChanged;
  final void Function(int surah, int ayah)? onAyahTap;
  final VoidCallback? onToggleOverlays;

  const QuranContinuousListView({
    super.key,
    this.initialSurah = 1,
    this.initialAyah = 1,
    this.isTajweedEnabled = true,
    this.showTranslation = false,
    this.fontSize = 24.0,
    this.themeMode = MushafThemeMode.white,
    this.onPositionChanged,
    this.onAyahTap,
    this.onToggleOverlays,
  });

  @override
  State<QuranContinuousListView> createState() => QuranContinuousListViewState();
}

class QuranContinuousListViewState extends State<QuranContinuousListView> {
  late final ScrollController _scrollController;
  final QuranReaderIndex _index = QuranReaderIndex.instance;
  final QuranAudioService _audioService = QuranAudioService();

  final Set<String> _bookmarkedAyahs = {};
  final Map<int, Map<int, String>> _tajweedMarkups = {};
  final Set<int> _prefetchedSurahs = {};

  Timer? _debounceTimer;
  int _lastReportedSurah = -1;
  int _lastReportedAyah = -1;
  double _lastCheckedOffset = -1.0;
  int _lastPrefetchedSurah = -1;

  @override
  void initState() {
    super.initState();
    final rawOffset = _index.offsetForAyah(
          widget.initialSurah,
          widget.initialAyah,
        ) ??
        0.0;
    final initialOffset = (widget.initialAyah > 1 || widget.initialSurah > 1)
        ? (rawOffset - 150.0).clamp(0.0, double.infinity)
        : 0.0;
    _scrollController = ScrollController(initialScrollOffset: initialOffset);

    _loadBookmarks();
    _prefetchTajweed(widget.initialSurah);
    if (widget.initialSurah < 114) {
      _prefetchTajweed(widget.initialSurah + 1);
    }

    _scrollController.addListener(_onScroll);
    _audioService.activeAyahNotifier.addListener(_handleAudioAyahChange);
  }

  @override
  void didUpdateWidget(covariant QuranContinuousListView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.fontSize != widget.fontSize ||
        oldWidget.themeMode != widget.themeMode) {
      TajweedService.clearCache();
    }

    if (!oldWidget.isTajweedEnabled && widget.isTajweedEnabled) {
      _prefetchTajweed(widget.initialSurah);
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _audioService.activeAyahNotifier.removeListener(_handleAudioAyahChange);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadBookmarks() async {
    final bookmarks = await BookmarkService.getBookmarks();
    if (!mounted) return;
    setState(() {
      _bookmarkedAyahs.clear();
      for (final b in bookmarks) {
        _bookmarkedAyahs.add('${b.surah}:${b.ayah}');
      }
    });
  }

  Future<void> _prefetchTajweed(int surah) async {
    if (!widget.isTajweedEnabled || _prefetchedSurahs.contains(surah)) return;
    _prefetchedSurahs.add(surah);

    // Evict distant surahs from memory if cache grows too large
    if (_prefetchedSurahs.length > 8) {
      final distant = _prefetchedSurahs.firstWhere(
        (s) => (s - surah).abs() > 4,
        orElse: () => -1,
      );
      if (distant != -1) {
        _prefetchedSurahs.remove(distant);
        _tajweedMarkups.remove(distant);
      }
    }

    final markups = await TajweedVerseService.getSurahMarkups(surah);
    if (!mounted || markups.isEmpty) return;

    // Only trigger rebuild if surah is currently adjacent or visible
    final currentSurah = _lastPrefetchedSurah;
    if (currentSurah == -1 || (currentSurah - surah).abs() <= 1) {
      setState(() {
        _tajweedMarkups[surah] = markups;
      });
    } else {
      _tajweedMarkups[surah] = markups;
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final offset = _scrollController.offset;

    // Throttle heavy index calculations to at least 50px delta
    if ((offset - _lastCheckedOffset).abs() < 50.0 && _lastCheckedOffset >= 0) {
      return;
    }
    _lastCheckedOffset = offset;

    final itemIndex = _index.indexForOffset(offset);
    final pos = _index.positionAt(itemIndex);

    // Prefetch tajweed only on surah transition
    if (widget.isTajweedEnabled && pos.surah != _lastPrefetchedSurah) {
      _lastPrefetchedSurah = pos.surah;
      _prefetchTajweed(pos.surah);
      if (pos.surah < 114) {
        _prefetchTajweed(pos.surah + 1);
      }
    }

    // Debounced bi-directional sync with reader viewer
    if (pos.surah != _lastReportedSurah || pos.ayah != _lastReportedAyah) {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(AppMotion.debounce, () {
        if (!mounted) return;
        _lastReportedSurah = pos.surah;
        _lastReportedAyah = pos.ayah;
        widget.onPositionChanged?.call(pos.surah, pos.ayah, pos.page);
      });
    }
  }

  void _handleAudioAyahChange() {
    final activeSurah = _audioService.activeSurahNotifier.value;
    final activeAyah = _audioService.activeAyahNotifier.value;
    if (activeSurah != null && activeAyah != null) {
      jumpToAyah(activeSurah, activeAyah, animate: true);
    }
  }

  /// Jump to a specific verse within the continuous stream.
  void jumpToAyah(int surah, int ayah, {bool animate = false}) {
    if (!_scrollController.hasClients) return;
    final rawOffset = _index.offsetForAyah(surah, ayah);
    if (rawOffset == null) return;

    final targetOffset = (ayah > 1 || surah > 1)
        ? (rawOffset - 150.0).clamp(0.0, double.infinity)
        : 0.0;

    if (animate) {
      _scrollController.animateTo(
        targetOffset,
        duration: AppMotion.slow,
        curve: Curves.easeInOut,
      );
    } else {
      _scrollController.jumpTo(targetOffset);
    }
  }

  /// Jump to a specific page within the continuous stream.
  void jumpToPage(int page, {bool animate = false}) {
    final pageData = quran.getPageData(page.clamp(1, 604));
    if (pageData.isEmpty) return;
    final surah = pageData.first['surah'] as int;
    final ayah = pageData.first['start'] as int;
    jumpToAyah(surah, ayah, animate: animate);
  }

  Future<void> _toggleBookmark(int surah, int ayah) async {
    HapticFeedback.selectionClick();
    final isAdded = await BookmarkService.toggleBookmark(surah, ayah);
    if (!mounted) return;
    final key = '$surah:$ayah';
    setState(() {
      if (isAdded) {
        _bookmarkedAyahs.add(key);
      } else {
        _bookmarkedAyahs.remove(key);
      }
    });
  }

  Color _getBackgroundColor() => MushafColors.bgFor(widget.themeMode);

  @override
  Widget build(BuildContext context) {
    final bgColor = _getBackgroundColor();

    return ValueListenableBuilder<int?>(
      valueListenable: _audioService.activeAyahNotifier,
      builder: (context, activeAyah, _) {
        final activeSurah = _audioService.activeSurahNotifier.value;

        return ColoredBox(
          color: bgColor,
          child: ListView.builder(
            controller: _scrollController,
            cacheExtent: 600,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsetsDirectional.only(
              start: AppSpace.md,
              end: AppSpace.md,
              top: AppSpace.sm + 64,
              bottom: AppSize.navClearance(context) + AppSpace.xxl,
            ),
            itemCount: _index.length,
            itemBuilder: (context, index) {
              final item = _index[index];

              switch (item) {
                case QuranReaderSurahHeaderItem header:
                  return MushafSurahBanner(
                    key: ValueKey('surah_header_${header.surahNumber}'),
                    surahNumber: header.surahNumber,
                    themeMode: widget.themeMode,
                  );

                case QuranReaderBasmalahItem basmalah:
                  return QuranBasmalahBanner(
                    key: ValueKey('basmalah_${basmalah.surahNumber}'),
                    themeMode: widget.themeMode,
                    fontSize: widget.fontSize,
                  );

                case QuranReaderJuzHeaderItem juzHeader:
                  return QuranJuzSectionHeader(
                    key: ValueKey(
                      'juz_${juzHeader.juzNumber}_${juzHeader.surahNumber}_${juzHeader.ayahNumber}',
                    ),
                    juzNumber: juzHeader.juzNumber,
                    themeMode: widget.themeMode,
                  );

                case QuranReaderAyahItem ayahItem:
                  final isPlaying = activeSurah == ayahItem.surahNumber &&
                      activeAyah == ayahItem.ayahNumber;
                  final isBookmarked = _bookmarkedAyahs.contains(
                    '${ayahItem.surahNumber}:${ayahItem.ayahNumber}',
                  );
                  final markup = _tajweedMarkups[ayahItem.surahNumber]?[ayahItem.ayahNumber];

                  return RepaintBoundary(
                    key: ValueKey('ayah_${ayahItem.surahNumber}_${ayahItem.ayahNumber}'),
                    child: _ContinuousAyahCard(
                      key: ValueKey('ayah_card_${ayahItem.surahNumber}_${ayahItem.ayahNumber}'),
                      item: ayahItem,
                    themeMode: widget.themeMode,
                    fontSize: widget.fontSize,
                    isTajweedEnabled: widget.isTajweedEnabled,
                    showTranslation: widget.showTranslation,
                    isPlaying: isPlaying,
                    isBookmarked: isBookmarked,
                    tajweedMarkup: markup,
                    onTap: () {
                      if (widget.onAyahTap != null) {
                        widget.onAyahTap!(ayahItem.surahNumber, ayahItem.ayahNumber);
                      } else {
                        AyahDetailsSheet.show(
                          context,
                          surahNumber: ayahItem.surahNumber,
                          ayahNumber: ayahItem.ayahNumber,
                          onBookmarkChanged: _loadBookmarks,
                        );
                      }
                    },
                    onBookmarkToggle: () => _toggleBookmark(
                      ayahItem.surahNumber,
                      ayahItem.ayahNumber,
                    ),
                    onPlayToggle: () {
                      if (isPlaying) {
                        _audioService.pause();
                      } else {
                        _audioService.playVerse(
                          ayahItem.surahNumber,
                          ayahItem.ayahNumber,
                        );
                      }
                    },
                    onOpenDetails: () {
                      AyahDetailsSheet.show(
                        context,
                        surahNumber: ayahItem.surahNumber,
                        ayahNumber: ayahItem.ayahNumber,
                        onBookmarkChanged: _loadBookmarks,
                      );
                    },
                  ),
                );
              }
            },
          ),
        );
      },
    );
  }
}

/// Tokenized verse card inside the continuous stream.
class _ContinuousAyahCard extends StatelessWidget {
  final QuranReaderAyahItem item;
  final MushafThemeMode themeMode;
  final double fontSize;
  final bool isTajweedEnabled;
  final bool showTranslation;
  final bool isPlaying;
  final bool isBookmarked;
  final String? tajweedMarkup;
  final VoidCallback onTap;
  final VoidCallback onBookmarkToggle;
  final VoidCallback onPlayToggle;
  final VoidCallback onOpenDetails;

  const _ContinuousAyahCard({
    super.key,
    required this.item,
    required this.themeMode,
    required this.fontSize,
    required this.isTajweedEnabled,
    required this.showTranslation,
    required this.isPlaying,
    required this.isBookmarked,
    required this.tajweedMarkup,
    required this.onTap,
    required this.onBookmarkToggle,
    required this.onPlayToggle,
    required this.onOpenDetails,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    final verseText = quran.getVerse(
      item.surahNumber,
      item.ayahNumber,
      verseEndSymbol: false,
    );
    final hasSajdah = quran.isSajdahVerse(item.surahNumber, item.ayahNumber);
    final verseSymbol = '\uFD3E${item.ayahNumber}\uFD3F';

    final cardBg = isPlaying
        ? palette.primarySoft.withValues(alpha: 0.14)
        : palette.surfaceRaised;

    final borderColor = isPlaying
        ? palette.primary
        : isBookmarked
            ? palette.gold.withValues(alpha: 0.5)
            : palette.border;

    return Container(
      margin: const EdgeInsetsDirectional.only(bottom: AppSpace.sm),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: AppRadius.mdRadius,
        border: Border.all(
          color: borderColor,
          width: isPlaying ? 1.5 : 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppRadius.mdRadius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsetsDirectional.all(AppSpace.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top control bar
                Row(
                  children: [
                    // Arabic-Indic Ayah Number Badge
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isPlaying ? palette.primary : palette.surfaceMuted,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isPlaying ? palette.primary : palette.border,
                        ),
                      ),
                      alignment: AlignmentDirectional.center,
                      child: Text(
                        '${item.ayahNumber}',
                        style: textTheme.caption.copyWith(
                          color: isPlaying ? palette.onPrimary : palette.textMuted,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (hasSajdah) ...[
                      const SizedBox(width: AppSpace.xs),
                      Container(
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: AppSpace.xs,
                          vertical: AppSpace.xxs,
                        ),
                        decoration: BoxDecoration(
                          color: palette.goldSoft,
                          borderRadius: AppRadius.pillRadius,
                        ),
                        child: Text(
                          'سجدة',
                          style: textTheme.caption.copyWith(
                            color: palette.gold,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    // Recitation Play / Pause
                    AppIconButton(
                      icon: isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      tooltip: 'استماع للآية',
                      color: isPlaying ? palette.primary : palette.textMuted,
                      onPressed: onPlayToggle,
                    ),
                    // Bookmark toggle
                    AppIconButton(
                      icon: isBookmarked
                          ? Icons.bookmark_added_rounded
                          : Icons.bookmark_add_outlined,
                      tooltip: 'حفظ العلامة',
                      color: isBookmarked ? palette.gold : palette.textMuted,
                      onPressed: onBookmarkToggle,
                    ),
                    // Tafsir & details sheet
                    AppIconButton(
                      icon: Icons.menu_book_rounded,
                      tooltip: 'التفسير والتدبر',
                      color: palette.textMuted,
                      onPressed: onOpenDetails,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.xs),

                // Sacred Arabic Verse Text with Tajweed Coloring
                Padding(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpace.xs,
                    vertical: AppSpace.xs,
                  ),
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: RichText(
                      textAlign: TextAlign.justify,
                      text: TextSpan(
                        children: [
                          ...TajweedService.buildVerseSpans(
                            plainUthmani: verseText,
                            quranComMarkup: tajweedMarkup,
                            baseStyle: textTheme.sacredLarge.copyWith(
                              color: palette.text,
                              fontSize: fontSize,
                              height: 1.8,
                            ),
                            isTajweedEnabled: isTajweedEnabled,
                          ),
                          const TextSpan(text: ' '),
                          TextSpan(
                            text: verseSymbol,
                            style: textTheme.sacredLarge.copyWith(
                              color: palette.gold,
                              fontSize: fontSize * 0.9,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Optional English Translation
                if (showTranslation) ...[
                  const SizedBox(height: AppSpace.xs),
                  Divider(height: 1, color: palette.border.withValues(alpha: 0.5)),
                  const SizedBox(height: AppSpace.xs),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      quran.getVerseTranslation(item.surahNumber, item.ayahNumber),
                      style: textTheme.bodySmall.copyWith(
                        color: palette.textMuted,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
