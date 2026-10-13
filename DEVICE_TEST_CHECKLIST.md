# Physical Device Verification Checklist — talib_ilm

This checklist outlines the manual and profiling test procedures that require a physical Android / iOS device or device lab hardware.

---

## 1. Setup & Profiling Command

Always run performance and memory validations in **Profile** mode (debug mode contains VM assertion overhead and does not reflect production frame rates):

```bash
# Connect physical device via ADB (ensure USB debugging is active)
adb devices

# Launch app in profile mode with DevTools Observatory URL
flutter run --profile

# Open DevTools Performance and Memory tabs via the generated DevTools URL
```

---

## 2. Test Procedures & Pass/Fail Criteria

### 2.1. 50-Page Rapid Swipe (Memory Leaks & 60fps Frame Times)
* **Goal**: Validate that continuous, rapid Mushaf page flipping doesn't leak memory or cause frame drops (jank).
* **Procedure**:
  1. Open the Mushaf reader on Page 1.
  2. In DevTools, open the **Performance** tab and click **Record**.
  3. Rapidly swipe through 50 consecutive pages (e.g. from Page 1 to Page 50) within 30 seconds.
  4. In the **Memory** tab, trigger a manual garbage collection (`GC`) and inspect the heap snapshot.
* **Pass Criteria**:
  - Zero out-of-memory (`OOM`) crashes.
  - Heap memory stabilizes under 150MB after GC.
  - Less than 5% dropped frames; UI thread frame render time stays below 16.6ms.

---

### 2.2. Audio Interruptions & Audio Focus Management
* **Goal**: Ensure Quran recitation handles system interruptions gracefully without crashes or orphaned playback.
* **Procedures**:
  1. **Incoming Phone Call**:
     - Start audio playback of Surah Al-Fatihah.
     - Place an incoming phone call to the device.
     - *Pass*: Playback immediately pauses upon ringing and resumes cleanly (or remains paused) when call ends without audio glitching.
  2. **Headset Disconnect (Noisy Intent)**:
     - Connect 3.5mm or USB-C wired headphones while audio is playing.
     - Unplug the headphones abruptly.
     - *Pass*: Playback pauses immediately. Audio does NOT blast out of the device's loudspeakers.
  3. **Bluetooth Connection & Disconnect**:
     - Connect Bluetooth earbuds; play recitation.
     - Turn off Bluetooth on device.
     - *Pass*: Player enters paused state smoothly.
  4. **Audio Focus Loss (Duck vs Pause)**:
     - Play audio in talib_ilm, then start media in another app (e.g. YouTube or voice recorder).
     - *Pass*: `just_audio` pauses or yields focus gracefully; no simultaneous audio clash.

---

### 2.3. TalkBack (Android) & VoiceOver (iOS) Accessibility
* **Goal**: Guarantee blind and visually impaired users can navigate the Mushaf and prayer features.
* **Procedure**:
  1. Enable Android TalkBack (`Settings > Accessibility > TalkBack`) or iOS VoiceOver.
  2. Navigate through the bottom navigation tabs: Home, Quran, Ilm, Adhkar, Prayer, More.
  3. Open the Mushaf screen and interact with:
     - Surah header card.
     - Ayah long-press bottom sheet actions (Tafsir, Share, Audio recitation).
     - Audio player controller (Play/Pause, Reciter, Repeat, Speed).
* **Pass Criteria**:
  - All interactive buttons have descriptive Arabic labels (`aria-label`/`Semantics`/`tooltip`).
  - No "Unlabelled button" announcements.
  - Minimum touch target is 48x48dp across all interactable elements.

---

### 2.4. Tajweed Rules Contrast on Physical OLED & LCD Screens
* **Goal**: Confirm Medina Mushaf Tajweed color rules remain readable under direct sunlight and in dark environments.
* **Procedure**:
  1. Open Mushaf page with rich tajweed markings (e.g. Page 1, Page 2, Page 50).
  2. Switch between **Light**, **Dark**, and **Sepia** color modes.
  3. Test under:
     - Direct sunlight at 100% device screen brightness.
     - Low ambient light at 15% device screen brightness.
* **Benchmark Colors**:
  - Ghunnah (Amber Gold `#B45309`) ≥ 4.5:1 on background.
  - Qalqalah (Ocean Blue `#0284C7`) ≥ 4.5:1 on background.
  - Ikhfaa (Emerald `#059669`) ≥ 4.5:1 on background.
  - Idgham (Regal Purple `#7C3AED`) ≥ 4.5:1 on background.
  - Madd (Crimson `#DC2626`) ≥ 4.5:1 on background.
* **Pass Criteria**:
  - Text glyphs are sharp with zero clipping on curved/folded screen edges.
  - Verified no illegible color bleeding on OLED true black (`#000000`).

---

### 2.5. Screen Responsiveness: Compact Phone vs Large Tablet
* **Goal**: Ensure layout survives different form factors without overflow warnings (`RenderFlex overflowed`).
* **Procedure**:
  1. **Compact phone (<360dp width)**:
     - Test on 320dp width simulator or small phone (e.g. iPhone SE, small Android).
     - Verify Home hero card, Hizb cards, and prayer times grid.
  2. **Tablet / Foldable (>600dp width)**:
     - Test on tablet or foldable device unfolded.
     - Verify Mushaf two-page mode or centered page constraint (`AppSpace.maxContentWidth`).
* **Pass Criteria**:
  - Zero yellow/black striped overflow errors.
  - Text scales smoothly with system font size at 1.0x, 1.5x, and 2.0x.

---

### 2.6. Cold Start Time & APK Binary Footprint
* **Goal**: Maintain fast cold start and light binary distribution.
* **Commands**:
  ```bash
  # Measure cold start time via ADB
  adb shell am start-activity -W -n com.talibilm.app/com.talibilm.app.MainActivity

  # Build optimized release APK
  flutter build apk --release

  # Inspect APK size
  ls -lh build/app/outputs/flutter-apk/app-release.apk
  ```
* **Pass Criteria**:
  - Cold start `TotalTime` < 1500ms on mid-range hardware (Snapdragon 680 or equivalent).
  - Release APK size < 35MB (with vendored Uthmani fonts and KFGQPC assets bundled).

---

### 2.7. Airplane Mode Offline Reading & Downloaded Audio Playback
* **Goal**: Verify 100% offline autonomy.
* **Procedure**:
  1. While connected to Wi-Fi, download Surah Al-Fatihah and Surah Al-Ikhlas via the Audio Downloader (`المزيد > تحميل التلاوات الصوتية`).
  2. Put the device into **Airplane Mode** (disable Wi-Fi, Cellular, and Bluetooth).
  3. Close the app completely (`kill` process) and re-open.
  4. Read Mushaf pages 1 to 604.
  5. Play recitation for Surah Al-Fatihah.
  6. Attempt to play a non-downloaded Surah (e.g. Surah Al-Baqarah).
* **Pass Criteria**:
  - All 604 Mushaf pages render offline from local bundled assets/database with zero network requests.
  - Surah Al-Fatihah plays instantly from local storage with full playback controls.
  - Non-downloaded Surah shows an informative Arabic offline error message (`تعذر الاتصال بالشبكة`) and resets the player cleanly to idle without crashing.
