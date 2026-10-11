import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quran/quran.dart' as quran;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../../app/theme/app_palette.dart';
import '../../data/services/bookmark_service.dart';
import '../../data/services/quran_audio_service.dart';
import '../../data/services/quran_tafsir_service.dart';
import '../../data/services/reading_stats_service.dart';
import 'ayah_details_sheet.dart';
import 'mushaf_reader_overlays.dart';
import 'mushaf_settings_sheet.dart';
import 'mushaf_single_page.dart';
import 'quran_ayah_list_view.dart';

/// Unified Dual-Mode Quran Reader
///
/// Supports:
/// - Mode A: Authentic 604-page King Fahd Complex Medina Mushaf ([PageviewQuran])
/// - Mode B: Smooth scrolling continuous Ayah list view ([QuranAyahListView])
/// - Seamless switching with synchronized Surah/Ayah position
/// - Floating / Docked Mini Audio Player
/// - Auto-saved last read position
/// - Keep screen awake via WakelockPlus
class MushafPageViewer extends StatefulWidget {
  final int? initialPage;
  final int? initialSurah;
  final int? initialAyah;

  const MushafPageViewer({
    super.key,
    this.initialPage,
    this.initialSurah,
    this.initialAyah,
  });

  @override
  State<MushafPageViewer> createState() => _MushafPageViewerState();
}

class _MushafPageViewerState extends State<MushafPageViewer> {
  late final PageController _pageController;
  final ReadingStatsService _statsService = ReadingStatsService();
  final QuranAudioService _audioService = QuranAudioService();

  int _currentPage = 1;
  int _currentSurah = 1;
  int _currentAyah = 1;

  QuranReadingMode _readingMode = QuranReadingMode.mushafPage;
  MushafThemeMode _themeMode = MushafThemeMode.sepia;
  bool _isTajweedEnabled = true;
  bool _showTranslation = false;
  bool _keepScreenAwake = true;
  double _fontSize = 24.0;
  bool _showOverlays = true;

  late final DateTime _sessionStartTime;
  static const String _kLastPageKey = 'dashboard_last_page';
  static const String _kReadingModeKey = 'mushaf_reading_mode';
  static const String _kTajweedKey = 'mushaf_tajweed_enabled';
  static const String _kThemeModeKey = 'mushaf_theme_mode';
  static const String _kFontSizeKey = 'mushaf_font_size';
  static const String _kTranslationKey = 'mushaf_show_translation';
  static const String _kWakelockKey = 'mushaf_keep_screen_awake';

  @override
  void initState() {
    super.initState();
    _sessionStartTime = DateTime.now();

    int startPage = 1;
    if (widget.initialPage != null) {
      startPage = widget.initialPage!.clamp(1, 604);
      final pageData = quran.getPageData(startPage);
      if (pageData.isNotEmpty) {
        _currentSurah = pageData.first['surah'] as int;
        _currentAyah = pageData.first['start'] as int;
      }
    } else if (widget.initialSurah != null) {
      _currentSurah = widget.initialSurah!.clamp(1, 114);
      _currentAyah = widget.initialAyah ?? 1;
      startPage = quran.getPageNumber(_currentSurah, _currentAyah).clamp(1, 604);
    }

    _currentPage = startPage;
    _pageController = PageController(initialPage: _currentPage - 1);

    _loadSavedSettings();
    _applyWakelock(_keepScreenAwake);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _recordStats();
    if (_keepScreenAwake) {
      WakelockPlus.disable();
    }
    super.dispose();
  }

  Future<void> _loadSavedSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final modeIdx = prefs.getInt(_kReadingModeKey) ?? 0;
    final tajweed = prefs.getBool(_kTajweedKey) ?? true;
    final themeIdx = prefs.getInt(_kThemeModeKey) ?? 1; // 1 = sepia
    final size = prefs.getDouble(_kFontSizeKey) ?? 24.0;
    final trans = prefs.getBool(_kTranslationKey) ?? false;
    final wake = prefs.getBool(_kWakelockKey) ?? true;

    if (!mounted) return;
    setState(() {
      _readingMode = QuranReadingMode.values[modeIdx.clamp(0, 1)];
      _isTajweedEnabled = tajweed;
      _themeMode = MushafThemeMode.values[themeIdx.clamp(0, 2)];
      _fontSize = size;
      _showTranslation = trans;
      _keepScreenAwake = wake;
    });

    _applyWakelock(wake);
  }

  Future<void> _applyWakelock(bool enable) async {
    try {
      if (enable) {
        await WakelockPlus.enable();
      } else {
        await WakelockPlus.disable();
      }
    } catch (_) {}
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kReadingModeKey, _readingMode.index);
    await prefs.setBool(_kTajweedKey, _isTajweedEnabled);
    await prefs.setInt(_kThemeModeKey, _themeMode.index);
    await prefs.setDouble(_kFontSizeKey, _fontSize);
    await prefs.setBool(_kTranslationKey, _showTranslation);
    await prefs.setBool(_kWakelockKey, _keepScreenAwake);
    await prefs.setInt(_kLastPageKey, _currentPage);

    await BookmarkService.saveLastRead(
      surah: _currentSurah,
      ayah: _currentAyah,
      page: _currentPage,
    );
  }

  Future<void> _recordStats() async {
    final duration = DateTime.now().difference(_sessionStartTime).inSeconds;
    if (duration > 5) {
      try {
        await _statsService.recordSession(
          durationSeconds: duration,
          versesRead: 0,
          surahNumber: _currentSurah,
        );
      } catch (_) {}
    }
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
      final pageData = quran.getPageData(page);
      if (pageData.isNotEmpty) {
        _currentSurah = pageData.first['surah'] as int;
        _currentAyah = pageData.first['start'] as int;
      }
    });

    BookmarkService.saveLastRead(
      surah: _currentSurah,
      ayah: _currentAyah,
      page: _currentPage,
    );
  }

  void _jumpToPage(int page) {
    _onPageChanged(page);
    if (_readingMode == QuranReadingMode.mushafPage && _pageController.hasClients) {
      _pageController.jumpToPage(page - 1);
    }
  }

  void _toggleOverlays() {
    setState(() => _showOverlays = !_showOverlays);
  }

  void _openSettings() {
    HapticFeedback.lightImpact();
    MushafSettingsSheet.show(
      context,
      currentTheme: _themeMode,
      currentReadingMode: _readingMode,
      isTajweedEnabled: _isTajweedEnabled,
      showTranslation: _showTranslation,
      keepScreenAwake: _keepScreenAwake,
      fontSize: _fontSize,
      selectedReciter: _audioService.selectedReciter,
      selectedTafsir: TafsirScholar.muyassar,
      onThemeChanged: (mode) {
        setState(() => _themeMode = mode);
        _saveSettings();
      },
      onReadingModeChanged: (mode) {
        setState(() => _readingMode = mode);
        _saveSettings();
      },
      onTajweedChanged: (val) {
        setState(() => _isTajweedEnabled = val);
        _saveSettings();
      },
      onTranslationChanged: (val) {
        setState(() => _showTranslation = val);
        _saveSettings();
      },
      onKeepScreenAwakeChanged: (val) {
        setState(() => _keepScreenAwake = val);
        _applyWakelock(val);
        _saveSettings();
      },
      onFontSizeChanged: (val) {
        setState(() => _fontSize = val);
        _saveSettings();
      },
      onReciterChanged: (r) {
        _audioService.setSelectedReciter(r);
      },
      onTafsirChanged: (_) {},
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

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final bgColor = _getBackgroundColor();

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Main Reader Content
            Positioned.fill(
              child: _readingMode == QuranReadingMode.mushafPage
                  ? _buildMushafPageMode(palette)
                  : _buildAyahListMode(),
            ),

            // Top Bar Overlay
            AnimatedPositioned(
              duration: AppMotion.slow,
              curve: Curves.easeInOut,
              top: _showOverlays ? 0 : -85,
              left: 0,
              right: 0,
              child: MushafReaderTopBar(
                currentSurah: _currentSurah,
                currentPage: _currentPage,
                currentAyah: _currentAyah,
                readingMode: _readingMode,
                onJumpToPage: _jumpToPage,
                onModeChanged: (mode) {
                  setState(() => _readingMode = mode);
                  _saveSettings();
                },
                onOpenSettings: _openSettings,
              ),
            ),

            // Bottom Bar Overlay & Floating Audio Player
            AnimatedPositioned(
              duration: AppMotion.slow,
              curve: Curves.easeInOut,
              bottom: _showOverlays ? 0 : -100,
              left: 0,
              right: 0,
              child: MushafReaderBottomBar(
                currentPage: _currentPage,
                onPageChanged: _jumpToPage,
                audioService: _audioService,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMushafPageMode(AppPalette palette) {
    return ValueListenableBuilder<int?>(
      valueListenable: _audioService.activeAyahNotifier,
      builder: (context, activeAyah, _) {
        final activeSurah = _audioService.activeSurahNotifier.value;

        return Directionality(
          textDirection: TextDirection.rtl,
          child: PageView.builder(
            controller: _pageController,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            itemCount: 604,
            onPageChanged: (index) => _onPageChanged(index + 1),
            itemBuilder: (context, index) {
              final pageNumber = index + 1;
              return MushafSinglePage(
                pageNumber: pageNumber,
                themeMode: _themeMode,
                isTajweedEnabled: _isTajweedEnabled,
                activeSurah: activeSurah,
                activeAyah: activeAyah,
                onAyahTap: (surah, ayah) {
                  HapticFeedback.selectionClick();
                  _currentSurah = surah;
                  _currentAyah = ayah;
                  AyahDetailsSheet.show(
                    context,
                    surahNumber: surah,
                    ayahNumber: ayah,
                  );
                },
                onToggleOverlays: _toggleOverlays,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildAyahListMode() {
    return QuranAyahListView(
      surahNumber: _currentSurah,
      initialAyah: _currentAyah,
      fontSize: _fontSize,
      isTajweedEnabled: _isTajweedEnabled,
      showTranslation: _showTranslation,
      onAyahTap: (surah, ayah) {
        _currentSurah = surah;
        _currentAyah = ayah;
        AyahDetailsSheet.show(
          context,
          surahNumber: surah,
          ayahNumber: ayah,
        );
      },
    );
  }
}
