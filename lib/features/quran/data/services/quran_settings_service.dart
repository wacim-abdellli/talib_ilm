import 'package:shared_preferences/shared_preferences.dart';

class QuranSettingsService {
  static const String _keyDarkMode = 'quran_dark_mode';
  static const String _keyFontSize = 'quran_font_size';
  static const String _keyEnglishNumbers = 'quran_english_numbers';
  static const String _keyFontFamily = 'quran_font_family';

  // Singleton
  static final QuranSettingsService _instance = QuranSettingsService._();
  QuranSettingsService._();
  static QuranSettingsService get instance => _instance;

  Future<Map<String, dynamic>> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'isDark': prefs.getBool(_keyDarkMode) ?? false,
      'fontSize': prefs.getDouble(_keyFontSize) ?? 22.0,
      'useEnglishNumbers': prefs.getBool(_keyEnglishNumbers) ?? false,
      'fontFamily': prefs.getString(_keyFontFamily) ?? 'Amiri',
    };
  }

  Future<void> saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) await prefs.setBool(key, value);
    if (value is double) await prefs.setDouble(key, value);
    if (value is String) await prefs.setString(key, value);
    if (value is int) await prefs.setInt(key, value);
  }

  // Keys
  static String get keyDarkMode => _keyDarkMode;
  static String get keyFontSize => _keyFontSize;
  static String get keyEnglishNumbers => _keyEnglishNumbers;
  static String get keyFontFamily => _keyFontFamily;
  static String get keyReadingMode => 'quran_readingMode';
}
