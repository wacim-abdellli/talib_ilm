import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quran/quran.dart' as quran;
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:qcf_quran_plus/qcf_quran_plus.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../data/models/quran_reader_index.dart';
import '../../data/services/bookmark_service.dart';
import '../../data/services/quran_audio_service.dart';
import '../../data/services/quran_reader_preferences.dart';
import '../../data/services/quran_tafsir_service.dart';
import '../../data/services/reading_stats_service.dart';
import 'ayah_details_sheet.dart';
import 'mushaf_reader_overlays.dart';
import 'mushaf_settings_sheet.dart';
import 'mushaf_single_page.dart';
import 'quran_continuous_list_view.dart';

/// Unified Dual-Mode Quran Reader
///
/// Supports:
/// - Mode A: Authentic 604-page King Fahd Complex Medina Mushaf ([MushafSinglePage])
/// - Mode B: Smooth scrolling continuous Ayah list view ([QuranContinuousListView])
/// - Instant 0ms switching with IndexedStack and synchronized position
/// - Floating / Docked Mini Audio Player
/// - Auto-saved last read position (debounced)
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
  final GlobalKey<QuranContinuousListViewState> _continuousListKey = GlobalKey();

  int _currentPage = 1;
  int _currentSurah = 1;
  int _currentAyah = 1;

  late final ValueNotifier<QuranPosition> _positionNotifier;
  Timer? _saveLastReadDebounceTimer;

  QuranReadingMode _readingMode = QuranReadingMode.mushafPage;
  bool _isListModeLoaded = false;
  MushafThemeMode _themeMode = MushafThemeMode.sepia;
  bool _isTajweedEnabled = true;
  bool _showTranslation = false;
  bool _keepScreenAwake = true;
  double _fontSize = 24.0;
  bool _showOverlays = true;
  TafsirScholar _defaultTafsir = TafsirScholar.muyassar;

  late final DateTime _sessionStartTime;

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
    _positionNotifier = ValueNotifier(
      QuranPosition(
        surah: _currentSurah,
        ayah: _currentAyah,
        page: _currentPage,
        juz: quran.getJuzNumber(_currentSurah, _currentAyah),
      ),
    );

    _loadSavedSettings();
    _applyWakelock(_keepScreenAwake);
    QcfFontLoader.preloadPages(_currentPage, radius: 3);
  }

  @override
  void dispose() {
    _saveLastReadDebounceTimer?.cancel();
    BookmarkService.saveLastRead(
      surah: _currentSurah,
      ayah: _currentAyah,
      page: _currentPage,
    );
    _positionNotifier.dispose();
    _pageController.dispose();
    _recordStats();
    if (_keepScreenAwake) {
      WakelockPlus.disable();
    }
    super.dispose();
  }

  void _scheduleSaveLastRead(int surah, int ayah, int page) {
    _saveLastReadDebounceTimer?.cancel();
    _saveLastReadDebounceTimer = Timer(AppMotion.toast, () {
      BookmarkService.saveLastRead(
        surah: surah,
        ayah: ayah,
        page: page,
      );
    });
  }

  Future<void> _loadSavedSettings() async {
    final snapshot = await QuranReaderPreferences.load();

    if (!mounted) return;
    setState(() {
      _readingMode = snapshot.readingMode;
      if (snapshot.readingMode == QuranReadingMode.ayahList) {
        _isListModeLoaded = true;
      }
      _isTajweedEnabled = snapshot.isTajweedEnabled;
      _themeMode = snapshot.themeMode;
      _fontSize = snapshot.fontSize;
      _showTranslation = snapshot.showTranslation;
      _keepScreenAwake = snapshot.keepScreenAwake;
      _defaultTafsir = snapshot.defaultTafsir;
    });

    _audioService.setSelectedReciter(snapshot.reciter);
    _applyWakelock(snapshot.keepScreenAwake);
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
    await Future.wait([
      QuranReaderPreferences.saveReadingMode(_readingMode),
      QuranReaderPreferences.saveTajweedEnabled(_isTajweedEnabled),
      QuranReaderPreferences.saveThemeMode(_themeMode),
      QuranReaderPreferences.saveFontSize(_fontSize),
      QuranReaderPreferences.saveShowTranslation(_showTranslation),
      QuranReaderPreferences.saveKeepScreenAwake(_keepScreenAwake),
      QuranReaderPreferences.saveLastPage(_currentPage),
    ]);

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
    _currentPage = page;
    final pageData = quran.getPageData(page);
    if (pageData.isNotEmpty) {
      _currentSurah = pageData.first['surah'] as int;
      _currentAyah = pageData.first['start'] as int;
    }
    _positionNotifier.value = QuranPosition(
      surah: _currentSurah,
      ayah: _currentAyah,
      page: _currentPage,
      juz: quran.getJuzNumber(_currentSurah, _currentAyah),
    );
    QcfFontLoader.preloadPages(page, radius: 3);
    _scheduleSaveLastRead(_currentSurah, _currentAyah, _currentPage);
  }

  void _setReadingMode(QuranReadingMode mode) {
    if (_readingMode == mode) return;
    final isSwitchingToList = mode == QuranReadingMode.ayahList;
    setState(() {
      _readingMode = mode;
      if (isSwitchingToList) {
        _isListModeLoaded = true;
      }
    });
    if (mode == QuranReadingMode.mushafPage) {
      final page = quran
          .getPageNumber(_currentSurah, _currentAyah)
          .clamp(1, 604);
      _currentPage = page;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(page - 1);
      }
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _continuousListKey.currentState?.jumpToAyah(_currentSurah, _currentAyah);
      });
    }
    _saveSettings();
  }

  void _jumpToPage(int page) {
    _onPageChanged(page);
    if (_readingMode == QuranReadingMode.mushafPage && _pageController.hasClients) {
      _pageController.jumpToPage(page - 1);
    } else if (_readingMode == QuranReadingMode.ayahList) {
      _continuousListKey.currentState?.jumpToPage(page);
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
      selectedTafsir: _defaultTafsir,
      onThemeChanged: (mode) {
        setState(() => _themeMode = mode);
        _saveSettings();
      },
      onReadingModeChanged: (mode) {
        _setReadingMode(mode);
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
        QuranReaderPreferences.saveReciter(r);
      },
      onTafsirChanged: (scholar) {
        setState(() => _defaultTafsir = scholar);
        QuranReaderPreferences.saveTafsirScholar(scholar);
      },
    );
  }

  void _openAyahDetails(int surah, int ayah) {
    _currentSurah = surah;
    _currentAyah = ayah;
    AyahDetailsSheet.show(
      context,
      surahNumber: surah,
      ayahNumber: ayah,
      initialTafsirScholar: _defaultTafsir,
    );
  }

  Color _getBackgroundColor() => MushafColors.bgFor(_themeMode);

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final bgColor = _getBackgroundColor();

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Main Reader Content: Instant 0ms IndexedStack keeping state alive
            Positioned.fill(
              child: IndexedStack(
                index: _readingMode == QuranReadingMode.mushafPage ? 0 : 1,
                children: [
                  _buildMushafPageMode(palette),
                  _isListModeLoaded
                      ? _buildAyahListMode()
                      : const SizedBox.shrink(),
                ],
              ),
            ),

            // Top Bar Overlay
            AnimatedPositioned(
              duration: AppMotion.slow,
              curve: AppMotion.easeOut,
              top: _showOverlays ? 0 : -100,
              left: 0,
              right: 0,
              child: ValueListenableBuilder<QuranPosition>(
                valueListenable: _positionNotifier,
                builder: (context, pos, _) {
                  return MushafReaderTopBar(
                    currentSurah: pos.surah,
                    currentPage: pos.page,
                    currentAyah: pos.ayah,
                    readingMode: _readingMode,
                    themeMode: _themeMode,
                    onJumpToPage: _jumpToPage,
                    onModeChanged: _setReadingMode,
                    onOpenSettings: _openSettings,
                  );
                },
              ),
            ),

            // Bottom Bar Overlay & Floating Audio Player
            AnimatedPositioned(
              duration: AppMotion.slow,
              curve: AppMotion.easeOut,
              bottom: _showOverlays ? 0 : -120,
              left: 0,
              right: 0,
              child: ValueListenableBuilder<QuranPosition>(
                valueListenable: _positionNotifier,
                builder: (context, pos, _) {
                  return MushafReaderBottomBar(
                    currentPage: pos.page,
                    themeMode: _themeMode,
                    onPageChanged: _jumpToPage,
                    audioService: _audioService,
                  );
                },
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
              return RepaintBoundary(
                child: MushafSinglePage(
                  pageNumber: pageNumber,
                  themeMode: _themeMode,
                  isTajweedEnabled: _isTajweedEnabled,
                  fontSize: _fontSize,
                  activeSurah: activeSurah,
                  activeAyah: activeAyah,
                  onAyahTap: (surah, ayah) => _toggleOverlays(),
                  onAyahLongPress: _openAyahDetails,
                  onToggleOverlays: _toggleOverlays,
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildAyahListMode() {
    return QuranContinuousListView(
      key: _continuousListKey,
      initialSurah: _currentSurah,
      initialAyah: _currentAyah,
      fontSize: _fontSize,
      themeMode: _themeMode,
      isTajweedEnabled: _isTajweedEnabled,
      showTranslation: _showTranslation,
      onPositionChanged: (surah, ayah, page) {
        if (_currentSurah == surah && _currentAyah == ayah && _currentPage == page) {
          return;
        }
        _currentSurah = surah;
        _currentAyah = ayah;
        _currentPage = page;
        _positionNotifier.value = QuranPosition(
          surah: surah,
          ayah: ayah,
          page: page,
          juz: quran.getJuzNumber(surah, ayah),
        );
        _scheduleSaveLastRead(surah, ayah, page);
      },
      onAyahTap: (surah, ayah) => _toggleOverlays(),
      onAyahLongPress: _openAyahDetails,
      onToggleOverlays: _toggleOverlays,
    );
  }
}
