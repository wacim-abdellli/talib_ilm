import WidgetKit
import SwiftUI

// MARK: - Safe Data Extraction & Formatters

private let appGroupId = "group.com.talibilm.app"

/// Inspects embedded provisioning profile to dynamically resolve the active App Group
/// when apps are sideloaded via AltStore, Sideloadly, or signed with custom team IDs.
private func getProvisionedAppGroup() -> String? {
    let bundle = Bundle.main
    let possiblePaths = [
        bundle.path(forResource: "embedded", ofType: "mobileprovision"),
        bundle.bundleURL.deletingLastPathComponent().appendingPathComponent("embedded.mobileprovision").path,
        bundle.bundleURL.deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("embedded.mobileprovision").path
    ]
    for path in possiblePaths {
        guard let p = path,
              let data = try? Data(contentsOf: URL(fileURLWithPath: p)),
              let string = String(data: data, encoding: .ascii) else { continue }
        if let range = string.range(of: "com.apple.security.application-groups") {
            let substring = string[range.upperBound...]
            if let stringStart = substring.range(of: "<string>"),
               let stringEnd = substring[stringStart.upperBound...].range(of: "</string>") {
                let group = String(substring[stringStart.upperBound..<stringEnd.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                if group.starts(with: "group.") {
                    return group
                }
            }
        }
    }
    return nil
}

/// Discovers the active shared UserDefaults suite across standard, provisioned, and dynamic groups.
private func getPreferences() -> UserDefaults {
    var candidateGroups: [String] = [appGroupId]
    if let provisioned = getProvisionedAppGroup(), !candidateGroups.contains(provisioned) {
        candidateGroups.insert(provisioned, at: 0)
    }
    if let bundleId = Bundle.main.bundleIdentifier {
        let baseApp = bundleId.replacingOccurrences(of: ".widgets", with: "").replacingOccurrences(of: ".Widgets", with: "")
        let dynamicGroup = "group." + baseApp
        if !candidateGroups.contains(dynamicGroup) {
            candidateGroups.append(dynamicGroup)
        }
    }

    // Return the first candidate suite that holds shared prayer data
    for group in candidateGroups {
        if let userDefaults = UserDefaults(suiteName: group) {
            if userDefaults.object(forKey: "prayer_data_json") != nil ||
               userDefaults.object(forKey: "prayer_fajr_epoch_ms") != nil ||
               userDefaults.object(forKey: "next_prayer_name") != nil {
                return userDefaults
            }
        }
    }

    // Fall back to first valid suite or standard
    for group in candidateGroups {
        if let userDefaults = UserDefaults(suiteName: group) {
            return userDefaults
        }
    }

    return UserDefaults.standard
}

private func loadJsonPayload(from prefs: UserDefaults) -> [String: Any]? {
    guard let jsonStr = prefs.string(forKey: "prayer_data_json"),
          let data = jsonStr.data(using: .utf8),
          let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
        return nil
    }
    return dict
}

private func getInt64(from prefs: UserDefaults, json: [String: Any]?, key: String) -> Int64? {
    if let num = prefs.object(forKey: key) as? NSNumber {
        let val = num.int64Value
        if val > 0 { return val }
    }
    if let str = prefs.string(forKey: key), let val = Int64(str), val > 0 {
        return val
    }
    let val = prefs.integer(forKey: key)
    if val > 0 { return Int64(val) }

    if let json = json {
        if let num = json[key] as? NSNumber {
            let val = num.int64Value
            if val > 0 { return val }
        }
        if let str = json[key] as? String, let val = Int64(str), val > 0 {
            return val
        }
    }
    return nil
}

private func getString(from prefs: UserDefaults, json: [String: Any]?, key: String) -> String? {
    if let s = prefs.string(forKey: key), !s.isEmpty {
        return s
    }
    if let json = json, let s = json[key] as? String, !s.isEmpty {
        return s
    }
    return nil
}

private func getDate(from prefs: UserDefaults, json: [String: Any]?, key: String) -> Date? {
    guard let ms = getInt64(from: prefs, json: json, key: key) else { return nil }
    if ms > 10_000_000_000 {
        return Date(timeIntervalSince1970: Double(ms) / 1000.0)
    } else {
        return Date(timeIntervalSince1970: Double(ms))
    }
}

private func formatTime(date: Date?) -> String {
    guard let d = date else { return "--:--" }
    let calendar = Calendar.current
    let hour = calendar.component(.hour, from: d)
    let minute = calendar.component(.minute, from: d)
    let hour12 = (hour % 12 == 0) ? 12 : (hour % 12)
    let period = (hour >= 12) ? "م" : "ص"
    return String(format: "%d:%02d %@", hour12, minute, period)
}

// MARK: - Autonomous Offline Astronomical Prayer Calculator Fallback

/// Mathematical solar position and Islamic prayer time calculator.
/// Guarantees that the widget never shows '--:--' even on fresh installs or stripped App Groups.
struct OfflinePrayerCalculator {
    static func calculate(date: Date, latitude: Double, longitude: Double, timezoneOffsetHours: Double) -> [String: Date] {
        let calendar = Calendar(identifier: .gregorian)
        var comp = calendar.dateComponents(in: TimeZone.current, from: date)
        guard let year = comp.year, let month = comp.month, let day = comp.day else {
            return [:]
        }

        // Astronomical Julian Day
        var y = Double(year)
        var m = Double(month)
        let d = Double(day)
        if m <= 2 {
            y -= 1
            m += 12
        }
        let a = floor(y / 100.0)
        let b = 2.0 - a + floor(a / 4.0)
        let jd = floor(365.25 * (y + 4716.0)) + floor(30.6001 * (m + 1.0)) + d + b - 1524.5

        let t = (jd - 2451545.0) / 36525.0
        let l0 = (280.46646 + 36000.76983 * t).truncatingRemainder(dividingBy: 360.0)
        let mSun = (357.52911 + 35999.05029 * t).truncatingRemainder(dividingBy: 360.0)
        let mRad = mSun * .pi / 180.0
        let c = (1.914602 - 0.004817 * t) * sin(mRad) + 0.019993 * sin(2.0 * mRad) + 0.000289 * sin(3.0 * mRad)
        let trueLong = l0 + c
        let lambdaRad = trueLong * .pi / 180.0

        let eps = (23.439291 - 0.0130042 * t) * .pi / 180.0
        let declination = asin(sin(eps) * sin(lambdaRad))

        // Equation of Time in minutes
        let yTan = tan(eps / 2.0) * tan(eps / 2.0)
        let eotMinutes = 4.0 * (180.0 / .pi) * (
            yTan * sin(2.0 * lambdaRad) -
            2.0 * 0.016708634 * sin(mRad) +
            4.0 * 0.016708634 * yTan * sin(mRad) * cos(2.0 * lambdaRad) -
            0.5 * yTan * yTan * sin(4.0 * lambdaRad) -
            1.25 * 0.016708634 * 0.016708634 * sin(2.0 * mRad)
        )

        // Solar Noon (Dhuhr) in local hours with 2-minute standard precaution
        let noonHours = 12.0 + timezoneOffsetHours - (longitude / 15.0) - (eotMinutes / 60.0) + (2.0 / 60.0)
        let latRad = latitude * .pi / 180.0

        func hourAngle(forAltitude altitudeDeg: Double) -> Double? {
            let altRad = altitudeDeg * .pi / 180.0
            let cosH = (sin(altRad) - sin(latRad) * sin(declination)) / (cos(latRad) * cos(declination))
            if cosH < -1.0 || cosH > 1.0 { return nil }
            return acos(cosH) * 180.0 / .pi
        }

        func dateFromHours(_ hours: Double) -> Date {
            var adjustedHours = hours.truncatingRemainder(dividingBy: 24.0)
            if adjustedHours < 0 { adjustedHours += 24.0 }
            let h = Int(floor(adjustedHours))
            let mFloat = (adjustedHours - Double(h)) * 60.0
            let m = Int(floor(mFloat))
            let s = Int(floor((mFloat - Double(m)) * 60.0))

            comp.hour = h
            comp.minute = m
            comp.second = s
            return calendar.date(from: comp) ?? date
        }

        guard let hSunrise = hourAngle(forAltitude: -0.8333),
              let hFajr = hourAngle(forAltitude: -18.0) else {
            return [:]
        }

        let hIsha = hourAngle(forAltitude: -18.0) ?? hSunrise

        // Asr: Shafi'i / Hanbali / Maliki standard shadow factor = 1
        let asrAltRad = atan(1.0 / (1.0 + tan(abs(latRad - declination))))
        let asrAltDeg = asrAltRad * 180.0 / .pi
        let hAsr = hourAngle(forAltitude: asrAltDeg) ?? 45.0

        let fajrDate = dateFromHours(noonHours - (hFajr / 15.0))
        let dhuhrDate = dateFromHours(noonHours)
        let asrDate = dateFromHours(noonHours + (hAsr / 15.0))
        let maghribDate = dateFromHours(noonHours + (hSunrise / 15.0) + (2.0 / 60.0))
        let ishaDate = dateFromHours(noonHours + (hIsha / 15.0) + (1.0 / 60.0))

        return [
            "fajr": fajrDate,
            "dhuhr": dhuhrDate,
            "asr": asrDate,
            "maghrib": maghribDate,
            "isha": ishaDate,
        ]
    }
}

// MARK: - Schedule & Evaluation Models

struct PrayerSchedule {
    let fajr: Date?
    let dhuhr: Date?
    let asr: Date?
    let maghrib: Date?
    let isha: Date?
    let tomorrowFajr: Date?
    let isFriday: Bool
    let iqamaFajr: Int
    let iqamaDhuhr: Int
    let iqamaAsr: Int
    let iqamaMaghrib: Int
    let iqamaIsha: Int

    let fajrStr: String
    let dhuhrStr: String
    let asrStr: String
    let maghribStr: String
    let ishaStr: String
}

private func loadSchedule(from prefs: UserDefaults) -> PrayerSchedule {
    let json = loadJsonPayload(from: prefs)

    var fajr = getDate(from: prefs, json: json, key: "prayer_fajr_epoch_ms")
    var dhuhr = getDate(from: prefs, json: json, key: "prayer_dhuhr_epoch_ms")
    var asr = getDate(from: prefs, json: json, key: "prayer_asr_epoch_ms")
    var maghrib = getDate(from: prefs, json: json, key: "prayer_maghrib_epoch_ms")
    var isha = getDate(from: prefs, json: json, key: "prayer_isha_epoch_ms")
    var tomorrowFajr = getDate(from: prefs, json: json, key: "prayer_tomorrow_fajr_epoch_ms")

    // If prayer times are missing from shared preferences, compute astronomical times
    if fajr == nil || dhuhr == nil || asr == nil || maghrib == nil || isha == nil {
        var lat = prefs.double(forKey: "location_latitude")
        var lon = prefs.double(forKey: "location_longitude")
        if let json = json {
            if lat == 0, let jLat = json["latitude"] as? Double { lat = jLat }
            if lon == 0, let jLon = json["longitude"] as? Double { lon = jLon }
        }
        if lat == 0 && lon == 0 {
            let locale = Locale.current.identifier
            if locale.contains("TN") || locale.contains("Tunis") {
                lat = 36.8065
                lon = 10.1815
            } else {
                lat = 21.4225
                lon = 39.8262
            }
        }
        let tzOffset = Double(TimeZone.current.secondsFromGMT()) / 3600.0
        let calcToday = OfflinePrayerCalculator.calculate(date: Date(), latitude: lat, longitude: lon, timezoneOffsetHours: tzOffset)
        let calcTomorrow = OfflinePrayerCalculator.calculate(date: Date().addingTimeInterval(86400), latitude: lat, longitude: lon, timezoneOffsetHours: tzOffset)

        fajr = fajr ?? calcToday["fajr"]
        dhuhr = dhuhr ?? calcToday["dhuhr"]
        asr = asr ?? calcToday["asr"]
        maghrib = maghrib ?? calcToday["maghrib"]
        isha = isha ?? calcToday["isha"]
        tomorrowFajr = tomorrowFajr ?? calcTomorrow["fajr"]
    }

    let isFriday = prefs.object(forKey: "is_friday") as? Bool ?? (Calendar.current.component(.weekday, from: dhuhr ?? Date()) == 6)

    let iqamaFajr = prefs.integer(forKey: "iqama_fajr_min") > 0 ? prefs.integer(forKey: "iqama_fajr_min") : 25
    let iqamaDhuhr = prefs.integer(forKey: "iqama_dhuhr_min") > 0 ? prefs.integer(forKey: "iqama_dhuhr_min") : 20
    let iqamaAsr = prefs.integer(forKey: "iqama_asr_min") > 0 ? prefs.integer(forKey: "iqama_asr_min") : 20
    let iqamaMaghrib = prefs.integer(forKey: "iqama_maghrib_min") > 0 ? prefs.integer(forKey: "iqama_maghrib_min") : 10
    let iqamaIsha = prefs.integer(forKey: "iqama_isha_min") > 0 ? prefs.integer(forKey: "iqama_isha_min") : 20

    let fajrStr = getString(from: prefs, json: json, key: "prayer_fajr_time_str") ?? formatTime(date: fajr)
    let dhuhrStr = getString(from: prefs, json: json, key: "prayer_dhuhr_time_str") ?? formatTime(date: dhuhr)
    let asrStr = getString(from: prefs, json: json, key: "prayer_asr_time_str") ?? formatTime(date: asr)
    let maghribStr = getString(from: prefs, json: json, key: "prayer_maghrib_time_str") ?? formatTime(date: maghrib)
    let ishaStr = getString(from: prefs, json: json, key: "prayer_isha_time_str") ?? formatTime(date: isha)

    return PrayerSchedule(
        fajr: fajr,
        dhuhr: dhuhr,
        asr: asr,
        maghrib: maghrib,
        isha: isha,
        tomorrowFajr: tomorrowFajr,
        isFriday: isFriday,
        iqamaFajr: iqamaFajr,
        iqamaDhuhr: iqamaDhuhr,
        iqamaAsr: iqamaAsr,
        iqamaMaghrib: iqamaMaghrib,
        iqamaIsha: iqamaIsha,
        fajrStr: fajrStr,
        dhuhrStr: dhuhrStr,
        asrStr: asrStr,
        maghribStr: maghribStr,
        ishaStr: ishaStr
    )
}

struct EvaluatedPrayer {
    let activePrayerName: String
    let displayTitle: String
    let countdownPrefix: String
    let targetTime: Date?
    let isPrayerActive: Bool
}

private func evaluatePrayer(at date: Date, schedule: PrayerSchedule, prefs: UserDefaults) -> EvaluatedPrayer {
    guard let fajr = schedule.fajr,
          let dhuhr = schedule.dhuhr,
          let asr = schedule.asr,
          let maghrib = schedule.maghrib,
          let isha = schedule.isha else {
        let json = loadJsonPayload(from: prefs)
        let nextName = getString(from: prefs, json: json, key: "next_prayer_name") ?? "الظهر"
        let displayTitle = getString(from: prefs, json: json, key: "prayer_display_title") ?? "صلاة الظهر"
        let countdownPrefix = getString(from: prefs, json: json, key: "countdown_prefix") ?? "بقي على الأذان"
        let nextDate = getDate(from: prefs, json: json, key: "next_prayer_epoch_ms")
        return EvaluatedPrayer(
            activePrayerName: nextName,
            displayTitle: displayTitle,
            countdownPrefix: countdownPrefix,
            targetTime: nextDate,
            isPrayerActive: false
        )
    }

    let dhuhrTitle = schedule.isFriday ? "صلاة الجمعة" : "صلاة الظهر"
    let dhuhrName = schedule.isFriday ? "الجمعة" : "الظهر"

    if date < fajr {
        return EvaluatedPrayer(
            activePrayerName: "الفجر",
            displayTitle: "صلاة الفجر",
            countdownPrefix: "بقي على الأذان",
            targetTime: fajr,
            isPrayerActive: false
        )
    } else if date < dhuhr {
        let iqamaDate = fajr.addingTimeInterval(Double(schedule.iqamaFajr * 60))
        if date < iqamaDate {
            return EvaluatedPrayer(
                activePrayerName: "الفجر",
                displayTitle: "صلاة الفجر",
                countdownPrefix: "الإقامة بعد ",
                targetTime: iqamaDate,
                isPrayerActive: true
            )
        }
        return EvaluatedPrayer(
            activePrayerName: dhuhrName,
            displayTitle: dhuhrTitle,
            countdownPrefix: "بقي على الأذان",
            targetTime: dhuhr,
            isPrayerActive: false
        )
    } else if date < asr {
        let iqamaDate = dhuhr.addingTimeInterval(Double(schedule.iqamaDhuhr * 60))
        if date < iqamaDate {
            return EvaluatedPrayer(
                activePrayerName: dhuhrName,
                displayTitle: dhuhrTitle,
                countdownPrefix: "الإقامة بعد ",
                targetTime: iqamaDate,
                isPrayerActive: true
            )
        }
        return EvaluatedPrayer(
            activePrayerName: "العصر",
            displayTitle: "صلاة العصر",
            countdownPrefix: "بقي على الأذان",
            targetTime: asr,
            isPrayerActive: false
        )
    } else if date < maghrib {
        let iqamaDate = asr.addingTimeInterval(Double(schedule.iqamaAsr * 60))
        if date < iqamaDate {
            return EvaluatedPrayer(
                activePrayerName: "العصر",
                displayTitle: "صلاة العصر",
                countdownPrefix: "الإقامة بعد ",
                targetTime: iqamaDate,
                isPrayerActive: true
            )
        }
        return EvaluatedPrayer(
            activePrayerName: "المغرب",
            displayTitle: "صلاة المغرب",
            countdownPrefix: "بقي على الأذان",
            targetTime: maghrib,
            isPrayerActive: false
        )
    } else if date < isha {
        let iqamaDate = maghrib.addingTimeInterval(Double(schedule.iqamaMaghrib * 60))
        if date < iqamaDate {
            return EvaluatedPrayer(
                activePrayerName: "المغرب",
                displayTitle: "صلاة المغرب",
                countdownPrefix: "الإقامة بعد ",
                targetTime: iqamaDate,
                isPrayerActive: true
            )
        }
        return EvaluatedPrayer(
            activePrayerName: "العشاء",
            displayTitle: "صلاة العشاء",
            countdownPrefix: "بقي على الأذان",
            targetTime: isha,
            isPrayerActive: false
        )
    } else {
        let tomorrowFajr = schedule.tomorrowFajr ?? fajr.addingTimeInterval(86400)
        let iqamaDate = isha.addingTimeInterval(Double(schedule.iqamaIsha * 60))
        if date < iqamaDate {
            return EvaluatedPrayer(
                activePrayerName: "العشاء",
                displayTitle: "صلاة العشاء",
                countdownPrefix: "الإقامة بعد ",
                targetTime: iqamaDate,
                isPrayerActive: true
            )
        }
        return EvaluatedPrayer(
            activePrayerName: "الفجر",
            displayTitle: "صلاة الفجر",
            countdownPrefix: "بقي على الأذان",
            targetTime: tomorrowFajr,
            isPrayerActive: false
        )
    }
}

// MARK: - Timeline Entry & Provider

struct PrayerWidgetEntry: TimelineEntry {
    let date: Date
    let nextPrayerName: String
    let prayerDisplayTitle: String
    let countdownPrefix: String
    let nextPrayerDate: Date?
    let fajrTime: String
    let dhuhrTime: String
    let asrTime: String
    let maghribTime: String
    let ishaTime: String
    let hijriDate: String
    let cityName: String
    let dailyGem: String
    let dailyGemAuthor: String
    let isDark: Bool
    let widgetThemeMode: String
    let appThemeMode: String
    let isPrayerActive: Bool
}

struct PrayerTimelineProvider: TimelineProvider {
    typealias Entry = PrayerWidgetEntry

    private func buildEntry(date: Date, prefs: UserDefaults, schedule: PrayerSchedule) -> PrayerWidgetEntry {
        let evaluated = evaluatePrayer(at: date, schedule: schedule, prefs: prefs)
        let json = loadJsonPayload(from: prefs)

        let hijri = getString(from: prefs, json: json, key: "hijri_date") ?? "طالب العلم"
        let city = getString(from: prefs, json: json, key: "location_city") ?? "مكة المكرمة"
        let gem = getString(from: prefs, json: json, key: "daily_gem_text") ?? "من سلك طريقاً يلتمس فيه علماً سهل الله له به طريقاً إلى الجنة"
        let author = getString(from: prefs, json: json, key: "daily_gem_author") ?? "حديث نبوي شريف"
        let isDark = prefs.object(forKey: "widget_is_dark") as? Bool ?? true
        let widgetThemeMode = getString(from: prefs, json: json, key: "prayer_widget_theme_mode") ?? "dark"
        let appThemeMode = getString(from: prefs, json: json, key: "theme_mode") ?? "system"

        return PrayerWidgetEntry(
            date: date,
            nextPrayerName: evaluated.activePrayerName,
            prayerDisplayTitle: evaluated.displayTitle,
            countdownPrefix: evaluated.countdownPrefix,
            nextPrayerDate: evaluated.targetTime,
            fajrTime: schedule.fajrStr,
            dhuhrTime: schedule.dhuhrStr,
            asrTime: schedule.asrStr,
            maghribTime: schedule.maghribStr,
            ishaTime: schedule.ishaStr,
            hijriDate: hijri,
            cityName: city,
            dailyGem: gem,
            dailyGemAuthor: author,
            isDark: isDark,
            widgetThemeMode: widgetThemeMode,
            appThemeMode: appThemeMode,
            isPrayerActive: evaluated.isPrayerActive
        )
    }

    func placeholder(in context: Context) -> PrayerWidgetEntry {
        let prefs = getPreferences()
        let schedule = loadSchedule(from: prefs)
        return buildEntry(date: Date(), prefs: prefs, schedule: schedule)
    }

    func getSnapshot(in context: Context, completion: @escaping (PrayerWidgetEntry) -> Void) {
        let prefs = getPreferences()
        let schedule = loadSchedule(from: prefs)
        completion(buildEntry(date: Date(), prefs: prefs, schedule: schedule))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PrayerWidgetEntry>) -> Void) {
        let now = Date()
        let prefs = getPreferences()
        let schedule = loadSchedule(from: prefs)

        var entries: [PrayerWidgetEntry] = []

        // Entry 1: Current live state
        entries.append(buildEntry(date: now, prefs: prefs, schedule: schedule))

        // Collect upcoming prayer transition points
        var transitionDates: [Date] = []
        if let fajr = schedule.fajr, fajr > now { transitionDates.append(fajr) }
        if let dhuhr = schedule.dhuhr, dhuhr > now { transitionDates.append(dhuhr) }
        if let asr = schedule.asr, asr > now { transitionDates.append(asr) }
        if let maghrib = schedule.maghrib, maghrib > now { transitionDates.append(maghrib) }
        if let isha = schedule.isha, isha > now { transitionDates.append(isha) }
        if let tomorrowFajr = schedule.tomorrowFajr, tomorrowFajr > now { transitionDates.append(tomorrowFajr) }

        // Also add Iqama transition points
        if let fajr = schedule.fajr {
            let iqama = fajr.addingTimeInterval(Double(schedule.iqamaFajr * 60))
            if iqama > now { transitionDates.append(iqama) }
        }
        if let dhuhr = schedule.dhuhr {
            let iqama = dhuhr.addingTimeInterval(Double(schedule.iqamaDhuhr * 60))
            if iqama > now { transitionDates.append(iqama) }
        }
        if let asr = schedule.asr {
            let iqama = asr.addingTimeInterval(Double(schedule.iqamaAsr * 60))
            if iqama > now { transitionDates.append(iqama) }
        }
        if let maghrib = schedule.maghrib {
            let iqama = maghrib.addingTimeInterval(Double(schedule.iqamaMaghrib * 60))
            if iqama > now { transitionDates.append(iqama) }
        }
        if let isha = schedule.isha {
            let iqama = isha.addingTimeInterval(Double(schedule.iqamaIsha * 60))
            if iqama > now { transitionDates.append(iqama) }
        }

        transitionDates.sort()

        // Settle 1 second after each transition so the widget state advances accurately
        for transition in transitionDates {
            let entryDate = transition.addingTimeInterval(1)
            entries.append(buildEntry(date: entryDate, prefs: prefs, schedule: schedule))
        }

        // Timeline reload policy
        let reloadDate = transitionDates.first ?? Calendar.current.date(byAdding: .minute, value: 30, to: now) ?? now.addingTimeInterval(1800)
        let timeline = Timeline(entries: entries, policy: .after(reloadDate))
        completion(timeline)
    }
}

// MARK: - Main Widget Declaration

@main
struct TalibIlmWidgets: Widget {
    let kind: String = "TalibIlmWidgets"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayerTimelineProvider()) { entry in
            TalibIlmWidgetsEntryView(entry: entry)
        }
        .configurationDisplayName("مواقيت الصلاة والأذكار")
        .description("عرض مواقيت الصلاة والعد التنازلي ودرر السلف اليومية.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
