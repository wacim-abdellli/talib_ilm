# Code production audit and agent remediation guide

Date: 23 October 2026. Status: audit and implementation plan; fixes below are not implemented by this document.

Implementation update: the R30 checkpoint is committed and remotely backed up as `4d09095` on `ui/r30-release-verification`. R31 implements the first T01 audio fix batch with five demonstrated pre-fix failures and 14 new lifecycle regressions; see the latest `UI_PROGRESS.md` entry for exact gate results. Findings/line anchors below describe the pre-fix audit. Remaining golden failures are carried forward explicitly; the owner's instruction to proceed with code fixes permits isolated behavioral remediation without pretending the unrelated visual baseline is green. Publication remains deferred.

## 1. Objective and scope

Make the existing application dependable, maintainable, accessible, and demonstrably correct before starting Play Store preparation. The owner explicitly requested code quality first. This plan includes Dart services, persistence, asynchronous behavior, native widget integration, UI correctness, tests, and development tooling. It excludes store listing, publication, developer-account setup, signing credentials, and legal/scholarly certification. Those belong to a later release phase.

The owner's code-quality request permits planning behavioral/service fixes beyond the older visual-only program. Implement only the selected task's behavior changes; it does not authorize rewriting content, deleting features, changing Quran text, or changing unrelated Arabic strings. Preserve current behavior unless a documented defect requires a specific correction. Root project instructions still govern visual tokens, small stages, verification, and Git handling.

“10/10” is a quality target, not a claim of perfection. Completion means the documented acceptance gates pass and no known critical/high-impact code defects remain unresolved. A passing test count alone does not establish that.

## 2. Evidence and limitations

- Current app inventory: 335 Dart files under `lib/`, 92,464 lines, 19 files over 600 lines; 80 test files. Counts include catalogs; they do not justify splitting generated data.
- This continuation inspected startup/shell, notification initialization/routing/scheduling, foreground prayer lifecycle, location/network fallback, Quran audio/downloads, bookmark models/storage/backup/import, reading history/stats, legacy and current book progress, quiz loading/progression, Shamela fetch/download, radio lifecycle, shared buttons, app text scaling, and dependency/analyzer configuration. Call-site searches distinguish active paths from legacy candidates.
- Reviewed `.agent/AGENT_DESIGN_BRIEF.md` and `.agent/SCROLL_ARCHITECTURE_FIX.md` as historical context. Their claims are not fresh proof. Root design specifications take precedence for current visual work.
- Prior verification at this working tree: 333 non-golden tests pass; nine reviewed component golden comparisons pass; scoped `flutter analyze --no-pub lib test` reports zero issues. Normal UI lint: zero failures, 248 warnings, seven allows. Other ten golden-test files remain unapproved for the real-font harness. These checks were not all rerun during this planning continuation.
- New focused probes ran against production services: six tests described below. They intentionally assert existing bad behavior to establish the audit evidence. They are NOT regression tests that should remain green after fixing the defects. Convert each to the desired-behavior test in its implementation task.
- Probe source/log: ignored `build/release-tools/code_audit_probe_test.dart` and `build/release-tools/code-audit-probes.log`. They are diagnostic artifacts, not tracked application changes.
- No new APK, live-device acceptance, coverage measurement, performance profile, vulnerability certification, or exhaustive line-by-line review of all 92,464 lines is claimed. Native widget classes were inventoried; their complete behavior still needs the dedicated integration task.
- Latest actual APK build failed in the host Dart VM: `Could not start thread DartWorker: 22`, exit -1073740791. This is not evidence that app source fails compilation. `.git` is read-only and connected GitHub metadata reports no push permission. Existing work remains uncommitted. See `RELEASE_VERIFICATION_2026-10-23.md` for exact prior results.

Evidence labels: **R** = focused executable reproduction; **S** = defect or behavior established from source/control flow; **H** = risk requiring a targeted reproduction/profile before changing behavior. Severity is user impact, not a security exploit claim.

## 3. Findings register

Paths are repository-relative here for portability. Line anchors describe this checkout and must be rechecked after changes.

| ID | Priority / evidence | Code evidence and impact | Task |
|---|---|---|---|
| C01 | High / S; runtime event order H | `lib/features/quran/data/services/quran_audio_service.dart:289,331,336,347,352`: transition flag remains set while awaiting `AudioPlayer.play()`. Installed just_audio 0.10.5 documents that future as completing at completion/pause/stop, not startup. Completion handling may run while transitions are blocked. Additionally, repeat paths call `_startPlay` without clearing the same `_lastCompletedAyahKey`; subsequent completion of that verse is rejected. Existing audio tests check settings/URLs, not actual event sequences. | T01 |
| C02 | High / H | Same service `_startPlay`, retries and `stop`: no operation generation/cancellation guard. A delayed source load/retry can finish after a newer play/stop command. Reproduce rapid A→B and play→stop with controlled futures before selecting a fix. | T01 |
| C03 | Medium / R | `lib/features/more/presentation/widgets/backup_restore_sheet.dart:73`: `String.fromCharCodes(file.bytes!)` interprets UTF-8 bytes as code points. Probe confirms Arabic changes. This applies to the bytes branch; the file-path `readAsString` branch is different. | T02 |
| C04 | Medium / R | `lib/features/quran/data/services/bookmark_backup_service.dart:108`: `app: 42` throws TypeError outside the JSON parsing catch rather than returning a validation failure. Import UI catches errors; this is not claimed as an uncaught whole-app crash. | T02 |
| C05 | High / R | `bookmark_service.dart:22,60` and backup validator: explicit page bypasses Quran lookup and no range validation is performed. Probe imports surah/ayah/page 999 as valid. Reader consumers call Quran indexing functions, so invalid data can reach unsafe downstream paths; that downstream failure was not reproduced. | T02 |
| C06 | High / R | `bookmark_service.dart:99,117,249`: concurrent additions both read then replace the complete list. `Future.wait` adding 1:1 and 2:1 leaves ONE bookmark in the mocked preference backend. Other whole-list stores need the same audit; cross-isolate behavior needs separate treatment. | T03 |
| C07 | Medium / R + S | `lib/core/services/progress_service.dart:13,25,36`: corrupt JSON escapes as FormatException (probe). Active consumers include Home/lessons/book view. `BookProgressService.getAllProgress:94` likewise parses the entire collection without per-record recovery. Silently returning empty and overwriting it would also be unsafe. | T03 |
| C08 | Medium / R + S | `lib/features/quran/data/services/reading_stats_service.dart:28,44,69`: session list grows without a cap/aggregation, and one malformed session causes daily statistics to throw (probe). Long-term I/O/memory cost requires measurement. | T03, T13 |
| C09 | High / S | `main.dart:35`, `app_shell.dart:75,108`, `prayer_schedule_service.dart:81`: multiple entry points initialize/request notification access. The shell starts scheduling independently of the onboarding decision. Background refresh must not own interactive permission prompting. | T04 |
| C10 | Medium / S; runtime race H | `notification_service.dart:17,23,342`: initialized flag is instance-local, set after awaits; no shared in-flight initialization. Multiple service instances exist. Repeated channel setup/callback registration can overlap. The exact plugin-visible consequence needs a fake-plugin test. | T04 |
| C11 | High / S | `notification_service.dart:366–429` logs final scheduling failure and returns void. `prayer_schedule_service.dart:110–113` then stores success metadata after the scheduling calls. The 12-hour early-return can treat unsuccessful work as fresh. Return an explicit result and persist success only for a verifiably successful batch. | T05 |
| C12 | High / H | Scheduler keys use city string and a subset of notification settings (`:38,224`), not a complete coordinate/timezone/calculation/adjustment fingerprint. No refresh serialization is visible. Force-refresh call sites may mitigate some paths; trace them before asserting a stale-schedule bug. Timezone fallback picks the first zone sharing today's UTC offset (`notification_service.dart:959`), which need not share future DST rules. | T05 |
| C13 | Medium / S | `notification_router.dart:54,64,76,86,95,102,112,160` selects tab 2 for Adhkar. In the shell tab 2 is Ilm; Adhkar is tab 3. The pushed page can be correct while Back returns to the wrong section. Existing route tests check the pushed widget, not the tab after Back. | T06 |
| C14 | High / S + H | `quran_audio_downloader.dart:198–439`: no per-key in-flight guard before flags/client/temp-file ownership is assigned. Repeated same-surah requests may share/delete temp files and reset cancellation flags. Generation ownership must be tested, not assumed. | T07 |
| C15 | High / S | Downloader `:305,320,355` has no explicit connection/body deadline and promotes a 200 response without validating nonempty content, declared length, or plausible audio. Existing-file validation is merely nonzero length (`:116,296`). A 200 HTML error body can be treated as downloaded. Tests cover cancellation/pause but not this integrity matrix. | T07 |
| C16 | Medium / S | Downloader client is registered at `:211–212`; completion/already-downloaded/error returns have no enclosing finally to release owned clients/map entries. Pause/cancel close them, but normal completion does not. Define ownership of injected test clients explicitly. | T07 |
| C17 | High / S | `lib/features/ilm/data/services/shamela_service.dart:646–682`: each page error is swallowed, then `shamela_downloaded_<id>` is set true regardless of gaps. Unknown length can default to 50. Active callers are Maktaba download and reader toolbar. The app can promise an offline book it has not fully saved. | T08 |
| C18 | Medium / S | `ForegroundPrayerService.stop:95` cancels its player subscription; `init:56` returns forever once initialized. Starting the singleton again does not reattach that completion listener. `AppShell` leaves monitoring timers running during paused/hidden states. Do not conflate expected adhan background behavior with avoidable UI polling. | T09 |
| C19 | Medium / S + H | `main.dart:26–36` acknowledges uncaught platform errors globally and starts unawaited initialization; catches/logs do not establish feature recovery. `QuranRadioService` does not retain its three subscriptions, and pause calls to the Quran player are not awaited. Audio ownership across Quran/radio/mutun/adhan is not coordinated centrally. Reproduce collisions and disposal races before introducing an arbiter. | T09 |
| C20 | Medium / S | `backup_restore_sheet.dart:65,80,92,144`: asynchronous branches call setState without a fresh mounted check. Popping the sheet during picking/dialog/validation can leave callbacks targeting disposed state. Reader toolbar download progress also outlives its disposed notifier unless work/callback ownership is guarded. | T09 |
| C21 | Medium / S + H | App root caps scale at 1.5 (`app.dart:62`), so isolated 2.0 goldens do not prove real-app 2.0 support. Small `AppButton` wraps a smaller InkWell with an outer 48dp ConstrainedBox/Center (`app_button.dart:110–201`); outer size alone is not a guarantee that all 48dp are tappable. Prove edge taps in a widget test. Existing measured contrast failures remain. | T10 |
| C22 | Medium / S + H | `home_widget_service.dart:555` permits forced updates to overlap; earlier work can finish after a newer update. Multiple separate preference writes may expose mixed widget snapshots. Test both Dart completion order and Kotlin readers before choosing snapshot/version/coalescing changes. | T11 |
| C23 | Medium / S + H | `quiz_dump_service.dart:39–75` mutates caches while parsing, catches an entry failure after partial mutation; asset-load failure sets `_isLoaded = true`. Quiz result counters span multiple writes with no session idempotency contract. Malformed/partial loads and duplicate completion need targeted tests. | T12 |
| C24 | Medium / S | `location_service.dart:481–516`: HttpClient cleanup is not in finally, getUrl/body have no complete operation deadline, and body collection is unbounded. Remote coordinate fallback is real behavior; choose explicit user-intent gating or an offline alternative without mixing in store-policy work. Cleartext is enabled globally in Android manifest; actual required HTTP hosts must be inventoried before tightening. | T14 |
| C25 | Low–Medium / S + H | Nineteen oversized files; globally ignored deprecation diagnostics; domain services depend on `AppMotion` for network/clock intervals; old Quran API/cache/sync classes have limited apparent reachability beside the current QCF reader. These increase maintenance risk, not automatic user defects. Trace call sites, benchmark, and extract only around actual tasks. | T13, T15 |
| C26 | High quality gap / S | No tracked `.github` workflow or `integration_test` directory found. Current audio tests do not drive the completion state machine; notification tests miss post-Back tab state. A green unit suite does not prove native callbacks, restart, or audio focus behavior. | T00, T16 |

No P0 exploit or universal-crash claim was established. High findings above still block our code-quality target because they affect data retention, promised offline availability, or core prayer/audio behavior.

## 4. Execution order and dependency rules

Finish the existing R30 checkpoint first. Then execute one task per session; a large task becomes suffix stages (T03a, T03b...), never an oversized commit. Keep about 25 files or fewer including documentation. The current working set becomes 25 files with this guide: checkpoint it before adding another batch.

Suggested order: **T00 → T01 → T02 → T03 → T04 → T05 → T06 → T07 → T08 → T09 → T10 → T11 → T12 → T14 → T13 → T15 → T16**.

- T01, T02, T06 are relatively isolated once the baseline is usable.
- T03 touches persistence shared with T02/T12; serialize those changes and preserve schema compatibility.
- T04 precedes T05. T09 precedes final native/audio integration. T10's shared-component fixes precede screen reference batches.
- Do not run writers concurrently against the same checkout. The guide can be handed to another agent; no separate agents were launched for this audit.
- Branch/tag names must follow root rules: select the next unused `ui/r<n>-<task>` and `ui-r<n>-done`; do not invent a completed R number from this task list. Checkpoint commit and push at each completed coded part when access permits. Never declare completed/backed-up while blocked, force-push, rewrite history, or push unrelated work.

## 5. Implementation task cards

### T00 — Reproducible baseline and safe test seams

Owner role: tooling/test engineer. Dependencies: finish R30.

- Files: `tool/verify_release_readiness.ps1`, analyzer configuration, future CI configuration, existing test helpers. Inspect lockfile and tool versions; do not upgrade packages en masse.
- Diagnose host thread failure separately from source defects; preserve logs. Use writable SDK/cache paths. Never change ACLs or kill unrelated IDE processes.
- Complete remaining golden review in bounded batches. Record full-suite, scoped versus whole-project analysis, lint, and APK results honestly.
- Add small injectable clock/player/plugin/client/store seams as each following task needs them, not a global framework migration.
- Establish CI on a clean runner with pinned Flutter, committed lockfile, analysis/lint/tests and debug build. CI configuration can be prepared locally; enabling protection requires repository access.
- Acceptance: clean-run evidence and a fresh installable debug APK; no assertion loosening, broad goldens replacement, arbitrary sleeps, or skipped tests to obtain green.
- Rollback: tooling-only revert preserves app data and features.

### T01 — Quran audio state machine

Owner role: audio/asynchronous correctness engineer. Findings C01–C02.

- Files: `quran_audio_service.dart`, `test/quran_audio_service_test.dart`, a focused fake-player adapter/helper. Inspect existing just_audio package implementation/docs locally.
- Separate source-loading transition lifetime from playback lifetime. Use operation ownership/generation so old source loads/retries/events cannot mutate a newer request. Deduplicate completion events per playback instance, not permanently per verse. Keep selected reciter/speed/repeat/single-verse behavior intact.
- Regression matrix: sequential A→B exactly once, two duplicate completed events, repeat-once plays A twice then B, infinite plays A at least three times, stop during load/retry never restarts, rapid A→B obeys B, pause/resume, end-of-surah/end-of-Quran, error/retry, reciter switch, explicit range end semantics.
- Acceptance: event-driven tests exercise the actual service, with controlled futures and event order; no real network/sleeps. Device audio transition check follows in T16.
- Rollback: no persistence schema change; revert service/test commit together.

### T02 — Backup boundary and import lifecycle

Owner role: data-validation engineer. Findings C03–C05 and import part of C20.

- Files: backup service, bookmark model validation, import sheet, `test/bookmark_backup_test.dart`; add focused import widget tests.
- Decode bytes with UTF-8. Bound file size before reading where possible and bound decoded list/note sizes. Validate map field types, supported schema version, surah/ayah/page ranges and their consistency. Define partial-import behavior explicitly; never call “valid” a file whose entries were silently all discarded.
- Do not relabel the `app` identifier check as cryptographic authentication; the backup is an untrusted local input. Preserve version-1 valid exports.
- Guard mounted state after every relevant await, including cancellation/dialog branches. Validate first, then merge through T03's safe write boundary; preserve existing data on failure.
- Tests: Arabic/diacritics/newlines round trip through bytes AND path branches; non-string app; wrong top-level types; huge/empty lists; invalid coordinates/timestamps; duplicate entries; cancellation/disposal; merge/overwrite choice; future version rejection; no writes on invalid input.
- Acceptance: all six audit probes relevant to this task are replaced by desired-behavior regressions, and invalid inputs return a structured result without raw exceptions.
- Rollback: retain source backup, keep schema version compatible; no destructive migration.

### T03 — Persistence consistency and corruption recovery

Owner role: storage engineer. Findings C06–C08; cooperate with T12.

- Batch A: bookmark repository writes/imports. Batch B: favorites/current and legacy book progress. Batch C: reading stats/history. Do not combine all stores into one giant change.
- Serialize read-modify-write per store across all instances in the same isolate, or adopt a justified transactional boundary. A mutex on each new service object is insufficient. Analyze widget/background isolates separately; an in-memory lock does not protect them.
- Recover valid records independently; preserve/quarantine malformed raw payloads before any replacement. Do not turn parse errors into silent data deletion. Check write outcomes at the chosen storage boundary.
- Keep existing keys readable, make migrations idempotent, and test rollback/old data. Decide retention/aggregation of reading sessions while preserving historical totals/streak semantics.
- Tests: two simultaneous adds retain both, concurrent update/remove has specified ordering, importer versus note edit, one corrupt entry alongside valid entries, failed writes, repeated migration, corrupted collection, restart/load, bounded histories.
- Acceptance: data invariants and failure outcomes verified at the service boundary. Storage package migration only if a documented requirement cannot be met with the current approach.

### T04 — Initialization and user-owned permissions

Owner role: startup/platform engineer. Findings C09–C10.

- Files: `main.dart`, `app_shell.dart`, `notification_service.dart`, onboarding dialog, schedule entry points and tests.
- Separate passive plugin/channel initialization, permission status queries, explicit user permission requests, and scheduling. Introduce shared in-flight initialization with retry after failure and clear lifecycle ownership.
- Background/resume/scheduling paths must never create interactive permission prompts. Onboarding “later” must remain effective. Initialization must not repeatedly consume the same cold-start payload.
- Tests: concurrent init initializes once; failed init can retry; later/deny means zero request calls from refresh; allow triggers one intentional request sequence; resume does not re-prompt; cold/warm launch routes once.
- Acceptance: recorded call ordering and feature fallback for denied access, no startup hang or silent required-feature failure.

### T05 — Prayer scheduling correctness and recoverability

Owner role: scheduling/time engineer. Findings C11–C12.

- Files: notification/schedule/time services, settings invalidation call sites, reminder integrations, prayer resilience tests. Split the 1,398-line notification service in behavior-preserving commits where necessary; preserve IDs/channels.
- Return typed schedule outcomes; distinguish exact, fallback/inexact, skipped-past, denied, and failed. Do not write a successful batch fingerprint after total/partial failure. Define retry/checkpoint behavior and preserve currently sounding alerts.
- Serialize/coalesce refreshes and invalidate using all relevant calculation/location/timezone/settings inputs. Trace force-refresh paths first. Use civil-date arithmetic for local day windows; test DST rather than assuming 24 hours equals the next calendar day.
- Tests: failure at first/middle/last notification; retry same day; competing settings changes; same-city changed coordinates; timezone/DST change; midnight; method/madhab/adjustment/iqama changes; denied exact access; preserved active IDs; bounded rolling-window IDs; no duplicate sound.
- Acceptance: fake clock and fake plugin expose exact expected operations; real alarm timing/fallback behavior is verified in T16. Platform restrictions are represented accurately.

### T06 — Notification routing and navigation invariants

Owner role: navigation engineer. Finding C13.

- Files: router/shell, deep-link parser only if needed, `test/notification_router_test.dart`.
- Correct Adhkar's selected tab; use one authoritative destination mapping instead of scattered magic indices. Preserve supported legacy payloads. Check broad substring matching and malformed URI behavior without breaking valid historical links.
- Tests: every supported payload opens the intended page, Back returns to the intended tab, prayer routes pop correctly, cold-start pending payload consumed once, duplicate tap behavior, unknown/invalid payload safe fallback.
- Acceptance: assert underlying selected tab after pop, not merely the presence of the pushed page.

### T07 — Quran downloader ownership, time bounds, integrity

Owner role: networking/filesystem engineer. Findings C14–C16.

- Files: downloader, local-source resolution as necessary, download UI only for correct state, `test/quran_audio_download_test.dart`.
- One owned operation per reciter/surah; define duplicate requests as join/no-op, not concurrent writes. Old operations must not clear new state. Release owned clients/subscriptions/sinks in finally; document injected-client ownership.
- Bound connection, idle body, overall operation, and downloaded bytes as appropriate. A Future timeout alone does not cancel underlying I/O: actually close/cancel the owned operation.
- Validate response status, nonempty bytes, content length when provided, and plausible audio before atomic promotion. Use hashes only if a trusted manifest exists; do not invent trustworthy checksums. Legacy files need a migration/revalidation policy.
- Tests: duplicate calls, cancel then immediate restart, pause/resume, 200 HTML, zero body, truncated Content-Length, stalled headers/body, oversized response, disk failure, cleanup on every exit, already-complete path, network interruption, preserved completed ayahs.
- Acceptance: no invalid target promoted; no stuck downloading state; no leaked owned client; no cross-generation file deletion.

### T08 — Truthful complete-book downloads

Owner role: offline-reader engineer. Finding C17.

- Files: `shamela_service.dart`, reader toolbar/Maktaba download callers, Shamela tests. First make any required >600-line split separately and preserve public APIs.
- Persist a page manifest/checkpoint and count successful validated pages. An arbitrary fallback count cannot prove completeness. Failed pages must remain retryable and the book must not be marked fully offline.
- Define completion when length is unknown, cancellation ownership, progress on retry, and cache consistency after restart. Guard progress callbacks after UI disposal.
- Tests: one missing middle page, all pages failed, changed total, unknown total, retry fills gaps, empty/unparseable response, restart, cancellation, valid bundled book, no unnecessary re-download of valid pages.
- Acceptance: “downloaded” is true only when all required validated pages exist; callers show the real result rather than unconditional success.

### T09 — Service and screen lifecycle; audio ownership

Owner role: lifecycle/audio integration engineer. Findings C18–C20.

- Split into foreground prayer start/stop, audio coexistence, and asynchronous screen teardown batches.
- Make start/stop/start repeatable with required subscriptions restored. Distinguish app background from tab visibility. Pause unnecessary UI polling without disabling required adhan behavior.
- Inventory ownership of player subscriptions, timers, notifiers, asynchronous callbacks, and global singletons. Await asynchronous stop/pause where ordering matters and handle returned errors.
- Introduce a small audio-coordination seam only after tests establish required priority rules among Quran, radio, mutun, and adhan. Do not dispose process-lifetime services merely because a page closes.
- Define recoverable startup failures and bounded diagnostics; no silent global error swallowing as a substitute for recovery. Never log private coordinates/notes or add telemetry without explicit disclosure work.
- Tests: start/stop/start completion, repeated resume, pop while async work completes, no setState/notifier writes after dispose, radio→Quran and reverse, adhan interruption/resume policy, rapid audio switching, failed background initialization.
- Acceptance: one intended audible source under the specified rules, no orphan timers/listeners, visible/retryable feature failures.

### T10 — Accessibility and UI implementation correctness

Owner role: Flutter UI/accessibility engineer. Finding C21 and previously measured contrast failures.

- Start with shared button/tap semantics and semantic color fixes; then bounded screen groups. Preserve root token/RTL rules; propose any new tokens with contrast proof before use.
- Actual root app must honor supported 2.0 scaling after layouts are ready. Avoid simply disabling accessibility scaling or hiding overflow by shrinking everything.
- Tests: taps at all edges of the required 48dp target, semantic enabled/loading/button label, loading width behavior, long Arabic labels, input/keyboard/scroll/sheet behavior, light/dark at 1.0/1.5/2.0; actual app-root scale test.
- Golden updates need visual inspection. Essential controls/boundaries meet contrast, decorative dividers are assessed by their role. Fix existing warning classes instead of adding suppressions.
- Acceptance: no clipping/overflow on supported layouts, working TalkBack traversal, correct RTL and touch behavior; component goldens alone are insufficient.

### T11 — Native widget snapshot and refresh consistency

Owner role: Flutter/Kotlin integration engineer. Finding C22.

- Files: `home_widget_service.dart`, evaluator, five widget providers and chronometer helper, existing widget tests.
- Inspect the Dart→preferences→Kotlin contract, key types/defaults/units, dates and timezones, update throttling, force refresh, click destinations, resize, restart, and theme resolution.
- Coalesce latest requested state or publish versioned snapshots if needed. A forced refresh must not let older completion overwrite newer data. Keep provider compatibility during migration.
- Tests: deliberately reversed completion order, changed city while refreshing, clock/timezone changes, missing/stale keys, all widget sizes, background callback and cold navigation.
- Acceptance: every provider renders the same coherent prayer snapshot and correct countdown; native evidence belongs in T16.

### T12 — Quiz/catalog loading and progress invariants

Owner role: learning-data engineer. Finding C23.

- Files: quiz dump/progress/session services and their existing tests; catalog validators.
- Parse into temporary collections, validate, then publish atomically. Distinguish success, valid-empty, failed, and retryable states. Do not expose partial imports as a complete catalog.
- Validate result bounds and define a session-completion identity/idempotency contract; retrying the same completion must not duplicate XP/counters. Coordinate writes with T03 without rewriting unrelated learning behavior.
- Tests: malformed item after a valid item, wrong schema, missing asset/retry, concurrent load join, duplicate IDs, clear during load, negative/impossible score, duplicate completion, interrupted persistence, saved-session resume across supported catalog versions.
- Acceptance: stable catalogs and internally consistent totals/high scores/unlocks after retry/restart.

### T13 — Measured performance, caches, and bundle costs

Owner role: performance engineer. Findings C08/C25.

- Measure profile/release cold startup, Home polling, reading/page turns/search, retained fonts/caches, memory after repeated navigation/audio, and long-session growth on named devices.
- Inspect Dart size treemap and bundled assets. Preserve essential offline Quran assets; do not remove content merely to chase APK size. Quantify duplication before changing it.
- Replace theme-motion dependencies for domain timeouts with appropriately named core policy/configuration only in a separate no-behavior-change extraction. Use injected clocks where tests need determinism.
- Tests/benchmarks: repeatable scenario, device/OS/build hash, cold/warm conditions, baseline and after metrics. Set numeric performance budgets after baseline measurement, not from invented targets.
- Acceptance: no unexplained growth or avoidable hidden-tab polling, measured improvement with unchanged functional tests, explicit cache/retention budgets.

### T14 — Network boundaries and local security hardening

Owner role: networking/security-minded reviewer. Finding C24.

- Inventory live callers/hosts, transmitted values, URL schemes/redirects, response size and type limits, TLS behavior, local files, and external navigation.
- Fix location HttpClient lifetime/deadlines and gate remote coordinate fallback under intentional behavior. Verify debug-only certificate bypass remains unreachable in release. Restrict cleartext only after checking actual media requirements and compatibility.
- Make clients injectable where needed for malformed/status/error tests; no mandatory new HTTP abstraction across every service. Bound caches and key them by all content variants in active paths.
- Tests: timeout during headers/body, non-200, malformed JSON, oversized payload, offline/fallback, trusted/untrusted URI schemes, cancellation, redirects, no leaked client, no accidental coordinate transmission in declined/offline mode.
- Acceptance: bounded operations and documented data-flow behavior, no secrets/private content in source/logs. Dependency advisory review is separate evidence, not inferred from a lockfile.

### T15 — Maintainability and dependency hygiene

Owner role: refactoring/tooling engineer. Finding C25.

- Resolve strict-lint warning classes in small groups. Audit ignored deprecations rather than abruptly enabling thousands of diagnostics without a migration path.
- Verify dependency usage/support/native constraints and vendored Quran modifications. Do not upgrade everything to latest in one commit. Each upgrade needs an impact reason and relevant regression checks.
- Trace old Quran API/cache/sync/repository symbols versus the imported QCF repository. Unreachable-looking code is a candidate for investigation, not permission to delete it. Legacy edition fallback correctness/cache expiry issues should not be promoted above active data-loss/audio defects without a caller.
- Split oversized presentation/service modules around real boundaries; no package-wide state-management rewrite, cosmetic layer proliferation, or mechanical splits of generated catalogs.
- Acceptance: documented ownership/public contracts, fewer warnings, no changed public behavior in extraction commits, tests/build pass for each bounded upgrade.

### T16 — Code acceptance suite and final independent review

Owner role: integration/QA reviewer. Dependencies: all applicable tasks above.

- Add focused integration journeys for cold/warm startup, permission choices, notification Back destination, reading→bookmark→backup→restore, offline book completion, stalled/cancelled audio download, quiz resume/completion, and widget updates.
- Real Android matrix: supported minimum device/OS where available, current Android, at least one constrained physical phone, reboot, timezone change, process termination, screen-off audio, audio interruptions, low storage, offline and poor network. Clearly distinguish emulator/fake-plugin checks from physical results.
- Run full mandatory verification from a clean reproducible environment. Add release/profile functional smoke checks for behavior that debug cannot prove; this is code validation, not publication preparation.
- Review fixes against C01–C26, re-open unsupported completion claims, run the failure cases from original reproductions, inspect privacy-sensitive logging and migration safety.
- Acceptance: all gate rows below have revision-linked evidence; unresolved severity/limitations are explicit. Only then start the separate Play publication plan.

## 6. Definition of code-complete

| Area | Required evidence |
|---|---|
| Functional correctness | Core journeys and adverse-event sequences pass; no unresolved known high-impact findings. |
| Data safety | Concurrent writes, malformed data, migration, backup/restore and failed writes preserve valid user data. |
| Async/lifecycle | No stale-operation takeover, duplicate completion, unhandled async errors, disposed callbacks or resource ownership gaps in covered paths. |
| Prayer/time | Calculation/settings/timezone invalidation and scheduling failure recovery verified, including actual native behavior and documented platform limits. |
| Offline/network | Completion claims correspond to validated local content; bounded operations, cancellation, retries and cleanup work. |
| UI/accessibility | Actual app and components survive RTL/themes/scales; contrast, semantic labels and real tap areas verified. |
| Performance | Named-device baselines and agreed budgets pass; long-session memory/storage behavior measured. |
| Maintainability | Reproducible CI/build, meaningful guards, controlled dependency changes, documented contracts. |
| Regression quality | Each confirmed defect has a test that failed before its fix and passes afterward; no hidden skips or weakened assertions. |
| Audit honesty | Every task records commit, files, command/result, reviewed visuals/device, limitations and next step. |

Use status **not evaluated / failing / passing / blocked**, not a made-up numeric score. A category reaches the “10/10 target” only when its agreed gates pass. Production perfection and zero future bugs cannot be guaranteed.

## 7. Ready-to-paste handoff to another coding agent

```text
Work in D:\Projects\talib_ilm-main. Read AGENTS.md, DESIGN_SYSTEM.md,
ROUND2.md, UI_PROGRESS.md and docs/CODE_PRODUCTION_AUDIT_AND_AGENT_GUIDE.md.

Execute task [Txx, or its bounded suffix] ONLY. This is the owner's code-quality
program before Play publication. Behavioral fixes listed in that task are in scope;
do not redesign unrelated features or modify Quran/content/Arabic strings.

1. Inspect git status and current code. Preserve all pre-existing changes.
   Recheck the finding's line anchors and call sites. Finish/checkpoint R30 first.
2. State the exact invariant/defect, allowed files, dependencies and evidence level.
   For an H finding, reproduce or measure first; do not assert it is a proven bug.
3. Write a focused desired-behavior regression for the substantive defect.
   Add the smallest injectable seam required. Prove it fails for the stated reason.
4. Apply the smallest cohesive fix. Keep data/key/route compatibility unless the
   task specifies a tested migration. No blanket framework or package upgrade.
5. Exercise failure, cancellation, overlap, retry and teardown where relevant.
   Fakes must drive the real service, not duplicate its logic in the test.
6. Run relevant focused checks, then required project gates before completion.
   Review changed goldens/images manually. Report device checks separately.
7. Stay at approximately 25 changed files or fewer. Split oversized work; separate
   behavior-preserving extraction from restyling. No suppression-based green gate.
8. Commit/push using root branch/tag rules when accessible. Never claim a commit,
   push, successful build or device test that did not happen. No force push/ACL changes.
9. Update UI_PROGRESS.md with exact results, open issues and CONTINUE FROM.
   Report in the root's <=8-line format, then stop after this one task.

Do not configure publishing, upload a release, generate signing credentials,
change developer identity, or prepare store marketing in this code-only task.
```

If a finding is disproved, record the counterexample, tested condition, and why no fix is needed. Do not manufacture changes to satisfy the plan.

## 8. Verification commands and current environment

Required root gates:

```powershell
flutter analyze
python tool/ui_lint_v2.py
flutter test
flutter build apk --debug
```

The current standard SDK cache is not writable. The existing verification script supports `-FlutterSdk` and `-NoPub` and detects the ignored local SDK/cache. Its full execution and an unqualified whole-repository analysis are not certified by prior scoped results. Inspect the script and environment before choosing the invocation. Avoid `flutter clean` while the only usable SDK/cache is stored under `build/release-tools/`.

The audit probe command actually executed here:

```powershell
& ./build/release-tools/flutter/bin/cache/dart-sdk/bin/dart.exe `
  ./build/release-tools/flutter/bin/cache/flutter_tools.snapshot `
  --no-version-check --suppress-analytics test --no-pub --concurrency=1 `
  --reporter expanded build/release-tools/code_audit_probe_test.dart
```

The earlier broad audit `PLAY_STORE_READINESS_AUDIT_2026-10-23.md` remains useful context, but this code-only plan replaces its publication-oriented ordering for the current request. No store requirements are prerequisites to writing these code fixes, apart from obtaining a usable build/verification environment.
