# Android Exported Components Security Audit — طالب العلم (talib_ilm)

**Date:** 1 November 2026  
**Stage:** Remediation Task R3 (P1.4)  
**Target SDK:** 35 (Android 15) | Min SDK: 21 (Android 5.0)  

---

## 1. Inventory & Export Security Matrix

Every `<activity>`, `<service>`, and `<receiver>` in `android/app/src/main/AndroidManifest.xml` has been audited against Android 12+ explicit export requirements and intent spoofing risks:

| Component Name | Type | `android:exported` | Permission Guard | Registered Intent Filters | Security Justification |
|---|---|:---:|---|---|---|
| `.MainActivity` | Activity | `true` | None (Public) | `android.intent.action.MAIN`<br>`android.intent.category.LAUNCHER` | Primary user entry point launched by the Android launcher. |
| `com.ryanheise.audioservice.AudioService` | Service | `true` | System Media Session | `android.media.browse.MediaBrowserService` | Required for system lock-screen media controls, Bluetooth AVRCP metadata, and Android Auto. Bound with `foregroundServiceType="mediaPlayback"`. |
| `com.ryanheise.audioservice.MediaButtonReceiver` | Receiver | `true` | System Key Events | `android.intent.action.MEDIA_BUTTON` | Required to receive hardware play/pause/skip key events from wired/Bluetooth headphones. |
| `.RibbonWidgetProvider` | Receiver | `true` | AppWidget Subsystem | `android.appwidget.action.APPWIDGET_UPDATE` | Bound to launcher desktop for 4x1 ribbon prayer/tracker widget. |
| `.CompactWidgetProvider` | Receiver | `true` | AppWidget Subsystem | `android.appwidget.action.APPWIDGET_UPDATE` | Bound to launcher desktop for 2x2 compact prayer widget. |
| `.LargeWidgetProvider` | Receiver | `true` | AppWidget Subsystem | `android.appwidget.action.APPWIDGET_UPDATE` | Bound to launcher desktop for 4x2 detailed prayer/quran widget. |
| `es.antonborri.home_widget.HomeWidgetBackgroundReceiver` | Receiver | `true` | Implicit Intent Filter | `es.antonborri.home_widget.action.BACKGROUND` | Dispatches widget tap callbacks into Flutter background engine. |
| `es.antonborri.home_widget.HomeWidgetBackgroundService` | Service | `true` | `android.permission.BIND_JOB_SERVICE` | None | System job scheduler service. Protected by `BIND_JOB_SERVICE` (signature/system permission), making it impossible for untrusted third-party apps to invoke. |
| `com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver` | Receiver | **`false`** | Internal Only | None | Internal alarm trigger. Closed to external intent injection. |
| `com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver` | Receiver | **`false`** | Internal Only | `BOOT_COMPLETED`, `MY_PACKAGE_REPLACED`, `quickboot.poweron` | System broadcast receiver registered for device reboot recovery. Internal only. |
| `com.dexterous.flutterlocalnotifications.ActionBroadcastReceiver` | Receiver | **`false`** | Internal Only | None | Internal notification action click dispatcher. Closed to external apps. |

---

## 2. Dynamic Broadcast Receivers & Android 14+ Compliance

All runtime dynamically registered broadcast receivers inside the Flutter app are registered with `RECEIVER_NOT_EXPORTED` flag or protected by the application's unique signature permission:
`com.talibilm.app.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`

This ensures that no external application can broadcast fake notification or audio playback intents into `talib_ilm`.
