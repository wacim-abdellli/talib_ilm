import WidgetKit
import SwiftUI
import AppIntents
import Security

// MARK: - AppIntents Widget Configuration (Edit Widget Directly on iOS Home Screen)

enum WidgetThemeChoice: String, AppEnum {
    case auto
    case light
    case dark

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "المظهر")
    static var caseDisplayRepresentations: [WidgetThemeChoice: DisplayRepresentation] = [
        .auto: DisplayRepresentation(title: "تلقائي (من التطبيق والنظام)"),
        .light: DisplayRepresentation(title: "فاتح (أبيض)"),
        .dark: DisplayRepresentation(title: "داكن (أسود)")
    ]
}

enum WidgetCityChoice: String, AppEnum {
    case auto
    case sfax
    case tunis
    case sousse
    case kairouan
    case bizerte
    case gabes
    case makkah
    case madinah
    case riyadh
    case jeddah
    case cairo
    case alexandria
    case algiers
    case oran
    case rabat
    case casablanca
    case amman
    case jerusalem
    case doha
    case dubai
    case kuwait
    case baghdad
    case damascus
    case beirut
    case istanbul
    case paris
    case london

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "المدينة")
    static var caseDisplayRepresentations: [WidgetCityChoice: DisplayRepresentation] = [
        .auto: DisplayRepresentation(title: "تلقائي (من التطبيق)"),
        .sfax: DisplayRepresentation(title: "صفاقس"),
        .tunis: DisplayRepresentation(title: "تونس"),
        .sousse: DisplayRepresentation(title: "سوسة"),
        .kairouan: DisplayRepresentation(title: "القيروان"),
        .bizerte: DisplayRepresentation(title: "بنزرت"),
        .gabes: DisplayRepresentation(title: "قابس"),
        .makkah: DisplayRepresentation(title: "مكة المكرمة"),
        .madinah: DisplayRepresentation(title: "المدينة المنورة"),
        .riyadh: DisplayRepresentation(title: "الرياض"),
        .jeddah: DisplayRepresentation(title: "جدة"),
        .cairo: DisplayRepresentation(title: "القاهرة"),
        .alexandria: DisplayRepresentation(title: "الإسكندرية"),
        .algiers: DisplayRepresentation(title: "الجزائر العاصمة"),
        .oran: DisplayRepresentation(title: "وهران"),
        .rabat: DisplayRepresentation(title: "الرباط"),
        .casablanca: DisplayRepresentation(title: "الدار البيضاء"),
        .amman: DisplayRepresentation(title: "عمّان"),
        .jerusalem: DisplayRepresentation(title: "القدس"),
        .doha: DisplayRepresentation(title: "الدوحة"),
        .dubai: DisplayRepresentation(title: "دبي"),
        .kuwait: DisplayRepresentation(title: "الكويت"),
        .baghdad: DisplayRepresentation(title: "بغداد"),
        .damascus: DisplayRepresentation(title: "دمشق"),
        .beirut: DisplayRepresentation(title: "بيروت"),
        .istanbul: DisplayRepresentation(title: "إسطنبول"),
        .paris: DisplayRepresentation(title: "باريس"),
        .london: DisplayRepresentation(title: "لندن")
    ]

    var metadata: (name: String, lat: Double, lon: Double, country: String, tz: Double)? {
        switch self {
        case .auto: return nil
        case .sfax: return ("صفاقس", 34.7406, 10.7603, "TN", 1.0)
        case .tunis: return ("تونس", 36.8065, 10.1815, "TN", 1.0)
        case .sousse: return ("سوسة", 35.8256, 10.6369, "TN", 1.0)
        case .kairouan: return ("القيروان", 35.6781, 10.0963, "TN", 1.0)
        case .bizerte: return ("بنزرت", 37.2744, 9.8739, "TN", 1.0)
        case .gabes: return ("قابس", 33.8815, 10.0982, "TN", 1.0)
        case .makkah: return ("مكة المكرمة", 21.4225, 39.8262, "SA", 3.0)
        case .madinah: return ("المدينة المنورة", 24.4672, 39.6112, "SA", 3.0)
        case .riyadh: return ("الرياض", 24.7136, 46.6753, "SA", 3.0)
        case .jeddah: return ("جدة", 21.4858, 39.1925, "SA", 3.0)
        case .cairo: return ("القاهرة", 30.0444, 31.2357, "EG", 2.0)
        case .alexandria: return ("الإسكندرية", 31.2001, 29.9187, "EG", 2.0)
        case .algiers: return ("الجزائر العاصمة", 36.7538, 3.0588, "DZ", 1.0)
        case .oran: return ("وهران", 35.6971, -0.6308, "DZ", 1.0)
        case .rabat: return ("الرباط", 34.0209, -6.8416, "MA", 1.0)
        case .casablanca: return ("الدار البيضاء", 33.5731, -7.5898, "MA", 1.0)
        case .amman: return ("عمّان", 31.9454, 35.9284, "JO", 3.0)
        case .jerusalem: return ("القدس", 31.7683, 35.2137, "PS", 2.0)
        case .doha: return ("الدوحة", 25.2854, 51.5310, "QA", 3.0)
        case .dubai: return ("دبي", 25.2048, 55.2708, "AE", 4.0)
        case .kuwait: return ("الكويت", 29.3759, 47.9774, "KW", 3.0)
        case .baghdad: return ("بغداد", 33.3152, 44.3661, "IQ", 3.0)
        case .damascus: return ("دمشق", 33.5138, 36.2765, "SY", 3.0)
        case .beirut: return ("بيروت", 33.8938, 35.5018, "LB", 2.0)
        case .istanbul: return ("إسطنبول", 41.0082, 28.9784, "TR", 3.0)
        case .paris: return ("باريس", 48.8566, 2.3522, "FR", 1.0)
        case .london: return ("لندن", 51.5072, -0.1276, "GB", 0.0)
        }
    }
}

struct TalibPrayerWidgetIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "تخصيص ودجت الصلاة"
    static var description = IntentDescription("تحكم في المظهر والمدينة مباشرة من الويدجت أو اتركهما تلقائيين للمزامنة مع التطبيق")

    @Parameter(title: "المظهر", default: .auto)
    var themeMode: WidgetThemeChoice

    @Parameter(title: "المدينة", default: .auto)
    var cityOverride: WidgetCityChoice

    init() {}

    init(themeMode: WidgetThemeChoice, cityOverride: WidgetCityChoice) {
        self.themeMode = themeMode
        self.cityOverride = cityOverride
    }
}

// MARK: - Safe Data Extraction, App Group Discovery & Keychain Bridge

private let appGroupId = "group.com.talibilm.app"
private let sharedSnapshotFileName = "talib_widget_snapshot.json"
private let keychainService = "com.talibilm.app.widgetSnapshot"
private let keychainAccount = "snapshot_v1"

private func readProvisionPlists() -> [[String: Any]] {
    var result: [[String: Any]] = []
    let bundle = Bundle.main
    let possiblePaths = [
        bundle.path(forResource: "embedded", ofType: "mobileprovision"),
        bundle.bundleURL.appendingPathComponent("embedded.mobileprovision").path,
        bundle.bundleURL.deletingLastPathComponent().appendingPathComponent("embedded.mobileprovision").path,
        bundle.bundleURL.deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("embedded.mobileprovision").path
    ]
    for pathOpt in possiblePaths {
        guard let p = pathOpt,
              let data = try? Data(contentsOf: URL(fileURLWithPath: p)) else { continue }
        let decoded = String(decoding: data, as: UTF8.self)
        guard let plistStart = decoded.range(of: "<plist"),
              let plistEnd = decoded.range(of: "</plist>") else { continue }
        let xmlString = String(decoded[plistStart.lowerBound..<plistEnd.upperBound])
        guard let xmlData = xmlString.data(using: .utf8),
              let plist = try? PropertyListSerialization.propertyList(
                from: xmlData,
                options: [],
                format: nil
              ) as? [String: Any] else { continue }
        result.append(plist)
    }
    return result
}

private func getProvisionedAppGroups() -> [String] {
    var groups: [String] = []
    for plist in readProvisionPlists() {
        guard let entitlements = plist["Entitlements"] as? [String: Any],
              let appGroups = entitlements["com.apple.security.application-groups"] as? [String] else {
            continue
        }
        for group in appGroups {
            let trimmed = group.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty && !groups.contains(trimmed) {
                groups.append(trimmed)
            }
        }
    }
    return groups
}

private func discoverKeychainAccessGroups() -> [String] {
    var groups: [String] = []
    for plist in readProvisionPlists() {
        let entitlements = plist["Entitlements"] as? [String: Any]
        if let kcGroups = entitlements?["keychain-access-groups"] as? [String] {
            for g in kcGroups {
                let trimmed = g.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.hasSuffix(".*") {
                    let prefix = String(trimmed.dropLast(1))
                    let explicit = "\(prefix)com.talibilm.app.shared"
                    if !groups.contains(explicit) { groups.append(explicit) }
                } else if !trimmed.isEmpty && !groups.contains(trimmed) {
                    groups.append(trimmed)
                }
            }
        }
        if let prefixes = plist["ApplicationIdentifierPrefix"] as? [String],
           let teamPrefix = prefixes.first, !teamPrefix.isEmpty {
            let explicit = "\(teamPrefix).com.talibilm.app.shared"
            if !groups.contains(explicit) { groups.append(explicit) }
        }
        if let appId = entitlements?["application-identifier"] as? String,
           let dotIdx = appId.firstIndex(of: ".") {
            let teamPrefix = String(appId[..<dotIdx])
            let explicit = "\(teamPrefix).com.talibilm.app.shared"
            if !groups.contains(explicit) { groups.append(explicit) }
        }
    }
    let fallbackTeam = "V3N9W8G24A.com.talibilm.app.shared"
    if !groups.contains(fallbackTeam) {
        groups.append(fallbackTeam)
    }
    return groups
}

private func candidateAppGroups() -> [String] {
    var candidates = getProvisionedAppGroups()
    if !candidates.contains(appGroupId) {
        candidates.append(appGroupId)
    }
    if let bundleId = Bundle.main.bundleIdentifier {
        let baseApp = bundleId
            .replacingOccurrences(of: ".widgets", with: "")
            .replacingOccurrences(of: ".Widgets", with: "")
        let dynamicGroup = "group.\(baseApp)"
        if !candidates.contains(dynamicGroup) {
            candidates.append(dynamicGroup)
        }
    }
    return candidates
}

private func getPreferences() -> UserDefaults {
    let candidates = candidateAppGroups()

    for group in candidates {
        if FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: group) != nil,
           let userDefaults = UserDefaults(suiteName: group) {
            if userDefaults.object(forKey: "prayer_data_json") != nil ||
               userDefaults.object(forKey: "prayer_fajr_epoch_ms") != nil ||
               userDefaults.object(forKey: "prayer_widget_theme_mode") != nil {
                return userDefaults
            }
        }
    }

    for group in candidates {
        if let userDefaults = UserDefaults(suiteName: group) {
            if userDefaults.object(forKey: "prayer_data_json") != nil ||
               userDefaults.object(forKey: "prayer_fajr_epoch_ms") != nil ||
               userDefaults.object(forKey: "next_prayer_name") != nil {
                return userDefaults
            }
        }
    }

    for group in candidates {
        if FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: group) != nil,
           let userDefaults = UserDefaults(suiteName: group) {
            return userDefaults
        }
    }

    return UserDefaults.standard
}

private func snapshotTimestamp(_ dict: [String: Any]?) -> Int64 {
    guard let dict = dict else { return 0 }
    if let updated = dict["updated_at_epoch_ms"] as? NSNumber {
        return updated.int64Value
    }
    if let ver = dict["version"] as? NSNumber {
        return ver.int64Value
    }
    return 1
}

/// Loads the newest JSON payload across App Group container file, Shared Keychain, and UserDefaults.
private func loadJsonPayload(from prefs: UserDefaults) -> [String: Any]? {
    var bestDict: [String: Any]? = nil
    var bestScore: Int64 = -1

    for group in candidateAppGroups() {
        if let containerUrl = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: group) {
            let fileUrl = containerUrl.appendingPathComponent(sharedSnapshotFileName)
            if let data = try? Data(contentsOf: fileUrl),
               let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                let score = snapshotTimestamp(dict)
                if score > bestScore {
                    bestScore = score
                    bestDict = dict
                }
            }
        }

        if let groupDefaults = UserDefaults(suiteName: group),
           let jsonStr = groupDefaults.string(forKey: "prayer_data_json"),
           let data = jsonStr.data(using: .utf8),
           let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            let score = snapshotTimestamp(dict)
            if score > bestScore {
                bestScore = score
                bestDict = dict
            }
        }
    }

    for kcGroup in discoverKeychainAccessGroups() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecAttrAccessGroup as String: kcGroup,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecSuccess,
           let data = item as? Data,
           let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            let score = snapshotTimestamp(dict)
            if score > bestScore {
                bestScore = score
                bestDict = dict
            }
        }
    }

    if let jsonStr = prefs.string(forKey: "prayer_data_json"),
       let data = jsonStr.data(using: .utf8),
       let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
        let score = snapshotTimestamp(dict)
        if score > bestScore {
            bestDict = dict
        }
    }

    return bestDict
}

private func getInt64(from prefs: UserDefaults, json: [String: Any]?, key: String, prayerSlug: String? = nil) -> Int64? {
    if let json = json {
        if let num = json[key] as? NSNumber, num.int64Value > 0 {
            return num.int64Value
        }
        if let str = json[key] as? String, let v = Int64(str), v > 0 {
            return v
        }
        if let prayers = json["prayers"] as? [String: Any] {
            if let num = prayers[key] as? NSNumber, num.int64Value > 0 {
                return num.int64Value
            }
            if key == "prayer_tomorrow_fajr_epoch_ms",
               let num = prayers["tomorrow_fajr_epoch_ms"] as? NSNumber,
               num.int64Value > 0 {
                return num.int64Value
            }
            if let slug = prayerSlug,
               let pDict = prayers[slug] as? [String: Any],
               let num = pDict["epoch_ms"] as? NSNumber,
               num.int64Value > 0 {
                return num.int64Value
            }
        }
    }

    if let num = prefs.object(forKey: key) as? NSNumber {
        let val = num.int64Value
        if val > 0 { return val }
    }
    if let str = prefs.string(forKey: key), let val = Int64(str), val > 0 {
        return val
    }
    let val = prefs.integer(forKey: key)
    if val > 0 { return Int64(val) }

    return nil
}

private func getInt(from prefs: UserDefaults, json: [String: Any]?, key: String) -> Int? {
    if let json = json {
        if let num = json[key] as? NSNumber { return num.intValue }
        if let str = json[key] as? String, let v = Int(str) { return v }
    }
    if let num = prefs.object(forKey: key) as? NSNumber {
        return num.intValue
    }
    return nil
}

private func getBool(from prefs: UserDefaults, json: [String: Any]?, key: String) -> Bool? {
    if let json = json, let b = json[key] as? Bool {
        return b
    }
    if let num = prefs.object(forKey: key) as? NSNumber {
        return num.boolValue
    }
    return nil
}

private func getString(from prefs: UserDefaults, json: [String: Any]?, key: String, jsonFallbackKey: String? = nil) -> String? {
    if let json = json {
        if let s = (json[key] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty {
            return s
        }
        if let fb = jsonFallbackKey,
           let s = (json[fb] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty {
            return s
        }
    }
    if let s = prefs.string(forKey: key)?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty {
        return s
    }
    return nil
}

private func getDate(from prefs: UserDefaults, json: [String: Any]?, key: String, prayerSlug: String? = nil) -> Date? {
    guard let ms = getInt64(from: prefs, json: json, key: key, prayerSlug: prayerSlug) else { return nil }
    return dateFromEpoch(ms)
}

private func dateFromEpoch(_ ms: Int64) -> Date {
    if ms > 10_000_000_000 {
        return Date(timeIntervalSince1970: Double(ms) / 1000.0)
    } else {
        return Date(timeIntervalSince1970: Double(ms))
    }
}

private func dateKeyString(for date: Date) -> String {
    let cal = Calendar(identifier: .gregorian)
    let comps = cal.dateComponents([.year, .month, .day], from: date)
    let y = comps.year ?? 2026
    let m = comps.month ?? 1
    let d = comps.day ?? 1
    return String(format: "%04d-%02d-%02d", y, m, d)
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
    static func calculate(
        date: Date,
        latitude: Double,
        longitude: Double,
        timezoneOffsetHours: Double,
        isTunisia: Bool = false,
        isHanafi: Bool = false,
        countryCode: String = ""
    ) -> [String: Date] {
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

        let solarNoonHours = 12.0 + effectiveTz - (longitude / 15.0) - (eotMinutes / 60.0)
        let latRad = latitude * .pi / 180.0

        func hourAngle(forAltitude altitudeDeg: Double) -> Double? {
            let altRad = altitudeDeg * .pi / 180.0
            let cosH = (sin(altRad) - sin(latRad) * sin(declination)) / (cos(latRad) * cos(declination))
            if cosH < -1.0 || cosH > 1.0 { return nil }
            return acos(cosH) * 180.0 / .pi
        }

        // Round to nearest minute cleanly, matching adhan-dart PrayerTimes behavior
        func dateFromHours(_ hours: Double) -> Date {
            var adjustedHours = hours.truncatingRemainder(dividingBy: 24.0)
            if adjustedHours < 0 { adjustedHours += 24.0 }
            let totalMinutes = Int((adjustedHours * 60.0).rounded()) % 1440
            comp.hour = totalMinutes / 60
            comp.minute = totalMinutes % 60
            comp.second = 0
            return calendar.date(from: comp) ?? date
        }

        let (fajrAngle, ishaAngle): (Double, Double) = {
            switch countryCode {
            case "EG", "SD", "LY", "SY", "LB", "JO", "PS":
                return (-19.5, -17.5)
            case "SA", "YE":
                return (-18.5, -18.5)
            case "AE", "QA", "KW":
                return (-18.2, -18.2)
            default:
                return (-18.0, -18.0)
            }
        }()

        guard let hSunrise = hourAngle(forAltitude: -0.8333),
              let hFajr = hourAngle(forAltitude: fajrAngle) else {
            return [:]
        }

        let hIsha = hourAngle(forAltitude: ishaAngle) ?? hSunrise
        let shadowFactor = isHanafi ? 2.0 : 1.0
        let asrAltRad = atan(1.0 / (shadowFactor + tan(abs(latRad - declination))))
        let asrAltDeg = asrAltRad * 180.0 / .pi
        let hAsr = hourAngle(forAltitude: asrAltDeg) ?? 45.0

        let dhuhrPrecautionMin = isTunisia ? 6.0 : 2.0
        let asrPrecautionMin = isTunisia ? 1.0 : 0.0
        let maghribPrecautionMin = isTunisia ? 3.0 : 2.0
        let ishaPrecautionMin = isTunisia ? 1.0 : 1.0

        let fajrDate = dateFromHours(solarNoonHours - (hFajr / 15.0))
        let dhuhrDate = dateFromHours(solarNoonHours + (dhuhrPrecautionMin / 60.0))
        let asrDate = dateFromHours(solarNoonHours + (hAsr / 15.0) + (asrPrecautionMin / 60.0))
        let maghribDate = dateFromHours(solarNoonHours + (hSunrise / 15.0) + (maghribPrecautionMin / 60.0))
        let ishaDate: Date = {
            if countryCode == "SA" || countryCode == "YE" || countryCode == "QA" {
                return maghribDate.addingTimeInterval(90 * 60)
            }
            return dateFromHours(solarNoonHours + (hIsha / 15.0) + (ishaPrecautionMin / 60.0))
        }()

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
    let dayHijriDate: String?
}

private func findScheduledDay(
    in json: [String: Any]?,
    for date: Date
) -> [String: Any]? {
    guard let daysMap = json?["schedule_days"] as? [String: Any] else {
        return nil
    }
    let key = dateKeyString(for: date)
    return daysMap[key] as? [String: Any]
}

private func epochDate(in dict: [String: Any]?, key: String) -> Date? {
    guard let dict = dict else { return nil }
    if let num = dict[key] as? NSNumber, num.int64Value > 0 {
        return dateFromEpoch(num.int64Value)
    }
    if let str = dict[key] as? String, let val = Int64(str), val > 0 {
        return dateFromEpoch(val)
    }
    return nil
}

private func loadSchedule(
    from prefs: UserDefaults,
    json: [String: Any]?,
    cityOverride: WidgetCityChoice = .auto,
    for date: Date = Date()
) -> PrayerSchedule {
    let cal = Calendar.current
    let nextDay = cal.date(byAdding: .day, value: 1, to: date) ?? date.addingTimeInterval(86400)

    var fajr: Date?
    var dhuhr: Date?
    var asr: Date?
    var maghrib: Date?
    var isha: Date?
    var tomorrowFajr: Date?
    var dayHijri: String?
    var dayIsFriday: Bool?

    let forcedCityMeta = cityOverride.metadata

    if forcedCityMeta == nil {
        if let dayEntry = findScheduledDay(in: json, for: date) {
            fajr = epochDate(in: dayEntry, key: "fajr_epoch_ms")
            dhuhr = epochDate(in: dayEntry, key: "dhuhr_epoch_ms")
            asr = epochDate(in: dayEntry, key: "asr_epoch_ms")
            maghrib = epochDate(in: dayEntry, key: "maghrib_epoch_ms")
            isha = epochDate(in: dayEntry, key: "isha_epoch_ms")
            dayHijri = dayEntry["hijri"] as? String
            dayIsFriday = dayEntry["is_friday"] as? Bool
        }

        if let nextEntry = findScheduledDay(in: json, for: nextDay) {
            tomorrowFajr = epochDate(in: nextEntry, key: "fajr_epoch_ms")
        }

        if fajr == nil || dhuhr == nil || asr == nil || maghrib == nil || isha == nil {
            fajr = getDate(from: prefs, json: json, key: "prayer_fajr_epoch_ms", prayerSlug: "fajr")
            dhuhr = getDate(from: prefs, json: json, key: "prayer_dhuhr_epoch_ms", prayerSlug: "dhuhr")
            asr = getDate(from: prefs, json: json, key: "prayer_asr_epoch_ms", prayerSlug: "asr")
            maghrib = getDate(from: prefs, json: json, key: "prayer_maghrib_epoch_ms", prayerSlug: "maghrib")
            isha = getDate(from: prefs, json: json, key: "prayer_isha_epoch_ms", prayerSlug: "isha")
        }

        if tomorrowFajr == nil {
            tomorrowFajr = getDate(from: prefs, json: json, key: "prayer_tomorrow_fajr_epoch_ms")
        }
    }

    let scheduleValidForDate: Bool = {
        if forcedCityMeta != nil { return false }
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
        var lat = forcedCityMeta?.lat ?? prefs.double(forKey: "location_latitude")
        var lon = forcedCityMeta?.lon ?? prefs.double(forKey: "location_longitude")
        if forcedCityMeta == nil, let json = json {
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
        let countryCode = forcedCityMeta?.country
            ?? (getString(from: prefs, json: json, key: "country_code")?.uppercased() ?? "")
        let city = forcedCityMeta?.name
            ?? (getString(from: prefs, json: json, key: "location_city", jsonFallbackKey: "city") ?? "")
        let calcMethod = getString(from: prefs, json: json, key: "calculation_method") ?? ""
        let madhab = getString(from: prefs, json: json, key: "madhab") ?? ""
        let localeStr = Locale.current.identifier
        let isTunisia = countryCode == "TN" || (forcedCityMeta == nil && (calcMethod == "tunisia" || city.contains("تونس") || city.contains("صفاقس") || (countryCode.isEmpty && localeStr.contains("TN"))))
        let isHanafi = madhab == "hanafi"

        let systemTz = Double(TimeZone.current.secondsFromGMT(for: date)) / 3600.0
        let tzOffset: Double = {
            if let meta = forcedCityMeta, abs(systemTz - meta.tz) > 1.5 {
                return meta.tz
            }
            return systemTz
        }()

        let calcToday = OfflinePrayerCalculator.calculate(
            date: date,
            latitude: lat,
            longitude: lon,
            timezoneOffsetHours: tzOffset,
            isTunisia: isTunisia,
            isHanafi: isHanafi,
            countryCode: countryCode
        )
        let calcTomorrow = OfflinePrayerCalculator.calculate(
            date: nextDay,
            latitude: lat,
            longitude: lon,
            timezoneOffsetHours: tzOffset,
            isTunisia: isTunisia,
            isHanafi: isHanafi,
            countryCode: countryCode
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
        if let f = dayIsFriday { return f }
        if scheduleValidForDate, let prefFriday = getBool(from: prefs, json: json, key: "is_friday") {
            return prefFriday
        }
        return cal.component(.weekday, from: safeDhuhr) == 6
    }()

    let iqamaFajr = getInt(from: prefs, json: json, key: "iqama_fajr_min").flatMap { $0 > 0 ? $0 : nil } ?? 25
    let iqamaDhuhr = getInt(from: prefs, json: json, key: "iqama_dhuhr_min").flatMap { $0 > 0 ? $0 : nil } ?? (isFriday ? 25 : 20)
    let iqamaAsr = getInt(from: prefs, json: json, key: "iqama_asr_min").flatMap { $0 > 0 ? $0 : nil } ?? 20
    let iqamaMaghrib = getInt(from: prefs, json: json, key: "iqama_maghrib_min").flatMap { $0 > 0 ? $0 : nil } ?? 10
    let iqamaIsha = getInt(from: prefs, json: json, key: "iqama_isha_min").flatMap { $0 > 0 ? $0 : nil } ?? 15

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
        isFromTodayPrefs: scheduleValidForDate,
        dayHijriDate: dayHijri
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

struct Provider: AppIntentTimelineProvider {
    typealias Entry = PrayerEntry
    typealias Intent = TalibPrayerWidgetIntent

    func placeholder(in context: Context) -> PrayerEntry {
        let now = Date()
        let prefs = getPreferences()
        let json = loadJsonPayload(from: prefs)
        let schedule = loadSchedule(from: prefs, json: json, for: now)
        return buildEntry(for: now, schedule: schedule, prefs: prefs, json: json, config: TalibPrayerWidgetIntent())
    }

    func snapshot(for configuration: TalibPrayerWidgetIntent, in context: Context) async -> PrayerEntry {
        let now = Date()
        let prefs = getPreferences()
        let json = loadJsonPayload(from: prefs)
        let schedule = loadSchedule(from: prefs, json: json, cityOverride: configuration.cityOverride, for: now)
        return buildEntry(for: now, schedule: schedule, prefs: prefs, json: json, config: configuration)
    }

    func timeline(for configuration: TalibPrayerWidgetIntent, in context: Context) async -> Timeline<PrayerEntry> {
        let now = Date()
        let prefs = getPreferences()
        let json = loadJsonPayload(from: prefs)
        let schedule = loadSchedule(from: prefs, json: json, cityOverride: configuration.cityOverride, for: now)

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
                : loadSchedule(from: prefs, json: json, cityOverride: configuration.cityOverride, for: entryDate)
            entries.append(
                buildEntry(
                    for: entryDate,
                    schedule: entrySchedule,
                    prefs: prefs,
                    json: json,
                    config: configuration
                )
            )
        }

        if entries.isEmpty {
            entries.append(buildEntry(for: now, schedule: schedule, prefs: prefs, json: json, config: configuration))
        }

        let nextRefresh = min(
            now.addingTimeInterval(30 * 60),
            schedule.tomorrowFajr.addingTimeInterval(60)
        )
        return Timeline(entries: entries, policy: .after(nextRefresh))
    }

    private func buildEntry(
        for date: Date,
        schedule: PrayerSchedule,
        prefs: UserDefaults,
        json: [String: Any]?,
        config: TalibPrayerWidgetIntent
    ) -> PrayerEntry {
        let dhuhrLabel = schedule.isFriday ? "الجمعة" : "الظهر"

        let rawHijri: String = {
            if let dayH = schedule.dayHijriDate, !dayH.isEmpty {
                return dayH
            }
            if schedule.isFromTodayPrefs {
                return getString(from: prefs, json: json, key: "hijri_date", jsonFallbackKey: "hijri") ?? ""
            }
            return ""
        }()
        let cleanHijri = rawHijri
            .replacingOccurrences(of: #"\s*\d{4}\s*هـ?"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let hijriDate = cleanHijri.isEmpty ? formatUmmAlQuraHijri(for: date) : cleanHijri

        let locationName = config.cityOverride.metadata?.name
            ?? getString(from: prefs, json: json, key: "location_city", jsonFallbackKey: "city")
            ?? "مكة المكرمة"

        let isDarkFallback = getBool(from: prefs, json: json, key: "widget_is_dark") ?? false
        let rawMode = getString(from: prefs, json: json, key: "prayer_widget_theme_mode") ?? "auto"
        let appMode = getString(from: prefs, json: json, key: "theme_mode") ?? "system"
        let userSelectedWidget = getBool(from: prefs, json: json, key: "widget_theme_user_selected") ?? false

        let themePreference: String = {
            switch config.themeMode {
            case .light: return "light"
            case .dark: return "dark"
            case .auto: break
            }
            if rawMode == "light" { return "light" }
            if rawMode == "dark" {
                if !userSelectedWidget && appMode == "light" {
                    return "light"
                }
                return "dark"
            }
            if appMode == "light" { return "light" }
            if appMode == "dark" { return "dark" }
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
        AppIntentConfiguration(
            kind: kind,
            intent: TalibPrayerWidgetIntent.self,
            provider: Provider()
        ) { entry in
            TalibIlmWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("مواقيت الصلاة")
        .description("متابعة الصلاة القادمة والعد التنازلي وجدول الصلوات الخمس")
        .supportedFamilies([.systemMedium, .systemLarge])
        .disableContentMarginsIfNeeded()
    }
}
