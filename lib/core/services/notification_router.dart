import 'package:flutter/material.dart';

import '../../app/app.dart';
import '../../features/adhkar/data/adhkar_models.dart';
import '../../features/adhkar/presentation/adhkar_session_page.dart';
import '../../features/adhkar/presentation/after_prayer_athkar_page.dart';
import '../../features/adhkar/presentation/duas_misc_page.dart';
import '../../features/adhkar/presentation/evening_athkar_page.dart';
import '../../features/adhkar/presentation/morning_athkar_page.dart';
import '../../features/adhkar/presentation/sleeping_athkar_page.dart';
import '../../features/adhkar/presentation/tasbeeh_istighfar_page.dart';
import '../../features/quran/data/services/quran_deep_link_service.dart';
import '../../features/quran/presentation/widgets/mushaf_page_viewer.dart';
import '../../shared/navigation/app_shell.dart';
import '../../shared/navigation/fade_page_route.dart';

/// Semantic classification of notification / deep-link destinations.
enum NotificationDestination {
  morningAthkar,
  eveningAthkar,
  sleepingAthkar,
  afterPrayerAthkar,
  tasbeeh,
  istighfar,
  duasMisc,
  dynamicAthkar,
  surahKahf,
  quranDeepLink,
  prayer,
  unknown,
}

/// NotificationRouter - Centralized, reliable handler for notification clicks & deep link payloads.
/// Dispatches to the exact corresponding view (Morning Athkar, Evening Athkar, Sleeping Athkar,
/// Surah Al-Kahf, Prayer times, etc.) seamlessly in both running and cold-start app lifecycles.
class NotificationRouter {
  NotificationRouter._();

  /// Payload captured from cold-start getNotificationAppLaunchDetails
  static String? pendingPayload;

  static String? _lastDispatchedPayload;
  static int _lastDispatchTimestampMs = 0;

  /// Authoritative destination parser mapping raw payload strings to typed [NotificationDestination].
  static NotificationDestination parseDestination(String? rawPayload) {
    if (rawPayload == null || rawPayload.trim().isEmpty) {
      return NotificationDestination.unknown;
    }
    final payload = rawPayload.trim().toLowerCase();

    // ── 1. Adhkar Destinations ───────────────────────────────────────────
    if (payload == 'morning' ||
        payload == 'adhkar_morning' ||
        payload == 'adhkar:morning' ||
        payload == 'morning_athkar' ||
        payload.contains('morning') ||
        payload.contains('صباح')) {
      return NotificationDestination.morningAthkar;
    }

    if (payload == 'evening' ||
        payload == 'adhkar_evening' ||
        payload == 'adhkar:evening' ||
        payload == 'evening_athkar' ||
        payload.contains('evening') ||
        payload.contains('مساء')) {
      return NotificationDestination.eveningAthkar;
    }

    if (payload == 'sleep' ||
        payload == 'sleeping' ||
        payload == 'adhkar_sleep' ||
        payload == 'adhkar_sleeping' ||
        payload == 'adhkar:sleep' ||
        payload == 'sleeping_athkar' ||
        payload.contains('sleep') ||
        payload.contains('نوم')) {
      return NotificationDestination.sleepingAthkar;
    }

    if (payload == 'after_prayer' ||
        payload == 'afterprayer' ||
        payload == 'adhkar_after_prayer' ||
        payload == 'adhkar:after_prayer' ||
        payload.contains('بعد الصلاة') ||
        payload.contains('بعد_الصلاة')) {
      return NotificationDestination.afterPrayerAthkar;
    }

    if (payload == 'tasbeeh' ||
        payload == 'tasbih' ||
        payload.contains('تسبيح')) {
      return NotificationDestination.tasbeeh;
    }

    if (payload == 'istighfar' || payload.contains('استغفار')) {
      return NotificationDestination.istighfar;
    }

    if (payload == 'duas' ||
        payload == 'misc' ||
        payload.contains('أدعية') ||
        payload.contains('ادعية')) {
      return NotificationDestination.duasMisc;
    }

    // ── 2. Quran Notifications ───────────────────────────────────────────
    if (payload == 'surah_18' ||
        payload == 'surah_alkahf' ||
        payload == 'quran:kahf' ||
        payload.contains('kahf') ||
        payload.contains('كهف')) {
      return NotificationDestination.surahKahf;
    }

    if (payload.startsWith('talibilm://quran/')) {
      return NotificationDestination.quranDeepLink;
    }

    // ── 3. Prayer Notifications ───────────────────────────────────────────
    if (payload.startsWith('prayer') ||
        payload.startsWith('adhan') ||
        payload.startsWith('iqama') ||
        payload.contains('صلاة') ||
        payload.contains('أذان') ||
        payload.contains('اذان') ||
        payload.contains('إقامة') ||
        payload.contains('اقامة')) {
      return NotificationDestination.prayer;
    }

    // ── 4. Dynamic Adhkar Category Fallback ───────────────────────────────
    final stripped =
        payload.startsWith('adhkar_') ? payload.substring(7) : payload;
    final parsedCategory =
        adhkarCategoryFromId(payload) ?? adhkarCategoryFromId(stripped);
    if (parsedCategory != null) {
      return NotificationDestination.dynamicAthkar;
    }

    return NotificationDestination.unknown;
  }

  /// Handles an incoming notification payload with shell tab synchronization and duplicate suppression.
  static void handlePayload(String? rawPayload, {BuildContext? context}) {
    if (rawPayload == null || rawPayload.isEmpty) return;
    final payload = rawPayload.trim().toLowerCase();

    // If AppShell is not ready yet (e.g. cold booting or splash animating),
    // save the payload so AppShell can consume it once mounted.
    if (!AppShell.isAppShellReady) {
      pendingPayload = payload;
      return;
    }

    final nav = rootNavigatorKey.currentState;
    final targetContext = context ?? rootNavigatorKey.currentContext;

    if (nav == null && targetContext == null) {
      pendingPayload = payload;
      return;
    }

    // Duplicate tap suppression: ignore identical payload within 500ms
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (_lastDispatchedPayload == payload &&
        (nowMs - _lastDispatchTimestampMs) < 500) {
      return;
    }
    _lastDispatchedPayload = payload;
    _lastDispatchTimestampMs = nowMs;

    pendingPayload = null;

    final destination = parseDestination(payload);

    switch (destination) {
      case NotificationDestination.morningAthkar:
        AppShell.switchTo(targetContext, AppShellTab.adhkar);
        _pushPage(const MorningAthkarPage());
        break;

      case NotificationDestination.eveningAthkar:
        AppShell.switchTo(targetContext, AppShellTab.adhkar);
        _pushPage(const EveningAthkarPage());
        break;

      case NotificationDestination.sleepingAthkar:
        AppShell.switchTo(targetContext, AppShellTab.adhkar);
        _pushPage(const SleepingAthkarPage());
        break;

      case NotificationDestination.afterPrayerAthkar:
        AppShell.switchTo(targetContext, AppShellTab.adhkar);
        _pushPage(const AfterPrayerAthkarPage());
        break;

      case NotificationDestination.tasbeeh:
        AppShell.switchTo(targetContext, AppShellTab.adhkar);
        _pushPage(const TasbeehIstighfarPage(initialTabIndex: 0));
        break;

      case NotificationDestination.istighfar:
        AppShell.switchTo(targetContext, AppShellTab.adhkar);
        _pushPage(const TasbeehIstighfarPage(initialTabIndex: 1));
        break;

      case NotificationDestination.duasMisc:
        AppShell.switchTo(targetContext, AppShellTab.adhkar);
        _pushPage(const DuasMiscPage());
        break;

      case NotificationDestination.dynamicAthkar:
        final stripped =
            payload.startsWith('adhkar_') ? payload.substring(7) : payload;
        final cat =
            adhkarCategoryFromId(payload) ?? adhkarCategoryFromId(stripped);
        if (cat != null) {
          AppShell.switchTo(targetContext, AppShellTab.adhkar);
          _pushPage(AdhkarSessionPage(category: cat));
        }
        break;

      case NotificationDestination.surahKahf:
        // Surah Al-Kahf starts on page 293 in the Madani Mushaf
        _pushPage(const MushafPageViewer(initialPage: 293, initialSurah: 18));
        break;

      case NotificationDestination.quranDeepLink:
        final uri = Uri.tryParse(payload);
        if (uri != null) {
          final target = QuranDeepLinkService.parse(uri);
          if (target.isValid && target.page != null) {
            _pushPage(MushafPageViewer(
              initialPage: target.page!,
              initialSurah: target.surah,
              initialAyah: target.ayah,
            ));
          }
        }
        break;

      case NotificationDestination.prayer:
        AppShell.switchTo(targetContext, AppShellTab.prayer);
        _popToRoot();
        break;

      case NotificationDestination.unknown:
        // Graceful fallback for unknown or malformed payloads
        break;
    }
  }

  static void _pushPage(Widget page) {
    final nav = rootNavigatorKey.currentState;
    if (nav != null) {
      nav.popUntil((route) => route.isFirst);
      nav.push(buildFadeRoute(page: page));
    }
  }

  static void _popToRoot() {
    final nav = rootNavigatorKey.currentState;
    if (nav != null) {
      nav.popUntil((route) => route.isFirst);
    }
  }

  /// Consumes and executes any pending launch payload once the app shell is ready.
  static void consumePendingPayload(BuildContext context) {
    final p = pendingPayload;
    if (p != null && p.isNotEmpty) {
      pendingPayload = null;
      handlePayload(p, context: context);
    }
  }

  /// Resets internal dispatch rate-limiting state for test isolation.
  @visibleForTesting
  static void resetStateForTesting() {
    pendingPayload = null;
    _lastDispatchedPayload = null;
    _lastDispatchTimestampMs = 0;
  }
}
