# Gemini 3.8 Flash — talib_ilm Post-Audit Remediation & Store Readiness Guide

**Target Version:** `1.0.0+2002` (Application ID: `com.talibilm.app`)  
**Base Commit:** `44b902f` (`release(11): complete final exact-commit release gate and author release closure report`)  
**Context:** This master implementation guide translates the findings of the latest [`RELEASE_READINESS_AUDIT_REPORT.md`](RELEASE_READINESS_AUDIT_REPORT.md) into concrete, sequential, and fully verified remediation tasks.

---

## 1. Executive Ground Rules (Radical Honesty & Safety)

You are the implementation agent for **talib_ilm / طالب العلم**. Your objective is to address every open finding in the re-audit until the application achieves cross-platform, production-grade release readiness.

1. **One Bounded Task Per Session**: Execute strictly one task per branch/commit.
2. **Dedicated Branch & Tagging**:
   - Branch: `remediation/<task-id>-<short-name>`
   - Commit message: `remediation(<task-id>): <factual description>\n\nCo-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>`
   - Tag: `remediation-task-<task-id>-done`
   - Push immediately with tags: `git push -u origin <branch> --tags`.
3. **No Unrun Checks**: Never claim a test, build, or verification command ran unless you executed it and observed exit code 0.
4. **Preserve Documentation Integrity**: Update `UI_PROGRESS.md` at the end of every task.
5. **Never Touch Protected Paths**: Do not delete, clean, or modify `brag-output/` or `.claude/worktrees/`.
6. **No Breaking Changes**: Never alter core Islamic texts, prayer calculation formulas, or user-facing Arabic strings unless explicitly specified.

---

## 2. Current Baseline & Verified State

Before starting new work, confirm the established baseline on `main`:
- `flutter analyze --no-pub`: **0 issues found** across all 444 first-party Dart files.
- `python tool/ui_lint_v2.py --strict`: **OK** (7 allow markers used / cap 10).
- `flutter test --no-pub`: **794 / 794 tests PASSED, 0 FAILED (100% green)**.
- `python tool/audit_all_app_data.py`: **0 data-integrity errors** across 8,773 Salaf gems, 2,358 Hadiths, and 114 surahs.
- `python tool/verify_android_signing_fail_closed.py`: **5/5 tests PASSED** (release variants fail closed without credentials).
- `git tag -l "release-*"`: Complete tag sequence (`release-task-0-done` through `release-task-11-done` + `release-ready-v1.0.0`).

---

## 3. Prioritized Remediation Work Order

### Task R1 — Reconcile Re-Audit Report & Git History Integrity
**Scope:** `RELEASE_READINESS_AUDIT_REPORT.md` and release tag validation.
1. Reconcile internal copy-paste discrepancies in `RELEASE_READINESS_AUDIT_REPORT.md`:
   - Update Section 4 (P0.4) and Section 10 to reflect the verified 794/794 passing test suite (closing the stale 25-failure baseline).
   - Document `release-task-2-done` tag creation on commit `e3daac1`.
   - Update Section 10 decision matrix to reflect current verified dimensions.
2. Verify all local and remote release tags:
   ```bash
   git tag -l "release-task-*"
   ```
3. Commit, tag `remediation-task-1-done`, and push.

---

### Task R2 — Android Backup Rules & Ephemeral Coordinate Isolation (P1.7)
**Scope:** `android/app/src/main/AndroidManifest.xml` and Android resource XMLs.
1. In `android/app/src/main/res/xml/`:
   - Create `backup_rules.xml` (for Android 11 and below / legacy backup API).
   - Create `data_extraction_rules.xml` (for Android 12+ / Cloud & Device-to-Device transfer).
2. Configure rules:
   - **Include**: User preferences, bookmarks (`flutter.bookmarks*`), reading progress (`flutter.shamela_progress*`), completed khatma state, audio player settings, and theme tokens.
   - **Exclude**: Temporary audio caches, WebView cookies/caches, and sensitive ephemeral GPS coordinates (`flutter.last_latitude`, `flutter.last_longitude`, `flutter.last_altitude`).
3. In `android/app/src/main/AndroidManifest.xml`:
   - Add `android:fullBackupContent="@xml/backup_rules"` to `<application>`.
   - Add `android:dataExtractionRules="@xml/data_extraction_rules"` to `<application>`.
4. Verification:
   ```bash
   flutter build apk --debug --no-pub
   python tool/ui_lint_v2.py --strict
   flutter analyze --no-pub
   ```
5. Commit, tag `remediation-task-2-done`, and push.

---

### Task R3 — Android Exported Components & Intent Security Audit (P1.4)
**Scope:** `android/app/src/main/AndroidManifest.xml`.
1. Audit all `<service>`, `<receiver>`, and `<activity>` elements:
   - `MainActivity`: `android:exported="true"` (Required for `android.intent.action.MAIN` launcher).
   - `com.ryanheise.audioservice.AudioService`: `android:exported="true"` (Required for system `MediaBrowserService`); ensure `android:foregroundServiceType="mediaPlayback"` is present.
   - `com.ryanheise.audioservice.MediaButtonReceiver`: `android:exported="true"` with `android.intent.action.MEDIA_BUTTON`.
   - `RibbonWidgetProvider`, `CompactWidgetProvider`, `LargeWidgetProvider`: `android:exported="true"` with `android.appwidget.action.APPWIDGET_UPDATE`.
   - `HomeWidgetBackgroundReceiver`: `android:exported="true"` with `es.antonborri.home_widget.action.BACKGROUND`.
2. Ensure non-exported internal receivers have explicit `android:exported="false"`.
3. Verify Android 12+ (`targetSdk 35`) explicit export requirements.
4. Verification:
   ```bash
   python tool/verify_device_readiness.py
   flutter build apk --debug --no-pub
   ```
5. Commit, tag `remediation-task-3-done`, and push.

---

### Task R4 — iOS Production Distribution Pipeline & Signed Export Template (P0.1 / P0.3)
**Scope:** `.github/workflows/build_ios.yml` and `docs/IOS_RELEASE_READINESS.md`.
1. Update `.github/workflows/build_ios.yml`:
   - Retain the unsigned build step for pull requests and environments without Apple signing secrets.
   - Add a conditional signed release export step triggered when secrets (`APPLE_CERTIFICATE_BASE64`, `APPLE_CERTIFICATE_PASSWORD`, `PROVISIONING_PROFILE_BASE64`, `KEYCHAIN_PASSWORD`) are present.
   - Install distribution certificate into a temporary isolated keychain.
   - Run `flutter build ipa --release --export-options-plist=ios/ExportOptions.plist`.
   - Upload both the unsigned test artifact and signed release `.ipa` when generated.
2. In `docs/IOS_RELEASE_READINESS.md`:
   - Document exact GitHub Actions secret names and steps for the owner to generate production App Store signed IPAs.
3. Verification:
   ```bash
   python tool/test_ci_failure_propagation.py
   flutter analyze --no-pub
   ```
4. Commit, tag `remediation-task-4-done`, and push.

---

### Task R5 — Tasbeeh & Screen Reader Arabic Accessibility Announcements (P2.5)
**Scope:** `lib/features/adhkar/` presentation widgets and accessibility tests.
1. In the Tasbeeh / Rosary dial widget:
   - Integrate `SemanticsService.announce` on counter increment to vocalize the updated count and dhikr in Arabic for TalkBack / VoiceOver users:
     ```dart
     SemanticsService.announce('$currentDhikr: $newCount', TextDirection.rtl);
     ```
   - Ensure haptic feedback and tap target size (≥ 48dp) are retained.
2. In `test/accessibility_ui_correctness_test.dart`:
   - Add a focused test proving that incrementing the Tasbeeh emits semantic announcements.
3. Verification:
   ```bash
   flutter test test/accessibility_ui_correctness_test.dart --no-pub
   flutter test --no-pub
   python tool/ui_lint_v2.py --strict
   flutter analyze --no-pub
   ```
4. Commit, tag `remediation-task-5-done`, and push.

---

### Task R6 — External Web & Content Trust Boundary Enforcement (P1.8)
**Scope:** `lib/` URL launcher utilities and WebView components.
1. Audit all `launchUrl` and WebView usages:
   - Ensure only HTTPS scheme URLs (`https://`) can be launched externally.
   - Prevent arbitrary schema execution (`javascript:`, `file:`, `content:`).
   - In any WebView configuration, ensure `mixedContentMode` is blocked and file access from file URLs is disabled.
2. Add a focused unit test verifying that non-HTTPS schemes are rejected by the URL launcher boundary.
3. Verification:
   ```bash
   flutter test --no-pub
   flutter analyze --no-pub
   python tool/ui_lint_v2.py --strict
   ```
4. Commit, tag `remediation-task-6-done`, and push.

---

### Task R7 — Clean Exact-Commit Final Release Gate & Closure
**Scope:** Full verification runner, `docs/FINAL_RELEASE_REPORT.md`, `UI_PROGRESS.md`.
1. Ensure the working tree is 100% clean (`git status --short` shows 0 uncommitted changes).
2. Execute the full end-to-end verification pipeline:
   ```bash
   flutter analyze --no-pub
   python tool/ui_lint_v2.py --strict
   python tool/audit_all_app_data.py
   python tool/verify_android_signing_fail_closed.py
   flutter test --no-pub
   python tool/run_bundle_size_analysis.py
   flutter build apk --debug --no-pub
   ```
3. Update `docs/FINAL_RELEASE_REPORT.md` and `UI_PROGRESS.md` with exact commit hashes, file metrics, and binary checksums.
4. Fast-forward merge into `main` and push tags.

---

## 4. Execution Protocol for Gemini 3.8 Flash

When working on any task from this guide:
1. Announce the task name, branch, and scope before editing files.
2. Execute the precise edits.
3. Run the exact verification commands.
4. Format your report in ≤ 8 lines:
   `Stage · branch · commits · files changed · lint v2 before→after · analyze/tests/build results · what you looked at · open issues / owner actions`
5. Tag the commit and push immediately to GitHub (`git push -u origin <branch> --tags`).
