# Quran Feature Audit: Talib Ilm vs Wahy

**Audit date:** 2026-11-08
**Audit baseline:** `main` at `813b3a8` (Hafs-only after the requested Warsh/Qalun removal)
**Scope:** Quran reader, study tools, recitation, offline use, reading habits, and data stewardship.
**Method:** inspected the current Flutter implementation and compared it with Wahy's public product pages and Google Play listing. These are product capability ratings, not store ratings or a claim that Wahy's implementation is error-free. No private app internals were inspected.

## Executive assessment

Talib Ilm already has a strong, authentic Hafs reading foundation: the 604-page Madinah Mushaf is rendered through the vendored QCF package, with tajweed, bookmarks, reading history, Quran search/indexes, verse audio, reciter selection, and offline recitation downloads. Its main gap versus Wahy is the study and reading-plan layer around the Mushaf: the individual-word data exists, but a tap on a word currently only hides/shows reader controls; there are no Khatmah plans, no bookmark collections, and only five tafsir choices.

**Audit-baseline Quran-section readiness: 6.7 / 10. After the direct-word lookup in this increment: 7.0 / 10.** The score reflects breadth and reliability, not Mushaf-text authenticity. The core reader rates higher; study depth and personal organization rate lower. Ratings are engineering judgments based on the repository inspection below.

The first targeted parity improvement is direct word lookup from the Mushaf. This audit accompanies implementation of that interaction using the app's existing cached word data. The next substantial feature should be a local-first Khatmah planner. Do not restore Warsh or Qalun: the owner explicitly removed those editions. Do not copy Wahy's artwork, proprietary data, or exact screens.

## What Wahy publicly offers

Wahy's own materials describe:

- Madinah Mushaf pages in their printed form, several Hafs print editions, and Warsh.
- Word-level meanings, grammar/morphology and readings, with word lookup from the Mushaf.
- A library of more than 184 tafsir/translation/ Quran-science sources.
- More than 64 reciters in the Google Play listing; the English Wahy website currently says 81. Counts vary across the public pages, so treat them as changing product claims, not a numeric acceptance target.
- Verse-synchronized recitation, repeated listening, offline tafsir/recitation, and word pronunciation.
- Search and indexes, multiple grouped/color bookmarks, notes attached to verses, Khatmah plans, auto-scroll, configurable reading appearance, and sharing verses with supporting content as text or images.

Sources: [Wahy official site](https://main.wahy.net/), [Wahy English feature site](https://web.wahy.net/en), [Google Play listing](https://play.google.com/store/apps/details?id=com.logicdev.quran_reader), and [Tafsir Center's Wahy description](https://tafsir.net/wahy).

## Feature-by-feature scorecard

| Area | Talib Ilm today | Score | Gap and recommended direction |
|---|---|---:|---|
| Mushaf fidelity and reading | Authentic 604-page Hafs QCF Mushaf, tajweed rendering, page/surah/juz/hizb navigation, page appearance options, and saved reading position. | **9.0** | Protect this stable core. Keep Hafs as the default and never approximate printed Mushaf pages with reflowed text. |
| Search and navigation | Search/index for surahs, ayahs, juzs, hizbs, plus quick jump and local Arabic normalization. | **8.0** | Improve result context and offline availability only where evidence shows a real failure; no need to replace the current index. |
| Audio and recitation | 43 configured reciters, verse and continuous playback, current-ayah tracking/highlighting, repeat modes, playback speed, downloads by reciter/surah. | **8.0** | Add focused learning loops only after validating the existing audio/player behavior; word pronunciation is not currently exposed. |
| Word-level study | Word meanings/transliteration are fetched per ayah and cached. This increment adds direct word lookup, adjacent-word navigation, verse context, explicit English labeling, retry/offline state, and a route to the full meanings tab. `morphology` is not populated. | **4.0 → 6.5** | Later add other languages and morphology only from vetted, licensed datasets. |
| Tafsir and translation breadth | Five configured tafsir choices; content is fetched from remote endpoints and cached after access. | **4.0** | Build a source catalog with author, language, attribution/license, offline status, and download controls. Expand only with verified sources and rights. |
| Khatmah/read plans | Reading minutes and streak exist, but no Quran completion plan or daily page/juz assignment was found. The displayed goal is fixed at 20 minutes; service goal values are currently constants. | **2.0** | Highest remaining product gap: local-first Khatmah plans, target date or duration, daily assignment, progress, catch-up, pause/resume, and multiple plans. |
| Bookmarks and reflection | Up to 200 bookmarks, one note per bookmarked ayah, reading-position backup/import/export. No collection/group/color model was found. | **6.0** | Add named collections and colors while preserving existing bookmark data; avoid requiring sign-in for core use. |
| Offline and resilience | Hafs pages/data work locally; recitations can be downloaded; opened word/tafsir entries are cached. There is no user-facing bulk download manager for study sources. | **7.0** | Make offline status visible and let users manage selected verified tafsir/translation packs. Do not silently claim all study content is offline. |
| Personalization and accessibility | Mushaf theme, tajweed toggle, font size, keep-awake, reciter and default tafsir preferences exist. No auto-scroll control was found. | **7.0** | Add configurable auto-scroll with pause/resume, clear speed controls, and touch-to-stop behavior. Check large text and screen-reader labels as part of each UI change. |
| Sync across devices | Bookmark backup/import/export exists. Quran page-content sync is separate from personal-data sync; no account-backed Quran progress sync was found. | **3.0** | Consider opt-in encrypted sync only after local models and conflict rules are stable. Keep offline/local usage intact. |

## Evidence from this codebase

- The Hafs Mushaf uses `qcf_quran_plus` in `MushafSinglePage`; the reader provides 604 pages, tajweed settings, page themes, saved position, and audio/player overlays.
- `QuranTafsirService` defines five `TafsirScholar` values. Its word endpoint requests `language=en`; word data is cached by verse in memory and `SharedPreferences`.
- Before this increment, `MushafSinglePage`'s package `onWordTap` callback was wired to overlay toggling. It includes surah, ayah, word index, and tapped word, so direct lookup can use the existing renderer, word service, and cache without a new package.
- `QuranAudioService.reciters` contains 43 entries. `QuranAudioDownloader` supplies offline surah downloads.
- `BookmarkService` caps bookmarks at 200 and stores an optional note on each bookmark. `BookmarkBackupService` handles local file backup; it is not cross-device account sync.
- `ReadingStatsService` tracks minutes, verses, and streaks. No Khatmah plan model or service was found. The goal getter returns fixed values.
- Searches for auto-scroll and Khatmah plan implementations in `lib/features/quran/` returned no implementation.

## Implemented in this increment: word tap study

- A Mushaf word tap now opens a compact word-detail sheet instead of only toggling reader controls.
- The sheet uses the selected word index from the existing QCF renderer and the existing per-ayah word-data cache; it shows the word, English meaning, transliteration when available, neighboring words, and verse context.
- The source language is stated. On a cache miss with no network result, it shows a retry state and keeps the Quran text visible. The reader's long-press verse action menu remains available.
- **Verification:** `flutter analyze --no-pub` clean; `python tool/ui_lint_v2.py` passed; debug APK built successfully. Tests were not run.

## Prioritized implementation roadmap

### P1 — Direct word lookup from the Mushaf (this increment)

Tap a word to see that word's cached/fetched meaning, transliteration, verse context, and previous/next word navigation. Clearly label the present source as English. Preserve long-press verse actions and offer a route to the full verse study sheet. Show loading, retry, and offline/unavailable states without blocking reading.

### P1 — Local-first Khatmah planner

Allow multiple plans with a start date and target date or duration. Compute a daily assignment in pages/juzs with explicit catch-up behavior. Track actual completed units, not just time spent in the app. Support pause/resume and safe date/time-zone boundaries. Keep the plan entirely usable without an account.

### P1 — Trusted content catalog and offline study packs

Inventory every current tafsir/word source, record publisher/source and redistribution rights, then replace fragile assumptions with documented endpoints or versioned packs. The app currently calls the legacy `api.quran.com/api/v4` host without credentials; current Quran Foundation Content API documentation describes app credentials. Verify the legacy endpoint's supported lifetime and production requirements before broadening this dependency. Show language, author, source, last-updated state, download size, and offline availability. Do not target Wahy's advertised source count until each source is trustworthy and licensed.

### P2 — Bookmark collections

Add named, colored collections and allow one verse to belong to more than one collection. Migrate old bookmarks to a default collection without changing their coordinates or notes. Update backup format compatibly.

### P2 — Auto-scroll reading mode

Offer a visible speed setting, pause/resume, and immediate pause on touch or audio interaction. Prevent page jumps when overlays open and remember the user's preferred speed.

### P2 — Study sharing and discovery

Provide a share card for a verse plus the selected, attributed tafsir/translation. Add surah overview cards only from reliable source material. Avoid generated or unattributed religious explanations.

### P3 — Optional cross-device sync and broader language coverage

Define opt-in sync, encryption, account deletion, merge rules, and offline conflict handling before adding a backend. Add translations and word analysis language by language with source/license review.

## Release-quality acceptance rules

1. The Hafs QCF page rendering, page numbering, tajweed, and reading position remain unchanged by adjacent feature work.
2. No Quran meaning, translation, tafsir, or morphology is generated or presented without a named source and language.
3. Network failure never hides the Mushaf; every remote study action has an explicit retry/offline state.
4. Downloaded study content has visible storage accounting and a deletion path.
5. New progress is persisted safely and remains usable without login.
6. Features are keyboard/screen-reader discoverable and fit small screens, landscape, Arabic RTL, and enlarged text.
7. Do not add Warsh/Qalun UI or restore the deleted pack system unless the owner explicitly changes that product decision.

## Primary references

- [Wahy Arabic feature overview](https://main.wahy.net/)
- [Wahy English feature overview](https://web.wahy.net/en)
- [Wahy Google Play listing](https://play.google.com/store/apps/details?id=com.logicdev.quran_reader)
- [Tafsir Center description of Wahy](https://tafsir.net/wahy)
- [Quran Foundation API reference for word-by-word verse data](https://api-docs.quran.com/docs/content_apis_versioned/4.0.0/verses-by-verse-key/)
- [Quran Foundation API updates](https://api-docs.quran.com/docs/updates/)
