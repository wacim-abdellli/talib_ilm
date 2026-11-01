# iOS App Store & TestFlight Release Readiness — طالب العلم

## 1. Bundle Identifiers & Entitlements Hierarchy

| Component | Bundle Identifier | Entitlements | Frameworks |
|---|---|---|---|
| **Host Application (Runner)** | `com.talibilm.app` | App Groups: `group.com.talibilm.app` | Flutter, UIKit, AVFoundation, AudioToolbox |
| **Native Extension (TalibIlmWidgets)** | `com.talibilm.app.widgets` | App Groups: `group.com.talibilm.app` | WidgetKit, SwiftUI |
| **Unit / UI Tests** | `com.talibilm.app.RunnerTests` | None | XCTest |

## 2. Dynamic Version & Build Propagation
- Host `ios/Runner/Info.plist`:
  - `CFBundleShortVersionString`: `$(FLUTTER_BUILD_NAME)` (1.0.0)
  - `CFBundleVersion`: `$(FLUTTER_BUILD_NUMBER)` (2002)
- Extension `ios/TalibIlmWidgets/Info.plist`:
  - `CFBundleShortVersionString`: `$(FLUTTER_BUILD_NAME)`
  - `CFBundleVersion`: `$(FLUTTER_BUILD_NUMBER)`
- Sourced automatically from `pubspec.yaml` (`1.0.0+2002`) during `flutter build`. Prevents App Store ITMS-90062 and ITMS-90473 version mismatch rejections.

## 3. Mandatory Privacy & System Capabilities
- **Location Usage Descriptions (`NSLocationWhenInUseUsageDescription`, `NSLocationAlwaysAndWhenInUseUsageDescription`):**
  - Text: «نستخدم موقعك لحساب مواقيت الصلاة واتجاه القبلة بدقة.»
- **Background Modes (`UIBackgroundModes`):**
  - `audio`: Background Quran recitations and Radio streaming via `just_audio_background` and `AVAudioSessionCategoryPlayback`.
  - `fetch`: Periodic widget and background sync.
- **High-Priority Notification Audio:**
  - Bundled `.caf` sound files in `Runner.app/Library/Sounds/` and app bundle root for Adhan audio alerts.

## 4. Owner Actions Required for App Store / TestFlight Signing

To generate an official App Store signed IPA for TestFlight, the owner must configure the Apple Developer Account:

1. **App Group Setup:**
   - In Apple Developer Portal → Identifiers → App Groups: ensure `group.com.talibilm.app` is registered.
   - Assign `group.com.talibilm.app` to both App IDs: `com.talibilm.app` and `com.talibilm.app.widgets`.

2. **Distribution Certificates & Profiles:**
   - Apple Distribution Certificate (`.p12` with password).
   - App Store Distribution Provisioning Profile for `com.talibilm.app`.
   - App Store Distribution Provisioning Profile for `com.talibilm.app.widgets`.

3. **CI / Local Export Command:**
   ```bash
   flutter build ipa --release --export-options-plist=ios/ExportOptions.plist
   ```
   *Note: In the current Linux/Windows development environment without Apple private signing keys, the workflow generates unsigned IPAs for Sideloadly / AltStore / testing and verifies the embedded WidgetKit extension structure.*
