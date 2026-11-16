import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hijri/hijri_calendar.dart';
import 'location_service.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app/constants/app_strings.dart';
import '../../app/theme/app_palette.dart';
import '../../app/theme/app_theme.dart';
import '../../features/prayer/data/models/prayer_models.dart';
import '../../features/prayer/presentation/widgets/prayer_home_screen_widget.dart';
import '../../features/salaf_gems/data/repositories/salaf_gems_repository.dart';
import 'adhan_settings_service.dart';
import 'prayer_time_service.dart';

import 'home_widget_pre_render.dart';
export 'home_widget_pre_render.dart';

part 'home_widget_snapshot_serializer.dart';

/// Supported visual themes for the native Android and iOS home widgets.
enum WidgetThemeMode { dark, light, auto }

/// Manages native widget preference serialization, snapshot versioning, and
/// theme resolution to keep Android and iOS widget appearances in sync.
class HomeWidgetSnapshot {
  const HomeWidgetSnapshot._();

  static const String themeModeKey = 'prayer_widget_theme_mode';
  static const String appGroupId = 'group.com.talibilm.app';
  static const MethodChannel _iosBridgeChannel = MethodChannel(
    'com.talibilm.app/widget_bridge',
  );
  static String? _resolvedIosAppGroup;
  static bool? _iosContainerAccessible;
  static bool? _iosKeychainAccessible;
  static int _snapshotVersion = 0;
  static int get snapshotVersion => _snapshotVersion;
  static String? lastSyncError;

  static String get activeAppGroupId => _resolvedIosAppGroup ?? appGroupId;
  static bool? get iosContainerAccessible => _iosContainerAccessible;
  static bool? get iosKeychainAccessible => _iosKeychainAccessible;
  static bool get iosSyncBlocked =>
      !kIsWeb &&
      Platform.isIOS &&
      _iosContainerAccessible == false &&
      _iosKeychainAccessible == false;

  /// Queries the native iOS host app for the kernel-verified provisioned App Group
  /// and Keychain sharing state. Returns [appGroupId] on non-iOS platforms.
  static Future<String> resolveActiveAppGroupId() async {
    if (kIsWeb || !Platform.isIOS) return appGroupId;
    try {
      final info = await _iosBridgeChannel
          .invokeMapMethod<String, dynamic>('getWidgetBridgeInfo');
      if (info != null) {
        final active = info['activeAppGroup'] as String?;
        final accessible = info['containerAccessible'] as bool? ?? false;
        final kcAccessible = info['keychainAccessible'] as bool? ?? false;
        _iosContainerAccessible = accessible;
        _iosKeychainAccessible = kcAccessible;
        if (active != null && active.trim().isNotEmpty) {
          _resolvedIosAppGroup = active.trim();
          return _resolvedIosAppGroup!;
        }
        if (!accessible && !kcAccessible) {
          lastSyncError =
              'iOS App Group & Keychain sharing unavailable for this provisioning profile';
        }
      }
    } catch (_) {}
    return activeAppGroupId;
  }

  /// Writes a value to both the shared App Group and standard storage to ensure
  /// seamless data delivery across normal, sideloaded, and test environments.
  static Future<void> writeWidgetValue<T>(String key, T value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (value is int) {
        await prefs.setInt(key, value);
      } else if (value is String) {
        await prefs.setString(key, value);
      } else if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is double) {
        await prefs.setDouble(key, value);
      }
    } catch (_) {}

    final targetGroup = activeAppGroupId;
    try {
      await HomeWidget.saveWidgetData<T>(
        key,
        value,
        appGroupId: targetGroup,
      );
      try {
        await HomeWidget.saveWidgetData<T>(key, value);
      } catch (_) {}
      lastSyncError = null;
    } catch (error) {
      lastSyncError = error.toString();
      try {
        await HomeWidget.saveWidgetData<T>(key, value);
      } catch (_) {}
    }
  }

  static Future<bool> verifyAppGroup() async {
    if (!kIsWeb && Platform.isIOS) {
      await resolveActiveAppGroupId();
      if (_iosContainerAccessible == false && _iosKeychainAccessible == false) {
        return false;
      }
    }
    final targetGroup = activeAppGroupId;
    final probe = DateTime.now().microsecondsSinceEpoch.toString();
    try {
      final saved = await HomeWidget.saveWidgetData<String>(
        'widget_app_group_probe',
        probe,
        appGroupId: targetGroup,
      );
      if (saved == true) {
        final readBack = await HomeWidget.getWidgetData<String>(
          'widget_app_group_probe',
          appGroupId: targetGroup,
        );
        if (readBack == probe) {
          lastSyncError = null;
          return true;
        }
      }
      return false;
    } catch (error) {
      lastSyncError = error.toString();
      return false;
    }
  }

  /// Resolves whether the widget should render in dark mode.
  static Future<bool> resolveWidgetIsDark() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeStr = prefs.getString(themeModeKey);
      if (modeStr == 'light') return false;
      if (modeStr == 'dark') return true;

      final appTheme = prefs.getString('theme_mode');
      if (appTheme == 'light') return false;
      if (appTheme == 'dark') return true;
      if (appTheme == 'system') {
        return AppTheme.isSystemDark();
      }
    } catch (_) {}
    return AppTheme.isSystemDark();
  }

  /// Saves the target prayer epoch timestamp and all visual attributes for the
  /// native Android Chronometer and providers. Writes an atomic snapshot version
  /// to eliminate mixed/stale preference reads across widget updates.
  static Future<void> savePrayerSnapshot(
    EvaluatedPrayerWidgetState eval, {
    Map<String, DateTime>? allPrayers,
    bool? preResolvedDark,
    String? cityName,
  }) =>
      _savePrayerSnapshotImpl(
        eval,
        allPrayers: allPrayers,
        preResolvedDark: preResolvedDark,
        cityName: cityName,
      );

  /// Invalidates cached daily pre-rendered prayer state snapshots
  static void invalidateDailyCache() =>
      HomeWidgetPreRender.invalidateDailyCache();

  /// Pre-renders daily prayer state variations for Ribbon widget.
  static Future<void> preRenderDailyRibbonSnapshots({
    required PrayerTimesDay day,
    required bool useDark,
    required String hijriDate,
    bool force = false,
    double? width,
    double? height,
  }) =>
      HomeWidgetPreRender.preRenderDailyRibbonSnapshots(
        day: day,
        useDark: useDark,
        hijriDate: hijriDate,
        force: force,
        width: width,
        height: height,
      );

  /// Pre-renders daily prayer state variations for Large widget.
  static Future<void> preRenderDailyLargeSnapshots({
    required PrayerTimesDay day,
    required bool useDark,
    required String hijriDate,
    bool force = false,
    double? width,
    double? height,
  }) =>
      HomeWidgetPreRender.preRenderDailyLargeSnapshots(
        day: day,
        useDark: useDark,
        hijriDate: hijriDate,
        force: force,
        width: width,
        height: height,
      );
}
