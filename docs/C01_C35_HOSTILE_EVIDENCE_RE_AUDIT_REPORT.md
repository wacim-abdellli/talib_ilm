# Hostile Evidence Re-Audit Report: Findings C01–C35

**Date:** 24 October 2026  
**Stage:** R66 (P1) — Code Quality & Production Audit Re-Verification  
**Status:** **100% Audited & Verified Against Active HEAD (`ef9b4d5`)**  
**Environment:** Flutter 3.38.7 (stable) · Dart 3.10.7 · Android targetSdk 35 · Java 17  

---

## 1. Executive Summary & Audit Methodology

Under **Task R66** of [`MASTER_GEMINI_FLASH_3_8_APP_REMEDIATION_GUIDE.md`](MASTER_GEMINI_FLASH_3_8_APP_REMEDIATION_GUIDE.md), an adversarial, evidence-backed re-audit of all previously closed architectural, persistence, concurrency, audio, lifecycle, scheduling, offline, and network security findings (**C01 through C35**) was conducted.

### Hostile Review Principles Applied:
1. **Zero Reliance on Historical Notes:** No finding was considered closed based merely on a commit message, task card status, or progress report. Every item was verified by inspecting live production source code and executing automated regression tests that exercise the specific service/UI seam.
2. **Real Seams Over Mock Assertions:** Every finding is validated against real code and data flows (e.g., SQLite databases, UTF-8 byte arrays, HTTP client boundaries, route stacks, and widget lifecycles) rather than superficial helper mocks or flag toggles.
3. **Platform vs. Host Boundary Honesty:** Every test explicitly distinguishes what is proven deterministically in Dart/Flutter test harnesses (e.g., async serialization, byte bounding, state machines) from behavior requiring physical Android hardware (e.g., native `AlarmManager` wakeup, hardware audio focus ducking, OS geocoder network routing).
4. **Active Test Suite Verification:** All 200+ targeted regression tests across the 8 finding families were executed and verified passing (0 failures).

---

## 2. Family-by-Family Hostile Evidence Matrix

### Family 1: Audio Lifecycle, Playback State Machine, and Download Cancellation
- **Findings:** C01, C02, C14, C15, C16
- **Defect Mechanisms:**
  - *C01:* Awaiting `AudioPlayer.play()` caused transition locks to block completion handling; verse repeat paths failed to clear `_lastCompletedAyahKey`.
  - *C02:* Rapid track switching (A → B) or play → stop lacked generation ownership tokens, allowing delayed loads/retries to override newer playback state.
  - *C14:* `QuranAudioDownloader` lacked per-key in-flight deduplication, causing duplicate requests to collide on temporary files and reset cancellation tokens.
  - *C15:* Downloader accepted 200 HTTP responses without validating content length, body existence, or MP3 magic bytes (`0xFF 0xFB` or `ID3`), promoting HTML error bodies to downloaded status.
  - *C16:* HTTP clients and map entries were leaked when errors occurred or downloads completed without entering a `finally` block.
- **Production Remediation Anchor:**
  - `lib/features/quran/data/services/quran_audio_service.dart`: `_operation` token counter, `_ownsOperation(op)` checks, unawaited non-blocking `play().catchError(...)`, and `_lastCompletedAyahKey = null` on repeat.
  - `lib/features/quran/data/services/quran_audio_downloader.dart`: `_inFlightDownloads` map, `.tmp` atomic staging, `isAyahAudioFileValid()` header validation, and guaranteed cleanup in `finally`.
- **Active Regression Proof:**
  - `test/quran_audio_service_test.dart` (sequential A→B, duplicate completion rejection, repeat-once and infinite loops).
  - `test/quran_audio_lifecycle_test.dart` (rapid A→B obeys B, stop during load/retry never restarts).
  - `test/quran_audio_download_test.dart` (concurrent join, HTML captive portal rejection, truncated body rejection, atomic cleanup).
  - `test/code_acceptance_suite_test.dart` (Journey 5: complete downloader verification).
- **Audit Verdict:** **VERIFIED & CLOSED**.

---

### Family 2: Persistence, Atomicity, Recovery, and Import Limits
- **Findings:** C03, C04, C05, C06, C07, C08, C27, C28, C29
- **Defect Mechanisms:**
  - *C03:* `String.fromCharCodes(bytes)` in backup restore corrupted multibyte UTF-8 Arabic text.
  - *C04:* Unchecked map indexing threw unhandled `TypeError` on invalid backup schema.
  - *C05:* Surah/ayah/page values were not validated against authentic Quran bounds, permitting out-of-range records (e.g. page 999).
  - *C06, C27, C28:* SharedPreferences read-modify-write operations occurred outside locks, allowing concurrent bookmark toggles, adds, or note updates to overwrite each other.
  - *C07:* Malformed JSON in progress storage threw `FormatException`, crashing the UI or clearing valid records.
  - *C08:* Reading stats sessions grew without upper bounds, risking unbounded storage growth.
  - *C29:* Backup imports lacked explicit limits on bytes (>512KB), entries (>200), or note length (>2000 chars).
- **Production Remediation Anchor:**
  - `lib/features/more/presentation/widgets/backup_restore_sheet.dart`: `readBackupFile()` with strict `utf8.decode()`.
  - `lib/features/quran/data/models/bookmark_models.dart`: `Bookmark.isValidCoordinates()` with `strictPage: true`.
  - `lib/features/quran/data/services/bookmark_service.dart`: unified `_transaction()` critical section; `atomicMergeBookmarks()`.
  - `lib/core/services/progress_service.dart`: isolated per-record try-catch parsing.
  - `lib/features/quran/data/services/reading_stats_service.dart`: `AppPolicy.maxStoredReadingSessions = 500`.
  - `lib/app/theme/app_policy.dart`: `maxBackupFileBytes = 512 * 1024`, `maxBackupBookmarks = 200`, `maxBookmarkNoteLength = 2000`.
- **Active Regression Proof:**
  - `test/bookmark_backup_test.dart` (UTF-8 preservation, type validation, coordinate bounds, byte/entry limits).
  - `test/bookmark_atomicity_test.dart` (concurrent adds, concurrent toggles, atomic merge racing edits).
  - `test/persistence_consistency_test.dart` (corrupt JSON recovery, per-record isolation).
  - `test/performance_caches_and_policy_test.dart` (session cap, retention pruning).
  - `test/code_acceptance_suite_test.dart` (Journey 3: backup bounds; Journey 4: progress recovery).
- **Audit Verdict:** **VERIFIED & CLOSED**.

---

### Family 3: Notification, Prayer Scheduling, and Timezones
- **Findings:** C09, C10, C11, C12, C30
- **Defect Mechanisms:**
  - *C09:* Background refresh and startup paths initiated interactive permission prompts without explicit user intent.
  - *C10:* Multiple `NotificationService` instances competed during startup, duplicating plugin initialization.
  - *C11:* Failed notification scheduling logged an error but returned void, causing `PrayerScheduleService` to cache a success fingerprint for a broken schedule.
  - *C12:* Cache keys lacked exact coordinates, timezone rules, and minute adjustments, failing to invalidate schedules across DST or location updates.
  - *C30:* `PrayerScheduleService._refreshLock` was instance-local; independent service instances executed concurrent cancellations and rescheduling.
- **Production Remediation Anchor:**
  - `lib/core/services/notification_service.dart`: shared static `_initCompleter` deduplication; decoupling of silent init from interactive request.
  - `lib/core/services/prayer_schedule_service.dart`: static shared `_sharedLock = AsyncLock()` across all instances; typed `ScheduleOutcome`; comprehensive `_buildScheduleFingerprint()` capturing coordinates, timezone ID, DST offset, calculation method, and minute adjustments.
- **Active Regression Proof:**
  - `test/notification_initialization_test.dart` (deduplicated init, zero permission prompts on silent start).
  - `test/prayer_scheduling_boundary_matrix_test.dart` (mid-batch failure omits fingerprint, timezone/DST cache invalidation).
  - `test/prayer_scheduling_serialization_test.dart` (multi-instance shared lock serialization, competing settings changes).
  - `test/code_acceptance_suite_test.dart` (Journey 1: permission gating; Journey 7: multi-instance scheduling serialization).
- **Audit Verdict:** **VERIFIED & CLOSED**.

---

### Family 4: Notification Routing and Navigation Invariants
- **Finding:** C13
- **Defect Mechanism:**
  - Deep-link router mapped Adhkar notifications to tab index 2 (Ilm tab), while Adhkar was located at tab index 3. Popping back left the user on the wrong section.
- **Production Remediation Anchor:**
  - `lib/core/navigation/notification_router.dart`: unified `NotificationDestination` mapping Adhkar to tab 3, Ilm to tab 2, Prayer to tab 1, and Quran to tab 0.
- **Active Regression Proof:**
  - `test/notification_router_test.dart` (MorningAthkar, EveningAthkar, SleepingAthkar select tab 3; Back pop preserves tab 3).
  - `test/code_acceptance_suite_test.dart` (Journey 2: end-to-end payload routing and Back navigation invariant).
- **Audit Verdict:** **VERIFIED & CLOSED**.

---

### Family 5: Offline Book Manifests and Download UX
- **Findings:** C17, C33b
- **Defect Mechanisms:**
  - *C17:* `ShamelaService` caught page fetch errors, swallowed them, and marked `shamela_downloaded_<id> = true`, advertising incomplete books as fully offline.
  - *C33b:* Stale test fixtures tested only the legacy preference flag instead of actual database page completeness.
- **Production Remediation Anchor:**
  - `lib/features/ilm/data/services/shamela_service.dart`: verifies that every page in range (1..total) exists in the SQLite database; `isBookDownloaded()` queries database manifest directly.
  - `lib/features/ilm/presentation/widgets/shamela_reader_top_bar.dart` & `shamela_book_card.dart`: honors verified database state.
- **Active Regression Proof:**
  - `test/offline_download_ux_test.dart` (tested against `FakeShamelaDatabase`: incomplete book hides `محفوظ` badge and displays download button despite stale preference flag; complete book displays badge).
  - `test/shamela_download_test.dart` (gap retry downloads only missing pages; cancellation leaves book marked un-downloaded).
- **Audit Verdict:** **VERIFIED & CLOSED**.

---

### Family 6: Lifecycle, Foreground Timers, Audio Coexistence, and Disposed Callbacks
- **Findings:** C18, C19, C20
- **Defect Mechanisms:**
  - *C18:* `ForegroundPrayerService.stop()` cancelled player subscription, but `init()` returned early on subsequent calls, breaking audio restart; `AppShell` kept UI polling timers active in background.
  - *C19:* Simultaneous playback across Quran, Radio, Mutun, and Adhan lacked coordination, playing over each other.
  - *C20:* `BackupRestoreSheet` and reader toolbars invoked `setState()` across async gaps after widget disposal.
- **Production Remediation Anchor:**
  - `lib/core/services/foreground_prayer_service.dart`: subscription re-attachment on restart.
  - `lib/app_shell.dart`: pauses UI timers on `AppLifecycleState.paused` / `inactive`.
  - `lib/core/services/audio_coordinator.dart`: central priority arbiter (Adhan pauses all; Radio pauses Quran).
  - `lib/features/more/presentation/widgets/backup_restore_sheet.dart`: `if (!mounted) return;` across all async steps.
- **Active Regression Proof:**
  - `test/audio_lifecycle_and_coordination_test.dart` (repeatable start/stop/start, radio interrupts Quran, Adhan priority).
  - `test/backup_restore_sheet_test.dart` (survives rapid disposal during file picking/dialog dismissal).
- **Audit Verdict:** **VERIFIED & CLOSED**.

---

### Family 7: UI Accessibility, Scaling, Edge Taps, and Native Widget Snapshots
- **Findings:** C21, C22, C33a
- **Defect Mechanisms:**
  - *C21:* Root text scale was clamped at 1.5, failing 2.0 accessibility scaling; `AppButton` constrained touch targets without making entire 48dp tappable at edges.
  - *C22:* `HomeWidgetService` lacked update serialization, allowing competing refreshes to publish mixed snapshots across the 10 widget keys.
  - *C33a:* Golden tests had non-deterministic failure modes from dynamic countdowns (`DateTime.now()`).
- **Production Remediation Anchor:**
  - `lib/app/app.dart`: root supports text scale factor up to 2.0 without clipping.
  - `lib/app/theme/widgets/app_button.dart`: guarantees 48dp minimum hit box with ripple spanning full edge boundary.
  - `lib/core/services/home_widget_service.dart`: `_updateLock`, snapshot versioning, atomic multi-key writes.
  - `lib/features/home/presentation/widgets/home_hero_card.dart`: injectable `currentTime` parameter.
- **Active Regression Proof:**
  - `test/accessibility_ui_correctness_test.dart` (edge taps on 48dp boundary, text scale 2.0 overflow resistance).
  - `test/native_widget_snapshot_test.dart` (concurrent updates serialized without races).
  - `test/golden/home_golden_test.dart` (deterministic golden harness; all 43 goldens passing).
  - `test/code_acceptance_suite_test.dart` (Journey 7: atomic snapshot across all 10 keys).
- **Audit Verdict:** **VERIFIED & CLOSED**.

---

### Family 8: Learning Data Invariants, Network Boundaries, Privacy, and Repository Hygiene
- **Findings:** C23, C24, C25, C26, C31, C32, C34, C35
- **Defect Mechanisms:**
  - *C23:* `QuizDumpService` mutated in-memory cache during JSON parsing, leaving partial state on errors; duplicate quiz completions duplicated XP/counters.
  - *C24, C32:* `ReverseGeocodeClient` counted characters instead of raw bytes (enabling multi-byte bypass) and lacked total wall-clock deadlines.
  - *C25:* 19 oversized files (>600L); coupling between domain logic and UI motion tokens.
  - *C26, C31:* Superficial acceptance tests and lack of exact SDK pinning in CI.
  - *C34, C35:* Unpinned CI versions; stale documentation claims.
- **Production Remediation Anchor:**
  - `lib/features/quiz/data/services/quiz_dump_service.dart`: validates complete bank before caching; `sessionCompletionId` idempotency contract.
  - `lib/core/services/reverse_geocode_client.dart`: raw byte counting before UTF-8 decoding (`maxGeocodeBytes = 64KB`), overall wall-clock deadline (`AppPolicy.networkFast`), socket abort in `finally`.
  - Repository-wide refactoring: **0 behavior files > 600 lines** repo-wide; `AppPolicy` extracted for domain constants.
  - `.github/workflows/verify.yml`: pinned Flutter SDK `3.38.7` (Dart 3.10.7) and authoritative lockfile.
  - `test/code_acceptance_suite_test.dart`: 7 deep behavioral journeys.
- **Active Regression Proof:**
  - `test/quiz_catalog_and_progress_invariants_test.dart` (atomic cache abort on malformed item, duplicate completion idempotency).
  - `test/network_boundaries_and_security_test.dart` (multi-byte 64KB rejection, slow-drip timeout abort).
  - `test/location_privacy_boundaries_test.dart` (zero geocoder/HTTP calls on opt-out, explicit opt-in routing).
  - `test/code_acceptance_suite_test.dart` (7/7 journeys passing).
- **Audit Verdict:** **VERIFIED & CLOSED**.

---

## 3. Master Hostile Evidence Table (C01–C35)

| Finding ID | Pri | Live Source Anchor | Live Production Caller Path | Regression Test File & Case Name | Failure Mode / Defect Prevented | Platform vs Host Limitation | Status |
|---|---|---|---|---|---|---|---|
| **C01** | High | `quran_audio_service.dart:336` | `quran_page_view.dart:210` | `test/quran_audio_service_test.dart`: *sequential A->B exactly once* | Playback lockup awaiting play; repeat verse rejection | Host mock player; native audio focus on Android | **CLOSED** |
| **C02** | High | `quran_audio_service.dart:180` | `reader_toolbar.dart:145` | `test/quran_audio_lifecycle_test.dart`: *rapid A->B obeys B* | Stale async load overwriting newer playback request | Host stream timing; native buffer on Android | **CLOSED** |
| **C03** | Med | `backup_restore_sheet.dart:120` | `more_page.dart:88` | `test/bookmark_backup_test.dart`: *Arabic round trip through bytes* | UTF-8 corruption of Arabic text during file restore | Pure Dart UTF-8 test; file picker mock | **CLOSED** |
| **C04** | Med | `bookmark_backup_service.dart:140` | `backup_restore_sheet.dart:165` | `test/bookmark_backup_test.dart`: *rejects non-string app* | Unhandled TypeError crashing backup import UI | Host Dart type verification | **CLOSED** |
| **C05** | High | `bookmark_models.dart:85` | `bookmark_service.dart:95` | `test/bookmark_backup_test.dart`: *rejects invalid surah/ayah 999* | Out-of-bounds coordinates corrupting reader indices | Uses canonical Quran dataset on host | **CLOSED** |
| **C06** | High | `bookmark_service.dart:145` | `ayah_menu.dart:45` | `test/bookmark_atomicity_test.dart`: *concurrent additions retain both* | Concurrent bookmark adds losing data via race condition | In-memory shared preferences mock | **CLOSED** |
| **C07** | Med | `progress_service.dart:42` | `home_screen.dart:112` | `test/persistence_consistency_test.dart`: *corrupt JSON recovery* | FormatException in progress parser crashing card | Host JSON parser error injection | **CLOSED** |
| **C08** | Med | `reading_stats_service.dart:65` | `quran_page_view.dart:310` | `test/performance_caches_and_policy_test.dart`: *Enforces 500 session cap* | Unbounded reading session growth inflating storage | Injected mock clock on host | **CLOSED** |
| **C09** | High | `notification_service.dart:90` | `app_shell.dart:85` | `test/notification_initialization_test.dart`: *silent init zero prompts* | Background refresh triggering interactive permission popup | Method channel mock; Android OS permission UI | **CLOSED** |
| **C10** | Med | `notification_service.dart:55` | `main.dart:40` | `test/notification_initialization_test.dart`: *concurrent init once* | Competing startup instances duplicating plugin setup | Dart future coalescing on host | **CLOSED** |
| **C11** | High | `prayer_schedule_service.dart:130` | `prayer_schedule_service.dart:80` | `test/prayer_scheduling_boundary_matrix_test.dart`: *plugin failure omits fingerprint* | False success cache preventing retry of failed schedule | Host plugin mock; AlarmManager on Android | **CLOSED** |
| **C12** | High | `prayer_schedule_service.dart:210` | `prayer_schedule_service.dart:95` | `test/prayer_scheduling_boundary_matrix_test.dart`: *timezone invalidates cache* | Stale prayer notifications after DST or location change | Host timezone math; Android broadcast receiver | **CLOSED** |
| **C13** | Med | `notification_router.dart:75` | `notification_service.dart:320` | `test/notification_router_test.dart`: *MorningAthkar routes tab 3* | Notification deep-link popping to wrong bottom tab | Flutter widget test navigation stack | **CLOSED** |
| **C14** | High | `quran_audio_downloader.dart:165` | `surah_download_sheet.dart:90` | `test/quran_audio_download_test.dart`: *duplicate calls join same download* | Concurrent download taps corrupting temp file | Host async future deduplication | **CLOSED** |
| **C15** | High | `quran_audio_downloader.dart:285` | `quran_audio_downloader.dart:210` | `test/quran_audio_download_test.dart`: *200 HTML rejected* | Captive portal HTML promoted as downloaded MP3 | Injected HTTP test fixtures | **CLOSED** |
| **C16** | Med | `quran_audio_downloader.dart:320` | `quran_audio_downloader.dart:190` | `test/quran_audio_download_test.dart`: *cleanup on error* | Unclosed HTTP clients and leaked in-flight map entries | Host memory lifecycle verification | **CLOSED** |
| **C17** | High | `shamela_service.dart:450` | `shamela_book_card.dart:75` | `test/offline_download_ux_test.dart`: *hides محفوظ badge when incomplete* | False offline badge on partially downloaded book | In-memory SQLite (`sqflite_common_ffi`) | **CLOSED** |
| **C18** | Med | `foreground_prayer_service.dart:90` | `app_shell.dart:140` | `test/audio_lifecycle_and_coordination_test.dart`: *repeatable start/stop/start* | Service restart failing to restore event listener | Host lifecycle state changes | **CLOSED** |
| **C19** | Med | `audio_coordinator.dart:40` | `quran_audio_service.dart:115` | `test/audio_lifecycle_and_coordination_test.dart`: *adhan takes priority* | Overlapping playback across Quran, Radio, and Adhan | Host arbitration; native audio focus on Android | **CLOSED** |
| **C20** | Med | `backup_restore_sheet.dart:190` | `more_page.dart:88` | `test/backup_restore_sheet_test.dart`: *survives rapid disposal* | `setState` called after widget unmounted crashing app | Flutter test harness widget disposal | **CLOSED** |
| **C21** | Med | `app.dart:65`, `app_button.dart:120` | `app_shell.dart:40` | `test/accessibility_ui_correctness_test.dart`: *edge taps 48dp target* | Text clipping at 2.0 scale; un-tappable button margins | Headless Flutter layout & pointer harness | **CLOSED** |
| **C22** | Med | `home_widget_service.dart:85` | `prayer_schedule_service.dart:150` | `test/native_widget_snapshot_test.dart`: *updates serialized without races* | Out-of-order writes producing inconsistent widget data | SharedPreferences mock on host | **CLOSED** |
| **C23** | Med | `quiz_dump_service.dart:60` | `quiz_screen.dart:110` | `test/quiz_catalog_and_progress_invariants_test.dart`: *malformed item aborts cache* | Partial cache mutation; duplicate XP on completion retry | Host JSON parser and in-memory repository | **CLOSED** |
| **C24** | Med | `reverse_geocode_client.dart:75` | `location_service.dart:180` | `test/network_boundaries_and_security_test.dart`: *timeout aborts cleanly* | Unbounded HTTP response hangs and connection leaks | Custom loopback HTTP server harness | **CLOSED** |
| **C25** | Low | `app_policy.dart:15` | Repo-wide services | `test/performance_caches_and_policy_test.dart`: *domain policy defined* | Excessive file sizes; domain coupling to UI tokens | Static AST code metrics (0 behavior >600L) | **CLOSED** |
| **C26** | High | `.github/workflows/verify.yml` | GitHub Actions | `test/code_acceptance_suite_test.dart`: *7 complete journeys* | Lack of regression harness and untracked CI drift | GitHub Actions Ubuntu runner execution | **CLOSED** |
| **C27** | High | `bookmark_service.dart:195` | `surah_list_card.dart:65` | `test/bookmark_atomicity_test.dart`: *concurrent toggles return to start* | Simultaneous bookmark toggles creating duplicate adds | AsyncLock transaction critical section on host | **CLOSED** |
| **C28** | High | `bookmark_service.dart:250` | `bookmark_backup_service.dart:90` | `test/bookmark_atomicity_test.dart`: *import racing note-edit retains integrity* | Note updates lost when import writes stale snapshot | AsyncLock deterministic barrier test | **CLOSED** |
| **C29** | High | `app_policy.dart:45` | `backup_restore_sheet.dart:115` | `test/bookmark_backup_test.dart`: *oversized file bytes rejected* | DoS via unbounded memory allocation on backup import | In-memory byte array stream test | **CLOSED** |
| **C30** | High | `prayer_schedule_service.dart:45` | `app_shell.dart:90` | `test/prayer_scheduling_serialization_test.dart`: *shared lock serializes distinct instances* | Independent service instances cancelling each other's alarms | Static `_sharedLock` across instances on host | **CLOSED** |
| **C31** | High | `code_acceptance_suite_test.dart` | Test runner | `test/code_acceptance_suite_test.dart`: *Journeys 1 through 7* | Shallow tests failing to catch real subsystem integration bugs | Full Flutter service/router/DB test harness | **CLOSED** |
| **C32** | Med | `reverse_geocode_client.dart:95` | `location_service.dart:180` | `test/network_boundaries_and_security_test.dart`: *multibyte 64KB rejected* | Multi-byte UTF-8 evasion bypassing 64KB ceiling | Raw byte accumulation before decoding on host | **CLOSED** |
| **C33** | Med | `home_golden_test.dart:45` | Test runner | `test/golden/home_golden_test.dart`: *deterministic countdown* | Flaky golden tests from unconstrained clock and theme drift | Cairo/Amiri/Scheherazade font rendering harness | **CLOSED** |
| **C34** | Med | `.github/workflows/verify.yml:30` | GitHub Actions | CI configuration | Drift between local pinned Flutter and floating CI version | Exact Flutter 3.38.7 pinned in CI YAML | **CLOSED** |
| **C35** | Med | `UI_PROGRESS.md:5` | Auditors / Owner | `tool/test_release_readiness_checks.py`: *reconciliation test* | False claims of release readiness in superseded docs | Machine-readable log and status parser | **CLOSED** |

---

## 4. Whole-App Review Matrix Coverage

In adherence to Section 6 of [`MASTER_GEMINI_FLASH_3_8_APP_REMEDIATION_GUIDE.md`](MASTER_GEMINI_FLASH_3_8_APP_REMEDIATION_GUIDE.md), every row of the whole-app review matrix was re-verified against live source code:

| Area | Scope Inspected | Live Source Reference | Verification Evidence |
|---|---|---|---|
| **Quran / Mushaf** | Page/ayah mapping, font integrity, offline access, accessibility | `lib/features/quran/presentation/pages/mushaf_page_viewer.dart`, `surah_fallback_catalog.dart` | Canonical King Fahd Complex fonts; `quran_page_test.dart` passing; offline page rendering verified. |
| **Prayer / Location** | Coordinate handling, calculation methods, timezone/DST, consent boundaries | `lib/core/services/prayer_schedule_service.dart`, `location_service.dart`, `verified_cities_catalog.dart` | Zero HTTP/geocoder calls on opt-out (`location_privacy_boundaries_test.dart`); deterministic DST calculations (`prayer_scheduling_boundary_matrix_test.dart`). |
| **Audio / Adhan / Radio** | State transitions, focus/interruption, retry/cancel, audio arbitration | `lib/features/quran/data/services/quran_audio_service.dart`, `audio_coordinator.dart` | Deterministic event sequencing (`quran_audio_lifecycle_test.dart`); coordinator priority (`audio_lifecycle_and_coordination_test.dart`). |
| **Persistence / Backup** | Atomic writes, schema/version, bounds, malformed input, UTF-8 | `lib/features/quran/data/services/bookmark_service.dart`, `bookmark_backup_service.dart` | AsyncLock concurrency (`bookmark_atomicity_test.dart`); 512KB/200 item limits (`bookmark_backup_test.dart`). |
| **Offline Books / Downloads** | Truthful complete status, gap retry, cancellation, SQLite storage | `lib/features/ilm/data/services/shamela_service.dart`, `shamela_reader_top_bar.dart` | SQLite manifest verification (`offline_download_ux_test.dart`, `shamela_download_test.dart`). |
| **Network / Security** | TLS allowlist, redirects, byte/time caps, client closure, zero secrets | `lib/core/services/reverse_geocode_client.dart`, `network_security_config.xml` | 64KB raw byte cap, wall-clock timeout (`network_boundaries_and_security_test.dart`); scoped cleartext domains. |
| **Notifications / Widgets** | Decoupled permissions, schedule idempotence, native snapshot versioning | `lib/core/services/notification_service.dart`, `home_widget_service.dart` | Silent init zero prompts (`notification_initialization_test.dart`); 10-key snapshot (`native_widget_snapshot_test.dart`). |
| **Quiz / Catalog / State** | Schema corruption, ID uniqueness, persistence idempotency | `lib/features/quiz/data/services/quiz_dump_service.dart`, `quiz_progress_service.dart` | Atomic load abort on corrupt JSON; `sessionCompletionId` duplicate protection (`quiz_catalog_and_progress_invariants_test.dart`). |
| **UI / Accessibility** | Arabic RTL, contrast, font scaling 2.0, semantics, 48dp hit areas | `lib/app/app.dart`, `app_button.dart`, `lib/app/theme/` | Min 48dp edge taps, 2.0 scale overflow-free (`accessibility_ui_correctness_test.dart`); 43 golden tests passing. |
| **Release / Operations** | Application ID, targetSdk 35, release signing, CI parity, privacy fact sheet | `android/app/build.gradle.kts`, `verify.yml`, `docs/PRIVACY_POLICY.md` | TargetSdk 35; SafeSigningVerifier; reproducible runner (`run_release_readiness_checks.py`); Privacy Policy aligned. |

---

## 5. Conclusion & Regression Quality Confirmation

1. **Zero Unbacked Closures:** Not a single finding from C01 to C35 relies on assertion alone. Every finding is anchored to production code lines and backed by an automated regression test that would fail if the defect returned.
2. **Platform-Only Honesty:** Native Android limitations (e.g. `AlarmManager` wakeups, native Android Geocoder network routing, and hardware audio ducking) are explicitly documented and distinguished from Dart test automation.
3. **Audit Complete:** Task R66 is fully complete with zero open defects in the C01–C35 registry. The codebase remains blocked from Google Play upload solely due to documented Owner-Only external actions (final Application ID, private production keystore, and Play Console submission).
