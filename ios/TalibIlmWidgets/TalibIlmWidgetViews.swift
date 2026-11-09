import WidgetKit
import SwiftUI

// MARK: - Calm Scholar Palette Helpers

private let goldColor = Color(red: 0.79, green: 0.64, blue: 0.15)
private let emeraldColor = Color(red: 0.18, green: 0.52, blue: 0.38)
private let darkBgColor = Color(red: 0.07, green: 0.08, blue: 0.09)
private let lightBgColor = Color(red: 0.98, green: 0.97, blue: 0.95)

extension View {
    @ViewBuilder
    func applyWidgetBackground(isDark: Bool) -> some View {
        let bg = isDark ? darkBgColor : lightBgColor
        if #available(iOSApplicationExtension 17.0, *) {
            self.containerBackground(for: .widget) {
                bg
            }
        } else {
            self.background(bg)
        }
    }
}

// MARK: - Small Widget View (2x2)

struct PrayerSmallWidgetView: View {
    let entry: PrayerWidgetEntry

    var body: some View {
        VStack(alignment: .trailing, spacing: 5) {
            HStack {
                Text("طالب العلم")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(goldColor)
                Spacer()
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 11))
                    .foregroundColor(goldColor)
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
                    .foregroundColor(emeraldColor)
            } else {
                Text(entry.nextPrayerName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(emeraldColor)
            }

            Spacer()

            HStack {
                Text(entry.cityName)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                Spacer()
                Text(entry.hijriDate)
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .environment(\.layoutDirection, .rightToLeft)
        .applyWidgetBackground(isDark: entry.isDark)
    }
}

// MARK: - Medium Widget View (4x2)

struct PrayerMediumWidgetView: View {
    let entry: PrayerWidgetEntry

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.hijriDate)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(goldColor)
                    Text(entry.cityName)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(entry.prayerDisplayTitle)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(emeraldColor)
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
        .applyWidgetBackground(isDark: entry.isDark)
    }

    private func prayerColumn(name: String, time: String, isNext: Bool) -> some View {
        VStack(spacing: 4) {
            Text(name)
                .font(.system(size: 11, weight: isNext ? .bold : .regular))
                .foregroundColor(isNext ? goldColor : .secondary)

            Text(time)
                .font(.system(size: 10, weight: isNext ? .bold : .medium))
                .foregroundColor(isNext ? .primary : .secondary)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isNext ? goldColor.opacity(0.18) : Color.clear)
        )
    }
}

// MARK: - Large Widget View (4x4)

struct PrayerLargeWidgetView: View {
    let entry: PrayerWidgetEntry

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.hijriDate)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(goldColor)
                    Text(entry.cityName)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(entry.prayerDisplayTitle)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(emeraldColor)
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

            // Daily Gem / Athar Card (درة اليوم)
            VStack(alignment: .trailing, spacing: 4) {
                HStack {
                    Image(systemName: "quote.opening")
                        .font(.system(size: 10))
                        .foregroundColor(goldColor)
                    Text("درة اليوم")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(goldColor)
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
                    .fill(goldColor.opacity(0.08))
            )
        }
        .padding(14)
        .environment(\.layoutDirection, .rightToLeft)
        .applyWidgetBackground(isDark: entry.isDark)
    }

    private func prayerCard(name: String, time: String, isNext: Bool) -> some View {
        VStack(spacing: 4) {
            Text(name)
                .font(.system(size: 11, weight: isNext ? .bold : .regular))
                .foregroundColor(isNext ? goldColor : .secondary)

            Text(time)
                .font(.system(size: 11, weight: isNext ? .bold : .medium))
                .foregroundColor(isNext ? .primary : .secondary)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isNext ? goldColor.opacity(0.18) : Color.clear)
        )
    }
}

