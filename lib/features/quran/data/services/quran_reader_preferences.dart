import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'quran_audio_service.dart';
import 'quran_tafsir_service.dart';
import '../../../../app/theme/app_palette.dart';

/// Single source for Mushaf reader preferences (persisted).
class QuranReaderPreferences {
  QuranReaderPreferences._();

  static const String lastPageKey = 'dashboard_last_page';
  static const String readingModeKey = 'mushaf_reading_mode';
  static const String tajweedKey = 'mushaf_tajweed_enabled';
  static const String themeModeKey = 'mushaf_theme_mode';
  static const String fontSizeKey = 'mushaf_font_size';
  static const String translationKey = 'mushaf_show_translation';
  static const String wakelockKey = 'mushaf_keep_screen_awake';
  static const String reciterIdKey = 'mushaf_reciter_id';
  static const String tafsirScholarKey = 'mushaf_tafsir_scholar';
  static const String lastScrollIndexKey = 'mushaf_last_scroll_index';

  // In-memory memoized snapshot
  static QuranReaderSnapshot? _cachedSnapshot;

  @visibleForTesting
  static void resetCacheForTesting() {
    _cachedSnapshot = null;
  }

  static Future<QuranReaderSnapshot> load({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedSnapshot != null) {
      return _cachedSnapshot!;
    }

    final prefs = await SharedPreferences.getInstance();
    final reciterId = prefs.getString(reciterIdKey);
    final reciter = QuranAudioService.reciters.firstWhere(
      (r) => r.id == reciterId,
      orElse: () => QuranAudioService.reciters.first,
    );

    final tafsirIdx = prefs.getInt(tafsirScholarKey);
    TafsirScholar tafsir = TafsirScholar.muyassar;
    if (tafsirIdx != null &&
        tafsirIdx >= 0 &&
        tafsirIdx < TafsirScholar.values.length) {
      tafsir = TafsirScholar.values[tafsirIdx];
    }

    final snapshot = QuranReaderSnapshot(
      readingMode: QuranReadingMode
          .values[(prefs.getInt(readingModeKey) ?? 0).clamp(0, 1)],
      isTajweedEnabled: prefs.getBool(tajweedKey) ?? true,
      themeMode: MushafThemeMode
          .values[(prefs.getInt(themeModeKey) ?? 1).clamp(0, 2)],
      fontSize: prefs.getDouble(fontSizeKey) ?? 24.0,
      showTranslation: prefs.getBool(translationKey) ?? false,
      keepScreenAwake: prefs.getBool(wakelockKey) ?? true,
      reciter: reciter,
      defaultTafsir: tafsir,
    );

    _cachedSnapshot = snapshot;
    return snapshot;
  }

  static Future<void> saveReciter(QuranReciter reciter) async {
    _cachedSnapshot = _cachedSnapshot?.copyWith(reciter: reciter);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(reciterIdKey, reciter.id);
  }

  static Future<void> saveTafsirScholar(TafsirScholar scholar) async {
    _cachedSnapshot = _cachedSnapshot?.copyWith(defaultTafsir: scholar);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(tafsirScholarKey, scholar.index);
  }

  static Future<void> saveReadingMode(QuranReadingMode mode) async {
    _cachedSnapshot = _cachedSnapshot?.copyWith(readingMode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(readingModeKey, mode.index);
  }

  static Future<void> saveTajweedEnabled(bool enabled) async {
    _cachedSnapshot = _cachedSnapshot?.copyWith(isTajweedEnabled: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(tajweedKey, enabled);
  }

  static Future<void> saveThemeMode(MushafThemeMode mode) async {
    _cachedSnapshot = _cachedSnapshot?.copyWith(themeMode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(themeModeKey, mode.index);
  }

  static Future<void> saveFontSize(double size) async {
    _cachedSnapshot = _cachedSnapshot?.copyWith(fontSize: size);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(fontSizeKey, size);
  }

  static Future<void> saveShowTranslation(bool show) async {
    _cachedSnapshot = _cachedSnapshot?.copyWith(showTranslation: show);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(translationKey, show);
  }

  static Future<void> saveKeepScreenAwake(bool keep) async {
    _cachedSnapshot = _cachedSnapshot?.copyWith(keepScreenAwake: keep);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(wakelockKey, keep);
  }

  static Future<void> saveLastPage(int page) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(lastPageKey, page);
  }

  static Future<void> saveLastScrollIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(lastScrollIndexKey, index);
  }

  static Future<int?> getLastScrollIndex() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(lastScrollIndexKey);
  }
}

class QuranReaderSnapshot {
  final QuranReadingMode readingMode;
  final bool isTajweedEnabled;
  final MushafThemeMode themeMode;
  final double fontSize;
  final bool showTranslation;
  final bool keepScreenAwake;
  final QuranReciter reciter;
  final TafsirScholar defaultTafsir;

  const QuranReaderSnapshot({
    required this.readingMode,
    required this.isTajweedEnabled,
    required this.themeMode,
    required this.fontSize,
    required this.showTranslation,
    required this.keepScreenAwake,
    required this.reciter,
    required this.defaultTafsir,
  });

  QuranReaderSnapshot copyWith({
    QuranReadingMode? readingMode,
    bool? isTajweedEnabled,
    MushafThemeMode? themeMode,
    double? fontSize,
    bool? showTranslation,
    bool? keepScreenAwake,
    QuranReciter? reciter,
    TafsirScholar? defaultTafsir,
  }) {
    return QuranReaderSnapshot(
      readingMode: readingMode ?? this.readingMode,
      isTajweedEnabled: isTajweedEnabled ?? this.isTajweedEnabled,
      themeMode: themeMode ?? this.themeMode,
      fontSize: fontSize ?? this.fontSize,
      showTranslation: showTranslation ?? this.showTranslation,
      keepScreenAwake: keepScreenAwake ?? this.keepScreenAwake,
      reciter: reciter ?? this.reciter,
      defaultTafsir: defaultTafsir ?? this.defaultTafsir,
    );
  }
}

