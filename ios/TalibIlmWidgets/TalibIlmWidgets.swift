import WidgetKit
import SwiftUI

// MARK: - Model & Timeline Entry

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
}

// MARK: - Timeline Provider

struct PrayerTimelineProvider: TimelineProvider {
    typealias Entry = PrayerWidgetEntry

    private let appGroupId = "group.com.talibilm.app"

    private func getPreferences() -> UserDefaults {
        return UserDefaults(suiteName: appGroupId) ?? UserDefaults.standard
    }

    private func formatTime(epochMs: Int64?) -> String {
        guard let epoch = epochMs, epoch > 0 else { return "--:--" }
        let date = Date(timeIntervalSince1970: Double(epoch) / 1000.0)
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ar")
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }

    private func buildEntry(date: Date) -> PrayerWidgetEntry {
        let prefs = getPreferences()

        let nextPrayerName = prefs.string(forKey: "next_prayer_name") ?? "الظهر"
        let displayTitle = prefs.string(forKey: "prayer_display_title") ?? "صلاة الظهر"
        let countdownPrefix = prefs.string(forKey: "countdown_prefix") ?? "بقي على الأذان"
        let nextEpochMs = prefs.object(forKey: "next_prayer_epoch_ms") as? Int64 ?? (prefs.integer(forKey: "next_prayer_epoch_ms") > 0 ? Int64(prefs.integer(forKey: "next_prayer_epoch_ms")) : nil)
        let nextDate = nextEpochMs != nil ? Date(timeIntervalSince1970: Double(nextEpochMs!) / 1000.0) : nil

        let fajrMs = prefs.object(forKey: "prayer_fajr_epoch_ms") as? Int64
        let dhuhrMs = prefs.object(forKey: "prayer_dhuhr_epoch_ms") as? Int64
        let asrMs = prefs.object(forKey: "prayer_asr_epoch_ms") as? Int64
        let maghribMs = prefs.object(forKey: "prayer_maghrib_epoch_ms") as? Int64
        let ishaMs = prefs.object(forKey: "prayer_isha_epoch_ms") as? Int64

        let hijri = prefs.string(forKey: "hijri_date") ?? "طالب العلم"
        let city = prefs.string(forKey: "location_city") ?? "مكة المكرمة"
        let gem = prefs.string(forKey: "daily_gem_text") ?? "من سلك طريقاً يلتمس فيه علماً سهل الله له به طريقاً إلى الجنة"
        let author = prefs.string(forKey: "daily_gem_author") ?? "حديث شريف"
        let isDark = prefs.bool(forKey: "widget_is_dark")

        return PrayerWidgetEntry(
            date: date,
            nextPrayerName: nextPrayerName,
            prayerDisplayTitle: displayTitle,
            countdownPrefix: countdownPrefix,
            nextPrayerDate: nextDate,
            fajrTime: formatTime(epochMs: fajrMs),
            dhuhrTime: formatTime(epochMs: dhuhrMs),
            asrTime: formatTime(epochMs: asrMs),
            maghribTime: formatTime(epochMs: maghribMs),
            ishaTime: formatTime(epochMs: ishaMs),
            hijriDate: hijri,
            cityName: city,
            dailyGem: gem,
            dailyGemAuthor: author,
            isDark: isDark
        )
    }

    func placeholder(in context: Context) -> PrayerWidgetEntry {
        buildEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (PrayerWidgetEntry) -> Void) {
        completion(buildEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PrayerWidgetEntry>) -> Void) {
        let now = Date()
        let currentEntry = buildEntry(date: now)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: now) ?? now.addingTimeInterval(900)
        let timeline = Timeline(entries: [currentEntry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Widget Views

struct PrayerSmallWidgetView: View {
    let entry: PrayerWidgetEntry

    var body: some View {
        VStack(alignment: .trailing, spacing: 6) {
            HStack {
                Text("طالب العلم")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(red: 0.79, green: 0.64, blue: 0.15))
                Spacer()
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 12))
                    .foregroundColor(Color(red: 0.79, green: 0.64, blue: 0.15))
            }

            Spacer()

            Text(entry.prayerDisplayTitle)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.trailing)

            Text(entry.countdownPrefix)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)

            if let target = entry.nextPrayerDate, target > Date() {
                Text(target, style: .timer)
                    .font(.system(size: 18, weight: .heavy, design: .monospaced))
                    .foregroundColor(Color(red: 0.18, green: 0.52, blue: 0.38))
            } else {
                Text(entry.nextPrayerName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(red: 0.18, green: 0.52, blue: 0.38))
            }

            Spacer()

            HStack {
                Text(entry.cityName)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
        .padding(12)
        .environment(\.layoutDirection, .rightToLeft)
    }
}

struct PrayerMediumWidgetView: View {
    let entry: PrayerWidgetEntry

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.hijriDate)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(red: 0.79, green: 0.64, blue: 0.15))
                    Text(entry.cityName)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(entry.prayerDisplayTitle)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(red: 0.18, green: 0.52, blue: 0.38))
                    if let target = entry.nextPrayerDate, target > Date() {
                        Text(target, style: .timer)
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundColor(.primary)
                    }
                }
            }

            Divider()

            HStack(spacing: 4) {
                prayerColumn(name: "الفجر", time: entry.fajrTime, isNext: entry.nextPrayerName == "الفجر")
                prayerColumn(name: "الظهر", time: entry.dhuhrTime, isNext: entry.nextPrayerName == "الظهر" || entry.nextPrayerName == "الجمعة")
                prayerColumn(name: "العصر", time: entry.asrTime, isNext: entry.nextPrayerName == "العصر")
                prayerColumn(name: "المغرب", time: entry.maghribTime, isNext: entry.nextPrayerName == "المغرب")
                prayerColumn(name: "العشاء", time: entry.ishaTime, isNext: entry.nextPrayerName == "العشاء")
            }
        }
        .padding(12)
        .environment(\.layoutDirection, .rightToLeft)
    }

    private func prayerColumn(name: String, time: String, isNext: Bool) -> some View {
        VStack(spacing: 4) {
            Text(name)
                .font(.system(size: 11, weight: isNext ? .bold : .regular))
                .foregroundColor(isNext ? Color(red: 0.79, green: 0.64, blue: 0.15) : .secondary)

            Text(time)
                .font(.system(size: 10, weight: isNext ? .bold : .medium))
                .foregroundColor(isNext ? .primary : .secondary)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isNext ? Color(red: 0.79, green: 0.64, blue: 0.15).opacity(0.15) : Color.clear)
        )
    }
}

struct PrayerLargeWidgetView: View {
    let entry: PrayerWidgetEntry

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.hijriDate)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color(red: 0.79, green: 0.64, blue: 0.15))
                    Text(entry.cityName)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(entry.prayerDisplayTitle)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color(red: 0.18, green: 0.52, blue: 0.38))
                    if let target = entry.nextPrayerDate, target > Date() {
                        Text(target, style: .timer)
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(.primary)
                    }
                }
            }

            Divider()

            HStack(spacing: 4) {
                prayerCard(name: "الفجر", time: entry.fajrTime, isNext: entry.nextPrayerName == "الفجر")
                prayerCard(name: "الظهر", time: entry.dhuhrTime, isNext: entry.nextPrayerName == "الظهر" || entry.nextPrayerName == "الجمعة")
                prayerCard(name: "العصر", time: entry.asrTime, isNext: entry.nextPrayerName == "العصر")
                prayerCard(name: "المغرب", time: entry.maghribTime, isNext: entry.nextPrayerName == "المغرب")
                prayerCard(name: "العشاء", time: entry.ishaTime, isNext: entry.nextPrayerName == "العشاء")
            }

            Spacer()

            // Daily Gem / Athar Card
            VStack(alignment: .trailing, spacing: 4) {
                HStack {
                    Image(systemName: "quote.opening")
                        .font(.system(size: 10))
                        .foregroundColor(Color(red: 0.79, green: 0.64, blue: 0.15))
                    Text("درة اليوم")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(red: 0.79, green: 0.64, blue: 0.15))
                    Spacer()
                }

                Text(entry.dailyGem)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.primary)
                    .lineLimit(3)
                    .multilineTextAlignment(.trailing)

                Text("— " + entry.dailyGemAuthor)
                    .font(.system(size: 10, weight: .light))
                    .foregroundColor(.secondary)
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(red: 0.79, green: 0.64, blue: 0.15).opacity(0.08))
            )
        }
        .padding(14)
        .environment(\.layoutDirection, .rightToLeft)
    }

    private func prayerCard(name: String, time: String, isNext: Bool) -> some View {
        VStack(spacing: 4) {
            Text(name)
                .font(.system(size: 11, weight: isNext ? .bold : .regular))
                .foregroundColor(isNext ? Color(red: 0.79, green: 0.64, blue: 0.15) : .secondary)

            Text(time)
                .font(.system(size: 11, weight: isNext ? .bold : .medium))
                .foregroundColor(isNext ? .primary : .secondary)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isNext ? Color(red: 0.79, green: 0.64, blue: 0.15).opacity(0.18) : Color.clear)
        )
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
