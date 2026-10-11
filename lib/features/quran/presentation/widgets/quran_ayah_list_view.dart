  import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quran/quran.dart' as quran;

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../data/services/bookmark_service.dart';
import '../../data/services/quran_audio_service.dart';
import '../../data/services/tajweed_service.dart';
import 'ayah_details_sheet.dart';

/// High-performance continuous Ayah List View (Mode B)
///
/// Features:
/// - Lazy rendering via [ListView.builder]
/// - Authentic Surah header banner & Basmalah
/// - Color-coded Tajweed text spans or pure Uthmanic Arabic
/// - Optional translation display per ayah
/// - Audio playback highlight with auto-scroll
/// - Quick actions: Listen, Tafsir, Bookmark, Copy/Share
class QuranAyahListView extends StatefulWidget {
  final int surahNumber;
  final bool isTajweedEnabled;
  final bool showTranslation;
  final double fontSize;
  final int? initialAyah;
  final void Function(int surah, int ayah)? onAyahTap;

  const QuranAyahListView({
    super.key,
    required this.surahNumber,
    this.isTajweedEnabled = true,
    this.showTranslation = false,
    this.fontSize = 24.0,
    this.initialAyah,
    this.onAyahTap,
  });

  @override
  State<QuranAyahListView> createState() => _QuranAyahListViewState();
}

class _QuranAyahListViewState extends State<QuranAyahListView> {
  final ScrollController _scrollController = ScrollController();
  final QuranAudioService _audioService = QuranAudioService();
  final Set<int> _bookmarkedAyahs = {};

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
    _audioService.activeAyahNotifier.addListener(_handleAudioAyahChange);

    if (widget.initialAyah != null && widget.initialAyah! > 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToAyah(widget.initialAyah!);
      });
    }
  }

  @override
  void didUpdateWidget(covariant QuranAyahListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.surahNumber != widget.surahNumber) {
      _loadBookmarks();
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    }
  }

  @override
  void dispose() {
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
        if (b.surah == widget.surahNumber) {
          _bookmarkedAyahs.add(b.ayah);
        }
      }
    });
  }

  void _handleAudioAyahChange() {
    final activeSurah = _audioService.activeSurahNotifier.value;
    final activeAyah = _audioService.activeAyahNotifier.value;
    if (activeSurah == widget.surahNumber && activeAyah != null) {
      _scrollToAyah(activeAyah);
    }
  }

  void _scrollToAyah(int ayah) {
    if (!_scrollController.hasClients) return;
    // Estimated offset per ayah card
    final targetOffset = (ayah - 1) * 140.0;
    _scrollController.animateTo(
      targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: AppMotion.slow,
      curve: Curves.easeInOut,
    );
  }

  Future<void> _toggleBookmark(int ayah) async {
    HapticFeedback.selectionClick();
    final isAdded = await BookmarkService.toggleBookmark(widget.surahNumber, ayah);
    if (!mounted) return;
    setState(() {
      if (isAdded) {
        _bookmarkedAyahs.add(ayah);
      } else {
        _bookmarkedAyahs.remove(ayah);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    final totalVerses = quran.getVerseCount(widget.surahNumber);
    final surahName = quran.getSurahNameArabic(widget.surahNumber);
    final isMakki = quran.getPlaceOfRevelation(widget.surahNumber) == 'Makkah';

    // 0: Header banner, 1: Basmalah (if applicable), then Verses
    final hasBasmalah = widget.surahNumber != 9 && widget.surahNumber != 1;
    final headerItemCount = hasBasmalah ? 2 : 1;

    return ValueListenableBuilder<int?>(
      valueListenable: _audioService.activeAyahNotifier,
      builder: (context, activeAyah, _) {
        final activeSurah = _audioService.activeSurahNotifier.value;
        final isSurahActive = activeSurah == widget.surahNumber;

        return ListView.builder(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsetsDirectional.only(
            start: AppSpace.md,
            end: AppSpace.md,
            top: AppSpace.sm,
            bottom: AppSize.navClearance(context) + AppSpace.xl,
          ),
          itemCount: headerItemCount + totalVerses,
          itemBuilder: (context, index) {
            // Header Banner
            if (index == 0) {
              return _buildSurahBanner(palette, textTheme, surahName, totalVerses, isMakki);
            }

            // Basmalah Banner
            if (hasBasmalah && index == 1) {
              return _buildBasmalah(palette, textTheme);
            }

            // Verses (1-indexed)
            final verseIndex = index - headerItemCount + 1;
            final isPlaying = isSurahActive && activeAyah == verseIndex;
            final isBookmarked = _bookmarkedAyahs.contains(verseIndex);

            return _buildAyahCard(
              context: context,
              palette: palette,
              textTheme: textTheme,
              ayahNumber: verseIndex,
              isPlaying: isPlaying,
              isBookmarked: isBookmarked,
            );
          },
        );
      },
    );
  }

  Widget _buildSurahBanner(
    AppPalette palette,
    AppTextTheme textTheme,
    String surahName,
    int totalVerses,
    bool isMakki,
  ) {
    return Container(
      margin: const EdgeInsetsDirectional.only(bottom: AppSpace.md),
      padding: const EdgeInsetsDirectional.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: palette.surfaceRaised,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(color: palette.gold.withValues(alpha: 0.35)),
        boxShadow: palette.shadow,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 28,
                height: 1,
                color: palette.gold.withValues(alpha: 0.5),
              ),
              const SizedBox(width: AppSpace.sm),
              Icon(
                Icons.auto_stories_rounded,
                color: palette.gold,
                size: AppIcon.sm,
              ),
              const SizedBox(width: AppSpace.sm),
              Container(
                width: 28,
                height: 1,
                color: palette.gold.withValues(alpha: 0.5),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            'سورة $surahName',
            style: textTheme.sacred.copyWith(
              color: palette.text,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpace.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpace.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: palette.surfaceMuted,
                  borderRadius: AppRadius.pillRadius,
                  border: Border.all(color: palette.border),
                ),
                child: Text(
                  isMakki ? 'مكية' : 'مدنية',
                  style: textTheme.caption.copyWith(
                    color: palette.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              Text(
                '•  $totalVerses آية  •',
                style: textTheme.caption.copyWith(
                  color: palette.textMuted,
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              Container(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpace.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: palette.surfaceMuted,
                  borderRadius: AppRadius.pillRadius,
                  border: Border.all(color: palette.border),
                ),
                child: Text(
                  'الصفحة ${quran.getPageNumber(widget.surahNumber, 1)}',
                  style: textTheme.caption.copyWith(
                    color: palette.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBasmalah(AppPalette palette, AppTextTheme textTheme) {
    return Container(
      margin: const EdgeInsetsDirectional.only(bottom: AppSpace.md),
      padding: const EdgeInsetsDirectional.symmetric(vertical: AppSpace.md),
      alignment: AlignmentDirectional.center,
      child: Text(
        quran.basmala,
        style: textTheme.sacredLarge.copyWith(
          color: palette.primary,
          fontSize: widget.fontSize,
        ),
      ),
    );
  }

  Widget _buildAyahCard({
    required BuildContext context,
    required AppPalette palette,
    required AppTextTheme textTheme,
    required int ayahNumber,
    required bool isPlaying,
    required bool isBookmarked,
  }) {
    final verseText = quran.getVerse(
      widget.surahNumber,
      ayahNumber,
      verseEndSymbol: false,
    );
    final hasSajdah = quran.isSajdahVerse(widget.surahNumber, ayahNumber);
    final verseSymbol = quran.getVerseEndSymbol(ayahNumber);

    return Container(
      margin: const EdgeInsetsDirectional.only(bottom: AppSpace.sm),
      decoration: BoxDecoration(
        color: isPlaying ? palette.primarySoft.withValues(alpha: 0.12) : palette.surfaceRaised,
        borderRadius: AppRadius.mdRadius,
        border: Border.all(
          color: isPlaying
              ? palette.primary
              : isBookmarked
                  ? palette.gold.withValues(alpha: 0.5)
                  : palette.border,
          width: isPlaying ? 1.5 : 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppRadius.mdRadius,
          onTap: () {
            if (widget.onAyahTap != null) {
              widget.onAyahTap!(widget.surahNumber, ayahNumber);
            } else {
              AyahDetailsSheet.show(
                context,
                surahNumber: widget.surahNumber,
                ayahNumber: ayahNumber,
                onBookmarkChanged: _loadBookmarks,
              );
            }
          },
          child: Padding(
            padding: const EdgeInsetsDirectional.all(AppSpace.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top control bar
                Row(
                  children: [
                    // Ayah number badge
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isPlaying ? palette.primary : palette.surfaceMuted,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isPlaying ? palette.primary : palette.border,
                        ),
                      ),
                      alignment: AlignmentDirectional.center,
                      child: Text(
                        '$ayahNumber',
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
                          vertical: AppSpace.xs,
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
                    // Play audio button
                    AppIconButton(
                      icon: isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      tooltip: 'استماع',
                      color: isPlaying ? palette.primary : palette.textMuted,
                      onPressed: () {
                        if (isPlaying) {
                          _audioService.pause();
                        } else {
                          _audioService.playVerse(widget.surahNumber, ayahNumber);
                        }
                      },
                    ),
                    // Bookmark button
                    AppIconButton(
                      icon: isBookmarked
                          ? Icons.bookmark_added_rounded
                          : Icons.bookmark_add_outlined,
                      tooltip: 'حفظ العلامة',
                      color: isBookmarked ? palette.gold : palette.textMuted,
                      onPressed: () => _toggleBookmark(ayahNumber),
                    ),
                    // Tafsir & details sheet button
                    AppIconButton(
                      icon: Icons.menu_book_rounded,
                      tooltip: 'التفسير والتدبر',
                      color: palette.textMuted,
                      onPressed: () {
                        AyahDetailsSheet.show(
                          context,
                          surahNumber: widget.surahNumber,
                          ayahNumber: ayahNumber,
                          onBookmarkChanged: _loadBookmarks,
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.xs),

                // Arabic Verse Text
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
                          ...TajweedService.buildTajweedSpans(
                            verseText,
                            baseStyle: textTheme.sacredLarge.copyWith(
                              color: palette.text,
                              fontSize: widget.fontSize,
                              height: 1.8,
                            ),
                            isTajweedEnabled: widget.isTajweedEnabled,
                          ),
                          const TextSpan(text: ' '),
                          TextSpan(
                            text: verseSymbol,
                            style: textTheme.sacredLarge.copyWith(
                              color: palette.gold,
                              fontSize: widget.fontSize * 0.9,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Optional Translation
                if (widget.showTranslation) ...[
                  const SizedBox(height: AppSpace.xs),
                  Divider(height: 1, color: palette.border.withValues(alpha: 0.5)),
                  const SizedBox(height: AppSpace.xs),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      quran.getVerseTranslation(widget.surahNumber, ayahNumber),
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
