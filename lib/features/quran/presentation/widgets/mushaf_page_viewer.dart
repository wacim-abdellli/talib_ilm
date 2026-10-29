import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quran/quran.dart' as quran;
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:qcf_quran_plus/qcf_quran_plus.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../data/models/quran_reader_index.dart';
import '../../data/services/bookmark_service.dart';
import '../../data/services/quran_audio_service.dart';
import '../../data/services/quran_reader_preferences.dart';
import '../../data/services/quran_tafsir_service.dart';
import '../../data/services/reading_history_service.dart';
import '../../data/services/reading_stats_service.dart';
import 'ayah_action_menu_sheet.dart';
import 'mushaf_reader_overlays.dart';
import 'mushaf_settings_sheet.dart';
import 'mushaf_single_page.dart';

/// Authentic King Fahd Complex 604-Page Medina Mushaf Reader
///
/// Features:
/// - 604 authentic Medina Mushaf pages with Uthmani Tajweed rendering ([MushafSinglePage])
/// - Floating / Docked Mini Audio Player with Surah & Ayah controls
/// - Hold/Long-press interactive Quick Action Menu (Tafsir, Meanings, Repeat, Bookmark, etc.)
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
  int _currentPage = 1;
  int _currentSurah = 1;
  int _currentAyah = 1;

  int? _selectedSurah;
  int? _selectedAyah;
  int? _lastReadSurah;
  int? _lastReadAyah;
  int? _lastReadPage;
  Set<String> _bookmarkedAyahs = {};

  late final ValueNotifier<QuranPosition> _positionNotifier;
  Timer? _saveLastReadDebounceTimer;
  Timer? _preloadDebounceTimer;

  MushafThemeMode _themeMode = MushafThemeMode.sepia;
  bool _isTajweedEnabled = true;
  bool _keepScreenAwake = true;
  bool _showOverlays = true;
  TafsirScholar _defaultTafsir = TafsirScholar.muyassar;
  bool _userExplicitlySelectedTheme = false;
  MushafThemeMode? _lastDefaultMushafTheme;

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
        _currentSurah = widget.initialSurah ?? (pageData.first['surah'] as int);
        _currentAyah = widget.initialAyah ?? (pageData.first['start'] as int);
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
    _reloadLastReadAndBookmarks();
    _applyWakelock(_keepScreenAwake);
    QcfFontLoader.preloadPages(_currentPage, radius: 3);
    _audioService.errorNotifier.addListener(_onAudioError);
    _audioService.activeAyahNotifier.addListener(_onAudioAyahChanged);
  }

  void _onAudioAyahChanged() {
    final surah = _audioService.activeSurahNotifier.value;
    final ayah = _audioService.activeAyahNotifier.value;
    if (surah == null || ayah == null || !mounted) return;

    final targetPage = quran.getPageNumber(surah, ayah);
    if (targetPage != _currentPage) {
      _jumpToPage(targetPage);
    }
  }

  void _onAudioError() {
    final err = _audioService.errorNotifier.value;
    if (err != null && mounted) {
      AppSnackbar.error(context, err.message);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final defaultTheme = context.palette.defaultMushafTheme;
    if (_lastDefaultMushafTheme != defaultTheme) {
      _lastDefaultMushafTheme = defaultTheme;
      if (!_userExplicitlySelectedTheme) {
        if (_themeMode != defaultTheme) {
          _themeMode = defaultTheme;
        }
      }
    }
  }

  @override
  void dispose() {
    _audioService.activeAyahNotifier.removeListener(_onAudioAyahChanged);
    _audioService.errorNotifier.removeListener(_onAudioError);
    _saveLastReadDebounceTimer?.cancel();
    _preloadDebounceTimer?.cancel();

    final surahToSave = (_lastReadPage == _currentPage && _lastReadSurah != null)
        ? _lastReadSurah!
        : _currentSurah;
    final ayahToSave = (_lastReadPage == _currentPage && _lastReadAyah != null)
        ? _lastReadAyah!
        : _currentAyah;

    BookmarkService.saveLastRead(
      surah: surahToSave,
      ayah: ayahToSave,
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
      ReadingHistoryService.recordReading(
        surah: surah,
        ayah: ayah,
        page: page,
      );
    });
  }

  Future<void> _loadSavedSettings() async {
    final snapshot = await QuranReaderPreferences.load();

    if (!mounted) return;
    final defaultTheme = context.palette.defaultMushafTheme;
    setState(() {
      _isTajweedEnabled = snapshot.isTajweedEnabled;
      if (!_userExplicitlySelectedTheme) {
        _themeMode = defaultTheme;
      } else {
        _themeMode = snapshot.themeMode;
      }
      _keepScreenAwake = snapshot.keepScreenAwake;
      _defaultTafsir = snapshot.defaultTafsir;
    });

    _audioService.setSelectedReciter(snapshot.reciter);
    _applyWakelock(snapshot.keepScreenAwake);
  }

  Future<void> _reloadLastReadAndBookmarks() async {
    // hasSavedLastRead and getBookmarks are independent — fire both at once.
    final hasSavedFuture = BookmarkService.hasSavedLastRead();
    final bookmarksFuture = BookmarkService.getBookmarks();
    final hasSaved = await hasSavedFuture;
    final lastRead = hasSaved ? await BookmarkService.getLastRead() : null;
    final bookmarks = await bookmarksFuture;
    if (!mounted) return;
    setState(() {
      _lastReadSurah = lastRead?.surah;
      _lastReadAyah = lastRead?.ayah;
      _lastReadPage = lastRead?.page;
      _bookmarkedAyahs = bookmarks.map((b) => '${b.surah}:${b.ayah}').toSet();
    });
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
      QuranReaderPreferences.saveTajweedEnabled(_isTajweedEnabled),
      QuranReaderPreferences.saveThemeMode(_themeMode),
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
    _preloadDebounceTimer?.cancel();
    _preloadDebounceTimer = Timer(AppMotion.fast, () {
      QcfFontLoader.preloadPages(page, radius: 2);
    });
    _scheduleSaveLastRead(_currentSurah, _currentAyah, _currentPage);
  }

  void _jumpToPage(int page) {
    QcfFontLoader.ensureFontLoaded(page);
    _onPageChanged(page);
    if (_pageController.hasClients) {
      _pageController.jumpToPage(page - 1);
    }
  }

  void _toggleOverlays() {
    setState(() => _showOverlays = !_showOverlays);
  }

  void _toggleTheme() {
    _userExplicitlySelectedTheme = true;
    setState(() {
      _themeMode = switch (_themeMode) {
        MushafThemeMode.dark => MushafThemeMode.sepia,
        MushafThemeMode.sepia => MushafThemeMode.dark,
        MushafThemeMode.white => MushafThemeMode.dark,
      };
    });
    _saveSettings();
  }

  void _openSettings() {
    HapticFeedback.lightImpact();
    MushafSettingsSheet.show(
      context,
      currentTheme: _themeMode,
      isTajweedEnabled: _isTajweedEnabled,
      keepScreenAwake: _keepScreenAwake,
      selectedReciter: _audioService.selectedReciter,
      selectedTafsir: _defaultTafsir,
      onThemeChanged: (mode) {
        _userExplicitlySelectedTheme = true;
        setState(() => _themeMode = mode);
        _saveSettings();
      },
      onTajweedChanged: (val) {
        setState(() => _isTajweedEnabled = val);
        _saveSettings();
      },
      onKeepScreenAwakeChanged: (val) {
        setState(() => _keepScreenAwake = val);
        _applyWakelock(val);
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

  Future<void> _handleAyahLongPress(int surah, int ayah) async {
    HapticFeedback.mediumImpact();
    setState(() {
      _currentSurah = surah;
      _currentAyah = ayah;
      _selectedSurah = surah;
      _selectedAyah = ayah;
    });

    await AyahActionMenuSheet.show(
      context,
      surahNumber: surah,
      ayahNumber: ayah,
      audioService: _audioService,
      defaultTafsir: _defaultTafsir,
      onBookmarkChanged: _reloadLastReadAndBookmarks,
    );

    if (mounted) {
      setState(() {
        _selectedSurah = null;
        _selectedAyah = null;
      });
    }
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
            // Pure Authentic Medina Mushaf Page View
            Positioned.fill(
              child: _buildMushafPageMode(palette),
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
                    themeMode: _themeMode,
                    onJumpToPage: _jumpToPage,
                    onOpenSettings: _openSettings,
                    onToggleTheme: _toggleTheme,
                  );
                },
              ),
            ),

            // Bottom Bar Overlay & Mini Audio Player
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
        final effectiveSurah = activeAyah != null ? activeSurah : _selectedSurah;
        final effectiveAyah = activeAyah ?? _selectedAyah;

        return Directionality(
          textDirection: TextDirection.rtl,
          child: PageView.builder(
            controller: _pageController,
            allowImplicitScrolling: false,
            physics: const BouncingScrollPhysics(parent: PageScrollPhysics()),
            itemCount: 604,
            onPageChanged: (index) => _onPageChanged(index + 1),
            itemBuilder: (context, index) {
              final pageNumber = index + 1;
              return RepaintBoundary(
                child: MushafSinglePage(
                  key: ValueKey('mushaf_page_$pageNumber'),
                  pageNumber: pageNumber,
                  themeMode: _themeMode,
                  isTajweedEnabled: _isTajweedEnabled,
                  activeSurah: effectiveSurah,
                  activeAyah: effectiveAyah,
                  lastReadSurah: _lastReadSurah,
                  lastReadAyah: _lastReadAyah,
                  bookmarkedAyahs: _bookmarkedAyahs,
                  onAyahTap: (surah, ayah) => _toggleOverlays(),
                  onAyahLongPress: _handleAyahLongPress,
                  onToggleOverlays: _toggleOverlays,
                ),
              );
            },
          ),
        );
      },
    );
  }
}
