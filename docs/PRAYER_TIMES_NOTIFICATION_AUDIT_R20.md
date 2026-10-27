# Prayer Times and Notification Reliability — R20

**Date:** 2026-10-27  
**Stage:** R20 — User-configurable local Iqama intervals  
**Baseline:** R19 on `main` (`362e54a`)

## Implemented

- Added saved 0–180 minute intervals for Fajr, Dhuhr, Asr, Maghrib, Isha, and a separate Friday Jumua interval.
- One shared policy now resolves the configured interval or preserves the existing estimate when the user has not selected one.
- Scheduled Iqama reminders, foreground recovery, prayer-tab live state, home countdown, Flutter-rendered widgets, and Android native widget snapshots consume the same saved offsets.
- Iqama settings participate in the schedule fingerprint, so changing an interval rebuilds the rolling notification schedule.
- Existing app values remain defaults. User-entered intervals are described in Arabic as personal local-mosque settings, not official data.

## Official Prayer-Time API Finding

There is no single API key that makes prayer times authoritative for every country's government and local mosque.

- AlAdhan documents a worldwide calculation API and explicitly says its returned timings may not match a local mosque or government authority. Coordinate requests use latitude, longitude, and a selected calculation method; an external geocoding key is only relevant when a caller chooses a geocoding provider. Source: [AlAdhan Prayer Times API](https://aladhan.com/prayer-times-api).
- Türkiye's Directorate of Religious Affairs (Diyanet) describes its official service as publishing calculated schedules for 18,642 worldwide coordinate points, using an algorithm and database maintained by Diyanet astronomers. This is a Diyanet calculation service, not a claim that each listed country's government publishes or endorses those times. Source: [Diyanet prayer-times methodology and API](https://kurul.diyanet.gov.tr/tr/faaliyetler/2020-2025/ibadet-vakitleri-dini-gun-ve-gecelerin-tespiti/ileri-enlemlerde-namaz-vakitleri).
- Exact official schedules for all supported countries still require identifying each jurisdiction's publishing authority, its supported cities/dates, and its permitted API or data-reuse terms. Do not present a generic calculation endpoint as government-exact.

## Verification

- `flutter analyze --no-pub`: passed on the final merged tree, 0 issues (9.2s).
- `python tool/ui_lint_v2.py`: passed, 0 FAILs (8/10 allow markers).
- Focused settings persistence, invalid-value fallback, countdown, widget snapshot, settings interaction, and text-scale tests: passed.
- `flutter test --concurrency=1 --no-pub`: 711 tests passed; the existing `test/golden/shamela_reader_golden_test.dart` case failed on four Amiri text golden pixel comparisons (1.20% and 2.12%). Re-running that test alone reproduced the same diff; the actual and expected screenshots are visually equivalent, and no golden was updated.
- `flutter build apk --debug --no-pub`: passed on the final merged tree (45.7s). APK SHA-256: `A06A3D1D12DAC02457E57B2FD7ECC76DBCCD539D53029A81D9B4B9DF2BAA314A` (330,664,011 bytes).

## Remaining External Validation

- No all-country official timetable feeds or reuse approvals have been supplied or integrated.
- Real-device alarm/audio acceptance still requires Android 12–15 and iOS device testing across permission, Doze, reboot, timezone/DST, foreground/background, and terminated-app conditions. A successful scheduler API call does not prove OS delivery.
- iOS cannot be built or device-tested on this Windows host; the current changes also have not been exercised on a physical Android device.
- The Amiri rendering pixel diff in the unrelated Shamela golden is an outstanding full-suite failure on this host; investigate font/rasterizer determinism separately rather than masking it with a golden refresh in this Iqama change.
