# Typography System Documentation

## Overview

The Talib Ilm typography system is designed with accessibility, readability, and cultural appropriateness in mind. It follows strict guidelines to ensure all text is legible and properly sized for both UI elements and religious content.

## Design Principles

1. **Arabic Content Priority**: Quran and Hadith text uses Amiri font with a minimum size of 18sp
2. **UI Consistency**: All UI elements use Cairo font for a cohesive experience
3. **Clear Hierarchy**: Heading scale follows 24/20/18/16/14sp progression
4. **Optimal Readability**: Minimum line height of 1.5x for comfortable reading
5. **Accessibility First**: No text smaller than 12sp (WCAG compliance)

## Font Families

### Cairo (UI Font)
- **Type**: Modern Arabic sans-serif
- **Usage**: Buttons, labels, navigation, UI components
- **Characteristics**: Clean, modern, highly legible on screens

### Amiri (Content Font)
- **Type**: Traditional Arabic serif
- **Usage**: Quran, Hadith, Dhikr, scholarly names
- **Characteristics**: Traditional, elegant, optimized for Arabic script

## Typography Scale

### Headings (24/20/18/16/14sp)

| Style | Size | Weight | Usage | Line Height |
|-------|------|--------|-------|-------------|
| `heading1` | 24sp | 700 | Page titles, major sections | 1.5 |
| `heading2` | 20sp | 600 | Section headers, card titles | 1.5 |
| `heading3` | 18sp | 600 | Subsection headers | 1.5 |
| `heading4` | 16sp | 600 | Minor headers, emphasized text | 1.5 |
| `heading5` | 14sp | 600 | Small headers, labels | 1.5 |

### Body Text

| Style | Size | Weight | Usage | Line Height |
|-------|------|--------|-------|-------------|
| `bodyLarge` | 16sp | 400 | Primary body text, important content | 1.6 |
| `bodyMedium` | 14sp | 400 | Standard body text | 1.5 |
| `bodySmall` | 12sp | 400 | Secondary body text (minimum size) | 1.5 |

### Arabic Content (Minimum 18sp)

| Style | Size | Weight | Usage | Line Height |
|-------|------|--------|-------|-------------|
| `quranArabic` | 22sp | 400 | Quran verses | 2.0 |
| `hadithArabic` | 20sp | 400 | Hadith text | 1.9 |
| `dhikrLarge` | 24sp | 500 | Emphasized prayers/dhikr | 1.8 |
| `dhikrMedium` | 20sp | 400 | Standard prayers/dhikr | 1.7 |
| `dhikrSmall` | 18sp | 400 | Compact prayers (minimum) | 1.7 |
| `bookTitleArabic` | 18sp | 600 | Book titles in Arabic | 1.6 |
| `scholarNameArabic` | 18sp | 500 | Scholar/author names | 1.5 |

### Translations & Secondary Text

| Style | Size | Weight | Usage | Line Height |
|-------|------|--------|-------|-------------|
| `hadithTranslation` | 14sp | 400 | Hadith translations | 1.6 |
| `hadithNarrator` | 12sp | 500 | Hadith source/narrator | 1.5 |
| `quranTranslation` | 14sp | 400 | Quran translations (italic) | 1.6 |
| `dhikrTranslation` | 14sp | 400 | Dhikr translations (italic) | 1.5 |

### UI Components

| Style | Size | Weight | Usage | Line Height |
|-------|------|--------|-------|-------------|
| `appBarTitle` | 18sp | 600 | App bar titles | 1.5 |
| `cardTitle` | 16sp | 600 | Card titles | 1.5 |
| `cardSubtitle` | 14sp | 400 | Card subtitles | 1.5 |
| `button` | 16sp | 600 | Primary buttons | 1.5 |
| `buttonSmall` | 14sp | 600 | Secondary/small buttons | 1.5 |
| `label` | 14sp | 500 | Form labels, metadata | 1.5 |
| `caption` | 12sp | 400 | Timestamps, helper text (minimum) | 1.5 |
| `overline` | 12sp | 600 | Eyebrow text, categories | 1.5 |

### Prayer Times

| Style | Size | Weight | Usage | Line Height |
|-------|------|--------|-------|-------------|
| `prayerNameLarge` | 28sp | 700 | Current prayer display | 1.5 |
| `prayerNameMedium` | 20sp | 600 | Prayer list names | 1.5 |
| `prayerTime` | 18sp | 600 | Prayer times (tabular figures) | 1.5 |
| `prayerCountdown` | 16sp | 500 | Countdown timers (tabular figures) | 1.5 |

### Numbers & Statistics

| Style | Size | Weight | Usage | Line Height |
|-------|------|--------|-------|-------------|
| `numberExtraLarge` | 48sp | 800 | Hero numbers, large counters | 1.2 |
| `numberLarge` | 36sp | 700 | Large counters | 1.2 |
| `numberMedium` | 24sp | 700 | Standard counters | 1.5 |
| `numberSmall` | 18sp | 600 | Compact counters | 1.5 |
| `statNumber` | 20sp | 700 | Statistics display | 1.5 |
| `statLabel` | 12sp | 500 | Statistics labels (minimum) | 1.5 |

### Badges & Chips

| Style | Size | Weight | Usage | Line Height |
|-------|------|--------|-------|-------------|
| `badge` | 12sp | 700 | Notification badges, status | 1.5 |
| `chip` | 14sp | 500 | Filter chips, tags | 1.5 |

### Special Purpose

| Style | Size | Weight | Usage | Line Height |
|-------|------|--------|-------|-------------|
| `link` | 14sp | 500 | Hyperlinks (underlined) | 1.5 |
| `error` | 12sp | 500 | Error messages | 1.5 |
| `success` | 12sp | 500 | Success messages | 1.5 |
| `placeholder` | 14sp | 400 | Placeholder text (italic) | 1.5 |

## Usage Guidelines

### Arabic Religious Content
```dart
// ✅ CORRECT - Use dedicated Arabic styles
Text(
  'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
  style: AppTextStyles.quranArabic,
)

// ❌ WRONG - Don't use UI styles for Arabic content
Text(
  'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
  style: AppTextStyles.bodyLarge, // Too small, wrong font
)
```

### Minimum Text Size
```dart
// ✅ CORRECT - Use caption for smallest text (12sp)
Text(
  'Last updated 2 hours ago',
  style: AppTextStyles.caption,
)

// ❌ WRONG - Never use text smaller than 12sp
Text(
  'Last updated 2 hours ago',
  style: TextStyle(fontSize: 10), // Violates accessibility
)
```

### Line Height
```dart
// ✅ CORRECT - Maintain 1.5x minimum line height
Text(
  'Long paragraph text...',
  style: AppTextStyles.bodyMedium, // Has height: 1.5
)

// ❌ WRONG - Don't reduce line height below 1.5
Text(
  'Long paragraph text...',
  style: AppTextStyles.bodyMedium.copyWith(height: 1.2), // Too tight
)
```

### Tabular Figures
```dart
// ✅ CORRECT - Use tabular figures for numbers that change
Text(
  '12:34',
  style: AppTextStyles.prayerTime, // Has FontFeature.tabularFigures()
)

// Numbers align properly when they update:
// 12:34
// 12:35
// 12:36
```

## Accessibility Compliance

### WCAG AA Standards
- **Minimum text size**: 12sp (16px equivalent)
- **Line height**: 1.5x minimum for body text
- **Contrast ratios**: Handled by AppColors system
- **Touch targets**: Button text sized for 44pt minimum tap area

### Arabic Script Considerations
- **Minimum 18sp** for Arabic religious content ensures proper diacritic rendering
- **Amiri font** optimized for Arabic script legibility
- **Generous line height** (1.7-2.0) prevents diacritic overlap
- **Letter spacing** added where appropriate for clarity

## Migration from Old System

### Removed Styles
The following styles were removed for not meeting accessibility standards:

| Old Style | Replacement | Reason |
|-----------|-------------|--------|
| `labelSmall` (11sp) | `caption` (12sp) | Below minimum size |
| `caption` (11sp) | `caption` (12sp) | Increased to minimum |
| `statLabel` (11sp) | `statLabel` (12sp) | Increased to minimum |

### Size Adjustments

| Style | Old Size | New Size | Reason |
|-------|----------|----------|--------|
| `heading1` | 22sp | 24sp | Clearer hierarchy |
| `heading2` | 18sp | 20sp | Better progression |
| `bodyLarge` | 15sp | 16sp | Improved readability |
| `cardTitle` | 15sp | 16sp | Better prominence |
| `button` | 15sp | 16sp | Larger tap targets |
| `hadithArabic` | 17sp | 20sp | Meet 18sp minimum |
| `numberLarge` | 42sp | 36sp | More balanced |
| `numberMedium` | 28sp | 24sp | Better scaling |

## Best Practices

1. **Always use predefined styles** - Don't create ad-hoc TextStyle objects
2. **Respect minimum sizes** - Never go below 12sp
3. **Use appropriate fonts** - Cairo for UI, Amiri for Arabic content
4. **Maintain line height** - Keep at 1.5x or higher for readability
5. **Use tabular figures** - For numbers that update or align
6. **Test with real content** - Especially Arabic text with diacritics

## Examples

### Prayer Time Card
```dart
Column(
  children: [
    Text('الفجر', style: AppTextStyles.prayerNameMedium),
    Text('05:23', style: AppTextStyles.prayerTime),
    Text('in 2h 15m', style: AppTextStyles.prayerCountdown),
  ],
)
```

### Hadith Display
```dart
Column(
  children: [
    Text(
      'إِنَّمَا الْأَعْمَالُ بِالنِّيَّاتِ',
      style: AppTextStyles.hadithArabic,
    ),
    SizedBox(height: 12),
    Text(
      'Actions are judged by intentions',
      style: AppTextStyles.hadithTranslation,
    ),
    SizedBox(height: 8),
    Text(
      'Sahih al-Bukhari 1',
      style: AppTextStyles.hadithNarrator,
    ),
  ],
)
```

### Statistics Display
```dart
Column(
  children: [
    Text('42', style: AppTextStyles.statNumber),
    Text('Books Read', style: AppTextStyles.statLabel),
  ],
)
```

## Color Integration

All text styles use colors from `AppColors`:
- `textPrimary` - Main content
- `textSecondary` - Supporting content
- `textTertiary` - Muted content
- `textDisabled` - Disabled states
- `textOnPrimary` - Text on colored backgrounds
- `textOnAccent` - Text on accent backgrounds

Refer to `app_colors.dart` for the complete color system.
