# Wahy Benchmark and Talib Ilm Quran Product Roadmap

**Prepared:** 2026-11-08  
**Repository baseline:** `main` at `93db172` (`feat(quran): add direct word study from Mushaf`)  
**Scope:** Publicly documented Wahy Quran-app capabilities compared with the Quran section currently present in Talib Ilm. This is a product and implementation plan, not a clone specification.

## Decision

Yes: use Wahy as a capability benchmark and build a Quran experience with comparable depth. Reproduce the useful user outcomes in Talib Ilm's own design and architecture; do not copy Wahy's screens, artwork, source code, proprietary datasets, wording, or undocumented internals. Treat every Quran text, translation, tafsir, recitation, image, and pronunciation recording as a source-and-rights decision.

The best product direction is **a faithful Hafs Mushaf first, with an optional, local-first study layer around it**. Keep the 604-page QCF Mushaf stable and immediately usable. Put plans, study, audio, notes, downloads, and discovery around that reliable reading surface instead of turning the Mushaf itself into a crowded dashboard.

## Evidence and limits

This benchmark uses Wahy's official Arabic and English feature pages, Tafsir Center's Wahy description, and the current Google Play and Apple App Store listings. It does not inspect Wahy's private code or reverse-engineer its application. Publicly advertised counts differ by page and change over time: the official web reader currently presents 81 reciters and 55 tafsirs, while store/other official copy advertises 64+ reciters and 184+ combined Quran-science, tafsir, and translation sources. The Arabic site also describes 184+ sources. Those figures likely use different categories or release snapshots; they are not a reliable acceptance target. Build a trustworthy, useful catalog rather than chasing a headline count.

The public materials do not establish redistribution rights for each item or document Wahy's internal implementation. Talib Ilm must verify the rights, provenance, attribution, and technical availability of every source independently.

## Wahy's publicly advertised product, organized by user need

| User need | Publicly listed Wahy capabilities | Product lesson for Talib Ilm |
|---|---|---|
| Read the Quran in a familiar form | Printed Madinah Mushaf pages; more than one Hafs print edition; Warsh edition; a second interactive/list reading mode; index/navigation | Keep the authentic Hafs page as the default. If a reflowed/list mode is added, make it a clearly separate view and never fake printed page layout with ordinary text wrapping. |
| Understand a word | Word meaning, transliteration, grammar/morphology, readings, pronunciation, and in some presentations word-by-word recitation | Build a source-labelled word-study panel. Add only fields actually supplied by a verified dataset; missing morphology or audio must be presented as unavailable, never fabricated. |
| Understand an ayah or surah | Tafsir/translation library, thematic tafsir, surah information cards, short text/audio introductions, quiz questions, verse-linked content | Make ayah study consistent and attributed. Add curated surah guides and quizzes only from reviewed sources with citations and correction workflow. |
| Listen and learn | Verse-aware recitation, follow/highlight the current verse, repeat verse/range, many reciters, downloads, individual-word pronunciation, tafsir audio | Preserve the existing player and downloads; close learner gaps with reliable resume/repeat and word playback where authentic recordings and alignments exist. |
| Find a passage | Arabic text search, spelling-oriented search, indexes for surah and Quran sections, direct links/references | Improve result context and stable links. Keep the existing local search/index useful offline. |
| Continue personal study | Multiple bookmarks, color/group organization, notes/comments attached to ayahs, last position, multiple Khatmah plans, progress tracking | Add plans and bookmark collections locally first. Keep reading state and notes under user control without requiring an account. |
| Read comfortably and consistently | Page themes, interface language, font controls, automatic page scrolling | Add auto-scroll as an opt-in reader mode with clear speed/pause controls. Keep settings discoverable and accessible. |
| Take study material elsewhere | Share an ayah with related translation/tafsir as text or image; copy/direct access links | Upgrade the existing share flow with source attribution and clean, user-selected content. Do not silently include unselected commentary. |
| Use supporting visual context | Photos/illustrations, augmented-reality illustrations, locations referenced by Quranic words | Treat as a later, content-heavy feature. Require verified contextual sources, location accuracy, accessibility, and a clear explanation that illustrations are educational context, not Quran text. |
| Use on multiple devices | The store says account sync was added; the web reader describes account access to bookmarks, Khatmah, and last reading position | Consider optional sync only after local records and conflict handling are sound. Core reading must not require sign-in or network access. |

Sources: [Wahy official feature overview (Arabic)](https://main.wahy.net/), [Wahy official feature overview (English)](https://main.wahy.net/en/), [Wahy web reader](https://web.wahy.net/en), [Google Play listing](https://play.google.com/store/apps/details?id=com.logicdev.quran_reader), [Apple App Store listing](https://apps.apple.com/us/app/wahy-holy-quran/id1615454207), and [Tafsir Center's description](https://tafsir.net/wahy).

## Talib Ilm baseline: what is already present

Verified in the local source at the repository baseline above:

- **Mushaf:** 604-page Hafs QCF rendering, tajweed presentation, page/surah/juz/hizb navigation, page themes, configurable text size, keep-awake, saved reading position. Warsh and Qalun were intentionally removed and are out of scope.
- **Index and search:** Surah, juz, hizb, and bookmark index surfaces; local Quran text search; result cards and direct opening at a reference.
- **Audio:** 43 configured reciters, ayah and continuous playback, active-ayah state, repeat modes, speed control, sleep timer, and downloadable surah audio. The count in configuration is not a promise that every external recording URL will always be available; the production catalog needs health and rights checks.
- **Ayah study:** Ayah detail tabs, five configured tafsir choices, translation display, share action, and bookmark/note actions. Tafsir and word lookups use network sources with caching/fallbacks; this is not yet a complete, user-managed offline study library.
- **Word study:** A direct word-detail sheet was added at `93db172`. It uses Quran.com word-by-word data, currently requests English glosses, and exposes loading/error/offline behavior and neighboring-word navigation. This is a first interaction, not parity with Wahy's full morphology, languages, readings, and word-pronunciation experience. It has not yet received emulator/runtime validation in this increment.
- **Personal progress:** Reading minutes, verses, streak, and reading history. No Khatmah schedule or target-date planner is implemented; the current displayed daily goal is fixed.
- **Bookmarks and backup:** Up to 200 verse/surah bookmarks, one optional note per verse bookmark, and JSON export/import/merge for user backup. There are no named bookmark groups or colors.
- **Offline:** The Mushaf/core Quran data is available locally; recitations can be downloaded; some opened study data is cached. There is no unified source catalog and study-content download manager.
- **Missing advertised study tools:** No Khatmah plans, bookmark collections, reader auto-scroll, verified multi-language word study, word-level audio, surah knowledge cards/audio, Quran-content quiz flow, or educational imagery/location layer was found.

### Current ratings

These are engineering/product judgments, not store ratings. The prior audit's **overall Quran-section readiness is 7.0/10 after direct word lookup**. Against Wahy's advertised breadth, Talib Ilm is about **6.5/10 for capability coverage**: its core reader, navigation, and audio are strong; planning, content breadth, and personal study organization are the major gaps. This does not mean Wahy's features should all be copied or that a count of features predicts religious-content quality.

| Area | Talib Ilm | Gap |
|---|---:|---|
| Hafs Mushaf fidelity and reader foundation | 9/10 | Protect it; add regression coverage before altering renderer or page mapping. |
| Navigation and search | 8/10 | Improve discovery/context and direct links where users hit friction; do not replace working offline index without evidence. |
| Recitation and audio controls | 8/10 | Validate real device/background reliability; add word audio only when timing/assets are trustworthy. |
| Word study | 6.5/10 | Current direct lookup is English-first; morphology and other languages are not populated. |
| Tafsir/translation catalog and offline management | 4/10 | Five sources, remote-dependent lookup, incomplete catalog/download experience. |
| Khatmah / reading plans | 2/10 | No plans, target completion date, daily assignment, or plan progress. |
| Bookmarks and reflection | 5.5/10 | Bookmarks and one note exist, but there are no groups/colors and there is a hard 200-item cap. |
| Offline study resilience | 7/10 | Core reading/audio are strong; cached lookup is not equivalent to user-controlled offline content packs. |
| Reader personalization | 6.5/10 | Themes, tajweed, and sizing exist; no auto-scroll mode was found. |
| Cross-device continuity | 3/10 | File backup exists; account sync does not. |
| Surah learning, quizzes, visual context | 2/10 | Little or no source-backed, structured learning layer currently exists. |

## Recommended product design

### Keep the Mushaf sacred and quiet

The reading surface stays focused on the page. Word tap opens word study; verse long-press opens verse actions; playback follows verses without covering text. Study details belong in sheets or a dedicated study view. A user can always dismiss the study layer and return to the same page and scroll position.

### Make content status explicit

Every translation, tafsir, word gloss, grammar field, recitation, and media item should carry a source identifier, language, author/publisher, rights/attribution text, version/date, and offline state. Show the source near the content and in its detail view. An unavailable field is omitted or labelled; the app must never use generated religious text to fill a gap.

### Local-first, optional cloud

Plans, notes, bookmarks, and last-read state should work with no account. Backups should be portable. Sync can be opt-in later, with a clear conflict policy, encryption, account deletion, and offline behavior. Never make sign-in a gate to the Quran or to an existing user's local study data.

### Put advanced tools behind deliberate entry points

Keep common actions obvious: continue reading, find a passage, play, bookmark, today's plan. Put source selection, downloaded packs, word analysis, quizzes, and media under a compact Study/Library destination. Avoid placing every setting and feature directly on the Mushaf page.

## Prioritized implementation roadmap

### Phase 0 — Reliability and content governance (foundation)

1. Inventory every Quran content endpoint and bundled dataset: text, translation, tafsir, word meanings, audio, page images/fonts, and any future content.
2. Record per-source provenance, publisher, license/redistribution terms, attribution requirement, language, version/update method, and contact/terms URL.
3. Add a typed catalog model so UI choices are data-driven rather than growing another enum/switch for every source.
4. Measure request success/failure, response freshness, cache hit rate, and offline fallback without logging personal Quran notes or sensitive reading details.
5. Validate current API production requirements and remove fragile/unowned fallbacks only after a replacement is proven. Do not expand beyond five tafsirs or the current word feed until each source passes the same review.

**Done when:** every visible content choice has a named source and language; network failure has a tested and understandable offline state; no source is represented as downloadable/offline unless its data is actually stored and usable.

### Phase 1 — Local-first Khatmah planner (best next user-facing feature)

1. Create one or more plans with start date and either end date, duration, or a chosen daily amount.
2. Let users schedule by pages or juz; calculate assignments against the 604-page Hafs mapping and validate boundary conversions.
3. Show today's assignment, completed amount, overall progress, next session, and a calm overdue/catch-up state.
4. Support pause/resume, edit, archive/delete, and missed-day recovery without marking unseen content as read.
5. Record explicit plan completion separately from passive minutes/verse-count statistics.
6. Offer optional local reminders only after the plan logic is correct; reminders must be user-controlled and permission-aware.

**Done when:** dates, leap/month boundaries, paused plans, timezone changes, duplicate completion taps, missed days, and migrations are covered by deterministic tests; the plan works offline and with no account.

### Phase 2 — Bookmark collections and better notes

1. Add named collections with a small accessible color palette; allow a bookmark in multiple collections if the model and UX make that valuable.
2. Preserve existing bookmark coordinates, timestamps, surah bookmarks, and notes by migrating every old entry into a default collection.
3. Replace the hard 200-item behavior with a storage-backed policy that does not silently discard user material. If a limit remains for product reasons, warn before it is reached and never drop an older bookmark without consent.
4. Support finding/filtering bookmarks and editing notes from the collection view.
5. Version and extend backup/import format; test importing older JSON and merging duplicates without losing notes or group assignments.

**Done when:** migration and backup round trips preserve every item exactly; every add/update/delete operation has explicit feedback; no data is silently truncated.

### Phase 3 — Trusted study library and offline packs

1. Ship a catalog of current sources with title, scholar/translator, language, content type, attribution, license state, size, version, and availability.
2. Provide search/filter and source selection on the ayah and word study surfaces.
3. Add explicit download, pause/resume, retry, remove, and storage-usage states for sources whose license permits local storage.
4. Make user-selected downloads scoped (a language/source or selected surahs), resumable, integrity-checked, and recoverable after app restart.
5. Clearly separate core bundled Quran text/Mushaf assets from optional downloadable study/audio resources.

**Done when:** downloaded content continues working in airplane mode, integrity failure is detected, storage can be reclaimed, attribution persists, and the selected source is visible wherever its text appears.

### Phase 4 — Word-level learning, responsibly

1. Upgrade the current word sheet around a stable word identity (`surah:ayah:word`) and verified ordering aligned with the renderer.
2. Add language/source choice for translations only when the selected dataset is complete and vetted.
3. Populate morphology, grammar, and qira'at/readings only from an identified scholarly source; disclose the source and any limitations.
4. Add individual word playback only if licensed recordings and accurate word/audio alignment exist; provide a clear fallback to ayah playback.
5. Add previous/next word and ayah context without making word navigation accidentally move the Mushaf page.
6. Make content downloadable only under explicit source-specific rights.

**Done when:** test fixtures cover basmala, punctuation/waqf symbols, words with multiple orthographic forms, verse-final markers, missing data, RTL, and offline state; tapping a displayed word always resolves to its matching source record.

### Phase 5 — Reading/listening tools

1. Add optional Mushaf auto-scroll with a simple speed selector, pause/resume, immediate pause on touch, and stop-at-surah/page controls.
2. Keep audio playback state and visible ayah in sync after screen lock, backgrounding, route changes, and downloaded/streamed transitions.
3. Add user-defined ayah/range repetition with repeat count and pause interval if not already sufficient in the existing player UI.
4. Provide compact, accessible controls and persist only preferences, not assumptions about user completion.

**Done when:** audio and scroll remain synchronized in foreground/background and stop deterministically; controls work under RTL, large text, and screen readers.

### Phase 6 — Curated surah and ayah learning resources

1. Build short Surah Overview cards (names, verified themes, context, key metadata, optional audio) using explicitly cited editorial sources.
2. Add quizzes only from an approved question bank with answer references and review status; no model-generated religious questions or tafsir.
3. Add contextual images, maps/locations, or AR only after per-item verification, licensing, accessibility alt text, privacy review for location, and a strong explanation of the image's educational role.
4. Keep these resources optional and separate from Quran text, with a source/credit visible at the point of use.

**Done when:** content has reviewer/source metadata, correction and removal process, clear attribution, and no misleading visual implication about sacred text or historical certainty.

### Phase 7 — Optional sync and continuity

1. Define the minimum synchronized records: bookmarks/collections, notes, plans, last-read position, and reader preferences.
2. Specify encryption in transit/at rest, account deletion/export, duplicate handling, simultaneous edits, stale devices, and conflict resolution.
3. Keep local records authoritative while offline and show sync state/errors clearly.
4. Provide a migration from current JSON backups and never overwrite local content silently on sign-in.

**Done when:** offline edits converge predictably, conflict tests pass, users can export/delete their data, and the app remains fully usable when the account service is down.

## Recommended build order and scope control

Do not try to reproduce all of Wahy in one implementation sprint. The reliable sequence is:

1. **Foundation:** source/rights catalog and behavior audit for existing remote content.
2. **Khatmah planner:** greatest user-facing gap that does not depend on external content or account infrastructure.
3. **Bookmark collections:** high-value personal organization, with careful migration/backup.
4. **Study source catalog and selective offline packs:** unlock breadth without pretending network caches are a full offline library.
5. **Word-study depth:** more languages and analysis from vetted datasets, then word audio if real assets/alignment are available.
6. **Auto-scroll and audio-follow polish.**
7. **Surah cards/quizzes/context resources.**
8. **Optional sync.**
9. **Images/AR/geography last:** high content-validation and maintenance cost, lower value than core study/planning tools.

Do not set an arbitrary goal of matching “184 sources” or “81 reciters.” Set measurable outcomes instead: correct source attribution, user-selected offline access, reliable passage lookup, successful completion planning, and preservation of all user data.

## Release acceptance checklist for each Quran increment

- Hafs page assets, text, page numbering, tajweed, and saved position have zero unintended changes.
- Quran text and all explanations remain clearly distinct; every non-Quran content item identifies its source/language.
- Reading works offline, and online-only content says so before the user relies on it.
- No existing bookmark/note/backup data is discarded during migrations.
- RTL, small screens, landscape, enlarged accessibility text, screen readers, and Android/iOS navigation are covered.
- Empty/loading/error/retry/offline states are designed and tested, not just the successful network path.
- Focused tests and the full quality gate run for implementation work; screenshots/goldens are reviewed when reader UI changes.
- New dependencies, APIs, media, and datasets are reviewed for license, maintenance health, privacy, app-size, and failure modes before adoption.

## Implementation handoff summary

The next implementation ticket should be **Phase 0 source/content foundation plus Phase 1 local-first Khatmah**, delivered in separate bounded changes. First audit the current stats and persistence model, propose and test plan data structures, and preserve Hafs page mapping. Do not add account sync, new riwayat, remote bulk catalogs, AR, AI tafsir, or new Quran text in that ticket. Once the planner is stable, continue in the sequence above.

## References

- [Wahy official Arabic feature overview](https://main.wahy.net/)
- [Wahy official English feature overview](https://main.wahy.net/en/)
- [Wahy web Quran reader and source catalog](https://web.wahy.net/en)
- [Google Play: Wahy (Holy Quran)](https://play.google.com/store/apps/details?id=com.logicdev.quran_reader)
- [Apple App Store: Wahy: Holy Quran](https://apps.apple.com/us/app/wahy-holy-quran/id1615454207)
- [Tafsir Center's official Wahy description](https://tafsir.net/wahy)
