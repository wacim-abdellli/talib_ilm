import SwiftUI
import WidgetKit

// MARK: - Design Tokens (Light & Dark Parity with DESIGN_SYSTEM.md)
struct WidgetPalette {
    let isDark: Bool

    var background: Color {
        isDark
            ? Color(red: 0.055, green: 0.055, blue: 0.071) // #0E0E12
            : Color(red: 0.980, green: 0.973, blue: 0.961) // #FAF8F5
    }

    var surface: Color {
        isDark
            ? Color(red: 0.090, green: 0.090, blue: 0.118) // #17171E
            : Color(red: 0.941, green: 0.925, blue: 0.882) // #F0ECE1
    }

    var textPrimary: Color {
        isDark
            ? Color(red: 0.957, green: 0.945, blue: 0.918) // #F4F1EA
            : Color(red: 0.110, green: 0.106, blue: 0.094) // #1C1B18
    }

    var textSecondary: Color {
        isDark
            ? Color(red: 0.620, green: 0.620, blue: 0.682) // #9E9EAE
            : Color(red: 0.431, green: 0.416, blue: 0.388) // #6E6A63
    }

    var textMuted: Color {
        isDark
            ? Color(red: 0.431, green: 0.431, blue: 0.490) // #6E6E7D
            : Color(red: 0.549, green: 0.529, blue: 0.494) // #8C877E
    }

    var accent: Color {
        isDark
            ? Color(red: 0.831, green: 0.686, blue: 0.216) // #D4AF37
            : Color(red: 0.541, green: 0.427, blue: 0.122) // #8A6D1F
    }

    var divider: Color {
        isDark
            ? Color.white.opacity(0.08)
            : Color.black.opacity(0.07)
    }

    func prayerAccent(for key: String, isJumua: Bool = false) -> Color {
        switch key {
        case "fajr":
            return isDark
                ? Color(red: 0.831, green: 0.541, blue: 0.612) // #D48A9C
                : Color(red: 0.659, green: 0.329, blue: 0.408) // #A85468
        case "dhuhr":
            if isJumua {
                return isDark
                    ? Color(red: 0.322, green: 0.718, blue: 0.533) // #52B788
                    : Color(red: 0.118, green: 0.420, blue: 0.294) // #1E6B4B
            }
            return isDark
                ? Color(red: 0.914, green: 0.769, blue: 0.416) // #E9C46A
                : Color(red: 0.541, green: 0.427, blue: 0.122) // #8A6D1F
        case "asr":
            return isDark
                ? Color(red: 0.910, green: 0.573, blue: 0.290) // #E8924A
                : Color(red: 0.722, green: 0.365, blue: 0.098) // #B85D19
        case "maghrib":
            return isDark
                ? Color(red: 0.878, green: 0.478, blue: 0.373) // #E07A5F
                : Color(red: 0.651, green: 0.227, blue: 0.314) // #A63A50
        case "isha":
            return isDark
                ? Color(red: 0.561, green: 0.659, blue: 0.855) // #8FA8DA
                : Color(red: 0.231, green: 0.322, blue: 0.518) // #3B5284
        default:
            return accent
        }
    }

    func pillTextColor(for key: String, isJumua: Bool = false) -> Color {
        if !isDark { return .white }
        // In dark mode, bright gold/amber/emerald pills use dark ink for ≥7:1 contrast
        return Color(red: 0.078, green: 0.078, blue: 0.094) // #141418
    }

    static func prayerSymbol(for key: String) -> String {
        switch key {
        case "fajr": return "sunrise.fill"
        case "dhuhr": return "sun.max.fill"
        case "asr": return "sun.min.fill"
        case "maghrib": return "sunset.fill"
        case "isha": return "moon.stars.fill"
        default: return "sun.max.fill"
        }
    }
}

// MARK: - iOS 17+ Container Background Compatibility
extension View {
    @ViewBuilder
    func widgetBackground(_ color: Color) -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            self.containerBackground(for: .widget) {
                color
            }
        } else {
            self.background(color)
        }
    }
}

// MARK: - Entry View Router (Medium & Large Only)
struct TalibIlmWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) var colorScheme

    private var effectiveIsDark: Bool {
        switch entry.themePreference {
        case "dark": return true
        case "light": return false
        default: return colorScheme == .dark
        }
    }

    private var palette: WidgetPalette {
        WidgetPalette(isDark: effectiveIsDark)
    }

    var body: some View {
        Group {
            switch family {
            case .systemLarge:
                LargePrayerWidgetView(entry: entry, palette: palette)
            default:
                MediumPrayerWidgetView(entry: entry, palette: palette)
            }
        }
        // Use explicit physical Left-to-Right layout direction so Arabic RTL order
        // ([Isha][Maghrib][Asr][Dhuhr][Fajr] from left to right) is 100% deterministic
        // regardless of whether the iPhone OS language is English or Arabic.
        .environment(\.layoutDirection, .leftToRight)
        .widgetBackground(palette.background)
    }
}

// MARK: - Shared Prayer Column Item (Used in Medium & Large)
private struct PrayerColumnModel: Identifiable {
    let id: String
    let name: String
    let time: String
    let symbol: String
}

private func orderedColumns(for entry: PrayerEntry) -> [PrayerColumnModel] {
    // Physical Left-to-Right order = Arabic Right-to-Left reading order (Fajr on right, Isha on left)
    let dhuhrName = entry.isJumua ? "الجمعة" : "الظهر"
    return [
        PrayerColumnModel(id: "isha", name: "العشاء", time: entry.ishaTime, symbol: "moon.stars.fill"),
        PrayerColumnModel(id: "maghrib", name: "المغرب", time: entry.maghribTime, symbol: "sunset.fill"),
        PrayerColumnModel(id: "asr", name: "العصر", time: entry.asrTime, symbol: "sun.min.fill"),
        PrayerColumnModel(id: "dhuhr", name: dhuhrName, time: entry.dhuhrTime, symbol: "sun.max.fill"),
        PrayerColumnModel(id: "fajr", name: "الفجر", time: entry.fajrTime, symbol: "sunrise.fill")
    ]
}

// MARK: - 1. Medium Widget (.systemMedium — 4x2 Ribbon)
struct MediumPrayerWidgetView: View {
    let entry: PrayerEntry
    let palette: WidgetPalette

    var body: some View {
        let heroAccent = palette.prayerAccent(for: entry.activePrayerKey, isJumua: entry.isJumua)
        let heroSymbol = WidgetPalette.prayerSymbol(for: entry.activePrayerKey)
        let columns = orderedColumns(for: entry)

        VStack(spacing: 8) {
            // Top Bar: Left = Hijri Date + Calendar Icon | Right = Countdown Badge + Next Prayer Title + Icon
            HStack(alignment: .center, spacing: 6) {
                HStack(spacing: 5) {
                    Text(entry.hijriDate)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(palette.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Image(systemName: "calendar")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(palette.textSecondary)
                }

                Spacer(minLength: 6)

                HStack(spacing: 6) {
                    CountdownBadgeView(
                        entry: entry,
                        palette: palette,
                        accent: heroAccent,
                        fontSize: 12
                    )

                    Text(entry.heroTitle)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(heroAccent)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Image(systemName: heroSymbol)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(heroAccent)
                }
            }

            Rectangle()
                .fill(palette.divider)
                .frame(height: 1)

            // 5-Prayer Strip (Physical Left-to-Right: Isha -> Maghrib -> Asr -> Dhuhr -> Fajr)
            HStack(spacing: 4) {
                ForEach(columns) { col in
                    let isActive = col.id == entry.activePrayerKey
                    let colAccent = palette.prayerAccent(for: col.id, isJumua: entry.isJumua)

                    VStack(spacing: 4) {
                        Image(systemName: col.symbol)
                            .font(.system(size: isActive ? 15 : 13, weight: .semibold))
                            .foregroundColor(colAccent.opacity(isActive ? 1.0 : 0.85))
                            .frame(height: 16)

                        Text(col.name)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(isActive ? colAccent : palette.textSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)

                        Text(col.time)
                            .font(.system(size: 12, weight: .bold, design: .rounded).monospacedDigit())
                            .foregroundColor(
                                isActive
                                    ? palette.pillTextColor(for: col.id, isJumua: entry.isJumua)
                                    : palette.textPrimary
                            )
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(
                                RoundedRectangle(cornerRadius: 7, style: .continuous)
                                    .fill(isActive ? colAccent : Color.clear)
                            )
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(isActive ? colAccent.opacity(palette.isDark ? 0.10 : 0.08) : Color.clear)
                    )
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxHeight: .infinity, alignment: .center)
    }
}

// MARK: - 2. Large / Max Widget (.systemLarge — 4x4 Dashboard)
struct LargePrayerWidgetView: View {
    let entry: PrayerEntry
    let palette: WidgetPalette

    var body: some View {
        let heroAccent = palette.prayerAccent(for: entry.activePrayerKey, isJumua: entry.isJumua)
        let heroSymbol = WidgetPalette.prayerSymbol(for: entry.activePrayerKey)
        let columns = orderedColumns(for: entry)

        VStack(spacing: 12) {
            // 1. Header Bar: Left = Hijri Date | Right = Location Name
            HStack(alignment: .center) {
                HStack(spacing: 5) {
                    Text(entry.hijriDate)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(palette.textSecondary)
                        .lineLimit(1)

                    Image(systemName: "calendar")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(palette.accent)
                }

                Spacer(minLength: 8)

                HStack(spacing: 4) {
                    Text(entry.locationName)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(palette.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Image(systemName: "location.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(palette.accent)
                }
            }

            // 2. Hero Card (Next Prayer + Live Countdown Box)
            HStack(alignment: .center, spacing: 12) {
                // Left: Dedicated Next Prayer Time Left Box
                VStack(alignment: .center, spacing: 3) {
                    Text(
                        entry.isCallToPrayer
                            ? "الحالة"
                            : (entry.heroStatusText == "الإقامة" ? "الإقامة بعد" : "الوقت المتبقي")
                    )
                    .font(.system(size: 10.5, weight: .bold))
                    .foregroundColor(palette.textSecondary)
                    .lineLimit(1)

                    if let targetDate = entry.heroTargetDate, !entry.isCallToPrayer {
                        Text(targetDate, style: .timer)
                            .font(.system(size: 16, weight: .bold, design: .rounded).monospacedDigit())
                            .foregroundColor(palette.textPrimary)
                            .multilineTextAlignment(.center)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .frame(width: 76, alignment: .center)
                    } else {
                        Text(entry.heroStatusText.isEmpty ? "الآن" : entry.heroStatusText)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(heroAccent)
                            .lineLimit(1)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(palette.background.opacity(palette.isDark ? 0.65 : 0.85))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(palette.divider, lineWidth: 1)
                        )
                )

                Spacer(minLength: 4)

                // Right: Prayer Title + Adhan Time + Celestial Icon Badge
                HStack(spacing: 10) {
                    VStack(alignment: .trailing, spacing: 3) {
                        Text("الصلاة القادمة")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(palette.textSecondary)

                        Text(entry.heroTitle)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(heroAccent)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)

                        Text("موعد الأذان  \(entry.activePrayerTimePeriod)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(palette.textSecondary)
                            .lineLimit(1)
                    }

                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(heroAccent.opacity(palette.isDark ? 0.18 : 0.14))
                            .frame(width: 42, height: 42)

                        Image(systemName: heroSymbol)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(heroAccent)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(palette.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(heroAccent.opacity(0.22), lineWidth: 1)
                    )
            )

            // 3. Section Header
            HStack {
                Text("الصلوات الخمس")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(palette.textMuted)

                Spacer()

                Text("مواقيت اليوم")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(palette.textSecondary)
            }
            .padding(.horizontal, 2)

            // 4. 5-Prayer Columns Grid (Physical Left-to-Right: Isha -> Maghrib -> Asr -> Dhuhr -> Fajr)
            HStack(spacing: 6) {
                ForEach(columns) { col in
                    let isActive = col.id == entry.activePrayerKey
                    let colAccent = palette.prayerAccent(for: col.id, isJumua: entry.isJumua)

                    VStack(spacing: 8) {
                        Image(systemName: col.symbol)
                            .font(.system(size: isActive ? 18 : 16, weight: .semibold))
                            .foregroundColor(colAccent)
                            .frame(height: 20)

                        Text(col.name)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(isActive ? colAccent : palette.textSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)

                        Text(col.time)
                            .font(.system(size: 12, weight: .bold, design: .rounded).monospacedDigit())
                            .foregroundColor(
                                isActive
                                    ? palette.pillTextColor(for: col.id, isJumua: entry.isJumua)
                                    : palette.textPrimary
                            )
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 7, style: .continuous)
                                    .fill(isActive ? colAccent : Color.clear)
                            )
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(isActive ? colAccent.opacity(palette.isDark ? 0.14 : 0.10) : palette.surface)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(isActive ? colAccent.opacity(0.45) : palette.divider, lineWidth: 1)
                            )
                    )
                }
            }
            .frame(maxHeight: .infinity)
        }
        .padding(16)
    }
}

// MARK: - Live Countdown Badge Component
private struct CountdownBadgeView: View {
    let entry: PrayerEntry
    let palette: WidgetPalette
    let accent: Color
    let fontSize: CGFloat

    var body: some View {
        HStack(spacing: 4) {
            if let targetDate = entry.heroTargetDate, !entry.isCallToPrayer {
                Text(targetDate, style: .timer)
                    .font(.system(size: fontSize, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundColor(palette.textPrimary)
                    .multilineTextAlignment(.trailing)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(width: fontSize * 4.4, alignment: .trailing)

                Text(entry.heroStatusText.isEmpty ? "بعد" : entry.heroStatusText)
                    .font(.system(size: fontSize - 1, weight: .bold))
                    .foregroundColor(palette.textSecondary)
                    .lineLimit(1)
            } else {
                Text(entry.heroStatusText.isEmpty ? "الآن" : entry.heroStatusText)
                    .font(.system(size: fontSize, weight: .bold))
                    .foregroundColor(accent)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(palette.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(palette.divider, lineWidth: 1)
                )
        )
    }
}
