import WidgetKit
import SwiftUI

// MARK: - Safe Data Extraction & Formatters

private let appGroupId = "group.com.talibilm.app"

private func getPreferences() -> UserDefaults {
    return UserDefaults(suiteName: appGroupId) ?? UserDefaults.standard
}

private func getInt64(from prefs: UserDefaults, key: String) -> Int64? {
    if let num = prefs.object(forKey: key) as? NSNumber {
        let val = num.int64Value
        return val > 0 ? val : nil
    }
    if let str = prefs.string(forKey: key), let val = Int64(str), val > 0 {
        return val
    }
    let val = prefs.integer(forKey: key)
    return val > 0 ? Int64(val) : nil
}

private func getDate(from prefs: UserDefaults, key: String) -> Date? {
    guard let ms = getInt64(from: prefs, key: key) else { return nil }
    return Date(timeIntervalSince1970: Double(ms) / 1000.0)
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
    let fajr = getDate(from: prefs, key: "prayer_fajr_epoch_ms")
    let dhuhr = getDate(from: prefs, key: "prayer_dhuhr_epoch_ms")
    let asr = getDate(from: prefs, key: "prayer_asr_epoch_ms")
    let maghrib = getDate(from: prefs, key: "prayer_maghrib_epoch_ms")
    let isha = getDate(from: prefs, key: "prayer_isha_epoch_ms")
    let tomorrowFajr = getDate(from: prefs, key: "prayer_tomorrow_fajr_epoch_ms")

    let isFriday = prefs.bool(forKey: "is_friday")

    let iqamaFajr = prefs.integer(forKey: "iqama_fajr_min") > 0 ? prefs.integer(forKey: "iqama_fajr_min") : 25
    let iqamaDhuhr = prefs.integer(forKey: "iqama_dhuhr_min") > 0 ? prefs.integer(forKey: "iqama_dhuhr_min") : 20
    let iqamaAsr = prefs.integer(forKey: "iqama_asr_min") > 0 ? prefs.integer(forKey: "iqama_asr_min") : 20
    let iqamaMaghrib = prefs.integer(forKey: "iqama_maghrib_min") > 0 ? prefs.integer(forKey: "iqama_maghrib_min") : 10
    let iqamaIsha = prefs.integer(forKey: "iqama_isha_min") > 0 ? prefs.integer(forKey: "iqama_isha_min") : 20

    let fajrStr = prefs.string(forKey: "prayer_fajr_time_str") ?? formatTime(date: fajr)
    let dhuhrStr = prefs.string(forKey: "prayer_dhuhr_time_str") ?? formatTime(date: dhuhr)
    let asrStr = prefs.string(forKey: "prayer_asr_time_str") ?? formatTime(date: asr)
    let maghribStr = prefs.string(forKey: "prayer_maghrib_time_str") ?? formatTime(date: maghrib)
    let ishaStr = prefs.string(forKey: "prayer_isha_time_str") ?? formatTime(date: isha)

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
        let nextName = prefs.string(forKey: "next_prayer_name") ?? "الظهر"
        let displayTitle = prefs.string(forKey: "prayer_display_title") ?? "صلاة الظهر"
        let countdownPrefix = prefs.string(forKey: "countdown_prefix") ?? "بقي على الأذان"
        let nextDate = getDate(from: prefs, key: "next_prayer_epoch_ms")
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
    let isPrayerActive: Bool
}

struct PrayerTimelineProvider: TimelineProvider {
    typealias Entry = PrayerWidgetEntry

    private func buildEntry(date: Date, prefs: UserDefaults, schedule: PrayerSchedule) -> PrayerWidgetEntry {
        let evaluated = evaluatePrayer(at: date, schedule: schedule, prefs: prefs)

        let hijri = prefs.string(forKey: "hijri_date") ?? "طالب العلم"
        let city = prefs.string(forKey: "location_city") ?? "مكة المكرمة"
        let gem = prefs.string(forKey: "daily_gem_text") ?? "من سلك طريقاً يلتمس فيه علماً سهل الله له به طريقاً إلى الجنة"
        let author = prefs.string(forKey: "daily_gem_author") ?? "حديث نبوي شريف"
        let isDark = prefs.bool(forKey: "widget_is_dark")

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
            isPrayerActive: evaluated.isPrayerActive
        )
    }

    func placeholder(in context: Context) -> PrayerWidgetEntry {
        return PrayerWidgetEntry(
            date: Date(),
            nextPrayerName: "العصر",
            prayerDisplayTitle: "صلاة العصر",
            countdownPrefix: "بقي على الأذان",
            nextPrayerDate: Date().addingTimeInterval(3600),
            fajrTime: "5:12 ص",
            dhuhrTime: "12:15 م",
            asrTime: "3:30 م",
            maghribTime: "5:45 م",
            ishaTime: "7:15 م",
            hijriDate: "١٤٤٨ هـ",
            cityName: "مكة المكرمة",
            dailyGem: "العلم ما نفع، ليس العلم ما حفظ.",
            dailyGemAuthor: "الإمام الشافعي",
            isDark: false,
            isPrayerActive: false
        )
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

        // Entry 1: Current state
        entries.append(buildEntry(date: now, prefs: prefs, schedule: schedule))

        // Collect all future prayer transition points
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

        // Settle 1 second after each transition so the state switches accurately
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

// MARK: - Widget Entry View Dispatcher

struct TalibIlmWidgetsEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: PrayerTimelineProvider.Entry

    var body: some View {
        switch family {
        case .systemSmall:
            PrayerSmallWidgetView(entry: entry)
        case .systemMedium:
            PrayerMediumWidgetView(entry: entry)
        case .systemLarge:
            PrayerLargeWidgetView(entry: entry)
        default:
            PrayerSmallWidgetView(entry: entry)
        }
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
