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

  static Future<QuranReaderSnapshot> load() async {
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

    return QuranReaderSnapshot(
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
  }

  static Future<void> saveReciter(QuranReciter reciter) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(reciterIdKey, reciter.id);
  }

  static Future<void> saveTafsirScholar(TafsirScholar scholar) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(tafsirScholarKey, scholar.index);
  }

  static Future<void> saveReadingMode(QuranReadingMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(readingModeKey, mode.index);
  }

  static Future<void> saveTajweedEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(tajweedKey, enabled);
  }

  static Future<void> saveThemeMode(MushafThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(themeModeKey, mode.index);
  }

  static Future<void> saveFontSize(double size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(fontSizeKey, size);
  }

  static Future<void> saveShowTranslation(bool show) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(translationKey, show);
  }

  static Future<void> saveKeepScreenAwake(bool keep) async {
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
}
