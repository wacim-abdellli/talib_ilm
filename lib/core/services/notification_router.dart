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

/// NotificationRouter - Centralized, reliable handler for notification clicks & deep link payloads.
/// Dispatches to the exact corresponding view (Morning Athkar, Evening Athkar, Sleeping Athkar,
/// Surah Al-Kahf, Prayer times, etc.) seamlessly in both running and cold-start app lifecycles.
class NotificationRouter {
  NotificationRouter._();

  /// Payload captured from cold-start getNotificationAppLaunchDetails
  static String? pendingPayload;

  /// Handles an incoming notification payload.
  static void handlePayload(String? rawPayload, {BuildContext? context}) {
    if (rawPayload == null || rawPayload.isEmpty) return;
    final payload = rawPayload.trim().toLowerCase();

    // If AppShell is not ready yet (e.g. splash is still animating or cold booting),
    // save the payload so AppShell can consume it once fully mounted.
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

    pendingPayload = null;

    // ── 1. Adhkar Notifications ───────────────────────────────────────────
    // Morning Athkar: English keys, IDs, or Arabic strings
    if (payload == 'morning' ||
        payload == 'adhkar_morning' ||
        payload.contains('morning') ||
        payload.contains('صباح')) {
      AppShell.switchToTab(targetContext, 2);
      _pushPage(const MorningAthkarPage());
      return;
    }

    // Evening Athkar: English keys, IDs, or Arabic strings
    if (payload == 'evening' ||
        payload == 'adhkar_evening' ||
        payload.contains('evening') ||
        payload.contains('مساء')) {
      AppShell.switchToTab(targetContext, 2);
      _pushPage(const EveningAthkarPage());
      return;
    }

    // Sleeping Athkar: English keys, IDs, or Arabic strings
    if (payload == 'sleep' ||
        payload == 'sleeping' ||
        payload == 'adhkar_sleep' ||
        payload == 'adhkar_sleeping' ||
        payload.contains('sleep') ||
        payload.contains('نوم')) {
      AppShell.switchToTab(targetContext, 2);
      _pushPage(const SleepingAthkarPage());
      return;
    }

    // After-Prayer Athkar
    if (payload == 'after_prayer' ||
        payload == 'afterprayer' ||
        payload == 'adhkar_after_prayer' ||
        payload.contains('بعد الصلاة')) {
      AppShell.switchToTab(targetContext, 2);
      _pushPage(const AfterPrayerAthkarPage());
      return;
    }

    // Tasbeeh
    if (payload == 'tasbeeh' ||
        payload == 'tasbih' ||
        payload.contains('تسبيح')) {
      AppShell.switchToTab(targetContext, 2);
      _pushPage(const TasbeehIstighfarPage(initialTabIndex: 0));
      return;
    }

    // Istighfar
    if (payload == 'istighfar' || payload.contains('استغفار')) {
      AppShell.switchToTab(targetContext, 2);
      _pushPage(const TasbeehIstighfarPage(initialTabIndex: 1));
      return;
    }

    // Duas & Misc
    if (payload == 'duas' ||
        payload == 'misc' ||
        payload.contains('أدعية') ||
        payload.contains('ادعية')) {
      AppShell.switchToTab(targetContext, 2);
      _pushPage(const DuasMiscPage());
      return;
    }

    // ── 2. Quran Notifications (e.g. Surah Al-Kahf Friday) ────────────────
    if (payload == 'surah_18' ||
        payload == 'surah_alkahf' ||
        payload.contains('kahf') ||
        payload.contains('كهف')) {
      // Surah Al-Kahf starts on page 293 in the Madani Mushaf
      _pushPage(const MushafPageViewer(initialPage: 293, initialSurah: 18));
      return;
    }

    // Quran deep links: talibilm://quran/...
    if (payload.startsWith('talibilm://quran/')) {
      final uri = Uri.tryParse(payload);
      if (uri != null) {
        final target = QuranDeepLinkService.parse(uri);
        if (target.isValid && target.page != null) {
          _pushPage(MushafPageViewer(
            initialPage: target.page!,
            initialSurah: target.surah,
            initialAyah: target.ayah,
          ));
          return;
        }
      }
    }

    // ── 3. Prayer Notifications ───────────────────────────────────────────
    if (payload.startsWith('prayer') ||
        payload == 'adhan' ||
        payload == 'iqama' ||
        payload.contains('صلاة') ||
        payload.contains('أذان') ||
        payload.contains('اذان') ||
        payload.contains('إقامة') ||
        payload.contains('اقامة')) {
      AppShell.switchToTab(targetContext, 1);
      _popToRoot();
      return;
    }

    // ── 4. Fallback: Parse as dynamic Adhkar category ─────────────────────
    final parsedCategory = adhkarCategoryFromId(payload);
    if (parsedCategory != null) {
      AppShell.switchToTab(targetContext, 2);
      _pushPage(AdhkarSessionPage(category: parsedCategory));
      return;
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
}
