# Release verification stage — 23 October 2026

This continues the release-readiness audit. It repairs verification infrastructure, stale tests and shared button/tag layout at large text scales. Content, release signing and application identity are unchanged.

## Environment recovery

**Latest recovery result (R31):** Git commits and remote branch pushes now work; checkpoint `4d09095` and audio fix `154dc74` are on GitHub. Normal whole-project analyze passes (zero issues, 14.3s) after excluding only generated `build/**`. The copied SDK's Git ownership error is resolved by process-scoped trust of that exact SDK, preserving existing injected Git settings. The verification runner applies/restores that environment; its syntax is checked, not an end-to-end successful runner execution.

The fresh debug APK **built successfully in 312.5s** at `build/app/outputs/flutter-apk/app-debug.apk` (329,476,785 bytes; SHA-256 `B67CE1AEFE23B785F40001B877D5FB3B3D73B99BD2C1E279466E5A8156E66417`). This is a debug artifact, not the earlier approximately 140 MB release APK. Log: `build/release-tools/r31-build-final.log`. First R31 build failed on the copied SDK's Git ownership check; the corrected retry passed. No install/device playback or release signing certification is claimed.

Current full suite: **356 passed / 34 failed**, all failed entries in `test/golden/`; 37 focused audio/download/action tests pass, including 14 new lifecycle tests. Existing golden reference work remains pending. Historical failed/interrupted attempts below are retained as history; they do not override the successful latest build.

The shared Flutter SDK could not write its cache lockfile. A writable copy of Flutter 3.38.7 / Dart 3.10.7 was prepared under ignored `build/release-tools/flutter`. A separate writable Gradle cache was seeded under `build/release-tools/gradle`, excluding lock files. These are local build tools, not application assets or committed files. Generated `android/local.properties` now points to the local SDK; Git ignores that machine-specific file.

`tool/verify_release_readiness.ps1` detects that local SDK, accepts `-FlutterSdk` and `-NoPub`, runs the four project gates, saves logs/results, and restores the previous Gradle cache environment variable. Its PowerShell syntax was checked. The complete script was not itself rerun end-to-end; the commands below were executed directly while diagnosing failures.

## Reproduced baseline

| Check | Actual result |
|---|---|
| `flutter analyze --no-pub lib test` via local SDK | PASS, zero issues, 65.6 seconds. This is a scoped analyze, not an unqualified whole-repository analysis. |
| `python tool/ui_lint_v2.py` | PASS, zero FAIL rules; 248 warnings and seven allow markers remain unchanged. |
| Full `flutter test --no-pub --concurrency=2 --reporter expanded` | FAIL: 335 passed, 39 failed; completed in 9:48. |
| Focused five-file test run after initial repairs | 12 passed, two viewer assertions failed after the font timeout was removed. |
| Focused viewer run after title/navigation repairs | PASS: two tests, including an actual jump to page 2. |
| Analysis after test repairs | PASS on continuation: scoped `lib test` analysis, zero issues, 107.1 seconds. Another analysis after shared-widget/golden edits is tracked below. |
| `flutter build apk --debug --no-pub` | Attempted, no successful completion established. Kotlin daemon access to `C:\Users\pc\AppData\Local\kotlin\daemon` was denied; compilation fell back. |
| Offline Gradle diagnostics | Flutter Gradle plugin tasks reached UP-TO-DATE, then made no further reported progress; unfinished isolated checks/daemons were stopped. No successful APK build established. No final artifact is certified by this stage. |

Baseline logs are in ignored `build/release-tools/`: `analyze-final.log`, `tests-baseline.log`, `tests-repaired.log`, `tests-viewer.log`, `build-final.log`, and `gradle-diagnostic.log`. A baseline test failure is not automatically an application defect.

## Seven non-golden failures repaired

1. **Quiz test:** explicitly awaits the offline question dump, checks the actual 1,113-question syllabus, unique IDs and the existing 20-question level limit. The old 330-question/33-level expectation described the earlier catalog and raced asynchronous loading. Existing answer/evidence/reference assertions remain.
2. **More screen test:** scrolls to the theme row before expecting it. The row exists below the initial viewport; the app did not need a layout change.
3. **Prayer hero test:** expects the current pre-Iqama countdown and verifies that the congregation-start message is absent. The old elapsed-time label no longer describes current behavior.
4–5. **Single-page Quran tests:** preload real Quran data/fonts before the widget test's fake clock. Real isolate/font work was not finishing during `pumpAndSettle`; the repair does not increase timeouts or mock away rendering.
6–7. **Quran viewer tests:** use the same preload, expect the current vocalized title, verify the 604-page delegate, and exercise the quick-jump sheet to page 2. Previously the test named “Quick jump” did not perform navigation.

The five affected test files now pass across the two focused runs (12 tests in the first run plus the repaired two viewer tests). The full suite has not been rerun after these changes. The other 32 baseline failures were golden-test failures, untouched here; no reference images were regenerated or approved.

## Continuation: real-font shared-component goldens

- The golden helper now loads every font declared in the bundled `FontManifest.json`, explicitly requiring Cairo, Amiri and MaterialIcons. Font I/O completes outside fake widget time; test viewport size is reset during teardown. The harness now renders actual Arabic glyphs/icons instead of placeholder boxes.
- Real-font inspection exposed the fixed-height tag clipping at text scale 2.0. Tags and buttons now use minimum heights and vertical padding; button labels have bounded flexible width. Two dimension tokens were proposed before use: `AppSize.tagMinHeight = 28` and `AppSize.buttonSmallMinHeight = 40`. They retain prior minimum visual sizes; no new color pair is introduced.
- Added light/dark 2.0 component cases including a small button and a narrow icon button with a long label. The tag assertion checks that its rendered text receives its full intrinsic height; Flutter exceptions/overflows fail the test.
- Regenerated and visually opened nine final component references: light/dark buttons, light/dark card, list/tag/progress, empty state, navigation, and light/dark 2.0 component fixtures. Arabic/icon glyphs are readable and the scaled tag is fully visible. Long subtitles/button labels intentionally ellipsize. These are isolated-widget references, not full-screen/device certification.
- Four More-widget references were also inspected with real fonts, then restored byte-for-byte to HEAD to defer that group and keep the working set bounded. They are NOT approved/current real-font references in this change.
- Normal golden comparison (without update mode): **9/9 passed**, 7 seconds. All **333 non-golden tests across 69 files passed**, 9:18. This validates the prior seven repairs and the shared-widget changes. It is not a claim that the remaining ten golden-test files pass.
- After the shared-widget and golden-harness edits, `flutter analyze --no-pub lib test` passed with **zero issues**, 461.7 seconds in the contended/cold-cache environment.
- Contrast checks for unchanged pairs: light category 4.86:1, dark category 7.53:1, light primary label 5.97:1, dark primary label 8.70:1. All exceed 4.5:1. Other contrast issues from the original audit remain pending.
- Total uncommitted working set including the original audit/carryover: **24 files**. Do not start a broad reference refresh in the same stage.

## Open issues and continuation

- **T00 implementation attempt:** branch creation was retried and still denied at `.git/refs/heads/ui/r30-release-verification.lock`. A fresh standard debug-build retry reached Gradle; two thread dumps showed cache metadata reads/file hashing rather than a diagnosed application source failure. The build had no final result when deliberately stopped. Log: `build/release-tools/t00-debug-build.log`; diagnostic dumps: `t00-gradle-threads*.txt`. The correct status is **INTERRUPTED / no fresh APK certified**. Only the identified workspace Dart VM and isolated-cache Gradle daemon were stopped. No changes to unrelated IDE processes or ACLs.
- **Recovery snapshot:** all 25 changed/untracked files were archived under ignored `build/release-tools/checkpoints/`. ZIP integrity and every per-file SHA-256 comparison passed; the companion JSON records `file_count: 25`, `verified: true`, `remote_backup: false`. This does not satisfy the required commit/push. Only the exact zero-byte Kotlin session marker created by the interrupted attempt was removed after the owned daemon exited; no pre-existing files were deleted.
- **Final Android build result:** the standard local-SDK `flutter build apk --debug --no-pub` failed with exit **-1073740791**. `build/release-tools/flutter-build-r30-final.log` records `Could not start thread DartWorker: 22` in the Dart VM (`os_thread.cc:349`). This establishes a host runtime failure, not a diagnosed application compilation defect. No fresh debug APK is certified. A subsequent local `dart --version` succeeds; no remaining workspace-local Dart build process was found to stop safely. Other IDE processes were left running.
- **Diagnostic limitations:** the preceding offline Gradle diagnostic completed cold plugin configuration but failed because PowerShell split an unquoted property argument into a task name. This invocation mistake was corrected through the isolated Gradle properties file before the standard Flutter retry. Gradle also could not replace the pre-existing `build/reports/problems/problems-report.html`; a move within that build directory was denied. No file permissions were changed.
- **CONTINUE FROM R30 step 5:** recover the build host and obtain Git write/push access before proceeding with the next bounded reference batch. Current scoped analysis, all non-golden tests and the component references pass. The other ten golden-test files still require review; a broad baseline replacement would exceed the project's approximately 25-file stage limit.
- Git branch creation is denied by this session's read-only `.git`. The connected GitHub repository metadata also reports `push: false`. No commit, tag, branch push or main push was performed. These are access limits, not missing user authorization.
- All release configuration, privacy, permissions, accessibility, size and physical-device tasks from the main audit remain pending. No final app rating or production-ready claim is warranted yet.
