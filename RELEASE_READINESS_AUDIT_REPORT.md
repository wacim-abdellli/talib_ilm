# طالب العلم — Release Readiness Audit

**Audit date:** 1 November 2026  
**Audited branch:** `main`  
**Audited HEAD:** `3ad276f` — `perf(quran): optimize audio downloads scanning, instant page load & zero-lag reciter sheet`  
**Audit type:** Whole-app pre-publish release-readiness review  
**Scope:** Product coverage, code quality, UI, tests, security, privacy, Android release, iOS release, CI, store policy, and device-readiness evidence  
**Changes made during audit:** None to application source, tests, goldens, configuration, branches, or untracked files.

---

## 1. Executive verdict

### Current decision: **Do not publish yet**

The app has unusually broad Islamic-content and offline functionality, a substantial automated test suite, clean static analysis, and a mature feature set. However, the current checkout is not production-store ready because the full test suite fails, Android production signing is not configured, the iOS pipeline is unsigned, the public privacy-policy URL is not hosted, and several platform/device checks remain unverified.

### Current overall rating: **7.0 / 10 pre-release quality**

This is an engineering assessment, not a store approval or formal security certification.

| Dimension | Rating | Assessment |
|---|---:|---|
| Feature breadth | **8.5/10** | Quran, prayer, Qibla, Adhkar, Ilm, Shamela, Mutun, Hadith, Salaf gems, radio, audio, offline content, widgets, favorites, onboarding, and backup flows are present. |
| Architecture and code quality | **8.0/10** | Strong service boundaries, data validation, offline-first behavior, focused regression tests, and recent performance work. |
| Static analysis | **9.5/10** | `flutter analyze --no-pub` passed with zero issues. |
| UI consistency | **7.5/10** | Design-system work is extensive, but current golden mismatches mean the visual baseline is not currently proven. |
| Accessibility confidence | **7.0/10** | Semantics, tap targets, RTL, contrast, and text-scale tests exist; TalkBack/VoiceOver and broad device traversal evidence remain incomplete. |
| Security and privacy | **6.8/10** | No secrets found and privacy boundaries are substantially covered, but TLS bypass code, cleartext exceptions, exported components, backup behavior, and location retention need final review. |
| Android release readiness | **4.5/10** | Production upload key is not configured; release APK behavior can fall back to debug signing. |
| iOS release readiness | **3.5/10** | Current CI produces a no-code-sign build, not a signed App Store/TestFlight archive. |
| Store/legal readiness | **4.0/10** | Public privacy URL, Data Safety submission, permission declarations, and owner-controlled store setup remain open. |
| **Overall** | **7.0/10** | Strong product and engineering foundation; publishing gates are still open. |

---

## 2. Verification performed in this audit

### Passed

```text
flutter analyze --no-pub       PASS — No issues found
python tool/ui_lint_v2.py --strict  PASS — OK, 7 allow markers used, cap 10
git diff --check              PASS — no output / no whitespace errors
```

### Failed

```text
flutter test --no-pub          FAIL — 769 passed, 25 failed, exit code 1
```

The full test run took approximately **3 minutes 24 seconds**.

### Test result interpretation

The full test suite did not fail because of a single isolated test. It produced a broad group of golden/UI mismatches plus several functional/widget failures. This means the release cannot currently claim a clean regression baseline.

Do **not** update all golden files blindly. Each failure should be classified as one of:

1. Intentional UI change whose reference golden is stale.
2. Actual visual regression.
3. Environment/font/rendering difference.
4. Test expectation that no longer matches the intended product behavior.
5. Functional defect.

For every golden failure, inspect the reference image, actual image, and diff image before deciding.

---

## 3. Full test failures observed

### Golden/UI failures

The following golden scenarios failed during the current full-suite run:

- `AdhkarHeader` — light 1.0
- `RosaryDial` — light 1.0
- `AppListTile and AppTag` — light
- Populated Favorites page — light 1.0 / dark 1.5
- Home quick actions — light 1.0
- Home header — light 1.0 and dark 1.5
- Ilm daily motivation card — light 1.0 / dark 1.5
- Home above-the-fold hierarchy — light 1.0 and dark 1.5
- More theme option — light 1.0
- Onboarding page — light 1.0
- Prayer next-prayer card — light 1.0
- Prayer time card — light 1.0
- Prayer header — light 1.0
- Quran Surah card — unbookmarked light 1.0 / dark 1.5
- Quran Surah card — bookmarked light 1.0 / dark 1.5
- Astrolabe compass — light 1.0 / dark 1.5
- Quran Surah-number medallion — light 1.0 / dark 1.5
- Splash page — light 1.0 and dark 1.5
- Shamela page content — hamesh closed/open, light and dark

One especially large mismatch was recorded for the Ilm motivation golden:

```text
ilm_motivation_light_1_0.png — 78.68%, 258,992 pixels different
```

Other examples included:

```text
home_quick_actions_full_light_1_0.png — 2.37% different
astrolabe_compass_light_1_0.png — 2.62% different
splash_page_light_1_0.png — 1.99% different
```

### Non-golden failures observed

- Offline books UI scaling/rendering tests.
- Offline download UX expectation.
- Notification router/deep-link tests.
- Ilm header progress text expectation: expected `4/96 مُنجز`, but the finder found zero matching widgets.

The complete failure list is preserved in the test-run output for this audit.

---

## 4. P0 — Must resolve before any store submission

### P0.1 Android production signing is not fully fail-closed

**Evidence:** `android/app/build.gradle.kts:97-107`

The release build uses the real release signing configuration only when all credentials are available. Otherwise, the release build type assigns the debug signing configuration. A task-graph guard rejects missing signing for `bundleRelease`, but the same protection does not cover every release APK variant such as `assembleRelease` or split APK builds.

**Risk:** A release APK generated outside the AAB path can be signed with the Android debug certificate. This is unsafe and can create update/signing confusion.

**Required owner/engineering action:**

- Make every release artifact fail closed when production signing is absent.
- Add tests for `assembleRelease`, split APK release builds, and `bundleRelease`.
- Verify the certificate of the final AAB and APK with `apksigner`/`keytool`.
- Never commit the keystore or passwords.

### P0.2 Android production upload key is not configured

**Evidence:** `android/key.properties.example`, ignored `android/key.properties`, `android/app/build.gradle.kts:40-52`

The repository contains only the configuration template. A real owner-controlled upload keystore is not available in the audited checkout.

**Required owner action:**

- Generate or retrieve the production upload key securely.
- Configure it locally or through protected CI secrets.
- Build the final release AAB.
- Record the SHA-256 certificate fingerprint privately and verify that it matches the Play Console upload-key configuration.

### P0.3 iOS pipeline does not produce a store-uploadable artifact

**Evidence:** `.github/workflows/build_ios.yml:35-40`, `ios/Runner.xcodeproj/project.pbxproj`

The current workflow uses `flutter build ios --release --no-codesign` and packages an unsigned app. It demonstrates compilation only; it does not produce a signed App Store/TestFlight archive.

**Required owner/engineering action:**

- Configure Apple signing certificates and provisioning profiles or App Store Connect API-based signing.
- Build an archive with signing enabled.
- Export a signed IPA for TestFlight/App Store submission.
- Verify that the Runner and WidgetKit extension are both signed and embedded.

### P0.4 Full test suite is failing

**Evidence:** current command `flutter test --no-pub`

```text
769 passed, 25 failed, exit code 1
```

**Required engineering action:**

- Triage all 25 failures.
- Fix functional failures before visual refreshes.
- Review golden diffs one by one.
- Regenerate only intentionally changed goldens after visual inspection.
- Re-run the full suite on the exact release commit and retain the raw output.

### P0.5 Public privacy-policy URL is not hosted

**Evidence:** `docs/PRIVACY_POLICY.md:6`

The document currently states:

```text
Public Policy URL: To be hosted at publisher website / repository URL by owner
```

**Required owner action:**

- Host the policy at a stable public HTTPS URL.
- Verify that the URL opens without authentication.
- Use the same URL in Google Play Console and App Store Connect.
- Ensure the policy matches shipped behavior, including third-party media hosts, optional geocoding, local storage, backup behavior, notifications, and permissions.

---

## 5. P1 — Resolve before production release or internal testing

### P1.1 CI can mask failed gates

**Evidence:** `.github/workflows/verify.yml:59-93`

Several workflow steps pipe command output into `tee` without explicit `pipefail` or a final aggregate failure gate. The workflow also continues after failures with `if: success() || failure()`.

**Risk:** A failed Flutter/Python command can be obscured by the exit status of `tee`, and the workflow may appear successful without a reliable aggregate verdict.

**Required action:**

- Enable `set -o pipefail` for shell steps.
- Capture each command exit code explicitly.
- Add a final step that fails if any required gate failed.
- Upload logs while preserving the true workflow status.

### P1.2 Global debug TLS certificate bypass

**Evidence:** `lib/utils/ssl_helper_mobile.dart:4-17`

The debug HTTP override accepts every certificate:

```dart
badCertificateCallback = (cert, host, port) => true;
```

It is enabled only in debug mode, but it is global and can become a dangerous configuration footgun.

**Required action:**

- Prefer removing it entirely.
- If local emulator testing requires it, restrict it to an explicit test-only build/host.
- Add a CI assertion that release/profile builds cannot install this override.

### P1.3 Broad cleartext HTTP domain exemptions

**Evidence:** `android/app/src/main/res/xml/network_security_config.xml:9-15`

Cleartext traffic is allowed for entire domains and subdomains:

- `mp3quran.net`
- `qurango.net`
- `everyayah.com`
- `archive.org`

**Risk:** HTTP downgrade or man-in-the-middle manipulation of third-party content and media responses.

**Required action:**

- Prefer HTTPS-only URLs.
- Remove broad exceptions where HTTPS works.
- If a legacy HTTP endpoint is unavoidable, restrict the exception to the narrowest exact host and endpoint possible.
- Re-test audio/radio playback after tightening the policy.

### P1.4 Exported Android components need final review

**Evidence:** `android/app/src/main/AndroidManifest.xml:46-123`

Exported services, receivers, widgets, and HomeWidget background components include:

- AudioService
- MediaButtonReceiver
- Widget providers
- HomeWidget background receiver/service

Some exports are required for system integration, but each should be checked against the merged manifest and plugin contract.

**Required action:**

- Confirm every exported component is required.
- Add permissions where possible.
- Validate handling of external intents and payloads.
- Test on Android 12+ and current Android releases.

### P1.5 Exact alarms and full-screen intent need Play review

**Evidence:** `android/app/src/main/AndroidManifest.xml:3-14`

The app requests exact alarms and full-screen intent alongside location, boot, wake lock, notification, and foreground media permissions.

**Required action:**

- Confirm each permission is essential.
- Complete Play Console declarations accurately.
- Verify denial and restricted-device fallback behavior.
- Ensure full-screen intent is used only for an eligible, user-visible alarm use case.

### P1.6 iOS release metadata and background modes need reconciliation

**Evidence:** `ios/TalibIlmWidgets/Info.plist`, `ios/Runner/Info.plist`, `ios/Runner.xcodeproj/project.pbxproj`

Items to verify:

- Widget extension plist has hard-coded version values that may diverge from `pubspec.yaml` version `1.0.0+2002`.
- `NSLocationAlwaysAndWhenInUseUsageDescription` is declared; remove it if Always/background location is not genuinely used.
- `UIBackgroundModes` includes `audio` and `fetch`; remove `fetch` unless implemented and justified.
- Runner and WidgetKit identifiers match Apple Developer provisioning.

### P1.7 Location data retention and backup behavior

The app stores latitude/longitude in ordinary `SharedPreferences`. Android backup/extraction behavior is not explicitly declared in the inspected manifest.

**Required action:**

- Decide whether location and sensitive progress data should be excluded from backup.
- Add explicit backup/data-extraction rules or document the chosen behavior.
- Minimize coordinate retention and document it in the privacy policy.
- Verify every remote geocoding request is gated by the user’s explicit opt-in.

### P1.8 WebView and external-content trust boundary

The app uses YouTube/WebView-backed content and remote Shamela content.

**Required action:**

- Allow only expected HTTPS origins.
- Review JavaScript, mixed-content, file-access, navigation, and external-link settings.
- Avoid exposing JavaScript bridges to arbitrary remote pages.
- Add offline/error/timeout handling tests for external content.

---

## 6. P2 — Quality and confidence improvements

### P2.1 Device acceptance is incomplete

The current repository evidence does not fully prove behavior on:

- Locked-screen MIUI/Samsung prayer notifications.
- OEM battery restrictions and background execution.
- Audio interruptions from calls, Bluetooth, alarms, and other players.
- iOS WidgetKit gallery and App Group data refresh.
- Android 16 KB page-size/device behavior where applicable.
- TalkBack and VoiceOver traversal.
- Low-end device frame timing, RAM, cold start, and prolonged use.
- Reduce-motion behavior.

### P2.2 UI warning inventory needs a fresh baseline

Strict UI lint returns `OK`, but historical audit records report advisory warning counts, including font-weight and gradient warnings. `OK` means no blocking lint failures; it does not prove that advisory debt is zero.

Generate one current inventory on the exact release commit and distinguish:

- Blocking failures.
- Advisory warnings.
- Approved allow markers.
- Vendored/generated/data files.
- First-party behavior files.

### P2.3 Documentation/version drift

The repository contains historical reports from different revisions. Some older reports claim different test totals, package identifiers, warning counts, and release states.

Known drift to reconcile:

- `pubspec.yaml` reports `1.0.0+2002`.
- `README.md` advertises a different product/version state.
- Historical reports refer to older commits and older test totals.
- `UI_PROGRESS.md` contains corrupted control characters in some historical entries.

The final release report must cite only evidence from the exact release commit.

### P2.4 Bundle size and performance evidence

The app intentionally bundles substantial offline Quran and Islamic-content assets. That is a valid product choice, but the exact release artifact should be measured.

Required evidence:

- AAB size and composition.
- Split APK sizes by ABI.
- Estimated Play-delivered download size.
- Cold-start timing.
- Quran page switching.
- Download scan performance.
- Audio switching and playback startup.
- Memory after prolonged reading/audio use.
- Frame-time p95 on a named low-end device.

Do not describe “zero lag” or “60fps” as verified without device/profile evidence.

### P2.5 Accessibility evidence

Existing tests cover useful foundations:

- Semantics for shared controls.
- 48dp tap targets.
- RTL and directional spacing.
- Contrast ratios.
- Text scaling through 2.0 in selected widgets.

Still needed:

- TalkBack traversal of Home, Prayer, Quran, Ilm, Adhkar, More, and Tasbeeh.
- VoiceOver traversal on iOS.
- Header/button/selected roles.
- Announcement of Tasbeeh counter changes.
- Non-color-only prayer state communication.
- Dialog, sheet, filter, download, error, empty, and offline-state semantics.

---

## 7. Product and feature assessment

### Strong areas

- Broad Arabic-first Islamic knowledge coverage.
- Quran/Mushaf reading, offline pages, bookmarks, reading history, audio, downloads, tafsir, Tajweed, and navigation.
- Prayer calculations, Tunisia-specific calculation handling, Qibla, notifications, Adhan audio, widgets, and location fallback.
- Adhkar, Tasbeeh, fasting/reminders, and reading typography controls.
- Ilm curriculum, Mutun, Shamela heritage books, offline books, audio reciters, chapters, and persistent mini-player.
- Hadith collections and filtering.
- Salaf gems / classical and contemporary scholarly content with filtering and citations.
- Radio and video content.
- Favorites, backup/restore, onboarding, dark/light UI, and RTL support.
- Recent Quran download performance work appears well targeted and has focused regression tests.

### Weaker confidence areas

- Real native notification behavior across OEMs.
- iOS signed distribution and WidgetKit store behavior.
- Visual baseline consistency, as shown by 25 failed tests.
- Performance claims without current profile/device traces.
- Store policy declarations and public legal URL.
- Current exact-head evidence versus older historical documentation.

---

## 8. Recommended execution order

### Step 1 — Test and golden triage

- Fix functional failures first.
- Inspect all golden diffs.
- Update only intentionally changed references.
- Re-run the full suite until zero failures.

### Step 2 — Release integrity

- Make all release APK/AAB variants fail closed without real signing.
- Configure private production upload signing.
- Verify final artifact certificates.
- Add CI certificate and version checks.

### Step 3 — CI trustworthiness

- Add `pipefail`.
- Add explicit exit capture.
- Add final aggregate gate.
- Preserve raw logs and test summaries for the exact commit.

### Step 4 — Privacy and security hardening

- Remove or isolate TLS bypass.
- Reduce cleartext exceptions.
- Review exported components.
- Decide backup behavior.
- Verify all location/geocoding consent boundaries.
- Update the hosted policy to match actual behavior.

### Step 5 — iOS distribution

- Configure signing and provisioning.
- Build and verify an archive and IPA.
- Verify Runner and WidgetKit extension identifiers, versions, entitlements, and signatures.

### Step 6 — Device acceptance

- Android: Pixel/reference device plus at least one OEM with aggressive battery management.
- iOS: physical device with WidgetKit, notification, audio, permission, and background checks.
- Test RTL, text scale 2.0, offline mode, permission denial, notification delivery, audio interruption, backup, and deep links.

### Step 7 — Store preparation

- Confirm permanent application IDs.
- Host privacy policy.
- Complete Data Safety and App Privacy forms.
- Review restricted permissions.
- Produce store screenshots and release notes.
- Build final signed artifacts from a clean tagged commit.

---

## 9. Owner checklist

### Android / Google Play

- [ ] Confirm permanent application ID: `com.talibilm.app`.
- [ ] Confirm the ID is owned and reserved in the intended Play Console account.
- [ ] Generate or retrieve the production upload keystore.
- [ ] Store credentials only in protected local/CI secrets.
- [ ] Build signed release AAB.
- [ ] Verify AAB certificate fingerprint.
- [ ] Verify release APK certificate and ensure it is never debug-signed.
- [ ] Complete Play Data Safety form.
- [ ] Complete exact-alarm declaration.
- [ ] Complete full-screen-intent declaration if still required.
- [ ] Complete foreground-service/media declaration.
- [ ] Host and submit public privacy-policy URL.
- [ ] Test notifications and alarms on representative devices.

### iOS / App Store

- [ ] Confirm Runner bundle ID.
- [ ] Confirm WidgetKit extension bundle ID.
- [ ] Confirm App Group entitlement ownership.
- [ ] Configure distribution certificate/profile or App Store Connect signing.
- [ ] Produce signed archive and IPA.
- [ ] Verify both Runner and extension signatures.
- [ ] Align app and widget version/build metadata.
- [ ] Review location and background-mode declarations.
- [ ] Test notification, audio, permission, and widget behavior on a physical iPhone.
- [ ] Host and submit public privacy-policy URL.

### Engineering

- [ ] Resolve all 25 current test failures.
- [ ] Re-run `flutter analyze --no-pub`.
- [ ] Re-run `python tool/ui_lint_v2.py --strict`.
- [ ] Re-run `flutter test --no-pub` with zero failures.
- [ ] Run `flutter build appbundle --release` with real signing.
- [ ] Run `flutter build apk --release --split-per-abi` with real signing.
- [ ] Run current bundle-size analysis.
- [ ] Run physical-device acceptance.
- [ ] Tag the exact release commit.
- [ ] Archive all logs, hashes, certificates, screenshots, and device results.

---

## 10. Final release decision

```text
Current status: CODE AUDIT IN PROGRESS; PLAY/APP STORE UPLOAD BLOCKED

Static analysis:       PASS
Strict UI lint:        PASS
Whitespace check:     PASS
Full Flutter tests:   FAIL — 769 passed, 25 failed
Android signing:      BLOCKED pending production upload key and fail-closed APK behavior
iOS signing:           BLOCKED — current CI is no-code-sign
Privacy URL:           BLOCKED — not publicly hosted
Device evidence:       INCOMPLETE
Store declarations:    INCOMPLETE

Publish now:           NO
Internal testing:      After test/release-integrity fixes
```

The app is a strong product foundation with extensive functionality and meaningful automated coverage. It should move toward release only after the failing tests, artifact signing, CI truthfulness, privacy URL, store declarations, and real-device checks are closed on one exact release commit.
