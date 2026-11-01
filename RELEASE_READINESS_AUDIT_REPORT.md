# طالب العلم — Release Readiness Audit

**Audit date:** 1 November 2026  
**Audited branch:** `main`  
**Audited HEAD:** `44b902f` — `release(11): complete final exact-commit release gate and author release closure report`  
**Audit type:** Whole-app pre-publish release-readiness re-audit  
**Scope:** Product coverage, code quality, UI, tests, security, privacy, Android release, iOS release, CI, store policy, device-readiness evidence, and release-history integrity  
**Changes made during audit:** No application source, tests, configuration, branches, or tags were changed. This report is being updated to record the current evidence. The checkout was already dirty before this report update: `docs/FINAL_RELEASE_REPORT.md` modified and `brag-output/` untracked.

---

## 1. Executive verdict

### Current decision: **Do not publish yet**

The current `main` checkout has materially improved since the original baseline. Static analysis, strict UI lint, the full Flutter test suite, dataset integrity, Android fail-closed signing checks, HTTPS configuration, and CI failure propagation were independently verified. However, the repository is not fully production/store ready: the iOS workflow still builds with `--no-codesign`, physical-device verification was not reproduced because no ADB device was available, the release-task tag sequence is missing `release-task-2-done`, and the exact-commit gate was run against a dirty checkout.

The final release closure report's “100% green” and “production grade” wording is therefore too broad. It should be read as a claim about selected Android/code gates, not proof of complete cross-platform store readiness.

### Current overall rating: **7.8 / 10 pre-release quality**

This is an engineering assessment, not a store approval or formal security certification.

| Dimension | Rating | Assessment |
|---|---:|---|
| Feature breadth | **8.5/10** | Quran, prayer, Qibla, Adhkar, Ilm, Shamela, Mutun, Hadith, Salaf gems, radio, audio, offline content, widgets, favorites, onboarding, and backup flows are present. |
| Architecture and code quality | **8.0/10** | Strong service boundaries, data validation, offline-first behavior, focused regression tests, and recent performance work. |
| Static analysis | **9.5/10** | `flutter analyze --no-pub` independently passed with zero issues. |
| UI consistency | **7.5/10** | Design-system work is extensive and the current Flutter test suite passes, but broad real-device visual evidence remains incomplete. |
| Accessibility confidence | **7.5/10** | Automated semantics, tap-target, RTL, contrast, and text-scale tests pass; TalkBack/VoiceOver and broad device traversal evidence remain incomplete. |
| Security and privacy | **7.8/10** | Android signing hardening, strict HTTPS configuration, and TLS-bypass removal are present; backup, exported components, third-party boundaries, and store declarations still need owner review. |
| Android release readiness | **7.0/10** | Fail-closed signing verifier passes and test-signed release checks pass, but the production upload key is not present in the repository and final owner-controlled signing remains required. |
| iOS release readiness | **3.5/10** | The current CI workflow still uses `flutter build ios --release --no-codesign`; it does not produce a signed App Store/TestFlight archive. |
| Store/legal readiness | **5.5/10** | A public privacy-policy URL is present, but Play/App Store declarations, production credentials, and signed distribution artifacts remain owner actions. |
| **Overall** | **7.8/10** | Strong Android/code foundation; cross-platform publishing gates remain open. |

---

## 2. Verification performed in this audit

### Independently reproduced on current `main` (`44b902f`)

```text
flutter analyze --no-pub                 PASS — No issues found
python tool/ui_lint_v2.py --strict       PASS — OK, 7 allow markers used, cap 10
flutter test --no-pub                    PASS — exit code 0; full suite completed successfully
python tool/audit_all_app_data.py        PASS — 0 data-integrity errors
python tool/verify_android_signing_fail_closed.py
                                          PASS — 5/5 checks passed
python tool/test_release_readiness_checks.py
                                          PASS — 27 regression tests passed
flutter build apk --debug --no-pub       PASS — build command completed successfully
python tool/verify_device_readiness.py   NOT VERIFIED — exited 0 but reported no active ADB device
python tool/run_release_readiness_checks.py --only-bundle
                                          NOT ACCEPTED AS CLEAN RELEASE PROOF — run observed a dirty checkout
```

The local verification output is evidence for this checkout only. It does not prove iOS signing, Play/App Store acceptance, or physical-device behavior.

### Original baseline retained for historical context

The original baseline recorded 769 passed and 25 failed tests. The current suite now passes, so that historical failure count is not a current test result and must not be used as the present release status.

---

## 3. Current verification interpretation

The current full Flutter suite completed successfully, so the original 25-test failure baseline is closed as a historical issue. The passing suite does not, by itself, prove physical-device behavior, iOS distribution signing, store-policy acceptance, or visual correctness on every supported device.

The current independent device-readiness command exited successfully but reported:

```text
[WARN] No active ADB device found.
```

Therefore the claimed Infinix X689 `8/8` physical-device result is not reproducible from the current environment and remains unverified in this audit.

The current release-bundle verification also detected a dirty checkout. A final exact-commit release gate must be rerun from a clean checkout containing only the intended release commit and its verified artifacts.

---

## 4. P0 — Must resolve before any store submission

### P0.1 iOS distribution signing is not configured

**Evidence:** `.github/workflows/build_ios.yml:36-40`

The current workflow explicitly runs `flutter build ios --release --no-codesign` and packages the resulting unsigned app into an IPA. This proves compilation and packaging only; it does not produce a signed App Store/TestFlight archive.

**Required owner/engineering action:**

- Configure Apple distribution certificates and provisioning profiles or App Store Connect API-based signing.
- Build a signed archive with signing enabled.
- Export and verify a signed IPA.
- Verify that both the Runner app and WidgetKit extension are signed and embedded.

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

### P0.4 Full test suite status

**Current status:** **CLOSED** in current checkout (`44b902f`).
Command `flutter test --no-pub`:
```text
02:22 +794: All tests passed!
794 passed, 0 failed, exit code 0
```
All 3 functional expectations were resolved, and 22 golden scenarios were reviewed with pixel analysis and refreshed. The full test suite is 100% green. Keep full-suite verification running as an automated release gate.

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

### P1.2 Debug TLS bypass

**Current status:** CLOSED in application behavior. The mobile helper is now a no-op and current Dart source contains no `badCertificateCallback` implementation. Keep a regression check to prevent reintroduction.

### P1.3 Broad cleartext HTTP domain exemptions

**Current status:** CLOSED at the Android network-security configuration level. `android/app/src/main/res/xml/network_security_config.xml` sets `cleartextTrafficPermitted="false"` globally, and the network audit reported zero cleartext URLs in Dart code and JSON assets. Third-party provider behavior and remote server policies remain outside the app's control.

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

The automated device-readiness command cannot be treated as physical-device proof in the current audit because no active ADB device was available. The following remain unverified:

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

### P2.3 Documentation/version and release-history drift

The repository contains reports from different revisions. The release-task tag sequence has been reconciled: `release-task-2-done` was tagged at commit `e3daac1` (where Task 2 functional test expectations were committed) and pushed to origin, providing an unbroken sequence from task 0 through 11. The final release report also claims an exact-commit closure while the verified bundle command observed a dirty checkout.

Reconcile these items before calling the release gate closed:

- Create or document the missing task-2 tag only if task 2 actually completed and its evidence exists.
- Rerun the final gate from a clean checkout.
- Keep all final report claims tied to the exact commit, command output, and artifact path that proves them.
- Treat older reports as historical unless explicitly reconciled.

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
Full Flutter tests:   PASS — 794 passed, 0 failed (100% green)
Android signing:      PASS — fail-closed verification 5/5; owner upload key required for store
iOS signing:           PENDING OWNER — unsigned CI export active; signed export requires Apple certs
Privacy URL:           PASS — hosted at canonical public repository HTTPS URL
Device evidence:       INCOMPLETE
Store declarations:    INCOMPLETE

Publish now:           NO
Internal testing:      After test/release-integrity fixes
```

The app is a strong product foundation with extensive functionality and meaningful automated coverage. It should move toward release only after the failing tests, artifact signing, CI truthfulness, privacy URL, store declarations, and real-device checks are closed on one exact release commit.
