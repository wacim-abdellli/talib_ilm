import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home_widget_service.dart';

/// Service to manage theme mode preference
class ThemeService extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';

  static const String _defaultMigratedKey = 'theme_default_light_v1';

  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  bool get isDark => _themeMode == ThemeMode.dark;
  bool get isLight => _themeMode == ThemeMode.light;
  bool get isSystem => _themeMode == ThemeMode.system;

  /// Load theme preference from storage
  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();

    final isMigrated = prefs.getBool(_defaultMigratedKey) ?? false;
    if (!isMigrated) {
      await prefs.setBool(_defaultMigratedKey, true);
      final existingTheme = prefs.getString(_themeKey);
      // Migrate legacy default ('system') or unset to Light mode
      if (existingTheme == null || existingTheme == 'system') {
        _themeMode = ThemeMode.light;
        await prefs.setString(_themeKey, 'light');
        notifyListeners();
        return;
      }
    }

    final themeName = prefs.getString(_themeKey);

    if (themeName == 'dark') {
      _themeMode = ThemeMode.dark;
    } else if (themeName == 'system') {
      _themeMode = ThemeMode.system;
    } else {
      _themeMode = ThemeMode.light;
    }
    notifyListeners();
  }

  /// Set theme mode and save to storage
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    String themeName;
    switch (mode) {
      case ThemeMode.dark:
        themeName = 'dark';
        break;
      case ThemeMode.light:
        themeName = 'light';
        break;
      case ThemeMode.system:
        themeName = 'system';
        break;
    }
    await prefs.setString(_themeKey, themeName);
    try {
      HomeWidgetService.invalidateCache();
      HomeWidgetService.updatePrayerWidget(force: true);
    } catch (_) {}
  }

  /// Toggle between light and dark (ignores system)
  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.dark) {
      await setThemeMode(ThemeMode.light);
    } else {
      await setThemeMode(ThemeMode.dark);
    }
  }

  /// Cycle through: System -> Light -> Dark -> System
  Future<void> cycleTheme() async {
    switch (_themeMode) {
      case ThemeMode.system:
        await setThemeMode(ThemeMode.light);
        break;
      case ThemeMode.light:
        await setThemeMode(ThemeMode.dark);
        break;
      case ThemeMode.dark:
        await setThemeMode(ThemeMode.system);
        break;
    }
  }

  /// Get display name for current theme
  String get themeDisplayName {
    switch (_themeMode) {
      case ThemeMode.system:
        return 'تلقائي (حسب النظام)';
      case ThemeMode.light:
        return 'الوضع الفاتح';
      case ThemeMode.dark:
        return 'الوضع الداكن';
    }
  }

  /// Get icon for current theme
  IconData get themeIcon {
    switch (_themeMode) {
      case ThemeMode.system:
        return Icons.brightness_auto;
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
    }
  }
}
