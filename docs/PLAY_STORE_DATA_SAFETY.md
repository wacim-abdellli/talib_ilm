# Google Play Data Safety & Store Declarations — طالب العلم

## 1. Application Identification
- **Application ID:** `com.talibilm.app`
- **Version Name:** `1.0.0`
- **Version Code:** `2002`
- **Minimum SDK:** 21 (Android 5.0)
- **Target SDK:** 35 (Android 15)
- **Compile SDK:** 35

## 2. Declared Android Permissions & Justifications

| Permission | Purpose | Play Console Justification Category |
|---|---|---|
| `ACCESS_FINE_LOCATION` & `ACCESS_COARSE_LOCATION` | Calculate precise astronomical prayer times and accurate Qibla compass angle | App functionality / Navigation |
| `SCHEDULE_EXACT_ALARM` & `USE_EXACT_ALARM` | Trigger punctual Adhan and prayer reminder alarms at the exact minute of prayer | App functionality / Alarms & Reminders |
| `POST_NOTIFICATIONS` | Deliver Adhan, Iqama, and daily Adhkar reminder banners | App functionality / Notifications |
| `RECEIVE_BOOT_COMPLETED` | Automatically reschedule prayer alarm times after device reboot | App functionality / System |
| `FOREGROUND_SERVICE` & `FOREGROUND_SERVICE_MEDIA_PLAYBACK` | Uninterrupted Quran audio recitation playback with system lock-screen notification controls | Audio playback / Media |
| `WAKE_LOCK` | Prevent CPU sleep during long Quran surah audio playback | Audio playback / Media |
| `INTERNET` | Stream and download authentic Quran audio recitations | App functionality |
| `VIBRATE` | Haptic feedback for Tasbeeh counter and prayer alarms | User interaction |

## 3. Data Safety Declaration Matrix

### Data Collected:
1. **Location (Approximate & Precise):**
   - **Collected:** Yes (Ephemeral)
   - **Shared:** No (Never shared with third parties)
   - **Processed Ephemerally:** Yes, strictly used by the offline astronomical Adhan calculation engine on-device.
   - **Required / Optional:** Optional. The user can select their city manually from the catalog of 58 Algerian wilayas and international capitals without granting location permissions.

2. **Personal Info (Name, Email, Phone, Address, User IDs):**
   - **Collected:** None
   - **Shared:** None

3. **Financial Info / Purchases:**
   - **Collected:** None (App is 100% free, no ads, no in-app purchases).

4. **Health & Fitness:**
   - **Collected:** None

5. **Messages / Photos / Videos / Audio Files:**
   - **Collected:** None. Quran audio downloads are cached strictly on local private storage for offline listening.

6. **App Activity / Analytics:**
   - **Collected:** None. No third-party analytics trackers (no Firebase Analytics, no Facebook SDK, no AppsFlyer).

7. **Crash Logs / Diagnostics:**
   - **Collected:** None transmitted to remote servers.

## 4. Security Practices
- **Data Encrypted in Transit:** All network requests (Quran audio streams, Tafsir downloads) use TLS/HTTPS.
- **Data Deletion Mechanism:** The user can clear all saved favorites, reading progress, and downloaded audio at any time in Settings.
- **Children's Privacy:** App complies with Family Policy; contains no inappropriate content and collects no personal data.

