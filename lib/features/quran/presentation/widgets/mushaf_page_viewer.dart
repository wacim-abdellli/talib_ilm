import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quran/quran.dart' as quran;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../data/services/reading_stats_service.dart';
import '../../data/services/tajweed_service.dart';
import 'ayah_details_sheet.dart';
import 'mushaf_settings_sheet.dart';
import 'quick_jump_sheet.dart';

class MushafPageViewer extends StatefulWidget {
  final int? initialPage;
  final int? initialSurah;

  const MushafPageViewer({
    super.key,
    this.initialPage,
    this.initialSurah,
  });

  @override
  State<MushafPageViewer> createState() => _MushafPageViewerState();
}

class _MushafPageViewerState extends State<MushafPageViewer> {
  late final PageController _pageController;
  final ReadingStatsService _statsService = ReadingStatsService();

  int _currentPage = 1;
  bool _showOverlays = true;
  bool _isTajweedEnabled = true;
  MushafThemeMode _themeMode = MushafThemeMode.sepia;
  double _fontSize = 22.0;

  int? _selectedAyahSurah;
  int? _selectedAyahNumber;

  late final DateTime _sessionStartTime;
  static const String _kLastPageKey = 'dashboard_last_page';

  @override
  void initState() {
    super.initState();
    _sessionStartTime = DateTime.now();

    int startPage = 1;
    if (widget.initialPage != null) {
      startPage = widget.initialPage!.clamp(1, 604);
    } else if (widget.initialSurah != null) {
      final pages = quran.getSurahPages(widget.initialSurah!);
      if (pages.isNotEmpty) startPage = pages.first.clamp(1, 604);
    }

    _currentPage = startPage;
    _pageController = PageController(initialPage: _currentPage - 1);
    _loadSavedSettings();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _recordStats();
    super.dispose();
  }

  Future<void> _loadSavedSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final tajweed = prefs.getBool('mushaf_tajweed_enabled') ?? true;
    final themeIdx = prefs.getInt('mushaf_theme_mode') ?? 1; // 1 = sepia
    final size = prefs.getDouble('mushaf_font_size') ?? 22.0;

    if (!mounted) return;
    setState(() {
      _isTajweedEnabled = tajweed;
      _themeMode = MushafThemeMode.values[themeIdx.clamp(0, 2)];
      _fontSize = size;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('mushaf_tajweed_enabled', _isTajweedEnabled);
    await prefs.setInt('mushaf_theme_mode', _themeMode.index);
    await prefs.setDouble('mushaf_font_size', _fontSize);
    await prefs.setInt(_kLastPageKey, _currentPage);
  }

  Future<void> _recordStats() async {
    final duration = DateTime.now().difference(_sessionStartTime).inSeconds;
    if (duration > 5) {
      try {
        final pageData = quran.getPageData(_currentPage);
        final surah = pageData.isNotEmpty ? pageData.first['surah'] as int : 1;
        await _statsService.recordSession(
          durationSeconds: duration,
          versesRead: 0,
          surahNumber: surah,
        );
      } catch (_) {}
    }
  }

  void _jumpToPage(int page) {
    HapticFeedback.selectionClick();
    final p = page.clamp(1, 604);
    _pageController.jumpToPage(p - 1);
    setState(() => _currentPage = p);
  }

  void _toggleOverlays() {
    setState(() => _showOverlays = !_showOverlays);
  }

  void _onAyahTapped(int surah, int ayah) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedAyahSurah = surah;
      _selectedAyahNumber = ayah;
    });

    AyahDetailsSheet.show(
      context,
      surahNumber: surah,
      ayahNumber: ayah,
      onBookmarkChanged: () => _loadSavedSettings(),
    );
  }

  Color _getBackgroundColor() {
    switch (_themeMode) {
      case MushafThemeMode.white:
        return MushafColors.whiteBg;
      case MushafThemeMode.sepia:
        return MushafColors.sepiaBg;
      case MushafThemeMode.dark:
        return MushafColors.darkBg;
    }
  }

  Color _getTextColor() {
    switch (_themeMode) {
      case MushafThemeMode.white:
        return MushafColors.whiteText;
      case MushafThemeMode.sepia:
        return MushafColors.sepiaText;
      case MushafThemeMode.dark:
        return MushafColors.darkText;
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final bgColor = _getBackgroundColor();
    final textColor = _getTextColor();

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Stack(
          children: [
            // 1. Interactive PageView
            InkWell(
              onTap: _toggleOverlays,
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              child: PageView.builder(
                controller: _pageController,
                itemCount: 604,
                reverse: true, // Authentic Quran RTL page turning
                onPageChanged: (idx) {
                  final newPage = idx + 1;
                  setState(() => _currentPage = newPage);
                  _saveSettings();
                },
                itemBuilder: (context, idx) {
                  return _buildMushafPage(idx + 1, textColor, palette);
                },
              ),
            ),

            // 2. Top Navigation Overlay Bar
            if (_showOverlays)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildTopOverlay(palette),
              ),

            // 3. Bottom Control Overlay Bar
            if (_showOverlays)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildBottomOverlay(palette),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMushafPage(int pageNumber, Color textColor, AppPalette palette) {
    final pageData = quran.getPageData(pageNumber);
    if (pageData.isEmpty) return const SizedBox.shrink();

    final firstSurahNum = pageData.first['surah'] as int;
    final firstSurahName = quran.getSurahNameArabic(firstSurahNum);
    final juzNum = quran.getJuzNumber(firstSurahNum, pageData.first['start'] as int);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.xs),
      child: Column(
        children: [
          // Header: Surah & Juz
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: AppSpace.xs),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'الجزء $juzNum',
                  style: context.text.caption.copyWith(
                    color: textColor.withValues(alpha: 0.65),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'سورة $firstSurahName',
                  style: context.text.caption.copyWith(
                    color: textColor.withValues(alpha: 0.65),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: textColor.withValues(alpha: 0.15)),
          const SizedBox(height: AppSpace.xs),

          // Main Quran Page Body
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: pageData.map((data) {
                    final surahNum = data['surah'] as int;
                    final startAyah = data['start'] as int;
                    final endAyah = data['end'] as int;
                    final surahName = quran.getSurahNameArabic(surahNum);

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Surah Header Banner (Matching Wahy Screenshot 4)
                        if (startAyah == 1) ...[
                          _buildSurahBanner(surahName, palette),
                          if (surahNum != 1 && surahNum != 9) ...[
                            const SizedBox(height: AppSpace.sm),
                            _buildBasmalah(textColor),
                            const SizedBox(height: AppSpace.sm),
                          ],
                        ],

                        // Rich Verses Block with Tap-to-Inspect
                        _buildVersesBlock(
                          surahNum: surahNum,
                          startAyah: startAyah,
                          endAyah: endAyah,
                          textColor: textColor,
                          palette: palette,
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),

          // Footer: Page Number in Islamic Frame
          const SizedBox(height: AppSpace.xs),
          Divider(height: 1, color: textColor.withValues(alpha: 0.15)),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.md,
                vertical: AppSpace.xs,
              ),
              decoration: BoxDecoration(
                border: Border.all(color: textColor.withValues(alpha: 0.25)),
                borderRadius: AppRadius.pillRadius,
              ),
              child: Text(
                '$pageNumber',
                style: context.text.caption.copyWith(
                  color: textColor.withValues(alpha: 0.75),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSurahBanner(String surahName, AppPalette palette) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppSpace.sm),
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: AppSpace.xs),
      decoration: BoxDecoration(
        color: palette.primary.withValues(alpha: 0.12),
        borderRadius: AppRadius.smRadius,
        border: Border.all(color: palette.primary.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_stories_rounded, size: AppIcon.sm, color: palette.primary),
          const SizedBox(width: AppSpace.sm),
          Text(
            'سورة $surahName',
            style: context.text.sacred.copyWith(
              color: palette.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          Icon(Icons.auto_stories_rounded, size: AppIcon.sm, color: palette.primary),
        ],
      ),
    );
  }

  Widget _buildBasmalah(Color textColor) {
    return Text(
      'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
      textAlign: TextAlign.center,
      style: context.text.sacred.copyWith(
        color: textColor,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildVersesBlock({
    required int surahNum,
    required int startAyah,
    required int endAyah,
    required Color textColor,
    required AppPalette palette,
  }) {
    final spans = <InlineSpan>[];
    final baseTextStyle = context.text.sacredLarge.copyWith(
      fontSize: _fontSize,
      color: textColor,
      height: 2.1,
    );

    for (int ayah = startAyah; ayah <= endAyah; ayah++) {
      final verseText = quran.getVerse(surahNum, ayah, verseEndSymbol: false);
      final isSelected = _selectedAyahSurah == surahNum && _selectedAyahNumber == ayah;

      final ayahSpans = TajweedService.buildTajweedSpans(
        verseText,
        baseStyle: isSelected
            ? baseTextStyle.copyWith(color: palette.primary)
            : baseTextStyle,
        isTajweedEnabled: _isTajweedEnabled,
      );

      // Ayah body
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Material(
            color: isSelected ? palette.primary.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: AppRadius.smRadius,
            child: InkWell(
              onTap: () => _onAyahTapped(surahNum, ayah),
              child: Text.rich(
                TextSpan(children: ayahSpans),
                textAlign: TextAlign.justify,
              ),
            ),
          ),
        ),
      );

      // Ayah end marker ﴿X﴾
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: InkWell(
            onTap: () => _onAyahTapped(surahNum, ayah),
            borderRadius: AppRadius.pillRadius,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs),
              child: Text(
                ' ﴿$ayah﴾ ',
                style: context.text.sacred.copyWith(
                  color: palette.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
      child: Text.rich(
        TextSpan(children: spans),
        textAlign: TextAlign.justify,
        textDirection: TextDirection.rtl,
      ),
    );
  }

  Widget _buildTopOverlay(AppPalette palette) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.xs),
      decoration: BoxDecoration(
        color: palette.surfaceRaised.withValues(alpha: 0.95),
        border: Border(bottom: BorderSide(color: palette.border)),
        boxShadow: palette.shadow,
      ),
      child: Row(
        children: [
          AppIconButton(
            icon: Icons.arrow_back_rounded,
            tooltip: 'رجوع',
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: InkWell(
              onTap: () {
                QuickJumpSheet.show(
                  context,
                  onJumpToPage: _jumpToPage,
                );
              },
              borderRadius: AppRadius.smRadius,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'صفحة $_currentPage من 604',
                      style: context.text.titleSmall.copyWith(
                        color: palette.text,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'انقر للقفز السريع للسور والأجزاء',
                      style: context.text.caption.copyWith(
                        color: palette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AppIconButton(
            icon: _isTajweedEnabled ? Icons.palette_rounded : Icons.palette_outlined,
            tooltip: 'التجويد',
            color: _isTajweedEnabled ? palette.primary : palette.textMuted,
            onPressed: () {
              HapticFeedback.selectionClick();
              setState(() => _isTajweedEnabled = !_isTajweedEnabled);
              _saveSettings();
              AppSnackbar.info(
                context,
                _isTajweedEnabled ? 'تم تفعيل ألوان التجويد' : 'تم إيقاف ألوان التجويد',
              );
            },
          ),
          AppIconButton(
            icon: Icons.tune_rounded,
            tooltip: 'الإعدادات',
            onPressed: () {
              MushafSettingsSheet.show(
                context,
                currentTheme: _themeMode,
                isTajweedEnabled: _isTajweedEnabled,
                fontSize: _fontSize,
                onThemeChanged: (t) {
                  setState(() => _themeMode = t);
                  _saveSettings();
                },
                onTajweedChanged: (tj) {
                  setState(() => _isTajweedEnabled = tj);
                  _saveSettings();
                },
                onFontSizeChanged: (fs) {
                  setState(() => _fontSize = fs);
                  _saveSettings();
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomOverlay(AppPalette palette) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: AppSpace.sm),
      decoration: BoxDecoration(
        color: palette.surfaceRaised.withValues(alpha: 0.95),
        border: Border(top: BorderSide(color: palette.border)),
        boxShadow: palette.shadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Page Scrub Slider
          Row(
            children: [
              Text(
                '$_currentPage',
                style: context.text.caption.copyWith(
                  fontWeight: FontWeight.bold,
                  color: palette.primary,
                ),
              ),
              Expanded(
                child: Slider.adaptive(
                  value: _currentPage.toDouble(),
                  min: 1.0,
                  max: 604.0,
                  activeColor: palette.primary,
                  inactiveColor: palette.border,
                  onChanged: (val) {
                    _jumpToPage(val.round());
                  },
                ),
              ),
              Text(
                '604',
                style: context.text.caption.copyWith(
                  color: palette.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
