import WidgetKit
import SwiftUI

// MARK: - Safe Data Extraction & App Group Discovery

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
                let group = String(substring[stringStart.upperBound..<stringEnd.lowerBound])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
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
        let baseApp = bundleId
            .replacingOccurrences(of: ".widgets", with: "")
            .replacingOccurrences(of: ".Widgets", with: "")
        let dynamicGroup = "group." + baseApp
        if !candidateGroups.contains(dynamicGroup) {
            candidateGroups.append(dynamicGroup)
        }
    }

    for group in candidateGroups {
        if let userDefaults = UserDefaults(suiteName: group) {
            if userDefaults.object(forKey: "prayer_data_json") != nil ||
               userDefaults.object(forKey: "prayer_fajr_epoch_ms") != nil ||
               userDefaults.object(forKey: "next_prayer_name") != nil {
                return userDefaults
            }
        }
    }

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

private func getInt64(from prefs: UserDefaults, json: [String: Any]?, key: String, prayerSlug: String? = nil) -> Int64? {
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
        if let num = json[key] as? NSNumber, num.int64Value > 0 {
            return num.int64Value
        }
        if let str = json[key] as? String, let v = Int64(str), v > 0 {
            return v
        }
        if let slug = prayerSlug,
           let prayers = json["prayers"] as? [String: Any],
           let pDict = prayers[slug] as? [String: Any],
           let num = pDict["epoch_ms"] as? NSNumber,
           num.int64Value > 0 {
            return num.int64Value
        }
    }
    return nil
}

private func getString(from prefs: UserDefaults, json: [String: Any]?, key: String, jsonFallbackKey: String? = nil) -> String? {
    if let s = prefs.string(forKey: key)?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty {
        return s
    }
    if let json = json {
        if let s = (json[key] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty {
            return s
        }
        if let fb = jsonFallbackKey,
           let s = (json[fb] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty {
            return s
        }
    }
    return nil
}

private func getDate(from prefs: UserDefaults, json: [String: Any]?, key: String, prayerSlug: String? = nil) -> Date? {
    guard let ms = getInt64(from: prefs, json: json, key: key, prayerSlug: prayerSlug) else { return nil }
    if ms > 10_000_000_000 {
        return Date(timeIntervalSince1970: Double(ms) / 1000.0)
    } else {
        return Date(timeIntervalSince1970: Double(ms))
    }
}

private func formatCompactTime(date: Date?) -> String {
    guard let d = date else { return "--:--" }
    let calendar = Calendar.current
    let hour = calendar.component(.hour, from: d)
    let minute = calendar.component(.minute, from: d)
    let hour12 = (hour % 12 == 0) ? 12 : (hour % 12)
    return String(format: "%02d:%02d", hour12, minute)
}

private func formatTimeWithPeriod(date: Date?) -> String {
    guard let d = date else { return "--:--" }
    let calendar = Calendar.current
    let hour = calendar.component(.hour, from: d)
    let minute = calendar.component(.minute, from: d)
    let hour12 = (hour % 12 == 0) ? 12 : (hour % 12)
    let period = (hour >= 12) ? "م" : "ص"
    return String(format: "%02d:%02d %@", hour12, minute, period)
}

private func formatUmmAlQuraHijri(for date: Date, includeYear: Bool = false) -> String {
    var cal = Calendar(identifier: .islamicUmmAlQura)
    cal.locale = Locale(identifier: "ar")
    let formatter = DateFormatter()
    formatter.calendar = cal
    formatter.locale = Locale(identifier: "ar_SA@numbers=latn")
    formatter.dateFormat = includeYear ? "d MMMM yyyy هـ" : "d MMMM"
    return formatter.string(from: date)
}

// MARK: - Autonomous Offline Astronomical Prayer Calculator Fallback

struct OfflinePrayerCalculator {
    static func calculate(date: Date, latitude: Double, longitude: Double, timezoneOffsetHours: Double) -> [String: Date] {
        let calendar = Calendar(identifier: .gregorian)
        var comp = calendar.dateComponents(in: TimeZone.current, from: date)
        guard let year = comp.year, let month = comp.month, let day = comp.day else {
            return [:]
        }

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

        let yTan = tan(eps / 2.0) * tan(eps / 2.0)
        let eotMinutes = 4.0 * (180.0 / .pi) * (
            yTan * sin(2.0 * lambdaRad) -
            2.0 * 0.016708634 * sin(mRad) +
            4.0 * 0.016708634 * yTan * sin(mRad) * cos(2.0 * lambdaRad) -
            0.5 * yTan * yTan * sin(4.0 * lambdaRad) -
            1.25 * 0.016708634 * 0.016708634 * sin(2.0 * mRad)
        )

        let effectiveTz: Double = {
            if abs(timezoneOffsetHours - (longitude / 15.0)) > 2.5 {
                if abs(latitude - 21.4) < 1.0 && abs(longitude - 39.8) < 1.0 {
                    return 3.0
                }
                return (longitude / 15.0).rounded()
            }
            return timezoneOffsetHours
        }()

        let noonHours = 12.0 + effectiveTz - (longitude / 15.0) - (eotMinutes / 60.0) + (2.0 / 60.0)
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
    let fajr: Date
    let dhuhr: Date
    let asr: Date
    let maghrib: Date
    let isha: Date
    let tomorrowFajr: Date
    let isFriday: Bool
    let iqamaFajr: Int
    let iqamaDhuhr: Int
    let iqamaAsr: Int
    let iqamaMaghrib: Int
    let iqamaIsha: Int
    let isFromTodayPrefs: Bool
}

private func loadSchedule(from prefs: UserDefaults, for date: Date = Date()) -> PrayerSchedule {
    let json = loadJsonPayload(from: prefs)
    let cal = Calendar.current

    var fajr = getDate(from: prefs, json: json, key: "prayer_fajr_epoch_ms", prayerSlug: "fajr")
    var dhuhr = getDate(from: prefs, json: json, key: "prayer_dhuhr_epoch_ms", prayerSlug: "dhuhr")
    var asr = getDate(from: prefs, json: json, key: "prayer_asr_epoch_ms", prayerSlug: "asr")
    var maghrib = getDate(from: prefs, json: json, key: "prayer_maghrib_epoch_ms", prayerSlug: "maghrib")
    var isha = getDate(from: prefs, json: json, key: "prayer_isha_epoch_ms", prayerSlug: "isha")
    var tomorrowFajr = getDate(from: prefs, json: json, key: "prayer_tomorrow_fajr_epoch_ms")

    let scheduleValidForDate: Bool = {
        guard let f = fajr, let d = dhuhr, let a = asr, let m = maghrib, let i = isha else {
            return false
        }
        guard cal.isDate(f, inSameDayAs: date), cal.isDate(d, inSameDayAs: date) else {
            return false
        }
        guard f < d && d < a && a < m && m < i else {
            return false
        }
        let fajrHour = cal.component(.hour, from: f)
        let dhuhrHour = cal.component(.hour, from: d)
        return (2...8).contains(fajrHour) && (10...15).contains(dhuhrHour)
    }()

    if !scheduleValidForDate {
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
        let tzOffset = Double(TimeZone.current.secondsFromGMT(for: date)) / 3600.0
        let calcToday = OfflinePrayerCalculator.calculate(
            date: date,
            latitude: lat,
            longitude: lon,
            timezoneOffsetHours: tzOffset
        )
        let nextDay = cal.date(byAdding: .day, value: 1, to: date) ?? date.addingTimeInterval(86400)
        let calcTomorrow = OfflinePrayerCalculator.calculate(
            date: nextDay,
            latitude: lat,
            longitude: lon,
            timezoneOffsetHours: tzOffset
        )

        fajr = calcToday["fajr"] ?? fajr ?? date
        dhuhr = calcToday["dhuhr"] ?? dhuhr ?? date
        asr = calcToday["asr"] ?? asr ?? date
        maghrib = calcToday["maghrib"] ?? maghrib ?? date
        isha = calcToday["isha"] ?? isha ?? date
        tomorrowFajr = calcTomorrow["fajr"] ?? fajr!.addingTimeInterval(86400)
    }

    let safeFajr = fajr ?? date
    let safeDhuhr = dhuhr ?? date
    let safeAsr = asr ?? date
    let safeMaghrib = maghrib ?? date
    let safeIsha = isha ?? date
    let safeTomorrowFajr = tomorrowFajr ?? safeFajr.addingTimeInterval(86400)

    let isFriday: Bool = {
        if scheduleValidForDate, let prefFriday = prefs.object(forKey: "is_friday") as? Bool {
            return prefFriday
        }
        return cal.component(.weekday, from: safeDhuhr) == 6
    }()

    let iqamaFajr = prefs.integer(forKey: "iqama_fajr_min") > 0 ? prefs.integer(forKey: "iqama_fajr_min") : 25
    let iqamaDhuhr = prefs.integer(forKey: "iqama_dhuhr_min") > 0 ? prefs.integer(forKey: "iqama_dhuhr_min") : (isFriday ? 25 : 20)
    let iqamaAsr = prefs.integer(forKey: "iqama_asr_min") > 0 ? prefs.integer(forKey: "iqama_asr_min") : 20
    let iqamaMaghrib = prefs.integer(forKey: "iqama_maghrib_min") > 0 ? prefs.integer(forKey: "iqama_maghrib_min") : 10
    let iqamaIsha = prefs.integer(forKey: "iqama_isha_min") > 0 ? prefs.integer(forKey: "iqama_isha_min") : 15

    return PrayerSchedule(
        fajr: safeFajr,
        dhuhr: safeDhuhr,
        asr: safeAsr,
        maghrib: safeMaghrib,
        isha: safeIsha,
        tomorrowFajr: safeTomorrowFajr,
        isFriday: isFriday,
        iqamaFajr: iqamaFajr,
        iqamaDhuhr: iqamaDhuhr,
        iqamaAsr: iqamaAsr,
        iqamaMaghrib: iqamaMaghrib,
        iqamaIsha: iqamaIsha,
        isFromTodayPrefs: scheduleValidForDate
    )
}

struct PrayerEntry: TimelineEntry {
    let date: Date
    let hijriDate: String
    let locationName: String
    let heroTitle: String
    // Target date is rendered live via Text(targetDate, style: .timer) in TalibIlmWidgetViews
    let heroTargetDate: Date?
    let heroStatusText: String
    let isCallToPrayer: Bool
    let activePrayerKey: String
    let activePrayerTimePeriod: String
    let isJumua: Bool
    let fajrTime: String
    let dhuhrTime: String
    let asrTime: String
    let maghribTime: String
    let ishaTime: String
    let themePreference: String
    let isDarkFallback: Bool
}

struct Provider: TimelineProvider {
    typealias Entry = PrayerEntry

    func placeholder(in context: Context) -> PrayerEntry {
        let now = Date()
        let prefs = getPreferences()
        let schedule = loadSchedule(from: prefs, for: now)
        return buildEntry(for: now, schedule: schedule, prefs: prefs)
    }

    func getSnapshot(in context: Context, completion: @escaping (PrayerEntry) -> Void) {
        let now = Date()
        let prefs = getPreferences()
        let schedule = loadSchedule(from: prefs, for: now)
        completion(buildEntry(for: now, schedule: schedule, prefs: prefs))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PrayerEntry>) -> Void) {
        let now = Date()
        let prefs = getPreferences()
        let schedule = loadSchedule(from: prefs, for: now)

        var transitionDates = Set<Date>()
        transitionDates.insert(now)

        let prayersWithIqama: [(time: Date, iqamaMin: Int)] = [
            (schedule.fajr, schedule.iqamaFajr),
            (schedule.dhuhr, schedule.iqamaDhuhr),
            (schedule.asr, schedule.iqamaAsr),
            (schedule.maghrib, schedule.iqamaMaghrib),
            (schedule.isha, schedule.iqamaIsha),
            (schedule.tomorrowFajr, schedule.iqamaFajr)
        ]

        for item in prayersWithIqama {
            let adhanEnd = item.time.addingTimeInterval(2 * 60)
            let iqamaEnd = item.time.addingTimeInterval(Double(item.iqamaMin) * 60)
            let salahEnd = iqamaEnd.addingTimeInterval(12 * 60)
            if item.time > now { transitionDates.insert(item.time.addingTimeInterval(1)) }
            if adhanEnd > now { transitionDates.insert(adhanEnd.addingTimeInterval(1)) }
            if iqamaEnd > now { transitionDates.insert(iqamaEnd.addingTimeInterval(1)) }
            if salahEnd > now { transitionDates.insert(salahEnd.addingTimeInterval(1)) }
        }

        // Midnight rollover so Hijri date & tomorrow's schedule refresh cleanly
        if let nextMidnight = Calendar.current.nextDate(
            after: now,
            matching: DateComponents(hour: 0, minute: 0, second: 5),
            matchingPolicy: .nextTime
        ) {
            transitionDates.insert(nextMidnight)
        }

        // Periodic 15-minute checkpoints up to 6 hours ahead
        for step in 1...24 {
            transitionDates.insert(now.addingTimeInterval(Double(step) * 15 * 60))
        }

        let sortedDates = transitionDates.sorted().filter {
            $0 >= now && $0 <= schedule.tomorrowFajr.addingTimeInterval(3600)
        }

        var entries: [PrayerEntry] = []
        for entryDate in sortedDates {
            let entrySchedule = Calendar.current.isDate(entryDate, inSameDayAs: now)
                ? schedule
                : loadSchedule(from: prefs, for: entryDate)
            entries.append(buildEntry(for: entryDate, schedule: entrySchedule, prefs: prefs))
        }

        if entries.isEmpty {
            entries.append(buildEntry(for: now, schedule: schedule, prefs: prefs))
        }

        let nextRefresh = min(
            now.addingTimeInterval(30 * 60),
            schedule.tomorrowFajr.addingTimeInterval(60)
        )
        completion(Timeline(entries: entries, policy: .after(nextRefresh)))
    }

    private func buildEntry(
        for date: Date,
        schedule: PrayerSchedule,
        prefs: UserDefaults
    ) -> PrayerEntry {
        let json = loadJsonPayload(from: prefs)
        let dhuhrLabel = schedule.isFriday ? "الجمعة" : "الظهر"

        let rawHijri = schedule.isFromTodayPrefs
            ? (getString(from: prefs, json: json, key: "hijri_date", jsonFallbackKey: "hijri") ?? "")
            : ""
        let cleanHijri = rawHijri
            .replacingOccurrences(of: #"\s*\d{4}\s*هـ?"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let hijriDate = cleanHijri.isEmpty ? formatUmmAlQuraHijri(for: date) : cleanHijri

        let locationName = getString(
            from: prefs,
            json: json,
            key: "location_city",
            jsonFallbackKey: "city"
        ) ?? "مكة المكرمة"

        let isDarkFallback = (prefs.object(forKey: "widget_is_dark") as? Bool)
            ?? ((json?["widget_is_dark"] as? Bool) ?? false)
        let rawMode = getString(from: prefs, json: json, key: "prayer_widget_theme_mode") ?? "auto"
        let appMode = getString(from: prefs, json: json, key: "theme_mode") ?? "system"
        let userSelectedWidget = (prefs.object(forKey: "widget_theme_user_selected") as? Bool)
            ?? ((json?["widget_theme_user_selected"] as? Bool) ?? false)
        let userSelectedAppTheme = (prefs.object(forKey: "theme_user_selected") as? Bool)
            ?? ((json?["theme_user_selected"] as? Bool) ?? false)

        let themePreference: String = {
            if rawMode == "light" { return "light" }
            if rawMode == "dark" {
                if !userSelectedWidget && appMode == "light" {
                    return "light"
                }
                return "dark"
            }
            if userSelectedAppTheme {
                if appMode == "light" { return "light" }
                if appMode == "dark" { return "dark" }
            }
            return "system"
        }()

        let state = resolveState(at: date, schedule: schedule, dhuhrLabel: dhuhrLabel)
        let activeDate: Date = {
            switch state.activeKey {
            case "fajr": return date > schedule.isha ? schedule.tomorrowFajr : schedule.fajr
            case "dhuhr": return schedule.dhuhr
            case "asr": return schedule.asr
            case "maghrib": return schedule.maghrib
            case "isha": return schedule.isha
            default: return schedule.fajr
            }
        }()

        return PrayerEntry(
            date: date,
            hijriDate: hijriDate,
            locationName: locationName,
            heroTitle: state.title,
            heroTargetDate: state.targetDate,
            heroStatusText: state.statusText,
            isCallToPrayer: state.isCallToPrayer,
            activePrayerKey: state.activeKey,
            activePrayerTimePeriod: formatTimeWithPeriod(date: activeDate),
            isJumua: schedule.isFriday,
            fajrTime: formatCompactTime(date: schedule.fajr),
            dhuhrTime: formatCompactTime(date: schedule.dhuhr),
            asrTime: formatCompactTime(date: schedule.asr),
            maghribTime: formatCompactTime(date: schedule.maghrib),
            ishaTime: formatCompactTime(date: schedule.isha),
            themePreference: themePreference,
            isDarkFallback: isDarkFallback
        )
    }

    private func resolveState(
        at date: Date,
        schedule: PrayerSchedule,
        dhuhrLabel: String
    ) -> (title: String, targetDate: Date?, statusText: String, isCallToPrayer: Bool, activeKey: String) {
        let ordered: [(key: String, name: String, time: Date, iqamaMin: Int)] = [
            ("fajr", "الفجر", schedule.fajr, schedule.iqamaFajr),
            ("dhuhr", dhuhrLabel, schedule.dhuhr, schedule.iqamaDhuhr),
            ("asr", "العصر", schedule.asr, schedule.iqamaAsr),
            ("maghrib", "المغرب", schedule.maghrib, schedule.iqamaMaghrib),
            ("isha", "العشاء", schedule.isha, schedule.iqamaIsha),
            ("fajr", "الفجر", schedule.tomorrowFajr, schedule.iqamaFajr)
        ]

        for p in ordered {
            let adhanEnd = p.time.addingTimeInterval(2 * 60)
            let iqamaEnd = p.time.addingTimeInterval(Double(p.iqamaMin) * 60)
            let salahEnd = iqamaEnd.addingTimeInterval(12 * 60)

            if date < p.time {
                return ("صلاة \(p.name)", p.time, "بعد", false, p.key)
            } else if date < adhanEnd {
                return ("أذان \(p.name)", nil, "الآن", true, p.key)
            } else if date < iqamaEnd {
                return ("صلاة \(p.name)", iqamaEnd, "الإقامة", false, p.key)
            } else if date < salahEnd {
                return ("\(p.name) الآن", nil, "الصلاة", true, p.key)
            }
        }

        return ("صلاة الفجر", schedule.tomorrowFajr, "بعد", false, "fajr")
    }
}

extension WidgetConfiguration {
    func disableContentMarginsIfNeeded() -> some WidgetConfiguration {
        if #available(iOSApplicationExtension 17.0, *) {
            return self.contentMarginsDisabled()
        } else {
            return self
        }
    }
}

@main
struct TalibIlmWidgets: Widget {
    let kind: String = "TalibIlmWidgets"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            TalibIlmWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("مواقيت الصلاة")
        .description("متابعة الصلاة القادمة والعد التنازلي وجدول الصلوات الخمس")
        .supportedFamilies([.systemMedium, .systemLarge])
        .disableContentMarginsIfNeeded()
    }
}
