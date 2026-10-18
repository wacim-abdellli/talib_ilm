import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/app.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_sheet.dart';
import '../../data/catalogs/mutun_audio_catalog.dart';
import '../../data/catalogs/mutun_curriculum_catalog.dart';
import '../../data/models/mutun_models.dart';
import '../../data/services/mutun_audio_service.dart';
import 'mutn_memorization_view.dart';
import 'mutn_paragraph_options_sheet.dart';
import 'mutn_quick_jump_sheet.dart';
import 'mutun_audio_player_hud.dart';
import 'mutun_rosette_icon.dart';
import 'scholarly_reader_hud.dart' show BookPageTapDetector, ScholarlyReaderHud;
import 'shamela_text_highlighter.dart';
import 'shamela_typography_sheet.dart';

/// Authentic Continuous Scholarly Reader for curriculum mutun matching Hafed Mutun.
/// Features continuous text flow, group section headers, instant paragraph seeking on tap,
/// and quick jump navigation with docked audio controls.
class MutnCurriculumReaderView extends StatefulWidget {
  final IlmBook book;
  final MutunCurriculumBook curriculumBook;
  final MutunAudioService audioService;
  final VoidCallback onAddNote;
  final bool showControls;
  final VoidCallback? onToggleControls;
  final bool isBookmarked;
  final VoidCallback? onToggleBookmark;
  final VoidCallback? onShowBookmarks;
  final VoidCallback? onSwitchToFullBook;
  final String? fullBookLabel;
  final Future<void> Function(int page, int total)? onPageChanged;

  const MutnCurriculumReaderView({
    super.key,
    required this.book,
    required this.curriculumBook,
    required this.audioService,
    required this.onAddNote,
    this.showControls = true,
    this.onToggleControls,
    this.isBookmarked = false,
    this.onToggleBookmark,
    this.onShowBookmarks,
    this.onSwitchToFullBook,
    this.fullBookLabel,
    this.onPageChanged,
  });

  @override
  State<MutnCurriculumReaderView> createState() =>
      _MutnCurriculumReaderViewState();
}

class _MutnCurriculumReaderViewState extends State<MutnCurriculumReaderView> {
  late final ScrollController _scrollController;
  final Map<int, GlobalKey> _paragraphKeys = {};

  bool _showAudioBar = false;
  bool _memorizationMode = false;

  // Typography & Surface settings
  double _fontSizeDelta = 2.0;
  String _fontFamily = 'Amiri';
  double _lineHeight = 1.95;
  ShamelaReaderSurface _surface = ShamelaReaderSurface.normal;
  ShamelaAccentColor _accentColor = ShamelaAccentColor.emerald;

  int? _lastAutoScrolledParagraph;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    themeService.addListener(_onThemeChanged);
    widget.audioService.activeParagraphNotifier
        .addListener(_onActiveParagraphChanged);
    _loadPreferences();

    // Prepare global keys for each paragraph
    for (final sec in widget.curriculumBook.sections) {
      for (final p in sec.paragraphs) {
        _paragraphKeys[p.index] = GlobalKey();
      }
    }
  }

  void _onThemeChanged() {
    if (!mounted) return;
    setState(() {
      if (themeService.isDark) {
        _surface = ShamelaReaderSurface.night;
      } else {
        if (_surface == ShamelaReaderSurface.night) {
          _surface = ShamelaReaderSurface.normal;
        }
      }
    });
  }

  void _onActiveParagraphChanged() {
    if (!_showAudioBar) return;
    final active = widget.audioService.activeParagraphNotifier.value;
    if (active == null || active == _lastAutoScrolledParagraph) return;
    if (!widget.audioService.isPlayingNotifier.value) return;

    _lastAutoScrolledParagraph = active;
    _scrollToParagraph(active);
    _recordParagraphProgress(active);
  }

  void _scrollToParagraph(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final key = _paragraphKeys[index];
      final currentCtx = key?.currentContext;
      if (currentCtx != null && currentCtx.mounted) {
        Scrollable.ensureVisible(
          currentCtx,
          duration: AppMotion.slow,
          curve: Curves.easeInOutCubic,
          alignment: 0.22,
        );
      }
    });
  }

  @override
  void dispose() {
    themeService.removeListener(_onThemeChanged);
    widget.audioService.activeParagraphNotifier
        .removeListener(_onActiveParagraphChanged);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _fontSizeDelta = prefs.getDouble('mutn_reader_font_delta') ?? 2.0;
      _fontFamily = prefs.getString('mutn_reader_font_family') ?? 'Amiri';
      _lineHeight = prefs.getDouble('mutn_reader_line_height') ?? 1.95;
      final surfIndex = prefs.getInt('mutn_reader_surface') ?? 0;
      final savedSurface = ShamelaReaderSurface.values[surfIndex.clamp(0, 2)];
      if (themeService.isDark) {
        _surface = ShamelaReaderSurface.night;
      } else {
        _surface = savedSurface == ShamelaReaderSurface.night
            ? ShamelaReaderSurface.normal
            : savedSurface;
      }
      final accIndex = prefs.getInt('shamela_reader_accent') ?? 0;
      _accentColor = ShamelaAccentColor
          .values[accIndex.clamp(0, ShamelaAccentColor.values.length - 1)];
    });

    final savedPara = prefs.getInt('mutn_last_para_${widget.book.id}');
    if (savedPara != null && savedPara > 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToParagraph(savedPara);
      });
    }
  }

  void _recordParagraphProgress(int paraIndex) {
    unawaited(SharedPreferences.getInstance().then((prefs) {
      prefs.setInt('mutn_last_para_${widget.book.id}', paraIndex);
    }));
    final totalParas = widget.curriculumBook.totalParagraphs;
    final totalPages = widget.book.totalPages > 0
        ? widget.book.totalPages
        : (totalParas > 0 ? totalParas : 1);
    final calcPage = totalParas > 0
        ? ((paraIndex / totalParas) * totalPages).ceil().clamp(1, totalPages)
        : paraIndex;
    widget.onPageChanged?.call(calcPage, totalPages);
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('mutn_reader_font_delta', _fontSizeDelta);
    await prefs.setString('mutn_reader_font_family', _fontFamily);
    await prefs.setDouble('mutn_reader_line_height', _lineHeight);
    await prefs.setInt('mutn_reader_surface', _surface.index);
    await prefs.setInt('shamela_reader_accent', _accentColor.index);
  }

  void _openTypographySheet() {
    HapticFeedback.lightImpact();
    AppSheet.show<void>(
      context: context,
      builder: (sheetContext) => ShamelaTypographySheet(
        fontFamily: _fontFamily,
        fontSizeDelta: _fontSizeDelta,
        lineHeight: _lineHeight,
        surface: _surface,
        accentColor: _accentColor,
        onFontFamilyChanged: (font) {
          setState(() => _fontFamily = font);
          _savePreferences();
        },
        onFontSizeChanged: (delta) {
          setState(() => _fontSizeDelta = delta);
          _savePreferences();
        },
        onLineHeightChanged: (lh) {
          setState(() => _lineHeight = lh);
          _savePreferences();
        },
        onSurfaceChanged: (surf) {
          setState(() => _surface = surf);
          _savePreferences();
        },
        onAccentColorChanged: (accent) {
          setState(() => _accentColor = accent);
          _savePreferences();
        },
      ),
    );
  }

  void _openQuickJumpSheet() {
    HapticFeedback.lightImpact();
    AppSheet.show<void>(
      context: context,
      maxHeightFactor: 0.85,
      builder: (sheetContext) => MutunQuickJumpSheet(
        sections: widget.curriculumBook.sections,
        activeParagraph: widget.audioService.activeParagraphNotifier.value,
        onParagraphSelected: (para) {
          _scrollToParagraph(para);
          _recordParagraphProgress(para);
          widget.audioService.seekToParagraph(para, bookId: widget.book.id);
        },
      ),
    );
  }

  void _showParagraphOptions(MutunParagraph para) {
    MutnParagraphOptionsSheet.show(
      context: context,
      paragraph: para,
      book: widget.book,
      audioService: widget.audioService,
      onAddNote: widget.onAddNote,
      onOpenTypography: _openTypographySheet,
      onPlayFromParagraph: (index) {
        setState(() => _showAudioBar = true);
        widget.audioService.seekToParagraph(index, bookId: widget.book.id);
        _scrollToParagraph(index);
        _recordParagraphProgress(index);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    final tokens = MutunThemeColors.getTokens(isDark: palette.isDark);
    final surfaceTokens = ReaderSurfaceColors.getTokens(
      _surface,
      isDark: palette.isDark,
    );

    return Container(
      color: surfaceTokens.bg,
      child: Column(
        children: [
          // ── Scholarly Continuous Reading Feed ─────────────────────
          Expanded(
            child: BookPageTapDetector(
              onTap: () => widget.onToggleControls?.call(),
              child: Scrollbar(
                controller: _scrollController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpace.lg,
                  vertical: AppSpace.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final section in widget.curriculumBook.sections) ...[
                      // Section Divider Header Pill
                      _buildSectionHeader(
                        section: section,
                        surfaceTokens: surfaceTokens,
                        textTheme: textTheme,
                        tokens: tokens,
                      ),

                      const SizedBox(height: AppSpace.md),
                      // Paragraphs in this section
                      for (final para in section.paragraphs) ...[
                        _buildParagraphBlock(
                          para: para,
                          surfaceTokens: surfaceTokens,
                          tokens: tokens,
                          palette: palette,
                          textTheme: textTheme,
                        ),
                        const SizedBox(height: AppSpace.md),
                      ],
                      const SizedBox(height: AppSpace.md),
                    ],

                    // ── End of Memorization Syllabus / Switch to Full Book Banner ──
                    if (widget.onSwitchToFullBook != null)
                      Container(
                        margin: const EdgeInsetsDirectional.only(
                          top: AppSpace.md,
                          bottom: AppSpace.lg,
                        ),
                        padding: const EdgeInsetsDirectional.all(AppSpace.lg),
                        decoration: BoxDecoration(
                          color: surfaceTokens.surfaceRaised,
                          borderRadius: AppRadius.lgRadius,
                          border: Border.all(
                            color: tokens.rosetteGold.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                MutunRosetteIcon(
                                  size: AppIcon.md,
                                  color: tokens.rosetteGold,
                                ),
                                const SizedBox(width: AppSpace.sm),
                                Expanded(
                                  child: Text(
                                    'نهاية متن الحفظ (${widget.curriculumBook.totalParagraphs} فقرة)',
                                    style: textTheme.titleSmall.copyWith(
                                      color: palette.text,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpace.sm),
                            Text(
                              'أتممت بحمد الله مادة الحفظ والتسميع. يمكنك مواصلة القراءة في النسخة الكاملة للكتاب (${widget.fullBookLabel ?? "الكتاب كاملاً"}).',
                              style: textTheme.bodySmall.copyWith(
                                color: palette.textMuted,
                              ),
                            ),
                            const SizedBox(height: AppSpace.md),
                            AppButton(
                              label: widget.fullBookLabel ?? 'قراءة الكتاب كاملاً',
                              icon: Icons.auto_stories_rounded,
                              size: AppButtonSize.md,
                              onPressed: widget.onSwitchToFullBook,
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: AppSpace.xxxl),
                  ],
                ),
              ),
            ),
          ),
        ),

          // ── Bottom Floating Audio Player HUD ──────────────────────
          if (widget.showControls &&
              _showAudioBar &&
              MutunAudioCatalog.hasAudio(widget.book.id))
            MutunAudioPlayerHud(
              audioService: widget.audioService,
              bookId: widget.book.id,
              onOpenQuickJump: _openQuickJumpSheet,
              onClose: () => setState(() => _showAudioBar = false),
            ),

          // ── Consolidated Bottom Scholarly Toolstrip ───────────────
          ScholarlyReaderHud(
            currentPage: 1,
            totalPages: 1,
            showPageNavigation: false,
            isBookmarked: widget.isBookmarked,
            memorizationMode: _memorizationMode,
            showControls: widget.showControls,
            accentColor: _accentColor,
            surface: _surface,
            onPreviousPage: null,
            onNextPage: null,
            onPageIndicatorTap: _openQuickJumpSheet,
            onToggleBookmark: widget.onToggleBookmark ?? () {},
            onShowBookmarks: widget.onShowBookmarks,
            onAddNote: widget.onAddNote,
            onOpenFihris: _openQuickJumpSheet,
            onToggleMemorization: () {
              HapticFeedback.selectionClick();
              setState(() => _memorizationMode = !_memorizationMode);
            },
            onOpenTypography: _openTypographySheet,
            onToggleAudio: MutunAudioCatalog.hasAudio(widget.book.id)
                ? () {
                    HapticFeedback.selectionClick();
                    setState(() => _showAudioBar = !_showAudioBar);
                  }
                : null,
            isAudioActive: _showAudioBar,
            onShare: () {
              HapticFeedback.lightImpact();
              Share.share(
                '${widget.book.title}\n\n'
                '${widget.curriculumBook.sections.first.paragraphs.first.text}\n\n'
                '— تطبيق طالب العلم',
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required MutunSection section,
    required ReaderSurfaceTokens surfaceTokens,
    required AppTextTheme textTheme,
    required MutunThemeTokens tokens,
  }) {
    final isFirstSection = section == widget.curriculumBook.sections.first;

    return Padding(
      padding: EdgeInsetsDirectional.only(
        top: isFirstSection ? AppSpace.xs : AppSpace.xl,
        bottom: AppSpace.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!isFirstSection) ...[
            Divider(
              color: surfaceTokens.border.withValues(alpha: 0.5),
              height: 1,
            ),
            const SizedBox(height: AppSpace.md),
          ],
          Material(
            color: surfaceTokens.surfaceRaised,
            borderRadius: AppRadius.mdRadius,
            child: InkWell(
              borderRadius: AppRadius.mdRadius,
              onTap: () {
                widget.onToggleControls?.call();
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpace.md,
                  vertical: AppSpace.sm,
                ),
                decoration: BoxDecoration(
                  borderRadius: AppRadius.mdRadius,
                  border: Border.all(
                    color: tokens.rosetteGold.withValues(alpha: 0.35),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    MutunRosetteIcon(
                      size: AppIcon.sm,
                      color: tokens.rosetteGold.withValues(alpha: 0.85),
                    ),
                    const SizedBox(width: AppSpace.sm),
                    Flexible(
                      child: Text(
                        section.title,
                        textAlign: TextAlign.center,
                        style: textTheme.titleSmall.copyWith(
                          color: tokens.rosetteGold,
                          fontWeight: FontWeight.bold,
                          fontFamily: _fontFamily,
                          height: 1.35,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpace.sm),
                    MutunRosetteIcon(
                      size: AppIcon.sm,
                      color: tokens.rosetteGold.withValues(alpha: 0.85),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParagraphBlock({
    required MutunParagraph para,
    required ReaderSurfaceTokens surfaceTokens,
    required MutunThemeTokens tokens,
    required AppPalette palette,
    required AppTextTheme textTheme,
  }) {
    final key = _paragraphKeys[para.index];

    return KeyedSubtree(
      key: key,
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          vertical: AppSpace.xs,
          horizontal: AppSpace.xxs,
        ),
        child: InkWell(
          onTap: () {
            _recordParagraphProgress(para.index);
            widget.onToggleControls?.call();
          },
          onLongPress: () {
            _recordParagraphProgress(para.index);
            _showParagraphOptions(para);
          },
          borderRadius: AppRadius.mdRadius,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Clean Dignified Scholarly Text or Memorization Mode ──
              _memorizationMode
                  ? MutnMemorizationView(
                      content: para.text,
                      fontFamily: _fontFamily,
                      fontSizeDelta: _fontSizeDelta,
                      lineHeight: _lineHeight,
                    )
                  : Text.rich(
                      ShamelaTextHighlighter.buildSpans(
                        text: para.text,
                        palette: palette,
                        textTheme: textTheme,
                        fontFamily: _fontFamily,
                        fontSizeDelta: _fontSizeDelta,
                        lineHeight: _lineHeight,
                        accentColor: _accentColor,
                        surface: _surface,
                      ),
                      textAlign: TextAlign.start,
                    ),

              const SizedBox(height: AppSpace.xs),

              // ── Paragraph Number Badge (- 1 -, - 2 - ...) ─────────
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Container(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpace.xs,
                    vertical: AppSpace.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: surfaceTokens.surfaceRaised,
                    borderRadius: AppRadius.pillRadius,
                    border: Border.all(
                      color: surfaceTokens.border.withValues(alpha: 0.6),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    '- ${para.index} -',
                    style: textTheme.caption.copyWith(
                      color: tokens.paragraphNumber,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
