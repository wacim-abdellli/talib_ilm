# Quran Reading Experience Redesign - Implementation Plan

## Project Overview
A comprehensive redesign of the Quran reading experience to achieve Play Store quality with:
- Visual calm but alive interface
- Feature-rich functionality
- Offline-first architecture
- Professional polish

---

## Phase 1: Core UI/UX Foundation (Priority: Critical)

### 1.1 Reading Modes Enhancement
**Status:** Foundation exists, needs polish

**Files to modify:**
- `lib/features/quran/presentation/widgets/reading_modes.dart`
- `lib/features/quran/presentation/quran_reading_page.dart`

**Tasks:**
- [ ] Unify the three reading modes (Mushaf, Verse, Continuous)
- [ ] Ensure seamless mode switching without losing position
- [ ] Add smooth transitions between modes
- [ ] Implement RTL swipe for Mushaf mode

### 1.2 Page Layout Polish
**Files to modify:**
- `lib/features/quran/presentation/widgets/mushaf_page_widget.dart`

**Tasks:**
- [ ] Improve margins and line height for reading comfort
- [ ] Center Surah title card (only when Surah starts)
- [ ] Style Bismillah (centered, lighter tone)
- [ ] Add subtle page decorations

---

## Phase 2: Typography & Visual Polish (Priority: High)

### 2.1 Font System
**Files to create:**
- `lib/features/quran/presentation/utils/quran_typography.dart`

**Tasks:**
- [ ] Quran text: Uthmani/Amiri Quran fonts
- [ ] UI text: Cairo/Inter Arabic
- [ ] Font size slider with live preview
- [ ] Line spacing slider
- [ ] Word spacing toggle (normal/relaxed)

### 2.2 Color Themes
**Files to create:**
- `lib/features/quran/presentation/utils/quran_themes.dart`

**Tasks:**
- [ ] Light mode: Warm paper background (#FFF8F0)
- [ ] Dark mode: True black/deep charcoal (#0A0A0A, #1A1A1A)
- [ ] High-contrast mode for accessibility
- [ ] Ayah number circles with soft animation
- [ ] Current ayah highlight with subtle glow

### 2.3 Enhanced Settings Sheet
**Files to modify:**
- `lib/features/quran/presentation/widgets/reading_settings_sheet.dart`

**Tasks:**
- [ ] Font size slider (live preview)
- [ ] Line spacing control
- [ ] Word spacing toggle
- [ ] Theme selector (Light/Dark/Sepia)
- [ ] High-contrast toggle

---

## Phase 3: Interaction & Navigation (Priority: High)

### 3.1 Touch & Gestures
**Files to modify:**
- `lib/features/quran/presentation/quran_reading_page.dart`
- `lib/features/quran/presentation/widgets/verse_widget.dart`

**Tasks:**
- [ ] Tap center → show reading controls (fade animation)
- [ ] Long-press ayah → contextual menu with:
  - Tafsir
  - Translation
  - Audio
  - Bookmark
  - Share ayah (image/text)

### 3.2 Page Navigation
**Files to create:**
- `lib/features/quran/presentation/widgets/navigation_slider.dart`
- `lib/features/quran/presentation/widgets/jump_to_sheet.dart`

**Tasks:**
- [ ] Bottom progress slider (page-based)
- [ ] Jump to:
  - Surah (list/search)
  - Juz (30 parts)
  - Hizb (60 parts)
  - Page number (1-604)
- [ ] Visual page indicator

---

## Phase 4: Tafsir Integration (Priority: Critical)

### 4.1 Tafsir Data Layer
**Files to create:**
- `lib/features/quran/data/services/tafsir_service.dart`
- `lib/features/quran/data/models/tafsir_models.dart`
- `lib/features/quran/data/database/tafsir_database.dart`

**Tasks:**
- [ ] Define tafsir data models
- [ ] API integration for tafsir sources:
  - Tafsir Ibn Kathir (ar.ibnkathir)
  - Tafsir Al-Sa'di (ar.saadi)
  - English translations (en.sahih)
- [ ] SQLite caching per ayah
- [ ] Offline download per surah/juz

### 4.2 Tafsir UI
**Files to create:**
- `lib/features/quran/presentation/widgets/tafsir_sheet.dart`

**Tasks:**
- [ ] Bottom sheet / side panel UI
- [ ] Ayah text shown at top
- [ ] Scrollable tafsir content
- [ ] Source selector dropdown
- [ ] Font size control
- [ ] Copy/Share functionality
- [ ] Loading skeleton

### 4.3 Tafsir Offline Strategy
**Files to modify:**
- `lib/features/quran/data/services/tafsir_service.dart`

**Tasks:**
- [ ] Cache tafsir after first open
- [ ] Download button per surah
- [ ] Download button per juz
- [ ] Storage usage indicator
- [ ] Clear cache option

---

## Phase 5: Audio Enhancement (Priority: Medium)

### 5.1 Audio Player Improvements
**Files to modify:**
- `lib/features/quran/presentation/widgets/quran_audio_player.dart`

**Tasks:**
- [ ] Mini player overlay
- [ ] Verse-by-verse playback with highlight
- [ ] Multiple reciters support
- [ ] Playback speed control
- [ ] Repeat options (verse/page/surah)

---

## Phase 6: Offline-First Architecture (Priority: High)

### 6.1 Data Sync Improvements
**Files to modify:**
- `lib/features/quran/data/services/quran_sync_service.dart`
- `lib/features/quran/data/services/quran_cache_service.dart`

**Tasks:**
- [ ] Progressive chunk loading (existing, enhance)
- [ ] Background sync when online
- [ ] Sync status indicators
- [ ] Storage management UI

---

## Implementation Order (Recommended)

### Week 1: Core Foundation
1. **Phase 2.2** - Color themes (visual impact)
2. **Phase 2.1** - Font system improvements
3. **Phase 1.2** - Page layout polish

### Week 2: Tafsir (Most Important Feature)
4. **Phase 4.1** - Tafsir data layer
5. **Phase 4.2** - Tafsir UI
6. **Phase 4.3** - Offline tafsir

### Week 3: Navigation & Interaction
7. **Phase 3.2** - Page navigation slider/jump
8. **Phase 3.1** - Long-press contextual menu

### Week 4: Polish & Audio
9. **Phase 1.1** - Reading modes sync
10. **Phase 5.1** - Audio enhancements

---

## API Sources

### Quran Text
- **alquran.cloud** (existing) - Uthmani text
- **quran.com API v4** - Additional editions

### Tafsir APIs
```
Base: https://api.alquran.cloud/v1/

Endpoints:
- /surah/{surahNumber}/{tafsirEdition}
- /ayah/{surah}:{ayah}/{tafsirEdition}

Tafsir Editions:
- ar.ibnkathir - Tafsir Ibn Kathir (Arabic)
- ar.muyassar - Tafsir Al-Muyassar (Arabic)
- ar.jalalayn - Tafsir Al-Jalalayn (Arabic)
- en.sahih - Sahih International (English)
```

---

## File Structure After Implementation

```
lib/features/quran/
├── data/
│   ├── database/
│   │   ├── quran_database.dart
│   │   └── tafsir_database.dart (NEW)
│   ├── models/
│   │   ├── quran_models.dart
│   │   └── tafsir_models.dart (NEW)
│   ├── services/
│   │   ├── quran_api_service.dart
│   │   ├── quran_sync_service.dart
│   │   ├── tafsir_service.dart (NEW)
│   │   └── ...
│   └── ...
├── presentation/
│   ├── utils/
│   │   ├── quran_typography.dart (NEW)
│   │   └── quran_themes.dart (NEW)
│   ├── widgets/
│   │   ├── tafsir_sheet.dart (NEW)
│   │   ├── navigation_slider.dart (NEW)
│   │   ├── jump_to_sheet.dart (NEW)
│   │   ├── ayah_context_menu.dart (NEW)
│   │   └── ...
│   └── ...
└── ...
```

---

## Starting Point

I recommend starting with **Phase 4: Tafsir Integration** as it's marked "VERY IMPORTANT" and provides the most value. We'll implement:

1. `tafsir_models.dart` - Data structures
2. `tafsir_service.dart` - API + caching
3. `tafsir_sheet.dart` - Beautiful UI

Would you like me to begin with the Tafsir implementation, or would you prefer to start with the visual polish (themes/typography)?
