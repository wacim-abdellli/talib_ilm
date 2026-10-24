# Privacy Policy — طالب العلم (talib_ilm)

**Last Updated / Effective Date:** 24 October 2026  
**Application Name:** طالب العلم (talib_ilm)  
**Package Identifier:** `com.example.talib_ilm` *(Note: to be updated to confirmed publisher domain prior to production Play Store release)*  
**Contact / Publisher:** Talib Ilm Development Team (Community Islamic Knowledge Project)  
**Public Policy URL:** *To be hosted at publisher website / repository URL by owner*

---

## 1. Executive Summary & Core Commitment

The **طالب العلم (talib_ilm)** application is a dedicated, ad-free Islamic knowledge and spiritual utility platform designed to assist Muslims with authentic Quran reading, memorization, prayer timing calculation, scholarly books (Shamela), Islamic sciences (Mutun Talib Al-Ilm), and radio streaming.

We operate under a **local-first, transparent privacy model**:
- **Zero user accounts:** You never need to sign up, log in, or provide your name, phone number, or email address.
- **Zero commercial ads:** The app is 100% free of advertising networks, sponsored trackers, and monetization SDKs.
- **Zero analytics tracking:** We do not embed analytics SDKs (no Google Firebase Analytics, no Facebook Pixel, no AppsFlyer, no Adjust).
- **Zero silent location telemetry:** Prayer times and Qibla direction are calculated **100% locally on your device**. GPS coordinates never leave your device by default.

---

## 2. Categories of Data & Exact Processing Seams

### A. Location Data (Approximate and Precise)
- **Android Permissions:** `android.permission.ACCESS_FINE_LOCATION`, `android.permission.ACCESS_COARSE_LOCATION`.
- **Purpose:** Accurately calculating daily Islamic prayer times (Fajr, Dhuhr, Asr, Maghrib, Isha) and the Qibla compass bearing to Makkah based on your physical location.
- **Local Calculation Boundary:**
  - Prayer calculation is executed entirely on-device using the open-source astronomical calculation library (`adhan`).
  - Coordinates obtained from the device GPS are held ephemerally in memory or cached in device private storage (`shared_preferences`) solely for computing prayer schedules.
- **Offline Fallback Catalog:**
  - If coordinates are within 45 km of known locations or if the device is offline, nearest city names are matched against a local, embedded database of **950 verified cities** (`VerifiedCitiesCatalog`) with **strictly zero network calls**.
- **Optional Remote Reverse-Geocoding (Opt-In Only):**
  - By default, remote reverse-geocoding is **strictly disabled** (`false`). On clean install or opt-out, **strictly 0 platform geocoder and 0 HTTP requests are dispatched**.
  - Only if the user explicitly navigates to *Prayer Settings* and enables the **"جلب اسم المدينة عبر الإنترنت" (Fetch City Name Online)** switch, the app transmits the latitude and longitude to:
    1. The Android Platform Geocoder (system service), and
    2. BigDataCloud API (`https://api.bigdatacloud.net/data/reverse-geocode-client`), requesting only the Arabic locality name.
  - No user identifiers, device IDs, or personal information are sent. The user can disable this toggle at any moment, immediately halting all external geocoding requests.

### B. User Content & Local Storage
- **Storage Technology:** Local SQLite databases (`sqflite`) and key-value preferences (`shared_preferences`) stored in app-private sandbox directories on device storage (`/data/data/com.example.talib_ilm/`).
- **Data Held:**
  - Quran reading progress, bookmarks, and last-read ayah.
  - Personal spiritual notes, reflection journals, and Khatma targets.
  - Daily Dhikr counters and goal completions.
  - Quiz scores, Manhaj progression level, and session resume checkpoints.
  - Prayer calculation preferences (calculation method, Madhab, manual minute offsets, notification sounds).
- **Cloud Sync:** **None.** All user data resides exclusively on your local device hardware.

### C. User-Selected Files & Backup/Restore
- **File Access:** Uses the system Document Picker via `file_picker`.
- **Scope:** Triggered strictly on-demand when the user manually initiates an *Export Backup* or *Import Backup* action.
- **Handling:** Backup JSON files are saved to or read from the user-selected filesystem path. No files or folder contents are ever transmitted to any external server.

### D. Streaming Media & External Islamic Content Recipients
To provide authentic Islamic multimedia resources without requiring massive bundled downloads, the app connects to established, public third-party Islamic content repositories upon user request:

| Content Type | External Provider / Host | Data Sent | Purpose & Trigger |
| :--- | :--- | :--- | :--- |
| **Quran Audio Recitations** | `everyayah.com`<br>`cdn.islamic.network` | HTTP GET request for Surah/Ayah audio file | User selects a reciter and plays or downloads an audio track. |
| **Quranic Tafsir & Word Meanings** | `api.quran.com`<br>`cdn.jsdelivr.net` | HTTP GET request for specific Surah/Ayah ID | User opens Tafsir tab or word-by-word view for an Ayah. |
| **Quran Radio Streams** | `mp3quran.net`<br>`qurango.net` | HTTP GET request for radio catalog & audio stream | User opens the Quran Radio feature and selects a station. |
| **Islamic Books Library** | `shamela.ws` | HTTP GET request for book page ID | User browses or reads an online book in the Shamela section. |
| **Mutun Scholarly Lessons** | `youtube.com`<br>`youtube-nocookie.com` | Embedded YouTube player request via standard webview | User taps to watch an authentic scholarly lecture video. |
| **City Name Lookup (Opt-in only)** | `api.bigdatacloud.net`<br>Android OS Geocoder | Lat/Long coordinates (no user identifier) | User explicitly opts in to remote city lookup in prayer settings. |

> **Radical Honesty Disclosure Regarding Third-Party Providers:**  
> When your device streams or downloads content from external servers (such as EveryAyah, Mp3Quran, Shamela, or YouTube), your device communicates directly with those third-party hosting infrastructures. As with any standard Internet connection, those external servers receive standard TCP/IP networking metadata (including your device's public IP address, date/time, and client user-agent headers).  
> The data processing, server logging, and retention policies of those independent providers are governed by their respective terms and privacy policies (e.g., [Google/YouTube Privacy Policy](https://policies.google.com/privacy)). `talib_ilm` does not control, store, or receive those server logs.

---

## 3. Operating System Permissions Rationale

Every permission declared in `AndroidManifest.xml` is strictly tied to a user-facing religious utility:

| Permission | Technical Purpose | User-Facing Benefit |
| :--- | :--- | :--- |
| `ACCESS_FINE_LOCATION`<br>`ACCESS_COARSE_LOCATION` | Accesses GPS/network location on device. | Calculates accurate prayer times and Qibla direction for user's actual location. |
| `POST_NOTIFICATIONS` | Displays Android system status bar alerts. | Delivers timely Adhan reminders at prayer times and daily remembrance reminders. |
| `SCHEDULE_EXACT_ALARM`<br>`USE_EXACT_ALARM` | Registers precise alarms with `AlarmManager`. | Guarantees Adhan audio triggers exactly at prayer time, even in Android Doze mode. |
| `RECEIVE_BOOT_COMPLETED` | Triggers a boot receiver upon device restart. | Re-schedules prayer time alarms automatically after phone reboot without opening app. |
| `FOREGROUND_SERVICE`<br>`FOREGROUND_SERVICE_MEDIA_PLAYBACK` | Runs a foreground audio playback service. | Keeps Quran recitations and Radio playing smoothly when screen is locked or app is in background. |
| `WAKE_LOCK` | Briefly prevents CPU from sleeping. | Allows Adhan sound playback to complete without being killed by Android power manager. |
| `INTERNET` | Establishes standard outgoing network connections. | Streams Quran audio, radio, online books, tafsir, and videos. |
| `VIBRATE` | Vibrates device haptic hardware. | Provides subtle tactile feedback on prayer reminders and digital tasbih counter taps. |

---

## 4. Children's Privacy (COPPA & Family Policy Compliance)

`talib_ilm` is an educational and religious application suitable for all ages, including children and families:
- The app does not collect personal data from any user, regardless of age.
- The app does not contain commercial advertising, in-app purchases, or behavioral tracking.
- The app does not contain user-to-user messaging, social media feeds, or unmoderated chat forums.

---

## 5. User Control, Data Retention & Deletion

Because all personal notes, bookmarks, quiz histories, and settings are stored locally on your device:
1. **Immediate Deletion:** You can delete all data stored by the app at any time by going to:  
   **Android Settings → Apps → طالب العلم (talib_ilm) → Storage & cache → Clear storage**.
2. **Uninstall:** Uninstalling the app completely and irreversibly removes all local SQLite databases, audio cache, preferences, and downloaded files from your device.
3. **No Remote Accounts:** Because we operate no remote user databases, there is no remote account to delete or request deletion for.

---

## 6. Security Practices

- **Encrypted in Transit:** All network requests to API endpoints, Tafsir servers, and reverse-geocoding clients are enforced over **Transport Layer Security (TLS/HTTPS)** via Android Network Security Configuration (`res/xml/network_security_config.xml`). Legacy cleartext HTTP is strictly blocked, except for verified cleartext-only radio/audio stream origins.
- **Sandboxed Storage:** All user notes, bookmarks, and preferences are saved within the private Android application sandbox, inaccessible to other installed applications without root permissions.

---

## 7. Policy Updates & Owner Review

This Privacy Policy may be updated periodically to reflect architectural enhancements or newly added features. Any modifications will be documented in the repository history, reflected within the application's *Credits and Licenses* section, and posted to the public repository.

**Questions or Inquiries:**  
For any inquiries regarding this policy or the application's data practices, please open an issue on the official project repository or contact the project maintainers.
