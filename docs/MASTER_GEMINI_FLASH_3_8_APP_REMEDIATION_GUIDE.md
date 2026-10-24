# talib_ilm — Gemini Flash 3.8 Master Remediation Guide

**Owner objective:** Raise the app’s code quality and release confidence through evidence-led, complete fixes across the whole app. This guide is the authoritative coding handoff for Gemini Flash 3.8. It supersedes earlier remediation ordering where they conflict. It does not certify the app as “perfect,” “10/10,” or ready to upload.

**Audited baseline:** `main` at `efadd10` (`ui-r59-done`), 24 October 2026.
**Current decision:** Meaningful remediation is complete and the retained local test log reports 537 passing tests, but further high-risk findings remain. Play upload is blocked by the placeholder application ID, absence of a production upload key, privacy-flow uncertainty, and outstanding device checks.

## Copy and paste this instruction into Gemini Flash 3.8

> You are the implementation agent for the owner’s talib_ilm Flutter app. The owner explicitly asks for full code remediation across the areas in `docs/MASTER_GEMINI_FLASH_3_8_APP_REMEDIATION_GUIDE.md`. Read `AGENTS.md`, `DESIGN_SYSTEM.md`, `ROUND2.md`, `UI_PROGRESS.md`, and this guide before editing. Work on exactly the first unfinished task in the order below, in one session; do not multitask, skip ahead, or delegate. Reproduce that task’s current behavior before changing code. Add a regression test that would fail on the old behavior. Make the smallest complete fix within the task’s file scope and the 25-file stage limit. Inspect the full diff, run the task checks and required project gates, and record actual exit codes and retained logs. Never infer success from an artifact existing. Never delete, overwrite, or clean files unless the task created them and you verified their exact paths. Never expose or commit secrets. Preserve Arabic/Quran content and existing Arabic wording; request owner review before adding or changing user-facing religious, privacy, legal, or store copy. Commit and push the task branch, update `UI_PROGRESS.md`, report in eight lines or fewer, and stop. If a value or external credential belongs to the owner, stop at that boundary with a precise action request rather than inventing it. Do not report “10/10,” “all fixed,” or “Play ready” until the final hostile review and every gate below pass.

The owner’s latest instruction explicitly requests whole-app code remediation, including security, privacy, Android release configuration, services, and tests; this authorizes those non-visual changes within the tasks below. The project’s design-system rules, Arabic-content protections, RTL/accessibility standards, file-count limit, no-history-rewrite rule, and evidence/report requirements still apply.

## Ground truth the agent must preserve

The items below were inspected in the checkout. Recheck each at the start of its task because branches may advance.

| Finding | Current evidence | Consequence |
|---|---|---|
| Release signing test can delete user config | `tool/verify_release_signing_config.py` calls `cleanup()` before testing and in `finally`; `cleanup()` unconditionally removes `android/key.properties` and named temporary keystores. | **Do not run this script after the owner adds a real `android/key.properties` until R61 fixes it.** It could erase the owner’s credential configuration. |
| App ID is still a placeholder | `android/app/build.gradle.kts`: `applicationId = "com.example.talib_ilm"`. | Owner must choose the permanent unique package ID. Do not invent one or change it after a Play app/listing is created. |
| No production key is configured | `android/key.properties` is absent. Current AAB certificate inspection reports `CN=TestUpload`; it is not a production upload artifact. | A private upload key and owner-controlled credentials are still required. Never commit them. |
| Consent does not gate the platform geocoder | `lib/core/services/location_service.dart` calls `placemarkFromCoordinates(...)` before checking `isRemoteGeocodingAllowed()`. The setting gates only the later BigDataCloud request. | Android’s [Geocoder API documentation](https://developer.android.com/reference/android/location/Geocoder) warns geocoding may hit the network. Current opt-out tests do not prove all coordinates remain on-device. Review Android and iOS provider behavior before making privacy claims. |
| Bundle-size units and estimate are wrong/overstated | `tool/run_bundle_size_analysis.py` divides bytes by 1,048,576 but labels the result “MB”. For the archived AAB, 181,874,892 bytes = **181.87 MB decimal / 173.45 MiB**. The reported 104.38 value is **MiB**, derived by subtracting selected AAB ZIP entries; it is not a measured Play download size. Another report paragraph says ~112.8 MB. | Correct units and replace subtraction with a device-specific `bundletool get-size total` measurement/estimate. Do not claim Play delivery size from AAB subtraction. |
| Bundle-size runner can produce stale/false reports | It stores build exit codes but does not stop when they are nonzero; it can inspect old artifacts. It picks the first `*.json` in a persistent output directory and parses it as Flutter size data, then does not use that parsed value. | Make failures fatal, tie output to fresh artifacts and the exact commit, and consume the exact `--analyze-size` JSON file. Test the failure and stale-artifact paths. |
| File inventory in R59 report is inaccurate | The named “four repo-wide” paths do not match this checkout; e.g. `mutun_digital_catalog.dart` is 164 lines, while `packages/qcf_quran_plus` is a local path dependency and contains an 802-line `quran_page_view.dart` plus generated/static data. | Rebuild a `git ls-files` inventory. Report first-party `lib/`, vendored packages, generated files, and data catalogs separately. Never claim zero oversized files repo-wide without declaring scope. |
| Retained tests are green, but exact-run provenance is imperfect | `build/release-readiness/20261024-185547/tests.log` ends with `+537: All tests passed`; `summary.json` records exit 0 on branch R57, commit `5f6aa5c`, `is_dirty: true`. The app/test source change in R57 is the deterministic golden fix later committed in `c2288bf`; R58/R59 changed tools/docs, not app/test code. | The test result is credible for the current app/test code, but regenerate final clean-tree evidence on the exact head and record a source-tree hash. Do not claim the archived summary itself was captured on `efadd10`. |
| UI lint has substantial warning debt | `python tool/ui_lint_v2.py` returns `OK`, with 220 font-weight literals, 14 numeric `SizedBox` dimensions, 8 RTL-direction warnings, 6 gradient warnings, and 6/10 allow markers. | “OK” means no lint failures. Bring warning debt to zero or document each retained exception with rationale and owner. |
| Device and store actions remain | No production key, final package ID, or physical-device results are in the repository evidence. | Keep Play upload blocked until owner-specific identity/credentials and device acceptance are complete. |

Retained R57 evidence files are in `build/release-readiness/20261024-185547/`. Logs show 537 tests passing, analyzer reporting no issues, UI lint returning OK with warnings, and a successful debug build. The summary’s analyzer duration (15.79 s) differs from the analyzer log’s printed duration (12.9 s) and R59’s 41.4 s; reconcile such differences rather than copying whichever value looks best.

## Execution protocol — mandatory for every task

1. Start from a clean working tree. Confirm branch, `HEAD`, and remote tracking branch. Never stash, reset, clean, delete, or overwrite someone else’s work to make the tree clean.
2. Read only the task’s scoped source and callers. Write down the current behavior and a reproducer before editing. If the defect cannot be reproduced, inspect the call path and add an appropriate deterministic test seam; do not claim reproduction without evidence.
3. Add the failing-first regression before the fix. Avoid sleeps and wall-clock assumptions. Use controlled fakes, barriers, fixed clocks, and injected clients.
4. Edit only listed files, within the 25-file cap. If a larger change is needed, split it into `a/b` tasks and stop at the boundary. Preserve public APIs unless the task explicitly requires migration and updates every caller.
5. For secret, signing, and cleanup work, use a unique temporary directory or isolated worktree. Track every created path. Before cleanup, canonicalize it and prove it is inside that task’s temporary root. Never call cleanup on a path that existed before the task.
6. After the code change, inspect `git diff --check`, the full diff, `git status`, and secret scans. Verify Arabic text did not change accidentally. Run the targeted regression, `flutter analyze`, `python tool/ui_lint_v2.py`, the full `flutter test`, and the required build. Capture command, SDK, OS, commit, duration, exit code, and logs. If a command is interrupted, timed out, or lacks a final exit code, record “unverified.”
7. Commit one task only on `ui/r<n>-<name>`, push according to `AGENTS.md`, add the stage tag only after its acceptance criteria pass, update `UI_PROGRESS.md`, and stop. Do not merge or push unrelated local commits to `main`.

## Ordered work — one task in one session; do not skip

### R61 — Make signing validation incapable of deleting owner files (P0)

**Scope:** `tool/verify_release_signing_config.py`, `android/app/build.gradle.kts` only if the test seam needs it, and focused Python/Gradle validation tests.

- Remove the unconditional startup `cleanup()` and the cleanup of fixed, owner-meaningful paths. Do not create or overwrite `android/key.properties` in the test.
- Use Gradle’s supported environment-variable path with a uniquely named test keystore under a unique temp directory; clear signing variables for the “missing credentials” case. Keep any needed temporary files outside tracked project paths.
- If a test must write a project file, refuse to start if it already exists, record that this task created it, and restore it byte-for-byte in `finally`; prefer not writing it at all.
- Test all three cases: no credentials makes release fail actionably; debug build works without release credentials; a test-only release key signs an artifact whose signer is the test certificate. Also seed a sentinel pre-existing `android/key.properties` in an isolated test fixture and prove it remains byte-identical after both success and failure paths.
- Assert test keystore cleanup only removes the unique path created by the test. No wildcards, fixed-path cleanup, or deletes outside the temporary root.

**Pass:** running the verifier with or without a real ignored `android/key.properties` cannot remove or alter it; no debug-signed release fallback exists; all isolated tests pass. Do not ask the owner for a real key to test this.

### R62 — Make location privacy true at every provider boundary (P0)

**Scope:** location resolution/service, current location settings UI, privacy disclosure, platform geocoder integration, and focused tests only. Begin by tracing Android, iOS, package, HTTP, analytics, and logging paths that receive precise coordinates.

- The BigDataCloud setting currently defaults off, but the platform call `placemarkFromCoordinates` occurs before checking that setting. Inspect the Flutter plugin and Android/iOS implementation; Android’s official Geocoder documentation says it may hit the network.
- Define the behavior explicitly: with remote lookup off, use local city catalog/manual fallback and make **zero** platform or HTTP geocoder calls. With consent on, only call the specifically disclosed provider(s). Do not rely on an OS geocoder with an unknown backend while claiming coordinates stay local.
- Make the smallest safe change. Prefer skipping platform reverse-geocoding entirely in the opt-out path; if using it when opted in, the UI must disclose that the platform provider may process coordinates, not just name BigDataCloud. If exact recipient behavior cannot be established on a platform, do not describe it as local.
- Add injectable geocoder and HTTP seams. Test zero geocoder calls and zero HTTP requests on fresh install/opt-out, explicit opt-in behavior, opt-out immediately after opt-in, manual city behavior, exact coordinate/request bounds, timeout, and fallback outside catalog coverage. Include a platform acceptance check for Android and iOS where supported.
- Update the privacy policy wording and Play Data Safety guidance only to match verified data flows. Preserve the existing Arabic strings unless the owner reviews replacement copy. Make clear that prayer calculations use coordinates locally while city-name lookup may have a separately consented provider.

**Pass:** on a clean install with consent off, every app-controlled reverse-geocoding boundary records zero calls; with consent on, only disclosed calls occur. Tests prove it, and privacy copy no longer promises more than code can guarantee. Record any OS-level uncertainty as a blocker.

### R63 — Repair bundle-size measurements and stop stale-success reports (P1)

**Scope:** `tool/run_bundle_size_analysis.py`, focused script tests, and generated ignored reports under `build/release-readiness/size-analysis/`.

- Check and record every APK/AAB build exit status. Abort before inspecting outputs if a build fails. Require output files to be created/updated after this run starts; record exact SHA-256 and byte count.
- Give each invocation a unique output directory. Select the exact JSON path emitted by the current `--analyze-size` command; never use `glob(...)[0]` in a persistent directory. Remove the unused `flutter_size_data` placeholder or put the parsed current-run data into the report and validate its schema.
- Report both decimal MB (`bytes / 1,000,000`) and MiB (`bytes / 1,048,576`) with explicit labels. Fix all percentages by using the same unit/numerator/denominator. Keep raw bytes as the authoritative measurement.
- Generate a device-specific `.apks` set from the current AAB with Android `bundletool`, use an actual connected-device spec when available, and run `bundletool get-size total`. If only a hand-authored device spec is available, label the output an estimate and include the spec. Do not infer the delivered size by subtracting AAB ZIP entries and call it a measured Play download.
- Test simulated build failure with stale prior artifacts present; the script must exit nonzero and must not overwrite its report with a success summary. Test a clean build and ensure hashes/mtime tie outputs to the current run and commit.
- Do not delete signing files. The size script may use an owner-provided production key only when configured; otherwise create a unique test key in a temp root and clean only that key.

**Pass:** failed builds cannot produce a green report; every reported artifact is fresh and hashed; units are correct; device download estimate comes from bundletool; irreducible assets are supported by asset-reference and feature tests. Keep the raw AAB size and Play download estimate as separate numbers.

### R64 — Establish one trustworthy final verification record (P1)

**Scope:** `tool/run_release_readiness_checks.py`, `.github/workflows/verify.yml`, and generated ignored logs. Do not edit application code in this task.

- Make the Windows Flutter version probe use a correct, explicit subprocess invocation with a timeout. The current environment probe stalled at `flutter --version`; a stuck preflight must not hang the complete runner without a log or timeout.
- Record the clean `HEAD` SHA and fail or mark dirty before gates. Record exact Flutter/Dart/Java/OS versions. Log every command’s combined output, duration, exit code, and artifact SHA.
- Parse test counts only from the final actual test summary; validate that exit code is 0 and failed count is 0. Test parser behavior for pass, fail, empty, interrupted, and malformed logs. Never infer pass from partial `+N` progress.
- Run the required gates on the exact final commit: `flutter analyze`, `python tool/ui_lint_v2.py`, `flutter test`, `flutter build apk --debug`. For release readiness, separately build an AAB signed with a test key and verify its signer; use the actual production key only in the owner’s secure environment.
- CI must upload the logs even on failure and visibly identify the exact commit. Check the real GitHub Actions result for that SHA before saying CI passed. A configured workflow or local pass is not a remote CI pass.

**Pass:** clean-tree, exact-SHA run returns exit 0 for all required gates; archived logs and summary agree exactly; CI is green for that SHA or clearly marked pending. If Flutter fails to start, record the failure and do not claim any subsequent gate ran.

### R65 — Reconcile privacy and Play disclosures with actual behavior (P1)

**Scope:** location disclosure in app, privacy-policy source/link, Play Data Safety preparation document, and tests only after R62.

- Inventory every category and recipient of data: location, crash reports, diagnostics, analytics, external audio/content/video, cloud APIs, and user-selected files. Inspect manifests, SDK configuration, network clients, and platform plugins.
- Distinguish data stored locally, data transmitted only after consent, and data transmitted by platform services whose backend is not controlled by the app. Include purpose, recipient, retention/deletion if known, and whether collection is optional.
- Do not submit or invent legal answers. Prepare a fact sheet with source/test references and owner questions. The owner completes the Play Console form and approves public policy text.

**Pass:** app wording, external privacy policy, and Data Safety fact sheet agree with traced code and R62 tests. Unknown provider behavior remains explicitly unresolved, never described as “no data leaves the device.”

### R66 — Re-audit all previously closed C01–C35 findings against current code (P1)

**Scope:** source/tests for one finding family at a time; no broad refactor. Use `docs/FINAL_AUDIT_VERIFICATION_AND_CLOSURE_REPORT.md` as an index, not proof.

Re-run a hostile evidence review of: audio lifecycle/track switching/download cancellation; persistence transactions and import limits; prayer/notification scheduling across instances/time zones; lifecycle/disposal and background timers; offline Shamela manifests; quiz schemas/idempotence; native widget snapshots; network byte/deadline/redirect bounds; and all seven acceptance journeys. For each item record source path, caller path, regression test name, failure mode prevented, and any platform-only check. If the old test only checks a helper or preference flag, add a real service/UI-seam test. Create a new finding and a separate task whenever the original fix is incomplete.

**Pass:** every high-impact finding is supported by a regression that would fail if behavior regressed; no finding is marked closed solely from a commit message or progress note.

### R67 — Rebuild the whole-repository code and asset inventory (P2)

**Scope:** read-only inventory and a report update; make refactors only in later focused tasks.

- Use `git ls-files` to inventory tracked Dart sources and distinguish first-party app code, local path dependencies, generated code, static data, tests, and build output. Report exact current paths and line counts; do not copy the stale R59 list.
- For `packages/qcf_quran_plus`, identify the upstream repository/version and local modifications. Treat third-party code as a separate ownership category; do not mass-edit vendored code. Include its 802-line `quran_page_view.dart` in repository metrics and explain whether Rule 8 applies.
- Count all UI lint categories and allow markers, unused assets/fonts, duplicated assets, plugin/native dependencies, app permissions, cleartext exceptions, and large bundled assets. Preserve Islamic source datasets and verify references before any asset removal.

**Pass:** inventories can be regenerated by a documented command and match tracked files. Every exception says why it is exempt and who owns follow-up.

### R68 — Reduce UI warning debt and validate accessibility (P2)

**Scope:** one screen family or warning category per task, at most 25 files. This is a design-system stage; do not combine it with service or data changes.

- Triage the current 248 UI lint warnings by source file. Fix directional layout with approved directional APIs, replace numeric spacing and font weight with existing tokens/styles, and remove gradients only where visual review supports the change.
- Do not add tokens without a written proposal and contrast proof. Keep allow markers below the cap and do not add exceptions just to silence the tool.
- Test Arabic RTL, light/dark, text scale 1.0/1.5/2.0, 48dp tap targets, semantics/tooltips, contrast ≥4.5:1 text and ≥3:1 controls, small phones/tablets/landscape, and screen-reader traversal on core screens.
- Update goldens only after opening reference, actual, and diff images and confirming the intended visual change. Automated goldens do not replace device checks.

**Pass:** warnings reach zero or every remaining warning is documented with a concrete reason and owner; accessibility and screenshot evidence is retained; no text clipping or RTL regressions.

### R69 — Measure runtime performance, startup, and memory (P2)

**Scope:** measurable profile run and one issue per task. Do not set arbitrary performance thresholds before collecting a baseline.

Measure cold/warm startup, Quran page turn/search, offline book opening/download, audio track switching, prayer screen refresh, memory under prolonged use, and background/foreground transitions on a named physical device. Record build mode, device model, Android version, frame timing, memory, and repeat count. Profile image/font/data loading and timers before optimization. Keep offline reading and audio behavior intact.

**Pass:** each changed path has before/after measurements on the same device and scenario; no claim of “zero lag” or “60fps” without traces.

### R70 — Final release acceptance and owner handoff (P3)

**Scope:** evidence and decision only; no new feature work.

Before marking ready, collect: owner-confirmed permanent application ID; production upload key configured privately and release certificate fingerprint verified; exact clean-commit gates and CI; bundletool device-size estimate and reviewed asset composition; final privacy-policy/Data Safety owner approval; physical-device checks for location opt-in/opt-out, notifications/alarms, audio focus/interruption, home widget refresh, backup picker/share, offline Quran/Shamela, Arabic RTL, and 2.0 text scale. Record model, OS, build hash, steps, results, and failures.

**Pass:** all owner decisions are resolved, no P0/P1 finding remains, all evidence points at the same final commit, CI is green, production AAB is verified with the intended upload key, and physical checks are recorded. Only then may the owner decide whether to upload to internal testing. Store publication itself remains the owner’s action.

## Whole-app review matrix

The agent must touch every row during R66/R67, even when it finds no new defect. “No issue” requires a source/test reference.

| Area | Inspect for | Evidence required |
|---|---|---|
| Quran/Mushaf | correct page/ayah mapping, font integrity/licensing, offline access, accessibility and memory | catalog integrity, page mapping tests, page-render test/device check |
| Prayer/location | coordinate handling, calculation method, timezone/DST, remote provider consent, manual location, offline fallback | deterministic coordinate/time tests, provider call counts, device permission and no-network tests |
| Audio/Adhan/radio | transitions, focus/interruption, retries/cancel, app lifecycle, background notification path | fake event-order tests plus device interruption/background checks |
| Persistence/backup | atomic writes, schema/version, bounds, malformed input, UTF-8/Arabic preservation, duplicate/conflict rules | failure-injection, concurrent barriers, real file bytes and restore tests |
| Offline books/downloads | truthful complete status, gaps/retry/cancel/restart, cache eviction and storage use | SQLite-backed behavior tests, network fake tests, offline device check |
| Network/security | TLS/cleartext allowlist, redirects, byte/time caps, client closure, secrets, logs, URL hosts | injected HTTP tests and manifest/host inventory |
| Notifications/widgets | permissions, exact alarm behavior, schedule idempotence/timezone, payload routes, native snapshot consistency | method-channel tests and real device reboot/timezone/widget checks |
| Quiz/catalog/state | schema corruption, ID uniqueness, persistence, retry, duplicate completion, lifecycle | adversarial fixtures and deterministic state tests |
| UI/accessibility | RTL, contrast, font scaling, semantics, hit areas, loading/error/empty/offline states | lint, reviewed goldens, accessibility tree and device checks |
| Release/operations | application ID, target SDK, versioning, release signing, app bundle, CI, privacy policy, store declarations | signer verification, exact-SHA CI, bundletool report and owner checklist |

## Owner-only decisions — never invent

- Final unique `applicationId`; the example `com.talibilm.app` in an old report is only a suggestion and must not be adopted without owner confirmation.
- Production upload keystore and passwords; these stay outside Git and logs. The current test signer is `CN=TestUpload` and must never be sent to Play.
- Public privacy-policy URL and final Google Play Data Safety answers, after code/provider behavior is proven.
- Physical Android device and acceptance of any reduced/changed behavior needed for privacy or size.

## Definition of “closer to 10/10”

Do not assign 10/10 as a test result. Report separate evidence-based dimensions: correctness, data safety, privacy, accessibility, performance, maintainability, automated verification, release integrity, and device acceptance. A red/open P0/P1 item blocks an “excellent” claim. A passing unit suite does not prove privacy, UI quality, Play signing, CI, or real-device behavior.

## Required closeout (AGENTS.md, eight lines maximum)

`Task/stage · branch · commit · files changed · old behavior and regression · analyze/lint/focused/full tests/build with exit codes · artifacts/CI/device evidence · remaining blocker and owner action`
