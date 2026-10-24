import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:talib_ilm/app/app.dart';
import 'package:talib_ilm/app/constants/app_strings.dart';
import 'package:talib_ilm/core/constants/verified_cities.dart';
import 'package:talib_ilm/core/services/adhan_settings_service.dart';
import 'package:talib_ilm/core/services/foreground_prayer_service.dart';
import 'package:talib_ilm/core/services/home_widget_snapshot.dart';
import 'package:talib_ilm/core/services/notification_router.dart';
import 'package:talib_ilm/core/services/notification_service.dart';
import 'package:talib_ilm/core/services/prayer_schedule_service.dart';
import 'package:talib_ilm/core/services/prayer_time_service.dart';
import 'package:talib_ilm/core/services/progress_service.dart';
import 'package:talib_ilm/features/adhkar/presentation/evening_athkar_page.dart';
import 'package:talib_ilm/features/adhkar/presentation/morning_athkar_page.dart';
import 'package:talib_ilm/features/ilm/data/catalogs/islamic_quiz_catalog.dart';
import 'package:talib_ilm/features/ilm/data/models/book_progress_model.dart' as ilm_model;
import 'package:talib_ilm/features/ilm/data/services/book_progress_service.dart';
import 'package:talib_ilm/features/ilm/data/services/quiz_progress_service.dart';
import 'package:talib_ilm/features/prayer/data/models/prayer_models.dart';
import 'package:talib_ilm/features/prayer/presentation/widgets/prayer_home_screen_widget.dart';
import 'package:talib_ilm/features/quran/data/services/bookmark_backup_service.dart';
import 'package:talib_ilm/features/quran/data/services/bookmark_service.dart';
import 'package:talib_ilm/features/quran/data/services/quran_audio_downloader.dart';
import 'package:talib_ilm/features/quran/data/services/quran_audio_service.dart';
import 'package:talib_ilm/shared/navigation/app_shell.dart';
import 'package:timezone/data/latest_all.dart' as tz;

class RecordingNotificationService extends NotificationService {
  final List<int> scheduledPrayerIds = [];

  @override
  Future<void> init() async {}

  @override
  Future<void> cancelPrayerNotificationsOnly({Set<int>? preserveIds}) async {}

  @override
  Future<ScheduleOutcome> schedulePrayerNotification({
    required int id,
    required String prayerName,
    required DateTime scheduledTime,
    required PrayerNotificationMode mode,
    AdhanSound sound = AdhanSound.qatami,
    bool isJumua = false,
  }) async {
    scheduledPrayerIds.add(id);
    return ScheduleOutcome(status: ScheduleOutcomeStatus.exact, notificationId: id);
  }

  @override
  Future<ScheduleOutcome> schedulePrePrayerNotification({
    required int id,
    required String prayerName,
    required DateTime scheduledTime,
    required int minutesBefore,
    bool isJumua = false,
  }) async {
    return ScheduleOutcome(status: ScheduleOutcomeStatus.exact, notificationId: id);
  }

  @override
  Future<ScheduleOutcome> scheduleIqamaNotification({
    required int id,
    required String prayerName,
    required DateTime scheduledTime,
    bool isJumua = false,
  }) async {
    return ScheduleOutcome(status: ScheduleOutcomeStatus.exact, notificationId: id);
  }

  @override
  Future<ScheduleOutcome> scheduleSurahAlKahfNotification({
    required int id,
    required DateTime scheduledTime,
  }) async {
    return ScheduleOutcome(status: ScheduleOutcomeStatus.exact, notificationId: id);
  }
}

class TestPrayerTimeService extends PrayerTimeService {
  final DateTime Function() _mockNow;
  TestPrayerTimeService(this._mockNow) : super(now: _mockNow);

  @override
  Future<PrayerTimesDay> getPrayerTimesDay({
    DateTime? date,
    bool forceRefresh = false,
  }) async {
    final d = date ?? _mockNow();
    final prayers = <String, DateTime>{
      AppStrings.prayerFajr: DateTime(d.year, d.month, d.day, 5, 15),
      'الشروق': DateTime(d.year, d.month, d.day, 6, 45),
      AppStrings.prayerDhuhr: DateTime(d.year, d.month, d.day, 12, 45),
      AppStrings.prayerAsr: DateTime(d.year, d.month, d.day, 15, 55),
      AppStrings.prayerMaghrib: DateTime(d.year, d.month, d.day, 18, 30),
      AppStrings.prayerIsha: DateTime(d.year, d.month, d.day, 19, 50),
    };
    return PrayerTimesDay(
      city: 'الجزائر العاصمة',
      date: d,
      prayers: prayers,
      nextPrayer: AppStrings.prayerFajr,
      nextPrayerTime: prayers[AppStrings.prayerFajr],
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();

  final recordedMethodCalls = <String>[];

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    NotificationRouter.resetStateForTesting();
    NotificationService.resetSharedStateForTesting();
    PrayerScheduleService.resetSharedStateForTesting();
    recordedMethodCalls.clear();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('dexterous.com/flutter/local_notifications'),
          (call) async {
            recordedMethodCalls.add(call.method);
            if (call.method == 'initialize') return true;
            if (call.method == 'areNotificationsEnabled') return true;
            if (call.method == 'requestNotificationsPermission') return true;
            if (call.method == 'requestExactAlarmsPermission') return true;
            if (call.method == 'getNotificationAppLaunchDetails') return null;
            return null;
          },
        );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('flutter_timezone'),
          (call) async => 'Africa/Algiers',
        );
  });

  tearDown(() {
    ForegroundPrayerService().stop();
    NotificationRouter.resetStateForTesting();
    NotificationService.resetSharedStateForTesting();
    PrayerScheduleService.resetSharedStateForTesting();
  });

  group('T16 Code Acceptance Suite — Complete Journeys (Finding C31)', () {
    // ════════════════════════════════════════════════════════════════════════
    // Journey 1: Permission choices, notification initialization & cold start (C09, C10)
    // ════════════════════════════════════════════════════════════════════════
    test('Journey 1: Permission choices, plugin invocation counts, and silent background refresh', () async {
      final notifService = NotificationService();

      // 1. Initialization must NOT prompt the user for interactive permissions
      await notifService.init();
      expect(notifService.isInitialized, isTrue);
      expect(recordedMethodCalls.contains('initialize'), isTrue);
      expect(recordedMethodCalls.contains('requestNotificationsPermission'), isFalse);
      expect(recordedMethodCalls.contains('requestExactAlarmsPermission'), isFalse);

      // 2. Explicit requestPermissions prompts both notifications and exact alarms
      await notifService.requestPermissions();
      expect(recordedMethodCalls.where((m) => m == 'requestNotificationsPermission').length, equals(1));
      expect(recordedMethodCalls.where((m) => m == 'requestExactAlarmsPermission').length, equals(1));

      // 3. User chooses silent notifications
      final adhanSettingsService = AdhanSettingsService();
      final initial = await adhanSettingsService.getSettings();
      await adhanSettingsService.saveSettings(
        initial.copyWith(defaultMode: PrayerNotificationMode.silent, silentNotifications: true),
      );
      final updated = await adhanSettingsService.getSettings();
      expect(updated.defaultMode, equals(PrayerNotificationMode.silent));
      expect(updated.silentNotifications, isTrue);

      // 4. Background refresh with silent settings executes cleanly
      final testPrayerService = TestPrayerTimeService(() => DateTime(2026, 10, 24, 12, 0));
      final prayerService = PrayerScheduleService(
        notificationService: notifService,
        prayerTimeService: testPrayerService,
        adhanSettingsService: adhanSettingsService,
      );
      final batchResult = await prayerService.refreshSchedulesIfNeeded(force: true);
      expect(batchResult.isSuccess, isTrue);
    });

    // ════════════════════════════════════════════════════════════════════════
    // Journey 2: Notification deep link Back navigation destination (C13)
    // ════════════════════════════════════════════════════════════════════════
    testWidgets('Journey 2: Notification deep link routes and preserves Back tab destination', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: rootNavigatorKey,
          home: const AppShell(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // 1. Morning Adhkar payload -> opens MorningAthkarPage, sets Adhkar tab
      NotificationRouter.handlePayload('morning');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(MorningAthkarPage), findsOneWidget);
      expect(AppShell.currentTabIndex, equals(AppShellTab.adhkar.index));

      // Pop back -> returns to AppShell on Adhkar tab
      rootNavigatorKey.currentState!.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(MorningAthkarPage), findsNothing);
      expect(AppShell.currentTabIndex, equals(AppShellTab.adhkar.index));

      // 2. Evening Adhkar payload -> opens EveningAthkarPage, sets Adhkar tab
      NotificationRouter.handlePayload('evening');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(EveningAthkarPage), findsOneWidget);
      expect(AppShell.currentTabIndex, equals(AppShellTab.adhkar.index));

      rootNavigatorKey.currentState!.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(EveningAthkarPage), findsNothing);
      expect(AppShell.currentTabIndex, equals(AppShellTab.adhkar.index));
    });

    // ════════════════════════════════════════════════════════════════════════
    // Journey 3: Reading → Bookmark → UTF-8 Safe Export → Backup → Restore (C03-C06, C29)
    // ════════════════════════════════════════════════════════════════════════
    test('Journey 3: Bookmark creation, byte ceiling rejection, validation, and atomic merge', () async {
      // 1. Concurrent bookmark additions with Arabic notes
      await Future.wait([
        BookmarkService.addBookmark(1, 1, note: 'بداية الفاتحة المباركة'),
        BookmarkService.addBookmark(2, 255, note: 'آية الكرسي العظيمة'),
      ]);

      var bookmarks = await BookmarkService.getBookmarks();
      expect(bookmarks.length, equals(2));

      // 2. Export backup string as UTF-8 bytes
      final exportJson = await BookmarkBackupService.createBackupJson();
      final utf8Bytes = utf8.encode(exportJson);
      expect(utf8.decode(utf8Bytes).contains('آية الكرسي العظيمة'), isTrue);

      // 3. Oversized backup rejection (> 512 KB)
      final oversizedBytes = List<int>.filled(512 * 1024 + 1, 0x20);
      expect(
        () => BookmarkBackupService.readBackupFile(PlatformFile(
          name: 'oversized.json',
          size: oversizedBytes.length,
          bytes: Uint8List.fromList(oversizedBytes),
        )),
        throwsA(isA<FormatException>()),
      );

      // 4. Invalid coordinate rejection (out of range surah / invalid page)
      final invalidPayload = json.encode({
        'version': 1,
        'app': 'talib_ilm',
        'exportedAt': DateTime.now().toIso8601String(),
        'bookmarks': [
          {'surah': 999, 'ayah': 1, 'page': 1, 'timestamp': DateTime.now().toIso8601String()},
          {'surah': 1, 'ayah': 99, 'page': 1, 'timestamp': DateTime.now().toIso8601String()},
        ],
      });
      final invalidResult = BookmarkBackupService.validateAndParse(invalidPayload);
      expect(invalidResult.isValid, isFalse);
      expect(invalidResult.rejectedCount, equals(2));

      // 5. Atomic merge deduplication and capping
      final newBookmarks = [
        Bookmark(surah: 1, ayah: 1, page: 1, note: '', timestamp: DateTime.now()),
        Bookmark(surah: 3, ayah: 18, page: 52, note: 'شهد الله أنه لا إله إلا هو', timestamp: DateTime.now()),
      ];
      final mergeSummary = await BookmarkService.atomicMergeBookmarks(
        importedBookmarks: newBookmarks,
        overwriteExistingNotes: false,
      );
      expect(mergeSummary.addedCount, equals(1)); // Surah 3 added
      expect(mergeSummary.skippedCount, equals(1)); // Surah 1 existing note preserved, skipped

      bookmarks = await BookmarkService.getBookmarks();
      expect(bookmarks.length, equals(3));
      final b1 = bookmarks.firstWhere((b) => b.surah == 1 && b.ayah == 1);
      expect(b1.note, equals('بداية الفاتحة المباركة')); // Preserved
    });

    // ════════════════════════════════════════════════════════════════════════
    // Journey 4: Offline complete-book manifest & reading progress (C07, C17)
    // ════════════════════════════════════════════════════════════════════════
    test('Journey 4: ProgressService and BookProgressService handle corruption and retain valid books', () async {
      final prefs = await SharedPreferences.getInstance();

      // Corrupt progress data in storage with non-JSON bytes
      await prefs.setString('book_progress_data', '<<<NOT JSON>>>');

      final progressService = BookProgressService(prefs);
      // Survives corrupted JSON gracefully without crash
      final list = await progressService.getAllProgress();
      expect(list, isEmpty);

      // Add valid book progress
      final validBook = ilm_model.BookProgress(
        bookId: 'bk_usul_thalatha',
        bookTitle: 'الأصول الثلاثة وأدلتها',
        level: 'مبتدئ',
        totalPages: 28,
        currentPage: 28,
        lastReadDate: DateTime.now(),
        startedDate: DateTime.now(),
        completedDate: DateTime.now(),
      );
      await progressService.saveBookProgress(validBook);

      final retrieved = await progressService.getBookProgress('bk_usul_thalatha');
      expect(retrieved, isNotNull);
      expect(retrieved!.isCompleted, isTrue);
      expect(retrieved.currentPage, equals(28));

      // Test ProgressService per-record recovery
      await prefs.setString('book_progress', json.encode({
        'book_1': {'bookId': 'book_1', 'completedLessons': 5, 'totalLessons': 10},
        'corrupt': 'NOT A MAP',
        'book_2': {'bookId': 'book_2', 'completedLessons': 10, 'totalLessons': 20},
      }));

      final legacyProgress = ProgressService();
      final allLegacy = await legacyProgress.getAllProgress();
      expect(allLegacy.length, equals(2));
      expect(allLegacy.any((b) => b.bookId == 'book_1' && b.completedLessons == 5), isTrue);
      expect(allLegacy.any((b) => b.bookId == 'book_2' && b.completedLessons == 10), isTrue);
    });

    // ════════════════════════════════════════════════════════════════════════
    // Journey 5: Stalled / Cancelled / Retry Quran Audio Download (C01, C02, C14-C16)
    // ════════════════════════════════════════════════════════════════════════
    test('Journey 5: Downloader rejects HTML captive portals, empty/truncated bodies, and cleans up cancellations', () async {
      final downloader = QuranAudioDownloader();
      final tempAudioDir = await Directory.systemTemp.createTemp('quran_audio_test_');
      QuranAudioDownloader.testBaseDir = tempAudioDir;

      try {
        // 1. Rejects 200 OK with HTML content-type (Captive portal)
        final htmlClient = MockClient((request) async {
          return http.Response('<html><title>Wifi Portal</title></html>', 200,
              headers: {'content-type': 'text/html; charset=utf-8'});
        });
        await downloader.downloadSurah(surah: 108, client: htmlClient);
        expect(await QuranAudioDownloader.isSurahDownloaded(108), isFalse);

        // 2. Rejects empty body (0 bytes)
        final emptyClient = MockClient((request) async {
          return http.Response.bytes([], 200, headers: {'content-type': 'audio/mpeg'});
        });
        await downloader.downloadSurah(surah: 108, client: emptyClient);
        expect(await QuranAudioDownloader.isSurahDownloaded(108), isFalse);

        // 3. Rejects truncated stream (Content-Length mismatch)
        final truncatedClient = MockClient.streaming((request, bodyStream) async {
          return http.StreamedResponse(
            Stream.value(List.filled(100, 42)),
            200,
            contentLength: 5000,
            headers: {'content-type': 'audio/mpeg'},
          );
        });
        await downloader.downloadSurah(surah: 108, client: truncatedClient);
        expect(await QuranAudioDownloader.isSurahDownloaded(108), isFalse);

        // 4. Cancellation mid-stream cleans up temp files
        final cancelClient = MockClient((request) async {
          if (request.url.path.contains('108002')) {
            downloader.cancelDownload(108);
            throw http.ClientException('Cancelled by user', request.url);
          }
          return http.Response.bytes(List.filled(50, 42), 200, headers: {'content-type': 'audio/mpeg'});
        });
        await downloader.downloadSurah(surah: 108, client: cancelClient);
        final reciter = QuranAudioService().selectedReciter;
        final surahDir = await QuranAudioDownloader.getSurahDir(108, reciter.id);
        if (surahDir.existsSync()) {
          final tmpFiles = surahDir.listSync().where((f) => f.path.endsWith('.tmp'));
          expect(tmpFiles, isEmpty);
        }

        // 5. Successful download of all ayahs
        final successClient = MockClient((request) async {
          return http.Response.bytes(List.filled(50, 42), 200, headers: {'content-type': 'audio/mpeg'});
        });
        await downloader.downloadSurah(surah: 108, client: successClient);
        expect(await QuranAudioDownloader.isSurahDownloaded(108), isTrue);
        expect(await QuranAudioDownloader.getSurahDownloadedBytes(108), equals(150)); // 3 ayahs * 50 bytes
      } finally {
        QuranAudioDownloader.testBaseDir = null;
        if (tempAudioDir.existsSync()) {
          tempAudioDir.deleteSync(recursive: true);
        }
      }
    });

    // ════════════════════════════════════════════════════════════════════════
    // Journey 6: Islamic Quiz Load, Resume, Invariants & Completion (C23)
    // ════════════════════════════════════════════════════════════════════════
    test('Journey 6: Quiz level questions load and duplicate completion is strictly idempotent', () async {
      final prefs = await SharedPreferences.getInstance();
      final quizProgressService = QuizProgressService(prefs);

      // 1. Verify level questions exist and satisfy schema invariants
      final level = IslamicQuizCatalog.getLevel('aqidah_l1');
      expect(level, isNotNull);
      expect(level!.questions.length, greaterThanOrEqualTo(5));

      for (final q in level.questions) {
        expect(q.id, isNotEmpty);
        expect(q.question, isNotEmpty);
        expect(q.options.length, equals(4));
        expect(q.correctIndex, inInclusiveRange(0, 3));
      }

      // 2. Complete the quiz session for the first time
      const sessionToken = 'quiz_session_20261024_001';
      final res1 = await quizProgressService.recordLevelResult(
        levelId: 'aqidah_l1',
        correctCount: 5,
        totalQuestions: 5,
        maxStreak: 5,
        sessionCompletionId: sessionToken,
      );

      expect(res1.hasPassed, isTrue);
      expect(res1.scorePercentage, equals(100.0));
      expect(res1.earnedStars, equals(3));
      expect(res1.earnedXp, greaterThan(0));

      final statsAfterFirst = quizProgressService.getUserStats();
      expect(statsAfterFirst.totalXp, greaterThan(0));
      expect(statsAfterFirst.totalQuizzesTaken, equals(1));
      expect(statsAfterFirst.totalQuestionsAnswered, equals(5));
      expect(statsAfterFirst.totalCorrectAnswers, equals(5));

      // 3. Complete again with the duplicate session token -> MUST BE IDEMPOTENT
      final res2 = await quizProgressService.recordLevelResult(
        levelId: 'aqidah_l1',
        correctCount: 5,
        totalQuestions: 5,
        maxStreak: 5,
        sessionCompletionId: sessionToken,
      );

      expect(res2.earnedXp, equals(0)); // Zero XP for duplicate completion
      final statsAfterSecond = quizProgressService.getUserStats();
      expect(statsAfterSecond.totalXp, equals(statsAfterFirst.totalXp));
      expect(statsAfterSecond.totalQuizzesTaken, equals(statsAfterFirst.totalQuizzesTaken));
      expect(statsAfterSecond.totalQuestionsAnswered, equals(statsAfterFirst.totalQuestionsAnswered));
      expect(statsAfterSecond.totalCorrectAnswers, equals(statsAfterFirst.totalCorrectAnswers));
    });

    // ════════════════════════════════════════════════════════════════════════
    // Journey 7: Coherent Native Widget Snapshots & Calculation (C11, C12, C22, C30)
    // ════════════════════════════════════════════════════════════════════════
    test('Journey 7: Multi-instance prayer serialization and atomic native widget snapshot versioning', () async {
      final prefs = await SharedPreferences.getInstance();

      // 1. Invariants of Algerian prayer times
      final alger = VerifiedCitiesCatalog.findNearest(36.7538, 3.0588);
      expect(alger, isNotNull);
      expect(alger!.name, contains('الجزائر'));

      final fixedDate = DateTime(2026, 10, 24, 12, 0, 0);
      final testPrayerService = TestPrayerTimeService(() => fixedDate);
      final day = await testPrayerService.getPrayerTimesDay();
      expect(day.prayers.length, 6); // Includes Sunrise

      final fajr = day.prayers[AppStrings.prayerFajr]!;
      final dhuhr = day.prayers[AppStrings.prayerDhuhr]!;
      final asr = day.prayers[AppStrings.prayerAsr]!;
      final maghrib = day.prayers[AppStrings.prayerMaghrib]!;
      final isha = day.prayers[AppStrings.prayerIsha]!;
      expect(fajr.isBefore(dhuhr), isTrue);
      expect(dhuhr.isBefore(asr), isTrue);
      expect(asr.isBefore(maghrib), isTrue);
      expect(maghrib.isBefore(isha), isTrue);

      // 2. Serialized prayer scheduling across two distinct instances (C30 / R48)
      PrayerScheduleService.resetSharedStateForTesting();
      final recordingNotif = RecordingNotificationService();
      final inst1 = PrayerScheduleService(
        notificationService: recordingNotif,
        prayerTimeService: testPrayerService,
        now: () => fixedDate,
      );
      final inst2 = PrayerScheduleService(
        notificationService: recordingNotif,
        prayerTimeService: testPrayerService,
        now: () => fixedDate,
      );

      final results = await Future.wait([
        inst1.refreshSchedulesIfNeeded(force: false),
        inst2.refreshSchedulesIfNeeded(force: false),
      ]);
      expect(results[0].isSuccess, isTrue);
      expect(results[1].isSuccess, isTrue);
      // Exactly one instance schedules 7 days; second sees fresh fingerprint and skips (0 attempted)
      expect(
        (results[0].totalAttempted > 0 && results[1].totalAttempted == 0) ||
        (results[0].totalAttempted == 0 && results[1].totalAttempted > 0),
        isTrue,
      );
      expect(recordingNotif.scheduledPrayerIds.length, equals(34)); // Fajr past at 12:00 -> 4 remaining today + 30 next 6 days

      // 3. Native widget snapshot atomic versioning across all 10 keys (C11, C12, C22)
      final eval = PrayerWidgetStateEvaluator.evaluate(
        now: DateTime(2026, 10, 24, 15, 0),
        all: day.prayers,
      );

      final vBefore = HomeWidgetSnapshot.snapshotVersion;
      await HomeWidgetSnapshot.savePrayerSnapshot(eval, preResolvedDark: true);
      final vAfter = HomeWidgetSnapshot.snapshotVersion;

      expect(vAfter, greaterThan(vBefore));
      expect(prefs.getInt('widget_snapshot_version'), equals(vAfter));
      expect(prefs.getInt('next_prayer_epoch_ms'), equals(eval.targetPrayerTime.millisecondsSinceEpoch));
      expect(prefs.getString('next_prayer_name'), equals(eval.activePrayerName));
      expect(prefs.getString('prayer_display_title'), equals(eval.displayTitle));
      expect(prefs.getInt('prayer_color_value'), isNotNull);
      expect(prefs.getInt('widget_text_color'), isNotNull);
      expect(prefs.getBool('widget_is_dark'), isTrue);
      expect(prefs.getString('prayer_widget_theme_mode'), equals('dark'));
      expect(prefs.getString('countdown_prefix'), equals('بعد '));
      expect(prefs.getString('prayer_status_label'), equals(eval.statusLabel));
      expect(prefs.getBool('is_prayer_active'), isFalse);
    });
  });
}
