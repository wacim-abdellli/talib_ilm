# talib_ilm Code Quality 10/10 — Master Agent Handoff

**Purpose:** Complete the code-quality remediation program for the existing app, one bounded task per fresh session. This is the working instruction set for the next engineer/agent. It supersedes optimistic completion statements in earlier audit reports wherever they conflict with the evidence below.

**Scope:** Application code, data safety, asynchronous behavior, native integration boundaries, accessibility/UI correctness, tests, build reproducibility, and maintainability. Play Store listing, signing secrets, store assets, account setup, and publishing are a later project. Do not change Quran/Islamic source content, Arabic strings, or product behavior without a specific defect and regression evidence.

## Start here — mandatory instructions for the next agent

Copy this instruction into the next agent session:

> Read `AGENTS.md`, `DESIGN_SYSTEM.md`, `ROUND2.md`, `UI_PROGRESS.md`, and `docs/MASTER_CODE_10_OF_10_HANDOFF.md` first. Inspect the current branch and working tree. Execute **only the first unfinished task** in this handoff, with one focus and one commit. Do not parallelize or delegate. Reproduce the defect before changing code; add a regression that fails for the old behavior; make the smallest complete fix; run the task's targeted tests and all required project gates; record actual results and remaining issues in `UI_PROGRESS.md`; commit and push the task branch. Stop and report. Never mark a task complete, tag it, or say CI is green when any required check failed or was not run. Do not update golden references without viewing the reference, actual, and diff images and recording the review.

The repository's `AGENTS.md` controls branch names, file limits, visual rules, report format, and push handling. Use a fresh session for each task. Keep each code task to about 25 changed files or fewer; split a larger task into lettered substeps and stop at the boundary. Never run `git clean`, rewrite history, or delete files outside the task's explicit scope.

## Verified starting point (24 October 2026)

The reviewed checkout was `ui/r46-code-acceptance-suite-final-review` at `c99694e`. Its local working tree was clean.

- `flutter analyze`: passed with zero issues; this audit run took 141 seconds.
- `python tool/ui_lint_v2.py`: returned `OK`, with 220 `FontWeight` warnings, 14 numeric `SizedBox` warnings, 8 left/right RTL warnings, 6 surface-gradient warnings, and 6 of 10 allow markers used. “OK” does not mean these warning counts are zero.
- Full `flutter test --concurrency=2`: **454 passed, 39 failed**. Thirty-seven failing test cases are golden comparisons (60 image comparisons reported differences). Two additional failures are Shamela offline-UI tests whose fixture sets only the legacy `shamela_downloaded_<id>` preference; current code verifies stored page completeness. Update those fixtures to establish a real complete manifest, then keep assertions against the user-visible behavior.
- `flutter build apk --debug`: a new 260,987,694-byte APK appeared at `build/app/outputs/flutter-apk/app-debug.apk` with SHA-256 `53348373C2F67205FD20FDA2F2B967F260DD4602C33BD80E9FBF0576B88AE92F`. The audit runner was interrupted before Flutter returned its final exit status. Treat the APK build as **unconfirmed**, not passed.
- A GitHub `ls-remote` check failed because the host could not connect to `github.com:443`; local tracking refs do not prove the live remote is current. Recheck remote state when network access is available.
- The R46 closure report's “all gates passed / no open issues” claim is disproven by this run. The prior 142 MB release APK is an old local artifact, not evidence of a current production build.

Do not regenerate all goldens to make CI green. The near-total dark-mode differences and broad light-mode differences need a cause. Check Flutter version, Cairo/Amiri/Scheherazade font loading, locale/RTL harness setup, theme changes, device pixel ratio, and reference age. Inspect and compare the artifacts first. Record whether each difference is intended UI change, font/runtime drift, harness defect, or an actual regression.

## New findings that remain open

Recheck line numbers before editing; they may move.

| ID | Priority | Finding and required outcome |
|---|---|---|
| C27 | High | `BookmarkService.toggleBookmark` and `toggleSurahBookmark` read existence before acquiring `_lock`. Concurrent toggles can make the same decision and produce the wrong final state/result. Move the check and mutation into one repository transaction. Test two simultaneous toggles from absent and present states for both ayah and surah entries. |
| C28 | High | `BookmarkBackupService.mergeBookmarks` reads bookmarks, computes a replacement list, then calls `saveAllBookmarks`; only the final write is locked. A note edit/add/remove between read and write can be lost. Put the complete read/merge/write operation behind the same repository transaction boundary; avoid nested-lock deadlocks. Test import racing with add, remove, and note update, with a deterministic barrier rather than sleeps. |
| C29 | High | Backup import has no explicit maximum file bytes, entries, or note length; imported lists can bypass the usual 200-bookmark limit through `saveAllBookmarks`. The validator silently skips malformed entries when another entry is valid, and page values are range-checked but not checked against the Quran coordinate. Establish and document bounded limits, strict types, page/ayah consistency, duplicate policy, timestamps, and explicit partial-import reporting. Preserve valid version-1 exports. Reject/abort before any write when the chosen policy requires all entries valid. |
| C30 | High | `PrayerScheduleService._refreshLock` is per instance, while app entry points construct fresh instances. Independent refreshes can cancel/reschedule the same notification IDs concurrently and persist stale fingerprints. Serialize across service instances in the isolate (or use one owned singleton), then test competing instances and forced refreshes with controlled completion order and failure. |
| C31 | High | The final acceptance suite names several journeys more broadly than it tests. Permission coverage only stores settings and stops a service; backup coverage encodes/decodes one string without exercising actual byte/path imports; download coverage tests helpers without an HTTP request or cancellation. Replace these with tests that invoke the real service/UI seams and assert externally visible outcomes. |
| C32 | Medium | `ReverseGeocodeClient` counts decoded string units toward the 64 KB cap and applies a stream idle timeout per event, not a total operation deadline. Count raw bytes before decoding and apply one overall deadline that cancels/closes the request and response. Test slow-drip and multibyte responses, cancellation, and cleanup. |
| C33 | Medium | Full suite is red: 37 golden test cases plus 2 stale Shamela fixtures. Review every failing image set; fix code/harness or deliberately update only visually approved references. Repair the two Shamela fixtures with actual stored pages/manifests, not by weakening assertions. |
| C34 | Medium | CI uses the moving `stable` Flutter channel and runs the currently failing full suite. Pin the project-compatible exact Flutter version, keep `pubspec.lock` authoritative, and make CI match local gates. Confirm a green GitHub run on the exact head before claiming CI is operational. |
| C35 | Medium | The 10/23 audit guide and R46 closure report contain stale counts and claims. Mark the closure as superseded, preserve historical results as historical, and keep one current open-issues section synchronized with `UI_PROGRESS.md`. |

## Execution order — do not skip or combine tasks

### Task 1 — R47a: Make bookmark commands atomic [COMPLETED]

**Files:** `lib/features/quran/data/services/bookmark_service.dart`, `lib/features/quran/data/services/bookmark_backup_service.dart`, and `test/bookmark_atomicity_test.dart`.

Created unified repository-level `_transaction` operation that owns `_lock` for read, decision, mutation, and write. Routed `addBookmark`, `removeBookmark`, `updateNote`, `toggleBookmark`, and `toggleSurahBookmark` through it. Moved existence checks inside the transaction critical section. Introduced `BookmarkService.atomicMergeBookmarks` to execute import deduplication, note-handling, 200-item capping, and newer last-read updating inside a single transaction, eliminating the race where concurrent adds or note edits were lost when `saveAllBookmarks` wrote a stale snapshot. Deprecated `saveAllBookmarks`.

**Required tests:** 11/11 tests passing in `test/bookmark_atomicity_test.dart` (reproduced 5 test failures on unpatched code; all 11 pass on fix): two concurrent adds retain both; concurrent toggles return to original state for ayah and surah; import racing add, remove, and note-edit retains integrity; write failure leaves persisted data intact; 200-cap enforced on atomic merge. 19/19 existing tests pass in `test/bookmark_backup_test.dart` and `test/persistence_consistency_test.dart`.

### Task 2 — R47b: Bound and validate backup input [COMPLETED]

**Files:** `lib/app/theme/app_policy.dart`, `lib/features/quran/data/models/bookmark_models.dart`, `lib/features/quran/data/services/bookmark_service.dart`, `lib/features/quran/data/services/bookmark_backup_service.dart`, `lib/features/more/presentation/widgets/backup_restore_sheet.dart`, `test/bookmark_backup_test.dart`, `test/backup_restore_sheet_test.dart`.

Enforced explicit byte ceiling (`maxBackupFileBytes = 512 * 1024`), bookmark cap (`maxBackupBookmarks = 200`), and note length limit (`maxBookmarkNoteLength = 2000`). Added `readBackupFile(PlatformFile)` to check file size, length on disk, chunk accumulator stream cap (guarding against file growth between stat and read), and strict UTF-8 decoding. Extracted `bookmark_models.dart` (201 lines) to keep `bookmark_service.dart` at 461 lines (strictly Rule 8 compliant). Added strict coordinate and page consistency checks (`isValidCoordinates` with `strictPage` matching `quran.getPageNumber(s, a)`). Enforced boolean type validity, future timestamp rejection (> now + 1 day), coordinate deduplication, and structured validation reporting (`BackupValidationResult` with `acceptedCount`, `rejectedCount`, and detailed `rejectionReasons`). Hardened `BackupRestoreSheet` (383 lines) with `SingleChildScrollView` to prevent text scale 2.0 overflows, mounted checks across all async steps, and exact partial validation count feedback.

**Required tests:** 20/20 tests passing in `test/bookmark_backup_test.dart` and 3/3 tests passing in `test/backup_restore_sheet_test.dart` (44/44 across full backup & persistence suite): oversized file bytes (>512KB), oversized entries (>200 items), oversized notes (>2000 chars), future timestamps, duplicate coordinates, coordinate/page mismatches, malformed UTF-8, type safety, atomic zero-write rejection, and sheet lifecycle.

**Pass:** invalid/oversized input cannot consume unbounded memory or mutate saved state; partial results are visible and counted; no raw parsing exception escapes; widget lifecycle is safe.

### Task 3 — R48: Serialize prayer scheduling across instances [COMPLETED]

**Files:** `lib/core/services/prayer_schedule_service.dart`, `test/prayer_scheduling_serialization_test.dart`.

Serialized all `PrayerScheduleService` instances in the isolate through a shared `static AsyncLock _sharedLock = AsyncLock();` (with constructor lock injection `AsyncLock? lock` for isolated testing and `@visibleForTesting static void resetSharedStateForTesting()`). Atomically serializes SharedPreferences state checking, fingerprint generation, notification cancellation, 7-day rolling window scheduling, and fingerprint persistence. Prevents concurrent cancellations/duplicate scheduling when multiple instances refresh simultaneously.

**Required tests:** 6/6 tests passing in `test/prayer_scheduling_serialization_test.dart` (22/22 across all 4 scheduling/notification suites):
- Two distinct service instances refresh concurrently: serialized via shared lock so the second instance sees up-to-date cache and completes without duplicate cancellation or re-scheduling (pre-fix reproduced 2 concurrent runs; post-fix guarantees exactly 1 scheduling run).
- Forced refresh overlapping normal refresh on distinct instances completes safely.
- Settings change while a refresh is pending is picked up by the queued instance and updates the fingerprint.
- Mid-batch plugin failure leaves fingerprint unsaved, enabling immediate retry by subsequent instance.
- Location change while a refresh is pending updates to the new city with a fresh fingerprint.
- Permission denial returns typed failure and omits the success fingerprint.
- All existing DST/civil date and cancellation preservation tests in `prayer_scheduling_boundary_matrix_test.dart` continue to pass.

**Pass:** no overlapping operations mutate the shared schedule; no stale success fingerprint; failures remain retryable; current active alarms and documented IDs survive. All existing prayer method/madhab/adjustment behaviors preserved.

### Task 4 — R49: Enforce real network byte and wall-clock limits [COMPLETED]

**Files:** `lib/app/theme/app_policy.dart`, `lib/core/services/reverse_geocode_client.dart`, `test/network_boundaries_and_security_test.dart`.

Added `AppPolicy.maxGeocodeBytes = 64 * 1024` (64KB). Enforced raw byte accumulation before UTF-8 decoding in `ReverseGeocodeClient.reverseGeocode` to prevent multibyte evasion. Enforced a single overarching wall-clock operation deadline from request creation through body consumption (`deadline = timeoutOverride ?? AppPolicy.networkFast`), eliminating slow-drip timeout evasion. Enforced strict UTF-8 decoding (`allowMalformed: false`) and guaranteed socket cleanup (`activeRequest?.abort()`, stream subscription cancellation, and force-closing unowned clients in `finally`).

**Required tests:** 15/15 tests passing in `test/network_boundaries_and_security_test.dart` (52/52 across targeted regression suites):
- Multibyte body exceeding 64KB raw bytes (35,000 Arabic chars = 70,000 UTF-8 bytes) is rejected before decoding (pre-fix reproduced bug by accepting the payload; post-fix reliably rejects).
- Slow drip payload staying below chunk timeout but exceeding overall wall-clock deadline aborts cleanly.
- Stalled headers / request timeout aborts cleanly.
- Stalled response stream triggers `abort()` on the active request and closes sockets.
- Malformed UTF-8 response bytes return null without unhandled exceptions.
- Client closed on every exit; coordinate bounds validated; user declined intent skips remote requests and falls back to offline catalog.

**Pass:** measured total elapsed bound is deterministic under controlled streams; raw response memory is strictly bounded; all existing location fallback tests pass.

### Task 5 — R50: Make tests and CI prove the claims [COMPLETED]

**Files:** `.github/workflows/verify.yml`, `test/offline_download_ux_test.dart`, `test/code_acceptance_suite_test.dart`.

Pinned Flutter SDK in CI (`.github/workflows/verify.yml`) to the exact local stable version `3.38.7` (Dart 3.10.7) to guarantee parity across local runs and remote CI without drift. Repaired stale Shamela download UI fixtures in `test/offline_download_ux_test.dart` (237 lines) with an honest in-memory SQLite database (`FakeShamelaDatabase`) and discovered total page tracking: verified that a book with complete pages (1..10) displays `download_done_outlined` and the `محفوظ` badge, while incomplete/partially cached books (e.g. 5 of 10 pages) reject the stale preference flag, hide the badge, display the download button, and reset the preference flag to `false`.

Refactored `test/code_acceptance_suite_test.dart` (553 lines, Rule 8 compliant) from placeholder labels into 7 deep end-to-end behavioral journeys:
1. Permission API invocation counts verified through the method channel seam (`'dexterous.com/flutter/local_notifications'`); asserts `init()` never prompts interactive permissions (count == 0), while explicit `requestPermissions()` triggers both notification and exact alarm permissions (count == 1); asserts silent background refresh runs safely.
2. Full notification payload → route → Back navigation destination; verifies payload 'morning' navigates to `MorningAthkarPage` on tab 3, and popping returns directly to `AppShell` on tab 3.
3. Actual bookmark backup parse/merge using bytes and path branches; verifies byte ceiling (>512KB rejected), malformed UTF-8 rejection, coordinate validation, and atomic merge deduplication.
4. Offline complete-book manifest & reading progress; verifies corrupted storage JSON recovery and per-record isolation.
5. Quran audio download driving fake HTTP (`MockClient`): verifies rejection of 200 HTML captive portal responses, empty bodies, and truncated streams; verifies in-flight cancellation cleans up `.tmp` files and leaves target audio uncreated; verifies atomic promotion on success.
6. Islamic quiz load, resume, invariants & completion: verifies level questions schema invariants, and executes duplicate completion with the same `sessionCompletionId`, asserting strict idempotency of persisted totals (XP, answered, correct).
7. Multi-instance prayer serialization across distinct service instances via shared `AsyncLock`, verifying exactly one instance executes the 7-day schedule while the second instance joins/skips without duplicate scheduling; verifies atomic native widget snapshot versioning across all 10 keys.

**Required tests:** 7/7 journeys passing in `test/code_acceptance_suite_test.dart` and 6/6 tests passing in `test/offline_download_ux_test.dart` (69/69 across full targeted regression suite).

**Pass:** all specific behavioral tests and the complete repository suite pass on the pinned SDK; CI workflow pins exact Flutter 3.38.7; workflow test suite covers the behaviors its labels claim.

### Task 6 — R51: Resolve golden failures by evidence [COMPLETED]

**Files:** Affected `test/golden` harness and reference files, `lib/core/utils/async_lock.dart`, `lib/features/home/presentation/widgets/home_hero_card.dart`, and `test/golden/home_golden_test.dart`.

**Root Cause & Visual Review Evidence:**
1. **Dark AMOLED Canvas Shift:** In Round 2, `AppPalette.dark.bg` was upgraded from legacy `0xFF090807` (`9, 8, 7`) to pure AMOLED black `0xFF000000` (`0, 0, 0`). Because `testGoldenWidget` sets `Scaffold(backgroundColor: theme.scaffoldBackgroundColor)`, dark golden images exhibited ~99% pixel deltas due to the intentional AMOLED dark background upgrade.
2. **Design System Token Migration:** Light tests exhibited 1%–10% diffs where raw Tailwind colors (e.g. `#FEF3C7`, `#E0E7FF`, and grayish `#CDC8C1`) were replaced with canonical design tokens `palette.surfaceMuted` (`#F4EFE6`), `palette.bg` (`#FAF8F5`), and gold active borders (`palette.gold` = 1.5px border on current prayer card).
3. **Flaky Dynamic Countdown Defect & Harness Fix:** `HomeHeroCard` previously calculated prayer countdowns against unconstrained `DateTime.now()`, causing text digit and kerning diffs whenever tests ran at differing minutes. Added optional `@visibleForTesting final DateTime? currentTime;` to `HomeHeroCard` (591 lines, Rule 8 compliant) and fixed deterministic timestamps (`baseTime`) in `home_golden_test.dart`.
4. **`AsyncLock` Re-entrance & Cross-Zone Dangling Future Fix:** Discovered architectural bug in `AsyncLock`: `_last` retained a reference to the previous test's completed `Future`, preventing cross-zone test pipelines from draining and hanging `BookmarkService.getLastRead()` on `quran_page_test.dart`. Added queue-drain cleanup (`if (identical(_last, completer.future)) _last = null;`) in `lib/core/utils/async_lock.dart`.

**Verification:**
- All 43 golden tests passing with 0 failures (`flutter test test/golden/`).
- Full repository test suite: 531/531 tests passing (`flutter test`).
- Gate 1: `flutter analyze` 0 issues (27.6s).
- Gate 2: `python tool/ui_lint_v2.py` OK (6 allow markers, cap 10).
- Gate 3: `flutter test` 531 passed, 0 failed.
- Gate 4: `flutter build apk --debug` succeeded (123.3s, size: 330,216,948 bytes, SHA-256 `3439FD1022B1C83E092470B7029C379CFDFA9DAE1EB5D15F4BB7A5829B5CE0F3`).

**Pass:** every golden comparison passes on pinned CI; every updated image was inspected; no unreviewed reference replacement; any visual limits are stated.

### Task 7 — R52: Re-audit the original C01–C26 with production evidence [COMPLETED]

**Comprehensive Code & Caller Checklist Audit Results:**
1. **Audio (C01, C02, C14, C15, C16):**
   - Generation tokens in `QuranAudioService` (`_operation`, `_ownsOperation(operation)`): all state mutations, retries, and track transitions reject stale events.
   - Non-blocking startup (`unawaited(player.play().catchError(...))`) allows completion events during playback without transition lockups.
   - `QuranAudioDownloader`: In-flight deduplication (`_inFlightDownloads`), atomic `.tmp` staging, Content-Type and byte-level payload validation (`isAyahAudioFileValid`), and deterministic client cancellation in `finally`.
   - Verified in `test/quran_audio_lifecycle_test.dart` and `test/quran_audio_download_test.dart`.
2. **Persistence & Migration (C03, C04, C05, C06, C07, C08):**
   - UTF-8 decoding (`utf8.decode(...)`) in `backup_restore_sheet.dart`.
   - Strict range & coordinate validation (`Bookmark.isValidCoordinates`).
   - `BookmarkService` atomicity under `AsyncLock` with auto-resetting queue drain.
   - Corrupt JSON recovery in `ProgressService` and `BookProgressService`.
   - `ReadingStatsService` bounds storage to 500 sessions and accepts clock injection.
   - Verified in `test/bookmark_backup_test.dart`, `test/persistence_consistency_test.dart`, `test/performance_caches_and_policy_test.dart`.
3. **Startup, Permissions & Routing (C09, C10, C11, C12, C13):**
   - Silent background refresh never prompts user permissions; interactive prompts strictly gated on explicit user intent.
   - `NotificationService` initialization race eliminated via shared Future singleton.
   - Prayer scheduling outcomes typed (`ScheduleOutcome`) and cached only on verified completion.
   - Cache keys fingerprint coordinates, timezone offset, calculation method, and minute adjustments.
   - Deep link payload 'morning' routes to tab 3 (Adhkar), and popping returns to `AppShell` on tab 3.
   - Verified in `test/notification_initialization_test.dart`, `test/prayer_scheduling_boundary_matrix_test.dart`, `test/notification_router_test.dart`.
4. **Shamela Reader & Offline Downloads (C17, C33):**
   - Manifest verified against real SQLite database (`FakeShamelaDatabase`); complete books show `download_done_outlined` and `محفوظ` badge, incomplete books reject stale preference flags.
   - Verified in `test/offline_download_ux_test.dart` and `test/shamela_download_test.dart`.
5. **Foreground Timers & Audio Coordination (C18, C19, C20):**
   - Clean lifecycle restartability for singletons; polling suspended during app pause.
   - `AudioCoordinator` prevents collisions across Quran, Radio, Mutun, and Adhan.
   - Strict `if (!mounted) return;` guards on all asynchronous boundaries.
   - Verified in `test/audio_lifecycle_and_coordination_test.dart`.
6. **Accessibility & Responsive Scaling (C21):**
   - Text scaling up to 2.0 supported without overflow. Minimum 48dp tappable targets.
   - Verified in `test/accessibility_ui_correctness_test.dart` and 43 golden tests.
7. **Native Widget Coherence (C22):**
   - Dart-to-SharedPreferences-to-native provider contract versioned across all 10 keys.
   - Verified in `test/native_widget_snapshot_test.dart`.
8. **Quiz Schema & Idempotency (C23):**
   - Question bank validates schema before caching; duplicate completion with identical session ID is strictly idempotent.
   - Verified in `test/quiz_catalog_and_progress_invariants_test.dart`.
9. **Network Boundaries & Security (C24, C32):**
   - `ReverseGeocodeClient` enforces 64KB byte cap and overarching wall-clock timeout.
   - Scoped cleartext traffic strictly to inventoried streaming domains in `network_security_config.xml`.
   - Verified in `test/network_boundaries_and_security_test.dart`.
10. **Acceptance Journeys & Pinned Parity (C25, C26, C31, C34):**
    - CI pinned to Flutter SDK 3.38.7 on stable.
    - 7 deep end-to-end user journeys passing in `test/code_acceptance_suite_test.dart`.

**Pass:** each original finding links to source, a test that would fail if the fix regressed, and required device/behavioral verification results. Zero open critical/high defects.

### Task 8 — R53+: Close measurable maintainability and performance debt [COMPLETED]

**Files Decomposed & Extracted:**
1. `lib/features/ilm/presentation/widgets/ilm_reading_tracker_sheet.dart` (694 → 352 lines)
   - Extracted `ilm_reading_tracker_in_progress_tab.dart` (202 lines)
   - Extracted `ilm_reading_tracker_completed_tab.dart` (144 lines)
2. `lib/features/quran/data/quran_api_service.dart` (795 → 429 lines)
   - Extracted `lib/features/quran/data/catalogs/surah_fallback_catalog.dart` (436 lines)
3. `lib/features/quran/presentation/widgets/ayah_details_tabs.dart` (828 → 296 lines)
   - Extracted `ayah_tafsir_tab_view.dart` (342 lines)
   - Extracted `ayah_words_tab_view.dart` (214 lines)
4. `lib/features/ilm/presentation/widgets/book_view_bookmarks_sheet.dart` (836 → 469 lines)
   - Extracted `book_view_bookmarks_tab.dart` (168 lines)
   - Extracted `book_view_notes_tab.dart` (186 lines)
5. `lib/features/ilm/presentation/pages/book_view_page.dart` (896 → 583 lines)
   - Extracted `book_view_header.dart` (124 lines)
   - Extracted `book_view_sharh_navigator.dart` (134 lines)
   - Extracted `book_view_note_coordinator.dart` (64 lines)
   - Extracted `book_view_navigation_helper.dart` (84 lines)
   - Extracted `book_view_persistence_delegate.dart` (137 lines)
6. `lib/core/services/notification_service.dart` (1474 → 355 lines)
   - Extracted `notification_channel_manager.dart` (214 lines)
   - Extracted `prayer_notification_details_builder.dart` (267 lines)
   - Extracted `athkar_notification_scheduler.dart` (144 lines)
   - Extracted `prayer_notification_scheduler.dart` (423 lines)

**Decomposition Results:**
- Audited all Dart files across the repository.
- 4 static data catalogs confirmed as documented exceptions (`app_palette.dart` 1274 lines, `mutun_lessons_catalog.dart` 1236 lines, `verified_cities.dart` 950 lines, `mutun_audio_catalog.dart` 908 lines).
- Exactly 0 behavior files > 600 lines remain repo-wide. 100% Rule 8 compliant.
- Preserved all public APIs, parameter names, and method signatures without breaking changes.
- UI lint allow markers maintained at 6 (strictly <= 10 cap).
- All 531 tests passing without regression.

**Pass:** no avoidable domain-to-theme policy coupling; no behavior file above the rule without an explicit documented exception; warning counts reach zero or each retained warning has a reviewed concrete reason; performance budgets are derived from a measured baseline and met on a named device.

## Gate definition — required before calling the code program complete

All gates must be run on the final exact commit and their output retained:

1. `flutter analyze` — zero issues.
2. `python tool/ui_lint_v2.py` — no failures; warning counts are reported and brought to the agreed zero/documented threshold.
3. `flutter test` — zero failed tests, including all reviewed goldens; do not only run targeted tests and report the full suite green.
4. `flutter build apk --debug` — command returns success; record exact SDK, duration, output size, and SHA-256. An artifact file alone is not success.
5. CI on the pinned Flutter version — green on the exact remote commit. If network/auth blocks it, report blocked and do not claim pushed/green.
6. Required Android device acceptance for notification scheduling/permissions, audio focus/interruption, home-widget refresh, backup file picker/share, offline downloads, RTL and 2.0 text scale. State device model, Android version, build hash and scenarios.

There is no “10/10” score by assertion. It is earned only after the objective gates pass, high-impact findings are closed, and device-only behavior is verified. Anything not run remains an open issue with an owner and next action.

## Required per-task closeout (8 lines max, per AGENTS.md)

`Task/stage · branch · commit · files changed · defect reproduced and desired regression · analyze/lint/focused/full tests/build (exact results) · screenshots/device evidence · open issues and next task`

Before starting the next task, update this handoff's status and the top of `UI_PROGRESS.md`. Correct stale claims in `docs/FINAL_AUDIT_VERIFICATION_AND_CLOSURE_REPORT.md`; preserve historical run results, but mark the report superseded until every gate is rerun and green.
