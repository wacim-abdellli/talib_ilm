# Google Play Data Safety Preparation & Fact Sheet

**Document Version:** 1.0 (Task R65)  
**Target Release:** Google Play Store Production  
**App Name:** طالب العلم (talib_ilm)  
**Applicable Code Base:** Clean HEAD after Tasks R61–R64  

---

## 1. Purpose of this Document

Google Play requires all developers to complete a comprehensive **Data Safety Declaration** in the Google Play Console before submitting or updating an application. This declaration discloses to end users what data the app collects, why it collects it, whether it is shared with third parties, whether it is encrypted, and whether collection is optional.

This document provides the **authoritative, line-by-line guide and fact sheet** based directly on audited application code, network security configurations, and automated regression tests (specifically Tasks R56, R61, R62, and R64).

> **Owner Action Required:**  
> The app owner / publisher must log into the [Google Play Console](https://play.google.com/console), navigate to **Policy and programs → App content → Data safety**, and check the exact boxes specified below.

---

## 2. Global Data Safety Overview Questions

| Google Play Console Question | Required Answer | Justification & Technical Evidence |
| :--- | :--- | :--- |
| **Does your app collect or share any of the required user data types?** | **Yes** | The app accesses **Location** data to calculate prayer times and Qibla direction, and conditionally transmits coordinates to reverse-geocoding providers if user opts in. |
| **Is all of the user data collected by your app encrypted in transit?** | **Yes** | Android Network Security Configuration (`res/xml/network_security_config.xml`) strictly enforces TLS/HTTPS for all outgoing connections and API clients. |
| **Do you provide a way for users to request that their data be deleted?** | **Yes** | All user data (notes, bookmarks, settings, location cache) is stored strictly on the user's local device. Users can permanently delete all data at any time via Android System Settings (`Clear storage`) or by uninstalling the application. No remote account exists. |

---

## 3. Data Category by Category Breakdown

### Category 1: Location

| Sub-type | Collected? | Shared? | Processed Ephemerally? | Required or Optional? | Purposes |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Approximate location** (`ACCESS_COARSE_LOCATION`) | **Yes** | **Yes** *(Conditionally)* | **Yes** | **Optional** | **App functionality** |
| **Precise location** (`ACCESS_FINE_LOCATION`) | **Yes** | **Yes** *(Conditionally)* | **Yes** | **Optional** | **App functionality** |

#### Details for Location Form in Play Console:
1. **How is location used?**
   - **App functionality:** To calculate the accurate local Islamic prayer times (Fajr, Sunrise, Dhuhr, Asr, Maghrib, Isha) and compute the mathematical Qibla angle pointing toward Makkah using the on-device `adhan` calculation library.
2. **Is location data processed ephemerally?**
   - **Yes.** Coordinates are used directly in device memory to compute prayer timestamps. They are never transmitted to any database owned or operated by `talib_ilm`.
3. **Is location collection required or optional?**
   - **Optional.** Users can decline the Android location permission prompt and either:
     - Select their city manually from the built-in catalog of 950 verified cities, or
     - Enter custom prayer calculation parameters.
4. **Is location shared with third parties?**
   - **Yes, conditionally.**
   - *On Clean Install / Default:* Coordinates are **never shared** (0 external HTTP calls, 0 platform geocoder calls).
   - *Upon Explicit Opt-in:* If and only if the user explicitly turns on the **"جلب اسم المدينة عبر الإنترنت" (Fetch City Name Online)** switch in *Prayer Settings*, coordinates are transmitted to `BigDataCloud` (`api.bigdatacloud.net`) and the system OS geocoder to retrieve the Arabic name of the user's city/neighborhood.
   - Gated in code by `isRemoteGeocodingAllowed()`. Proven by 11/11 automated tests in `test/location_privacy_boundaries_test.dart`.

---

### Category 2: Personal Information (Name, Email, Phone, Address, IDs)
- **Collected:** **No**
- **Shared:** **No**
- *Explanation:* The application requires zero registration, no user account, no social login, and never requests or stores user identity details.

---

### Category 3: Financial Info (Credit Card, Bank Account, Payment History)
- **Collected:** **No**
- **Shared:** **No**
- *Explanation:* The application is 100% free and has zero in-app purchases, zero subscription billing, and zero payment processing.

---

### Category 4: Health and Fitness
- **Collected:** **No**
- **Shared:** **No**

---

### Category 5: Messages (Emails, SMS, In-app chat)
- **Collected:** **No**
- **Shared:** **No**

---

### Category 6: Photos and Videos
- **Collected:** **No**
- **Shared:** **No**
- *Explanation:* The app does not capture photos, access camera, or read gallery images.

---

### Category 7: Audio Files
- **Collected:** **No**
- **Shared:** **No**
- *Explanation:* The app plays and streams public Quran recitations and Islamic radio. It does not record or upload user audio or voice recordings.

---

### Category 8: Files and Documents
- **Collected:** **No**
- **Shared:** **No**
- *Explanation:* The app includes a backup export/import feature. File access is mediated entirely by the standard Android Document Picker (`file_picker`). Files selected by the user are read/written exclusively to local device storage. Zero file data is collected, transmitted, or shared with any external server.

---

### Category 9: Calendar
- **Collected:** **No**
- **Shared:** **No**

---

### Category 10: Contacts
- **Collected:** **No**
- **Shared:** **No**

---

### Category 11: App Activity (Page views, Clicks, In-app search)
- **Collected:** **No**
- **Shared:** **No**
- *Explanation:* All Quran reading progress, search queries, quiz histories, and Dhikr counts are recorded strictly within local SQLite tables (`sqflite`) and local `shared_preferences`. No user activity is transmitted to any analytics service.

---

### Category 12: Web Browsing History
- **Collected:** **No**
- **Shared:** **No**

---

### Category 13: App Info and Performance (Crash logs, Diagnostics)
- **Collected:** **No**
- **Shared:** **No**
- *Explanation:* The app bundles zero commercial crash reporting or telemetry SDKs (e.g., no Firebase Crashlytics, no Sentry, no Bugsnag). Standard operating system crash reports are handled at the platform level by Google Play Services if the user has enabled Android system diagnostics.

---

### Category 14: Device or Other Identifiers (IMEI, MAC Address, Advertising ID)
- **Collected:** **No**
- **Shared:** **No**
- *Explanation:* The app does not access device telephony IDs, MAC addresses, or Google Advertising ID (GAID).

---

## 4. Complete Third-Party Recipient & Network Host Inventory

For total transparency and Play Store compliance, here is every external network host contacted by the application:

| Host Domain | Protocol | Content / Functionality | Triggers & User Intent | Governed By |
| :--- | :--- | :--- | :--- | :--- |
| `everyayah.com` | HTTPS / HTTP (cleartext fallback) | Quran audio recitations (MP3) | User selects reciter and taps Play or Download. | EveryAyah Public Project |
| `cdn.islamic.network` | HTTPS | Secondary Quran audio stream | Fallback stream when selected by user. | Islamic Network CDN |
| `api.quran.com` | HTTPS | Quran Tafsir & Chapter metadata | User opens Tafsir tab or Ayah info. | Quran.com Foundation |
| `cdn.jsdelivr.net` | HTTPS | Static open-source Tafsir JSON (`spa5k/tafsir_api`) | User loads Tafsir explanations. | jsDelivr Open Source CDN |
| `mp3quran.net`<br>`qurango.net` | HTTPS / HTTP (cleartext fallback) | Quran Radio stations directory and live audio streams | User opens Radio tab and taps a station. | Mp3Quran Network |
| `shamela.ws` | HTTPS | Authentic Islamic book library pages | User browses online Shamela book. | Al-Maktaba Al-Shamela |
| `www.youtube.com`<br>`youtube-nocookie.com` | HTTPS | Video lectures for Mutun Talib Al-Ilm lessons | User taps a video lecture tile. | Google / YouTube Terms |
| `api.bigdatacloud.net` | HTTPS | Reverse geocoding (lat/long → Arabic city name) | **Strictly opt-in only:** user toggles "جلب اسم المدينة عبر الإنترنت". | BigDataCloud Privacy Policy |

---

## 5. Google Play Console Declarations Checklist for Owner

When preparing the store listing in Google Play Console, complete these specific declarations:

1. **Privacy Policy Link:**
   - In Console: **Policy and programs → App content → Privacy policy**.
   - Paste the public URL where `docs/PRIVACY_POLICY.md` is hosted (e.g., on GitHub Pages, official domain, or raw public repository file).

2. **Data Safety Form:**
   - Complete using Section 2 and Section 3 of this document.
   - Confirm Location data is:
     - Shared: Yes (conditional reverse geocoding).
     - Ephemeral: Yes.
     - Optional: Yes.
     - Purpose: App functionality.
   - Confirm all other 13 categories: **No data collected or shared**.

3. **Advertising ID Declaration:**
   - In Console: **App content → Advertising ID**.
   - Select: **No** (The app does not use the Advertising ID).

4. **Target Audience and Content:**
   - Select target age: **13 and above** (or include family/children if owner wishes, since app has 0 ads and 0 personal tracking).

5. **Special App Access:**
   - Select: **All functionality is available without special access** (no login credentials required).

6. **Permissions Declarations in Play Console:**
   - **`FOREGROUND_SERVICE_MEDIA_PLAYBACK`**:
     - *Justification:* Continuous background audio playback for Holy Quran recitations and Islamic Radio streams when user locks screen or uses other apps.
   - **`SCHEDULE_EXACT_ALARM` / `USE_EXACT_ALARM`**:
     - *Justification:* Timely notification of prayer times (Adhan) at exact calculated minutes, which is time-critical for Islamic worship obligations.
