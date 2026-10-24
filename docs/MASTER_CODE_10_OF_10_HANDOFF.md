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

### Task 2 — R47b: Bound and validate backup input

**Files:** backup service, bookmark coordinate validation, backup import sheet, backup tests. Keep within the file limit.

Check `PlatformFile.size` before loading bytes. For path-based files, check filesystem length before reading and handle a file changing between stat and read. Set explicit byte, entry, and note limits based on the maximum valid export (200 bookmarks) with a documented safety margin. Parse UTF-8 strictly. Validate root/map/list/item types, app identifier as a format marker (not authentication), supported version, surah and ayah, page consistency, booleans, timestamps, notes, duplicates, and optional last-read behavior. Return structured validation containing accepted/rejected counts or reject the whole file; show the user the exact partial-import outcome. Never write on a failed validation. Keep valid version-1 backups readable.

**Required tests:** Arabic/diacritics/newline round-trip through both bytes and path branches; malformed UTF-8; wrong `app` type; wrong root/list/item types; oversized bytes, list, and notes; empty and all-invalid files; mixed-validity policy; duplicate entries; invalid/mismatched page; invalid timestamp; future version; cancelled picker/dialog; widget disposed during every await; merge/overwrite choice; no writes on rejection; imported count never exceeds the chosen limit.

**Pass:** invalid/oversized input cannot consume unbounded memory or mutate saved state; partial results are visible and counted; no raw parsing exception escapes; widget lifecycle is safe.

### Task 3 — R48: Serialize prayer scheduling across instances

**Files:** `prayer_schedule_service.dart`, only the necessary scheduling entry points, and `test/prayer_scheduling_boundary_matrix_test.dart` / notification tests.

Trace every production constructor/caller first. Use a single shared lock/coalescer for the scheduling store and notification IDs, or inject one singleton owned by app scope. Include force-refresh behavior, failure retry, cancellation, fingerprint writes, and settings/location changes. A per-object lock is not acceptable while multiple objects reach the same IDs/store.

**Required tests:** two distinct service instances refresh concurrently; forced refresh overlaps normal refresh; older refresh finishes last; mid-batch plugin failure then retry; settings/location/timezone change while a refresh is pending; denied permission never prompts from background work; DST/civil date tests remain passing.

**Pass:** no overlapping operations mutate the shared schedule; no stale success fingerprint; failures remain retryable; current active alarms and documented IDs survive. Preserve all existing prayer method/madhab/adjustment behavior.

### Task 4 — R49: Enforce real network byte and wall-clock limits

**Files:** `reverse_geocode_client.dart`, `app_policy.dart` if a justified policy token is needed, and network-boundary tests.

Count incoming raw response bytes before UTF-8 decoding. Enforce one operation deadline from request creation through body completion, not a timeout that resets on each chunk. On timeout/cancel/oversize, stop reading and close the owned request/client in `finally`; make ownership clear for injected clients. Keep HTTPS, coordinate validation, user-intent gating, offline fallback, and scoped cleartext policy.

**Required tests:** multibyte body exceeding byte cap; slow drip staying below idle timeout but exceeding total deadline; stalled headers/body; malformed UTF-8/JSON; cancellation; client closed on every exit; user declined means no remote request. No real network or arbitrary sleep.

**Pass:** measured total elapsed bound is deterministic under a fake clock/controlled stream; raw response memory is bounded; all existing location fallback tests pass.

### Task 5 — R50: Make tests and CI prove the claims

**Files:** `test/code_acceptance_suite_test.dart`, stale test fixtures such as `test/offline_download_ux_test.dart`, `.github/workflows/verify.yml`, and exact verification documentation.

Replace labels with real assertions. Test permission API invocation counts through the plugin seam; test full notification payload → route → Back tab; test actual bookmark backup parse/merge using UTF-8 byte and path branches; drive fake HTTP for HTML/empty/truncated/stall/cancel/retry/cleanup; load and complete an actual quiz session twice and verify persisted totals; run prayer scheduling from two service instances; validate widget snapshot version consistency. Update Shamela tests with real SQLite page records/manifest for a downloaded book and assert incomplete books remain unavailable. Do not change implementation to satisfy a stale fixture when the current behavior is intentional.

Pin Flutter in CI to the exact project-compatible version used for local verification (confirm `flutter --version`; do not guess). Run the same commands as the project gate. Keep the full test suite in CI; do not exclude golden tests to get a green badge. Preserve CI logs/artifact links in the progress report.

**Pass:** all specific behavioral tests and the complete repository suite pass on the same pinned SDK; CI passes on the exact pushed commit; workflow test suite covers the behaviors its labels claim.

### Task 6 — R51: Resolve golden failures by evidence

**Files:** only the affected `test/golden` test harness/reference files and source widgets proven wrong by visual review. Batch by screen family under the 25-file limit.

For each failing case, inspect the checked-in reference, current actual image, and diff image at original size. Confirm fonts loaded and theme/locale/text scaling/device pixel ratio are the intended ones. Trace the cause. Fix a real UI regression in source; fix a harness defect in the harness; update a golden only when the shown UI is approved and the change is intentional. Never bulk-run `--update-goldens` as a substitute for review. Check all changed PNGs, including Arabic shaping, text contrast, clipping, alignment, 48 dp controls, light/dark, and scales 1.0/1.5/2.0. Keep UI tokens, 12sp minimum, directional layout, and no fixed text heights.

**Pass:** every golden comparison passes on pinned CI; every updated image was inspected; no unreviewed reference replacement; any visual limits are stated.

### Task 7 — R52: Re-audit the original C01–C26 with production evidence

Do not assume that a prior task title or test count closes a finding. Run a checklist against actual code and active callers:

- Audio request generations, completion/repeat/range boundaries, audio downloader ownership, limits, integrity, cancellation and retry.
- Backup/persistence atomicity, corruption preservation, migrations, all read-modify-write paths, and per-isolate/native boundaries.
- Startup initialization, explicit permission ownership, notification route + Back stack, schedule outcomes, all cache inputs, DST and user settings.
- Shamela complete-page manifests, unknown totals, gap retry, cancellation, restart and honest download UI.
- Foreground timer/subscription lifecycle; Quran/radio/mutun/adhan focus, interruption, app pause/resume, disposal.
- Accessibility: actual app root scale to 2.0, 48 dp hit area on edges, semantics, RTL, contrast, keyboard/sheets, and device traversal.
- Home widgets: Dart-to-SharedPreferences-to-native provider contract, versioned coherent snapshot, cold start, refresh ordering, timezone and resize.
- Quiz/catalog: atomic loads, retry, schema and IDs, duplicate completion, persisted resume/restart.
- Network: request schemes/hosts/redirects, privacy/coordinate consent, time/byte limits, cleanup, offline/error states, TLS/cleartext manifest.

For any uncovered gap, create a new finding and a separate task; do not pad an old test suite with helper-only assertions. Use fakes for deterministic event ordering and a real Android device for native-only behavior.

**Pass:** each original finding links to source, a test that would fail if the fix regressed, and any required device result; no “all fixed” claim while a high-impact item remains.

### Task 8 — R53+: Close measurable maintainability and performance debt

Use the project's `>600` line rule and current UI lint output as an inventory, not as a mechanical code churn target. Recount all Dart files. Review the 10 remaining oversized files observed in this audit; separate data catalogs from behavior files. Split behavior files only where that improves ownership, in behavior-preserving commits before styling changes. Resolve RTL/layout/font warnings by migration to approved tokens, screen group by screen group. Keep allow markers below 10 and add none without an explicit reason. Profile startup, Home/tab polling, Quran page turns/search, audio switching, memory and cache growth with device/build details before setting numeric targets.

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
