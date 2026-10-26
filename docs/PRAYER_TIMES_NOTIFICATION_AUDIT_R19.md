# Prayer Times and Notification Reliability Audit — R19

**Audit date:** 2026-10-27
**Scope:** calculated prayer times, Friday/Jumua handling, Adhan audio and alerts, Iqama reminders, daily Adhkar reminders, schedule refresh and permission behavior.
**Baseline:** R18 (`19855fa`) on `main`; R19 implementation is complete on `ui/r19-official-times-notification-closure`.

## Decision and ratings

| Area | Rating | What the rating means |
|---|---:|---|
| Calculation pipeline / internal consistency | 8/10 | Offline astronomical calculation and settings are used consistently; one official-date comparison was close, but broad government-table parity has not been demonstrated. |
| Government-exact prayer-time claim | 3/10 | The app currently computes estimates. There is no authorized, versioned official city-by-date data feed in the repository. Do not advertise times as official or exact. |
| Scheduled notification implementation | 8/10 | Scheduling is serialized, fingerprinted, retried on failure, and now records per-occurrence ownership for Adhan, pre-prayer, Iqama and Adhkar. This confirms a scheduling API result, not actual OS delivery. |
| Foreground recovery and duplicate control | 8/10 | Startup/resume ordering is fixed and foreground fallback runs only when no successful platform schedule is recorded. It cannot execute while the app is suspended or force-stopped. |
| Iqama schedule correctness | 6/10 | The widget and reminders now share the same app-default offsets. Those offsets are estimates; actual mosque congregation times are not available. |
| Audio behavior | 7/10 | The foreground fallback uses the app audio player for full Adhan and a silent banner to prevent a second sound; scheduled alerts use platform notification sound. Device/OEM playback behavior is not yet verified. |
| Real-device evidence | 2/10 | Automated tests and Android debug build cover code paths. No Android/iOS hardware matrix or iOS build was run for this stage. |

**Slice status:** the engineering defects below are remediated and automated verification is being completed. This prayer feature is **not yet proven store-ready** because official timetable parity and physical-device notification behavior remain unverified.

## What was inspected

- `PrayerTimeService`, calculation-method and location settings, the seven-day `PrayerScheduleService`, and the official-calendar comparison test.
- `NotificationService`, prayer and Adhkar schedulers, schedule outcomes, notification permissions, channels, and the R18 CAF notification resources.
- `ForegroundPrayerService` and `AppShell` startup/resume/background lifecycle.
- Adhan mode/audio selection, Iqama offsets used by the home countdown and scheduler, Friday Dhuhr/Jumua substitution, and the separate Friday Al-Kahf reminder.
- Existing prayer schedule, notification resilience, audio, official-calendar, and acceptance tests; R19 adds per-occurrence schedule-state and Iqama consistency coverage.

## Findings and remedies

### P0 — Prayer calculations are not government timetables

The app calculates prayer times astronomically from coordinates, date, calculation method, madhab and minute adjustments. R18 removed the unsupported blanket 18° Fajr/Isha override for Algeria, Morocco and Tunisia and labels the Algeria setting as an estimate. The code does not contain an authorized official timetable for each supported city and date.

One comparison against the Algerian Ministry's Algiers calendar for 2022-08-12 was within three minutes for all five prayers, with Isha within one minute. That is a single-date spot check; it does not establish accuracy across other cities, seasons, timezones, or official calculation revisions.

Sources inspected:

- [Algerian Ministry of Religious Affairs — official prayer schedules](https://marw.gov.dz/%D8%A3%D8%AE%D8%A8%D8%A7%D8%B1/%D8%A7%D9%84%D9%8A%D9%88%D9%85%D9%8A%D8%A9-%D8%A7%D9%84%D8%B1%D8%B3%D9%85%D9%8A%D8%A9-%D9%84%D9%85%D9%88%D8%A7%D9%82%D9%8A%D8%AA-%D8%A7%D9%84%D8%B5%D9%84%D8%A7%D8%A9)
- [Algiers Ministry calendar PDF used for the spot check](https://marw.gov.dz/media/calendrier/1444/alger.pdf)
- [Morocco Ministry city prayer schedule service](https://habous.gov.ma/prieres/horaires-par-mois.html)
- [Tunisia Ministry prayer-time service](https://affaires-religieuses.tn/public/ar/pages/829394034)

**Required path to exactness:** obtain a documented, authorized official data source for each target jurisdiction; confirm reuse/licensing terms; record each city's timezone, source/version and effective date; then build multi-city, multi-season differential tests. The inspected Algerian PDF includes a restriction against unapproved reproduction, so do not bundle government tables without written permission. Until a permitted official source is selected, retain the estimate label and allow users to choose the calculation method and adjustments.

### P1 — OS scheduling and foreground polling could both deliver the same prayer alert

The previous foreground path posted a notification and started audio at prayer time even when the OS already had a scheduled alert. This could create duplicate alerts/audio while the app was open. It also had no reliable per-occurrence evidence to decide whether a failed OS schedule needed recovery.

**R19 remedy:** `PrayerScheduleService` records exact, inexact, failed, denied, or unknown schedule ownership per local date and prayer for Adhan, pre-prayer, and Iqama. `ForegroundPrayerService` suppresses its duplicate when a successful OS schedule owns that occurrence; otherwise, while foregrounded, it attempts a one-time local recovery. For media Adhan playback, the recovery notification is silent so the OS notification does not start a second sound. Tone mode leaves the notification tone enabled.

### P1 — App startup/resume could poll before refreshing schedules

Starting foreground prayer polling before a schedule refresh completed exposed a race: the foreground service could make a decision using stale/missing schedule state.

**R19 remedy:** `AppShell` now waits for schedule refresh before starting foreground polling on cold startup and resume. Polling stays paused in background/inactive states.

### P1 — Iqama widget and notification used different offsets

The home countdown used 25/20/20/10/15 minute defaults for Fajr/Dhuhr/Asr/Maghrib/Isha, while scheduled Iqama reminders used 20 minutes for Fajr and 15 for most other prayers. Users could see one countdown and receive a notification at another time.

**R19 remedy:** `IqamaTimingPolicy` is now the shared source for the widget, scheduled reminders, and foreground recovery, including the Friday Jumua interval. These are explicitly app-default estimates—not local mosque data. A mosque-specific schedule is not currently modeled.

### P1 — Iqama had no foreground fallback when scheduling failed

Iqama was OS-scheduled but did not have the occurrence-level state or recovery path used for Adhan/pre-prayer.

**R19 remedy:** record per-occurrence Iqama scheduling status; recover with the same Iqama channel and notification ID during its one-minute foreground window when no platform alarm was confirmed; preserve the active scheduled ID during a schedule refresh.

### P1 — Adhkar had retries but no per-day foreground recovery state

R18 made failed daily Adhkar schedules retry independently, but a failed or not-yet-known occurrence could not be distinguished from one owned by the platform. A daily alarm scheduled after today's configured time rolls to tomorrow; treating today's occurrence as scheduled would suppress a needed foreground recovery.

**R19 remedy:** persist each morning/evening/sleep occurrence's schedule ownership for today and the next seven days. If the configured time has already passed when the repeating alarm is set, today's state stays eligible for foreground recovery while future occurrences remain OS-owned. Recovery uses the same reminder ID/content and is idempotent for that local date.

### P1 — Master prayer-alert switch did not fully own active alarm cleanup

Disabling the master prayer-alert setting could leave active prayer IDs preserved during a schedule refresh.

**R19 remedy:** no Adhan, pre-prayer, or Iqama alarm is retained/scheduled while the master switch is off; the separate Friday Al-Kahf reminder remains independent.

### P2 — iOS/macOS permission detection could report success without checking alert permission

The old permission check treated Apple platforms as granted, so a denied/revoked alert permission could be mistaken for successful notification capability.

**R19 remedy:** iOS/macOS now query the plugin's actual enabled and alert permission state. Android continues to check application notification permission; exact-alarm access is separately included in schedule freshness.

## What “scheduled” does and does not guarantee

An `exact` or `inexactFallback` result means the platform scheduling call accepted the request. It is **not a delivery receipt**. Android notification permission, exact-alarm access, user-muted notification channels, Doze/OEM battery policy, reboot/force-stop behavior and Android-version policy can affect actual delivery. iOS Focus/notification settings, permission state and sound limits can affect presentation. App code cannot override user or OS controls.

Foreground recovery only runs when the Dart app is active and its timer is running. It does not wake a terminated/suspended app, repair an alarm that the OS accepted and later dropped, or make a denied notification visible. The app's full-length Adhan player is an in-app foreground capability; OS notification sounds remain platform-managed and may be duration-limited (iOS CAF files are capped below 30 seconds).

## Required real-device acceptance before calling this reliable

Run on every supported Android API level (including at least one non-Pixel/OEM device) and a real iPhone on the supported iOS deployment range. Use short scheduled test events and record device, OS, app build, permissions, channel state, scheduled-vs-observed time and audio result.

1. Allow notifications and exact alarms; verify Adhan, pre-prayer, Iqama, Friday Dhuhr/Jumua and all three Adhkar reminders in foreground, background, locked screen and after process recreation.
2. Deny notifications, revoke them in system settings, deny exact alarms, then grant each permission; verify the in-app permission state and schedule rebuild after resume.
3. Mute/disable each Android notification channel, enable Do Not Disturb/Focus, and test battery optimization/Doze. Confirm UI diagnostics explain that the OS is suppressing alerts instead of claiming delivery.
4. Reboot, force-stop, change timezone, cross DST boundaries, and travel between locations. Verify rolling schedules rebuild and each occurrence is delivered at most once.
5. Exercise Adhan, Takbeer, tone and silent modes with media volume at zero, notification volume at zero, Bluetooth/headphones connected, audio focus held by Quran/radio, and notification sound resource missing/unavailable. Confirm full audio stop controls and no overlapping Adhan copies.
6. On iOS, build and test CAF resource registration and system presentation in foreground/background/terminated states. Confirm the platform-limited notification sound and foreground full-length audio behavior separately.
7. Confirm the alert payload opens the intended prayer/Adhkar destination on warm launch and cold launch.

## R19 implementation and verification record

Changed implementation areas: prayer schedule state/fingerprint, foreground delivery ownership/recovery, Iqama policy, Adhkar occurrence state/recovery, notification permission detection, AppShell initialization ordering, and focused test coverage. The R18 golden-test font loader repair is retained because it made the required full suite deterministic in this Windows test environment; no golden image content is intentionally changed.

**Final R19 verification:** `flutter analyze --no-pub` reported no issues (91.8s); `python tool/ui_lint_v2.py` passed with 0 FAILs and 8/10 allow markers; `flutter test --concurrency=1 --no-pub` passed 705/705 (12m39s); `flutter build apk --debug --no-pub` succeeded (70.1s). APK SHA-256: `A1BB83E11A050800A4DC78DBBC8528AD53BC99282F92B868F35CB9B9311F11E1` (330,520,102 bytes). The suite emitted one existing non-fatal hit-test warning in `mushaf_page_viewer_test.dart`; no test failed. No physical-device or native iOS build test was run.

## Remaining blockers

- Select and authorize an official per-city/date source before claiming government-exact prayer times.
- Obtain real-device Android/iOS results from the acceptance matrix above; this host is Windows and cannot produce a native iOS device/build verification.
- Decide whether the product should let users select a mosque or configure local Iqama times. Current Iqama times are app estimates.
