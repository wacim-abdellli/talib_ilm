import SwiftUI
import WidgetKit

// These values mirror AppPalette's existing light and dark widget tokens.
private struct WidgetPalette {
    let background: Color
    let surface: Color
    let inset: Color
    let text: Color
    let muted: Color
    let accent: Color
    let accentSoft: Color
    let accentInk: Color
    let prayer: Color

    init(isDark: Bool) {
        if isDark {
            background = Color(hex: 0xFF000000)
            surface = Color(hex: 0xFF070707)
            inset = Color(hex: 0xFF090909)
            text = Color(hex: 0xFFFAF8F5)
            muted = Color(hex: 0xFFA8A096)
            accent = Color(hex: 0xFFFBBF24)
            accentSoft = Color(hex: 0xFF1E170A)
            accentInk = Color(hex: 0xFFFDE68A)
            prayer = Color(hex: 0xFF34D399)
        } else {
            background = Color(hex: 0xFFFAF8F5)
            surface = Color(hex: 0xFFFFFFFF)
            inset = Color(hex: 0xFFF4EFE6)
            text = Color(hex: 0xFF1C1917)
            muted = Color(hex: 0xFF5E574E)
            accent = Color(hex: 0xFFB45309)
            accentSoft = Color(hex: 0xFFFEF3C7)
            accentInk = Color(hex: 0xFF713F08)
            prayer = Color(hex: 0xFF047857)
        }
    }
}

private extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: Double((hex >> 24) & 0xFF) / 255
        )
    }
}

private extension PrayerWidgetEntry {
    func resolvedDarkMode(for systemScheme: ColorScheme) -> Bool {
        if widgetThemeMode == "dark" { return true }
        if widgetThemeMode == "light" { return false }
        if appThemeMode == "dark" { return true }
        if appThemeMode == "light" { return false }
        if appThemeMode == "system" { return systemScheme == .dark }
        return isDark
    }
}

private extension View {
    @ViewBuilder
    func widgetBackground(_ color: Color) -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            containerBackground(for: .widget) { color }
        } else {
            background(color)
        }
    }
}

private struct PrayerSmallWidgetView: View {
    let entry: PrayerWidgetEntry
    let palette: WidgetPalette

    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            HStack(spacing: 6) {
                Text("طالب العلم")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(palette.accent)
                Spacer(minLength: 4)
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(palette.accent)
            }

            Spacer(minLength: 8)

            Text(entry.prayerDisplayTitle)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(palette.text)
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            Text(entry.countdownPrefix)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(palette.muted)
                .lineLimit(1)

            if let target = entry.nextPrayerDate, target > entry.date {
                Text(target, style: .timer)
                    .font(.system(size: 23, weight: .bold, design: .rounded))
                    .foregroundColor(palette.prayer)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            } else if entry.isPrayerActive {
                Text("حان الآن")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(palette.prayer)
                    .lineLimit(1)
            } else {
                Text(entry.nextPrayerName)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(palette.prayer)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            Text(entry.cityName)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(palette.muted)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
    }
}

private struct PrayerMediumWidgetView: View {
    let entry: PrayerWidgetEntry
    let palette: WidgetPalette

    var body: some View {
        VStack(spacing: 9) {
            HStack(alignment: .center, spacing: 8) {
                VStack(alignment: .trailing, spacing: 3) {
                    Text(entry.cityName)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(palette.text)
                        .lineLimit(1)
                    Text(entry.hijriDate)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(palette.muted)
                        .lineLimit(1)
                }
                Spacer(minLength: 6)
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(palette.accent)
            }

            FeaturedPrayerBlock(entry: entry, palette: palette, prominent: false)
            PrayerTimesRow(entry: entry, palette: palette, prominent: false)
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct PrayerLargeWidgetView: View {
    let entry: PrayerWidgetEntry
    let palette: WidgetPalette

    var body: some View {
        VStack(alignment: .trailing, spacing: 12) {
            HStack(spacing: 8) {
                VStack(alignment: .trailing, spacing: 3) {
                    Text("طالب العلم")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(palette.accent)
                    Text(entry.cityName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(palette.muted)
                        .lineLimit(1)
                }
                Spacer(minLength: 6)
                Text(entry.hijriDate)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(palette.muted)
                    .lineLimit(1)
            }

            FeaturedPrayerBlock(entry: entry, palette: palette, prominent: true)
            PrayerTimesRow(entry: entry, palette: palette, prominent: true)

            VStack(alignment: .trailing, spacing: 7) {
                HStack(spacing: 6) {
                    Text("درة اليوم")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(palette.accent)
                    Spacer(minLength: 4)
                    Image(systemName: "quote.opening")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(palette.accent)
                }

                Text(entry.dailyGem)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(palette.text)
                    .lineLimit(4)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                Text("— " + entry.dailyGemAuthor)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(palette.muted)
                    .lineLimit(1)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(palette.inset)
            )
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
    }
}

private struct FeaturedPrayerBlock: View {
    let entry: PrayerWidgetEntry
    let palette: WidgetPalette
    let prominent: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            VStack(alignment: .trailing, spacing: 3) {
                Text(entry.prayerDisplayTitle)
                    .font(.system(size: prominent ? 16 : 14, weight: .bold))
                    .foregroundColor(palette.text)
                    .lineLimit(1)
                Text(entry.countdownPrefix)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(palette.muted)
                    .lineLimit(1)
            }
            Spacer(minLength: 4)
            if let target = entry.nextPrayerDate, target > entry.date {
                Text(target, style: .timer)
                    .font(.system(size: prominent ? 25 : 21, weight: .bold, design: .rounded))
                    .foregroundColor(palette.prayer)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            } else if entry.isPrayerActive {
                Text("حان الآن")
                    .font(.system(size: prominent ? 21 : 18, weight: .bold))
                    .foregroundColor(palette.prayer)
                    .lineLimit(1)
            } else {
                Text(entry.nextPrayerName)
                    .font(.system(size: prominent ? 21 : 18, weight: .bold))
                    .foregroundColor(palette.prayer)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, prominent ? 12 : 9)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(palette.inset)
        )
    }
}

private struct PrayerTimesRow: View {
    let entry: PrayerWidgetEntry
    let palette: WidgetPalette
    let prominent: Bool

    var body: some View {
        HStack(spacing: 4) {
            prayerCell(name: "الفجر", time: entry.fajrTime, isNext: entry.nextPrayerName == "الفجر")
            prayerCell(name: "الظهر", time: entry.dhuhrTime, isNext: entry.nextPrayerName == "الظهر" || entry.nextPrayerName == "الجمعة")
            prayerCell(name: "العصر", time: entry.asrTime, isNext: entry.nextPrayerName == "العصر")
            prayerCell(name: "المغرب", time: entry.maghribTime, isNext: entry.nextPrayerName == "المغرب")
            prayerCell(name: "العشاء", time: entry.ishaTime, isNext: entry.nextPrayerName == "العشاء")
        }
    }

    private func prayerCell(name: String, time: String, isNext: Bool) -> some View {
        VStack(spacing: 5) {
            Text(name)
                .font(.system(size: 12, weight: isNext ? .bold : .medium))
                .foregroundColor(isNext ? palette.accentInk : palette.muted)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
            Text(time)
                .font(.system(size: 12, weight: isNext ? .bold : .medium))
                .foregroundColor(isNext ? palette.text : palette.muted)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, prominent ? 10 : 7)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isNext ? palette.accentSoft : palette.surface)
        )
    }
}

struct TalibIlmWidgetsEntryView: View {
    @Environment(\.widgetFamily) private var family
    @Environment(\.colorScheme) private var colorScheme
    let entry: PrayerTimelineProvider.Entry

    var body: some View {
        let isDark = entry.resolvedDarkMode(for: colorScheme)
        let palette = WidgetPalette(isDark: isDark)

        Group {
            switch family {
            case .systemSmall:
                PrayerSmallWidgetView(entry: entry, palette: palette)
            case .systemMedium:
                PrayerMediumWidgetView(entry: entry, palette: palette)
            case .systemLarge:
                PrayerLargeWidgetView(entry: entry, palette: palette)
            default:
                PrayerSmallWidgetView(entry: entry, palette: palette)
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
        .environment(\.colorScheme, isDark ? .dark : .light)
        .widgetBackground(palette.background)
    }
}
