# Play release blockers — strict remediation handoff

**Prepared:** 24 October 2026  
**Audited revision:** `main` at `5374fe6` (`ui-r54-done`)  
**Purpose:** Give the next coding agent a concrete, evidence-led sequence to correct the remaining release blockers and substantiate the quality claims. This guide records inspected facts separately from commands that completed in this audit. It does not certify a release.

## Copy this instruction to the next agent

> Read `AGENTS.md`, `DESIGN_SYSTEM.md`, `ROUND2.md`, `UI_PROGRESS.md`, and `docs/PLAY_RELEASE_BLOCKERS_REMEDIATION_HANDOFF.md` before touching code. The owner asked for these release blockers to be fixed. Do exactly the first unfinished task in this document in this session; do not multitask or delegate. First reproduce/confirm that task’s current behavior, then make the smallest complete change and add a regression test for the old failure. Keep the task within 25 changed files. Preserve all existing Arabic text; if new user-facing Arabic copy is required, stop that task and record the exact copy needed for owner review rather than inventing it. Run every required project check and record the actual command, exit status, duration, and relevant output in `UI_PROGRESS.md`. Commit the task on a `ui/r<n>-<name>` branch, push it as required by `AGENTS.md`, and stop with the required report of eight lines or fewer. Never say “Play ready”, “all green”, or “10/10” while a gate, owner action, privacy disclosure, or device check is open.

The project’s `AGENTS.md` visual-only rule remains in force. Release configuration is non-visual; do not use a visual-only task as a pretext to change services, permissions, Gradle, or Arabic strings. Treat the owner’s explicit request for release-blocker remediation as scope for the tasks below, while keeping each task limited to its listed files and tests.

## Verified current state

- `git status` was clean at `main...origin/main`; `HEAD` was `5374fe6` and tagged `ui-r54-done`.
- `android/app/build.gradle.kts` has `targetSdk = 35` and `versionCode`/`versionName` from `pubspec.yaml` (`1.0.0+2002`). It still has `applicationId = "com.example.talib_ilm"` and assigns the **debug signing config to release**. This is a hard upload blocker. No `android/key.properties` exists in this checkout.
- Release APK exists at 258,733,786 bytes; its SHA-256 matches the supplied report: `62615D813B4909D521F3B2CE90280215ACEA491D2F176C565FD8E943006E8905`.
- Release AAB exists at 181,915,363 bytes; its SHA-256 matches the supplied report: `4EC80E6169B021479F7CB02A9A0C3B92F56F50B27EF5BA85B6DF0179782F45D7`. That is 181.9 MB decimal (173.5 MiB). Artifact presence and matching hashes do not establish that an upload-key-signed release can be produced or uploaded.
- `lib/core/services/location_service.dart` defaults `isRemoteGeocodingAllowed()` to `true`. When native reverse geocoding throws, `_resolvePosition` may send the device latitude/longitude to BigDataCloud through `reverse_geocode_client.dart`. `rg` found no app UI call to `setRemoteGeocodingAllowed`; its observed callers are tests. Therefore the current “user intent / preference” gate is not user-controlled in the shipped UI, and “no personal data leaves device” is not an accurate description of this path.
- `python tool/ui_lint_v2.py` completed in this audit and returned `OK`, with 220 font-weight, 14 numeric `SizedBox`, 8 RTL, and 6 gradient warnings (248 total) and 6/10 allow markers. `OK` means no lint failures; it does not mean the warning debt is zero.
- A fresh `flutter test --concurrency=2` run did not return a result after more than 11 minutes and was interrupted. A fresh `flutter analyze` invocation likewise did not return a result in this environment and was interrupted. Do not represent these attempts as pass or fail. The only retained full-suite log found under `build/release-readiness` is `20261024-044654/tests.log`, ending at **454 passed / 39 failed**. Later progress entries claim 531/531, but the matching raw test log is not retained in that directory. Re-run and capture evidence on the pinned SDK before relying on the later claim.
- `lib/core/services/notification_service.dart` is currently 484 lines, while the prior handoff inventory says 355. It remains below 600; refresh exact counts in any current inventory.
- A line-count scan of `lib/**/*.dart` found only four files above 600 lines, all named static catalogs: `app_palette.dart` (1274), `verified_cities.dart` (950), `mutun_lessons_catalog.dart` (1236), and `mutun_audio_catalog.dart` (908). This supports the `lib` behavior-file conclusion, not automatically every file in the repository.

## Work order — one task per session, in this order

### Task R55 — Make the Android release identity and signing safe

**Files:** `android/app/build.gradle.kts`; a non-secret example/configuration note if needed; focused release-config validation. Do not commit a keystore, passwords, or populated `key.properties`.

1. Remove the `com.example` placeholder only after the owner supplies or confirms the final reverse-domain application ID. Do not invent an ID or change it after a Play listing has been created; Android package identity is permanent for the listing.
2. Replace `release { signingConfig = signingConfigs.getByName("debug") }` with release signing read from an ignored local properties file or documented environment variables. Fail the release task clearly when required secrets are absent; never silently fall back to debug signing. Debug builds must continue to work without production secrets.
3. Add a safe `key.properties.example` containing names only, verify the real key-properties path is ignored, and document local upload-key creation/storage without exposing a secret in logs.
4. Add a small Gradle/configuration test or a deterministic validation script that proves: debug can build without release secrets; release refuses missing secrets; release selects the release keystore when a test-only temporary keystore is supplied. Delete only temporary files created by this task and verify their paths first.
5. Verify the resulting release APK/AAB certificate with Android build tools and record the certificate SHA-256. Do not use the debug certificate as evidence of production signing.

**Pass:** owner-confirmed package ID is present; release has no debug-key fallback; missing secrets fail with an actionable message; debug remains buildable; a test-key signed artifact verifies as release-signed. If the owner ID or genuine upload key is unavailable, complete safe configuration and tests, record those owner actions, and do not claim Play-upload readiness.

### Task R56 — Correct coordinate sharing and consent behavior

**Files:** `lib/core/services/location_service.dart`, the existing location/prayer settings UI that owns location choices, `test/network_boundaries_and_security_test.dart`, and only the focused privacy/integration tests required. First locate all location providers, geocoder plugins, API calls, and UI entry points; do not assume BigDataCloud is the only coordinate recipient.

1. Reproduce the current path: fresh preferences default to remote enabled; native geocoding failure can send coordinates; there is no visible setter in the app UI.
2. Make remote coordinate transmission opt-in and default-off unless the owner explicitly approves a different behavior. An explicit control must explain the recipient and purpose before any coordinates are sent. Preserve offline/local fallback when declined.
3. Add failing-first tests for default-off, explicit opt-in, opt-out after opt-in, native-geocoder success without a BigDataCloud call, native failure with opt-out and local fallback, and opt-in sending only the expected request. Assert request counts and exact coordinates using the existing injected HTTP seam.
4. Audit logs, analytics, crash reporting, and other services for coordinates or precise location. Update privacy text/store Data Safety statements only from verified behavior. Do not say “no data leaves device” if any geocoder, map, analytics, or crash service receives it. Do not invent legal claims; identify the exact disclosure owner action if the public policy is outside the repository.
5. Preserve accurate prayer calculation and manual city behavior. No unrelated location refactor.

**Pass:** a clean install transmits no coordinate to the remote reverse-geocoding API until a clear opt-in; declining still yields the documented offline/manual behavior; automated tests prove both paths; exact recipient/purpose are recorded for the privacy policy and Play Data Safety form.

### Task R57 — Re-establish reproducible verification evidence

**Files:** `.github/workflows/verify.yml` only if a real CI gap is found; `UI_PROGRESS.md`; `build/release-readiness` output (ignored/generated only). Do not alter source or goldens to make the count green without a reproduced defect.

1. Use the exact pinned Flutter `3.38.7` and Dart version configured by CI. Record `flutter --version`, OS, and commit before running checks.
2. Run, capture stdout/stderr and exit status for `flutter analyze`, `python tool/ui_lint_v2.py`, and `flutter test`. Preserve a raw log and machine-readable test result under a timestamped ignored `build/release-readiness/<run-id>/` directory. A terminal that is still running is not a pass; wait for completion or record it as timed out/interrupted with no verdict.
3. Make CI upload the test/analyze/lint logs or a concise test report as artifacts when practical; verify the workflow runs against the exact pushed commit. Do not claim remote CI is green from a local run.
4. If the suite fails, list every failing test and root cause, fix only the failures in a separate task, and retain before/after evidence. Do not update goldens without inspecting reference, actual, and diff images.
5. Current `ui_lint_v2.py` warning counts must be recorded honestly. Resolve each warning in its own bounded UI stage using approved tokens and contrast evidence, or document a concrete exception with owner and rationale. Do not add `ui-lint: allow` markers merely to suppress counts.

**Pass:** all required commands exit zero on the final commit; raw logs are retained; `flutter test` reports the actual total and zero failures; CI is green for that exact commit; UI lint warnings are zero or each remaining warning has an explicit reviewed exception. Do not use the current 531/531 prose as a substitute for evidence.

### Task R58 — Measure and reduce delivered bundle size

**Files:** inspect `pubspec.yaml`, assets, native packaging, and build configuration first. Change only confirmed unused/duplicated assets or build settings; no speculative asset deletion.

1. Run Flutter's app-size analysis on the pinned SDK for release AAB and APK. Save the size-analysis JSON and a sorted breakdown of Dart/AOT, native libraries by ABI, fonts, images, audio/data assets, and duplicated content.
2. Identify the largest contributors and prove each candidate is unused or can be delivered on demand. Never remove Quran text/audio, prayer data, or other app content solely to meet an arbitrary number.
3. Prefer ABI-specific APKs for direct distribution and Play's split delivery from AAB; compare actual installed/download size where tooling provides it. Record baseline and after sizes with identical build flags and exact commit.
4. Re-run catalog integrity, offline, and asset-reference tests for any asset change; run full required gates after the final size change.

**Pass:** explain the AAB's 181.9 MB composition, demonstrate measured improvement where safe, and document remaining irreducible content. Do not label the raw AAB byte count as the user's exact Play download size.

### Task R59 — Correct the final audit and release decision

**Files:** `UI_PROGRESS.md`, `docs/FINAL_AUDIT_VERIFICATION_AND_CLOSURE_REPORT.md`, and any superseded audit guide. No source-code edits in this documentation task.

1. Replace the unconditional “10/10 / fully green / release readiness 10/10” language with a status tied to evidence and outstanding owner actions.
2. Correct stale line counts and ensure the report distinguishes: artifact generated, build exit status, signing certificate, tests, CI, and actual Play upload readiness.
3. Record remaining blockers plainly: package ID owner decision, genuine upload-key setup, coordinate/privacy-policy wording, any test/CI failure, remaining UI warnings, and size action.
4. Link every claim to a command log, test, source location, CI run, or device result. Do not call code quality a perfect score; report dimensions separately and explain any score as an assessment rather than a test result.

**Pass:** the report agrees with `UI_PROGRESS.md`, all counts and hashes are current, every gate is evidenced on the named revision, and no unresolved blocker is described as complete.

## Release decision checklist (do not skip)

Do not tell the owner to upload until all are true:

- Owner has confirmed the final unique Android application ID and it is fixed in the Play listing plan.
- A real upload key is stored privately; release Gradle config uses it and the built AAB certificate is verified.
- Coordinate collection/transmission behavior and public privacy disclosures match; remote geocoding requires the reviewed consent behavior.
- `flutter analyze`, UI lint, full tests, release AAB build, and exact-commit CI have completed with retained evidence.
- AAB contents and size have been reviewed; delivered size is measured/understood.
- Required device checks pass for location opt-in/offline fallback, notification scheduling/permissions, audio interruption, widget refresh, backup picker/share, offline books, Arabic RTL, and 2.0 text scale. Record device model, Android version, build hash, and scenarios.

Until then, report the status as **code audit in progress; Play upload blocked** with the exact open item and owner/agent responsible.

## Required per-session report (AGENTS.md, eight lines maximum)

`Task/stage · branch · commit · files changed · old behavior reproduced and regression added · analyze/lint/focused/full tests/build results with exit status · artifact/certificate/CI or device evidence · open issues and owner actions`
