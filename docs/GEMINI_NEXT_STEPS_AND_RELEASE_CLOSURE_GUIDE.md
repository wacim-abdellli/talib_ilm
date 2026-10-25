# talib_ilm — Gemini Next-Steps and Honest Release Closure Guide

**Purpose:** Close the remaining verification and owner-release work without overstating completion. This plan is based on checkout `1013a25` (`ui/r70-final-release-acceptance`) and the evidence inspected on 25 October 2026. Recheck the branch and worktree before acting; this document is a work order, not proof that a gate passed.

## What is actually left

Gemini’s R70 report is useful as a checklist, but its statement that all code and device verification is complete is stronger than the evidence supports:

- On this checkout, `python tool/test_release_readiness_checks.py` ran 18 tests and **failed one**: `test_flutter_probe_timeout_handling`. `probe_flutter_version()` calls `platform.system()` while `subprocess.run` is patched; on Windows, platform detection can itself call the patched subprocess and raise `TimeoutExpired` before the behavior under test is reached. R70’s claim of 5/5 for this same test file does not match the current file or this reproduction.
- Flutter commands hung at startup in the audit environment. Therefore the R70 analyzer, full Flutter test, and build results have not been independently reproduced on the current checkout. Historical logs may still be valid for the commit they identify; do not relabel them as evidence for `1013a25` without checking their recorded SHA.
- The R69 performance report explicitly records **no connected physical device** and describes host-engine benchmarks. R70’s “physical-device & runtime verification” table claims device-dependent behavior such as killed-state alarms, audio interruption, and offline operation was verified. Those claims need device logs or must be corrected to “not yet tested.” Microbenchmark results such as 12 µs for audio focus arbitration are not end-to-end playback latency.
- `tool/ui_lint_v2.py` currently reports 226 warnings (220 font-weight literals and 6 surface-gradient warnings), even though RTL and numeric-spacing warnings are now zero. This is remaining design-system debt to triage, not evidence of a broken release build.
- The Android application ID is still `com.example.talib_ilm`; no production upload key or public privacy-policy URL is configured in this checkout. Those are owner-controlled release decisions. The R70 Data Safety fact sheet is preparation material; the owner must verify answers in Play Console against the shipped behavior.

The easy-to-fix portion is small: repair the Python test seam and make reports match evidence. Exact Flutter verification and device acceptance are mostly environment/access tasks. Choosing the permanent app ID and protecting the upload key are short actions with lasting consequences, so do not choose values for the owner.

## Ordered remaining work

Complete exactly one task per Gemini session. Do not skip a task because a later report says “complete.” Follow `AGENTS.md`, `DESIGN_SYSTEM.md`, `ROUND2.md`, the master Gemini guide, and this document.

### R72 — Repair the release-readiness timeout regression test (small, code/tooling)

**Scope:** `tool/run_release_readiness_checks.py` and `tool/test_release_readiness_checks.py` only, unless a new focused helper test file is necessary. Stay under the 25-file cap.

1. Reproduce the current failure and preserve its exact traceback in the task log.
2. Make platform detection independent of the mocked subprocess, or patch the platform probe explicitly in the test. Keep the timeout behavior under test: a timeout must return `timed_out: true` and a useful summary without leaking the exception.
3. Add/adjust tests for Windows and non-Windows behavior, timeout, successful version parsing, and malformed/empty output as appropriate. Avoid patching global runtime behavior in a way that hides real probe failures.
4. Run `python tool/test_release_readiness_checks.py`, then `git diff --check` and inspect the full diff. Run Flutter gates only if Flutter can start; record unavailable or timed-out gates honestly.
5. Update `UI_PROGRESS.md` with the actual test count and commands. Commit/push the task branch and tag according to repository rules; stop after R72.

**Pass:** the focused suite passes with no skipped timeout assertion, and a simulated timeout is converted to the documented result without invoking a second subprocess through OS detection.

### R73 — Correct release report claims to match available evidence (documentation)

**Scope:** `docs/FINAL_RELEASE_ACCEPTANCE_AND_OWNER_HANDOFF.md`, `docs/RUNTIME_PERFORMANCE_AND_MEMORY_BASELINE_REPORT.md`, and `UI_PROGRESS.md` only.

- Separate host-engine/unit benchmark evidence from physical-device evidence. Keep all R69 numbers only with the stated harness and environment; do not call them device startup, device memory, frame-rate, network, or end-to-end audio measurements.
- Reclassify the R70 device-dependent rows as **pending** unless there are dated device logs identifying model, Android version, build SHA, steps, and outcomes. In particular, exact alarms across killed/reboot states, audio focus/interruption, widgets, permissions, and offline operation require actual Android-device observations.
- Link each automated gate claim to its exact retained log directory and commit SHA. Remove claims of “all 35 findings closed,” “100% complete,” or “all gates passed” where the report cannot point to current source/test and evidence.
- Preserve the three owner actions but label the Data Safety sheet as a draft to verify in Play Console, not a legal determination. Do not invent answers or publish policy text.

**Pass:** every PASS in the acceptance report has an evidence path, exact revision, and a test type (host test, emulator, physical device, or owner action). Unsupported device claims are explicitly pending.

### R74 — Obtain reproducible gates on one exact clean commit (verification)

**Scope:** verification runner/environment diagnosis and evidence only unless a distinct runner defect is found; any code fix becomes its own stage.

- First inspect `where.exe flutter`, `Get-Command flutter`, Flutter SDK path, Dart path, active processes, and Flutter lock/cache state. The prior audit observed `flutter --version` hanging; do not delete SDK caches, kill unrelated processes, switch SDK versions, or claim success from an old log.
- Run on a clean exact SHA with versions recorded: `flutter analyze`, `python tool/ui_lint_v2.py`, `flutter test`, and `flutter build apk --debug`. Run the release-signing verifier with a test key only in its isolated temp directory; verify the signer. Require final test summaries and zero exits.
- Run `python tool/run_release_readiness_checks.py --require-clean` after proving Git metadata works in that process. If the runner still cannot complete, fix that defect separately and mark remaining gates unverified.
- Check GitHub Actions for the same SHA; a configured workflow or local run is not remote CI evidence.

**Pass:** all required commands have retained logs, exit codes, environment versions, and the same clean commit SHA; CI status for that SHA is recorded separately.

### R75 — Perform real-device acceptance (owner supplies device/access)

Use a named Android phone and record model, Android version, app build SHA, network state, permission state, steps, observations, and logs/screenshots where useful. Cover location opt-out/opt-in, manual city fallback, prayer scheduling after reboot and timezone change, notification permission/exact alarm behavior, audio interruption/focus, home-widget refresh, backup picker/restore, offline Quran and Shamela, Arabic RTL, and text scale 2.0. Never infer device behavior from a widget test or benchmark.

**Pass:** each scenario has a result or a clearly recorded device/OS limitation. A missing device is an owner action, not a code PASS.

### R76 — Owner-controlled Google Play setup

The owner must select and confirm the permanent unique `applicationId` before creating/listing the Play app; generate and securely back up the upload key; configure ignored local `android/key.properties`; verify the resulting AAB certificate; host the privacy policy; and complete Play Console declarations after reviewing the actual code and providers. Do not ask Gemini to invent a package ID, handle passwords in chat, commit secrets, or submit legal declarations.

**Pass:** owner confirms app ID and Play listing, production signer fingerprint is verified without exposing secrets, public policy URL is reachable, and Play Console declarations are saved by the owner.

### R77 — Triage remaining UI lint warnings (quality improvement, not release blocker)

The remaining 220 font-weight and 6 gradient warnings should be reviewed by screen family in bounded stages. Use existing design tokens and approved text styles; do not mass-replace typography or gradients mechanically. Follow token proposal, contrast, Arabic RTL, light/dark, 1.0/1.5/2.0 text scaling, tap-target, semantics, and golden-review requirements in `AGENTS.md` and `DESIGN_SYSTEM.md`. Keep each stage below 25 files and stop after one stage.

**Pass:** warnings are eliminated or each residual is individually documented with visual rationale; no goldens are accepted without inspecting the reference, actual, and diff.

## Copy/paste prompt for Gemini Flash 3.8 — do R72 only

> Continue the talib_ilm release-closure work from the current checkout. Read `AGENTS.md`, `DESIGN_SYSTEM.md`, `ROUND2.md`, `UI_PROGRESS.md`, `docs/MASTER_GEMINI_FLASH_3_8_APP_REMEDIATION_GUIDE.md`, and `docs/GEMINI_NEXT_STEPS_AND_RELEASE_CLOSURE_GUIDE.md` before editing. Work on **R72 only**: reproduce and fix the failing timeout-handling test in `tool/test_release_readiness_checks.py`. The observed failure is that `platform.system()` may call `subprocess` on Windows while the test patches `subprocess.run`, causing `TimeoutExpired` to escape before the Flutter probe is tested. Confirm this against current code; do not assume this description is still current if the branch has moved. Add a regression that proves a Flutter probe timeout returns `timed_out: true` and an actionable summary on Windows and non-Windows paths. Make the smallest fix, keep within 25 changed files, and do not edit app behavior, package ID, privacy/legal wording, or secrets. Run the focused test suite and record actual count, exit code, and log; inspect `git diff --check`, the complete diff, and status. Run required Flutter gates only if Flutter starts, and mark every unavailable gate unverified. Update `UI_PROGRESS.md`, commit and push one R72 branch/tag under repository rules, report in eight lines or fewer, and stop. Do not start R73 or claim the app is fully verified or “10/10.”

## Final scoring rule

Report **fix effort** separately from **verified product state**. The remaining coding/tooling work appears low-to-moderate effort; owner identity/signing steps are short but sensitive; exact Flutter and physical-device evidence depend on the environment and owner hardware. Do not turn “easy to fix” into “already fixed,” “tested,” or “Play-ready.”
