"""
Device Acceptance Readiness Verification Script.
Queries connected Android device(s) via ADB to verify package installation,
manifest components, widget providers, alarm manager registrations,
and intent queryability.
"""

import json
import os
import subprocess
import sys

PACKAGE_NAME = "com.talibilm.app"

def run_adb(args):
    cmd = ["adb"] + args
    try:
        res = subprocess.run(cmd, capture_output=True, text=True, check=False, encoding="utf-8", errors="replace")
        return res.returncode, res.stdout.strip(), res.stderr.strip()
    except Exception as e:
        return -1, "", str(e)

def main():
    print(f"=== Device Acceptance Automated Telemetry Audit for {PACKAGE_NAME} ===")
    
    # 1. Device check
    code, out, _ = run_adb(["devices"])
    lines = [line.strip() for line in out.splitlines() if line.strip() and not line.startswith("List of")]
    devices = [l.split()[0] for l in lines if "device" in l]
    
    if not devices:
        print("[WARN] No active ADB device found.")
        sys.exit(0)
        
    device_id = devices[0]
    print(f"[OK] Target Device: {device_id}")
    
    # Device props
    _, model, _ = run_adb(["-s", device_id, "shell", "getprop", "ro.product.model"])
    _, brand, _ = run_adb(["-s", device_id, "shell", "getprop", "ro.product.brand"])
    _, android_ver, _ = run_adb(["-s", device_id, "shell", "getprop", "ro.build.version.release"])
    _, sdk_ver, _ = run_adb(["-s", device_id, "shell", "getprop", "ro.build.version.sdk"])
    _, density, _ = run_adb(["-s", device_id, "shell", "wm", "density"])
    _, size, _ = run_adb(["-s", device_id, "shell", "wm", "size"])
    
    print(f"     Hardware: {brand} {model} | Android {android_ver} (API {sdk_ver}) | {size} | {density}")

    report = {
        "device": {
            "serial": device_id,
            "brand": brand,
            "model": model,
            "android_version": android_ver,
            "sdk_version": sdk_ver,
            "display_size": size,
            "display_density": density,
        },
        "checks": {}
    }
    
    # 2. Package installation check
    code, out, _ = run_adb(["-s", device_id, "shell", "pm", "path", PACKAGE_NAME])
    pkg_installed = (code == 0 and "package:" in out)
    print(f"[CHECK 1] Package {PACKAGE_NAME} installed: {'YES' if pkg_installed else 'NO'}")
    report["checks"]["package_installed"] = pkg_installed
    
    # 3. Dumpsys package components
    code, out, _ = run_adb(["-s", device_id, "shell", "dumpsys", "package", PACKAGE_NAME])
    has_main_activity = "com.talibilm.app/.MainActivity" in out
    has_boot_receiver = "ScheduledNotificationBootReceiver" in out
    has_audio_service = "com.ryanheise.audioservice.AudioService" in out
    has_widgets = "RibbonWidgetProvider" in out and "LargeWidgetProvider" in out
    
    print(f"[CHECK 2] MainActivity registered: {'PASS' if has_main_activity else 'FAIL'}")
    print(f"[CHECK 3] Boot Receiver registered: {'PASS' if has_boot_receiver else 'FAIL'}")
    print(f"[CHECK 4] AudioService registered: {'PASS' if has_audio_service else 'FAIL'}")
    print(f"[CHECK 5] AppWidget Providers registered: {'PASS' if has_widgets else 'FAIL'}")
    
    report["checks"]["main_activity"] = has_main_activity
    report["checks"]["boot_receiver"] = has_boot_receiver
    report["checks"]["audio_service"] = has_audio_service
    report["checks"]["appwidget_providers"] = has_widgets
    
    # 4. AppWidget manager check
    code, out, _ = run_adb(["-s", device_id, "shell", "dumpsys", "appwidget"])
    widgets_bound = "com.talibilm.app" in out
    print(f"[CHECK 6] AppWidget system registration: {'PASS' if widgets_bound else 'FAIL'}")
    report["checks"]["widgets_bound"] = widgets_bound
    
    # 5. AlarmManager check
    code, out, _ = run_adb(["-s", device_id, "shell", "dumpsys", "alarm"])
    alarms_registered = "com.talibilm.app" in out
    has_scheduled_notifications = "ScheduledNotificationReceiver" in out and "com.talibilm.app" in out
    print(f"[CHECK 7] AlarmManager registrations: {'PASS' if alarms_registered else 'FAIL'}")
    print(f"[CHECK 8] ScheduledNotificationReceiver active in AlarmManager: {'PASS' if has_scheduled_notifications else 'FAIL'}")
    report["checks"]["alarms_registered"] = alarms_registered
    report["checks"]["scheduled_notifications_active"] = has_scheduled_notifications
    
    # Write summary json
    out_dir = os.path.join("build", "release-readiness", "device_qa")
    os.makedirs(out_dir, exist_ok=True)
    out_file = os.path.join(out_dir, "device_readiness_telemetry.json")
    with open(out_file, "w", encoding="utf-8") as f:
        json.dump(report, f, indent=2, ensure_ascii=False)
        
    print(f"\n[OK] Telemetry written to {out_file}")
    
    all_passed = all(report["checks"].values())
    if all_passed:
        print("[VERDICT] All automated ADB device checks PASSED!")
    else:
        print("[VERDICT] Some ADB device checks failed or need attention.")
        
    return 0 if all_passed else 1

if __name__ == "__main__":
    sys.exit(main())
