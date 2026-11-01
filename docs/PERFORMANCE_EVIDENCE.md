# Runtime Performance & Bundle Size Evidence — طالب العلم (talib_ilm)

**Date:** 1 November 2026  
**Stage:** Release Task 10 — Performance & Bundle Evidence  
**Environment:** Flutter 3.38.7 • Dart 3.10.7 • Windows-10 x64 / Android 11 (Infinix X689)  

---

## 1. APK Per-ABI Breakdown & Google Play App Bundle (AAB)

All binaries compiled in clean release mode with R8/ProGuard code shrinking and resource optimization:

| Artifact Name | Target Architecture | Decimal Size (MB) | Binary Size (MiB) | Exact Bytes | SHA-256 Checksum |
|---|---|---|---|---|---|
| **`app-release.aab`** | Google Play Store Upload | **183.87 MB** | 175.35 MiB | 183,867,767 | `bebc660891303d17e57c6b54a7c06eb6f505374eec74b4fc927161bcf7ba677c` |
| **`app-arm64-v8a-release.apk`** | Modern 64-bit Android (85%+ devices) | **144.02 MB** | 137.35 MiB | 144,019,917 | `fb4843fb41e18552199b44ddba084803b8793b8e4bc0bcaae7c33190e5fc502d` |
| **`app-armeabi-v7a-release.apk`** | Legacy 32-bit ARM | **144.38 MB** | 137.69 MiB | 144,383,490 | `013f1e469aa7579a32c256054e58b19a16f2ddfe4459f2e7f4c5409d84950ce4` |
| **`app-x86_64-release.apk`** | Emulators / ChromeOS | **145.72 MB** | 138.96 MiB | 145,715,206 | `548d0e62f91aee56ba5921867cbbd8417f7300c1df1542f7c006509f6358c232` |
| **`app-release.apk`** | Universal Fat APK (Sideloading) | **144.04 MB** | 137.37 MiB | 144,043,332 | `98d1932265baf4f128be482e994e43b17721759bbfa9cf6c2fb764dca6717540` |

### Google Play Dynamic Delivery (Bundletool Measurement)
- **Delivered Device Download Size**: **109.34 MB decimal (104.27 MiB)** (`109,336,577 bytes`).
- **Device Spec Tested**: `arm64-v8a`, SDK 35, Screen Density 480dpi, Arabic locale.
- **Dynamic Optimization**: Google Play strips unused 32-bit native libraries (-26.28 MB), x86_64 libraries (-25.48 MB), and debug symbols (-21.37 MB) before delivering to target 64-bit user devices.

---

## 2. AAB Internal Composition Breakdown

Total Compressed Bytes: **183,867,767 bytes** (100.0%)

| Category | Compressed (MB) | Compressed (MiB) | % of AAB | Functional Role |
|---|---|---|---|---|
| **Quran Mushaf Fonts (`qcf_quran_plus`)** | 69.98 MB | 66.74 MiB | 38.1% | 604 authentic King Fahd Complex Madinah Mushaf page fonts for 100% offline Quran reading |
| **Native Libs (`arm64-v8a`)** | 25.28 MB | 24.11 MiB | 13.75% | Compiled Dart AOT (`libapp.so`) + Flutter engine (`libflutter.so`) |
| **Native Libs (`armeabi-v7a`)** | 26.28 MB | 25.06 MiB | 14.29% | Legacy 32-bit native libraries (stripped by Play for 64-bit devices) |
| **Native Libs (`x86_64`)** | 25.48 MB | 24.30 MiB | 13.86% | Emulator libraries (stripped by Play for ARM devices) |
| **Play Symbols & Mappings** | 21.37 MB | 20.38 MiB | 11.62% | ProGuard mapping + native symbol tables (never downloaded by users) |
| **App Assets (`assets/`)** | 7.32 MB | 6.98 MiB | 4.00% | Adhan audio, typography, Hadith & Mutun datasets |
| **Android Resources (`res/`)** | 4.88 MB | 4.65 MiB | 2.65% | Drawables, layouts, and notification raw audio |
| **DEX Bytecode (`classes.dex`)** | 1.98 MB | 1.89 MiB | 1.08% | Compiled Java/Kotlin Android plugin bytecode |

---

## 3. Tracked Assets Inventory & Storage Footprint

Source: `tool/generate_code_and_asset_inventory.py` across 1,747 tracked files (Total asset footprint: **110.25 MB**):

| Asset Category | Tracked Files | Total Size (MB) | Details |
|---|---|---|---|
| **Madinah Mushaf Page Fonts** | 601 | 66.81 MB | 604 King Fahd Complex vector fonts (`.ttf.gz`) bundled locally |
| **Classical Islamic Mutun** | 16 | 14.95 MB | Curriculum texts in `assets/pdfs/mutun/` |
| **Authentic JSON Datasets** | 13 | 12.25 MB | Sunnah Adhkar, 1,000+ quiz questions, Minhaj Al Muslim, authentic Hadiths |
| **Branding & UI Vectors** | 210 | 4.40 MB | App icons, adaptive icons, splash screens, lockups |
| **Arabic Typography** | 12 | 4.15 MB | Cairo (5 weights), Scheherazade New (2 weights), Amiri (2 weights) |
| **Flutter Audio Assets** | 13 | 3.84 MB | In-app audio files for foreground prayer listener and test preview |
| **Android Native Raw Audio** | 14 | 3.84 MB | Bundled in `res/raw/` for background Doze-mode notification alarms |

---

## 4. Runtime Latency & Algorithmic Benchmarks

Measured via Flutter Host Engine Benchmark Test Runner (`test/runtime_performance_benchmarks_test.dart` & `docs/runtime_performance_baseline.json`):

| Operational Benchmark | Measured Performance | Production Threshold | Evaluation |
|---|---|---|:---:|
| **Startup Service Initialization** | **mean: 1.85 ms** (p95: 2.73 ms, min: 0.69 ms) | < 100 ms | **EXCELLENT** |
| **Quran 604 Pages Indexing** | **5 ms total** (9 µs / page) | < 50 ms | **EXCELLENT** |
| **Full-text Quran Ayah Search** | «الله»: 137 ms, «الرحمن»: 91 ms, «الصلاة»: 43 ms | < 300 ms | **EXCELLENT** |
| **Mutun Syllabus Catalog Load** | **6.03 ms** (7 curriculum sections) | < 50 ms | **EXCELLENT** |
| **Classical Text Tokenization** | **19 µs** per passage | < 1 ms | **EXCELLENT** |
| **Audio Focus Switching** | **31 µs** per switch (200 consecutive switches) | < 5 ms | **EXCELLENT** |
| **Algerian Wilayas Prayer Timetable** | **29 ms** for 15 wilayas (1.95 ms / city) | < 100 ms | **EXCELLENT** |
| **State Re-evaluation on Resume** | **1.49 ms** | < 16 ms (1 frame) | **EXCELLENT** |

---

## 5. Memory Footprint & Prolonged Use Stability

- **Initial Heap / RSS Footprint**: 334.8 MB (Host Dart VM harness under full test suite load).
- **Prolonged Use Delta**: **+1.77 MB** over 150 simulated reading sessions and screen transitions executed in 91 ms.
- **Physical Device Stability (Infinix X689)**: 0 Out-Of-Memory (OOM) exceptions observed; garbage collection stabilizes quickly after rapid page swiping.

---

## 6. Startup Time & Frame Jank Analysis

- **Release Cold Start (Android 11 / MediaTek Helio G70)**: `TotalTime` < 950 ms via `am start-activity -W`.
- **Frame Render Times**: 60 fps target maintained; UI thread frame render time stays below 16.6 ms for standard list and reading views.
- **Rapid 50-Page Swipe Jank Rate**: < 3.2% dropped frames during continuous Madinah Mushaf page flipping.

