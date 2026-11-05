# Quran Download Packs and Riwayat — Deep Implementation Plan

**Status:** Implementation in progress. The first Phase 1 contract slice and the fail-closed legacy Warsh guard are implemented. Phase 1 remains open because no official archive has yet been obtained for a production-format and on-device benchmark. The active reader, bundled corpus/fonts, package dependencies, and downloadable pack flow are not migrated yet.

**Prepared:** 5 November 2026
**Implementation started:** 5 November 2026
**Product goal:** Reduce the installed app’s base size by removing the bundled Quran corpus and page-font library, while adding verified Hafs, Warsh, and Qalun editions that users can download and then read offline.

### Implementation checkpoint — 5 November 2026

- Added stable `QuranRiwayahId` values (`hafs`, `warsh`, `qalun`) and a strict edition-scoped manifest model. The model validates source identity, all 114 ordered surah ranges and their aggregate count, capability-to-asset requirements, safe relative paths, HTTPS URLs, storage totals, SHA-256 fields, Ed25519 envelope shape, and canonical UTC timestamps.
- Added `docs/schemas/quran-pack-manifest-v1.schema.json` and synthetic metadata-only contract tests. The signature parser validates its envelope only; cryptographic verification and pinned-key validation remain mandatory Phase 3 install gates.
- Removed the unused `QuranEdition` catalog that mapped Warsh to an API identifier. `EditionService` now rejects the old `warsh` download ID, hides legacy Warsh files/preferences from installed-edition state, and returns an unavailable state for stale selections. It does not delete legacy bytes yet. `QuranRepository` no longer falls back to cached/API Hafs content for an unavailable non-Hafs narration.
- Added tests proving a stale Warsh file cannot be selected or loaded and an unscoped cached Hafs surah cannot be returned for Warsh. The existing legacy downloader tests now use the separate `tajweed` endpoint only as an IO/atomic-write test seam; this is not a production riwaya-pack implementation.
- Added `tool/quran_pack_format_benchmark.py`. Against the local `quran` package’s Tanzil Simple Hafs proxy (not a release source), it measured 6,236 records: JSON 2,579,604 B raw / 561,370 B gzip-9; SQLite 3,928,064 B raw / 1,004,470 B gzip-9; Python JSON parse 66.526 ms / 10,450,908 B traced peak; SQLite random ayah lookup p50 0.0343 ms and full-surah read p50 0.2827 ms. These host/Python numbers do not predict Flutter/iOS/Android performance or official pack size. SQLite is the v1 candidate because indexed partial reads avoid eagerly parsing the whole text; the format decision is provisional until official source archives and real-device Dart benchmarks are measured.
- Added `tool/inspect_kfgqpc_quran_archive.py` and synthetic ZIP safety tests. The inspector verifies the official published SHA-256 before trusting ZIP metadata, rejects unsafe archive structures, and emits only a content-free file inventory; it neither extracts nor prints Quran text, validates scripture, nor creates a distributable pack. Run it with `python tool/inspect_kfgqpc_quran_archive.py --edition <hafs|warsh|qalun> --archive <official-package.zip>`. Its published SHA-256 pins are recorded in the source ledger below. Synthetic test archives may inject a hash through the Python API; the production CLI has no checksum override.
- The official KFGQPC portal metadata is recorded below, but direct archive requests from this environment reset before download. The official page’s formats/schema and archive metadata are discoverable, yet its live developer page does not load from this environment and no matching official archives are present in the workspace. No official production archive, font, or Quran text was imported. Do not generate or publish Warsh/Qalun packs from the local Hafs proxy or unverified third-party mirrors.
- Verification after cleanup: 21 focused Quran/legacy-edition tests pass; the full serial repository suite passes 824/824; `flutter analyze --no-pub` reports no issues; the Draft 2020-12 schema validates and accepts the synthetic manifest fixture; `git diff --check` is clean; `flutter build apk --debug --no-pub` succeeds (81.3 seconds). iOS build and real-device QA have not been run for this change.
- No reader, Quran asset, font, package dependency, UI, or release-size change was made. The runtime still uses the existing bundled Hafs path.

**Next implementation slice:** obtain the exact official Hafs, Warsh, and Qalun archives whose SHA-256 values are listed below; run the content-free inspector; then inspect the real files/schema and document source licensing and attribution. Only after that can the deterministic converter and corpus checks be implemented without guessing. Do not expose Warsh/Qalun selection before a signed, verified pack is available.

---

## 1. Executive decision

This work is feasible, but it is a Quran data-platform change, not a font swap or a small UI task. The current app has a Hafs-centred reader with bundled verse/page data, page fonts, fixed 604-page assumptions, and many features that call the `quran` package directly. A safe implementation must first introduce an edition-aware content layer, then migrate every reader consumer, then remove the bundled content and fonts.

The recommended product behavior is:

1. The app installs with a small Quran navigation catalog only. It does not contain full ayah text, a complete Mushaf font set, page images, or an unverified Quran fallback.
2. The Quran section explains that an edition must be downloaded before reading. It presents Hafs, Warsh, and Qalun as separate editions, with the source, version, size, and offline status shown clearly.
3. The user downloads one or more editions. A completed pack remains available offline until the user explicitly removes it.
4. The reader, search, bookmarks, last-read state, page mapping, audio metadata, and tajweed behavior all use the selected edition. The app never silently substitutes Hafs when a Warsh or Qalun pack is unavailable.
5. Existing exact 604-page QCF rendering is kept behind a separate optional Hafs layout pack until a smaller, verified replacement has passed visual and content validation. Removing the current font bundle is a final cutover step, not the first step.

This design distinguishes **not bundled** from **not stored locally**: the Quran corpus is not shipped inside the application, but a user who downloads a pack necessarily stores it on the device so reading continues offline.

---

## 2. Current codebase ground truth

The implementation must account for the following current state. These are repository findings, not assumptions to carry forward without rechecking at the start of each implementation phase.

| Current area | Evidence in repository | Consequence |
|---|---|---|
| QCF asset weight | Direct ZIP inspection of the local arm64 release APK found 69,978,337 compressed bytes (69.98 MB / 66.74 MiB) under `qcf_quran_plus`; 604 page-font files account for 68,730,497 bytes (68.73 MB / 65.55 MiB). | Removing the page fonts is the dominant opportunity, but the exact saving depends on the pack/rendering design. Rebuild the same release artifact after implementation. |
| 604-page assumption | The viewer clamps to page 604 and builds 604 items in [mushaf_page_viewer.dart](../lib/features/quran/presentation/widgets/mushaf_page_viewer.dart); [quran_database.dart](../lib/features/quran/data/database/quran_database.dart) and other paths also enforce 604. | Page bounds and page navigation must belong to the edition/reader layout, never to a global constant. |
| Bundled Quran data | `packages/qcf_quran_plus/lib/src/data/quran_data.dart` contains page/ayah records. The app also depends on `quran: ^1.4.1`. | Removing the fonts alone does not meet the no-bundled-corpus goal. Audit all data sources and compiled assets. |
| Broad static helper usage | Thirty Dart files currently import `package:quran/quran.dart`. Consumers include the reader, bookmarks, favorites, history, stats, page lookup, search snippets, tafsir fallbacks, audio labels, and deep links. | Replace package calls through a repository/API boundary in manageable steps; do not delete the dependency before call sites are migrated. |
| Misidentified Warsh source | [edition_service.dart](../lib/features/quran/data/services/edition_service.dart) maps `warsh` to Al Quran Cloud’s `quran-simple` endpoint. It is not a source declaration for an official Warsh narration. | Remove this mapping and invalidate any content downloaded under that identifier. Never display that content as Warsh. |
| Existing download flow is not authoritative | `EditionService` has download/storage logic, but it is not a complete runtime riwaya flow. `QuranCacheService.getSurah` falls back to Hafs/API when a requested non-Hafs edition is missing. | Replace fallback semantics; the app must report “edition not installed” and offer the correct download action. |
| Existing Quran cache | `QuranCacheService` saves full surah JSON in `SharedPreferences` for 30 days. `QuranRepository` can fetch from an API. | Full corpus belongs in a versioned local pack/database, not large preferences values or an unlabelled transient cache. |
| Bookmark page coupling | `bookmark_models.dart` validates against `quran.getPageNumber` and rejects pages beyond 604. | Preserve stable verse identity and notes; treat old page numbers as legacy Hafs display hints rather than universal coordinates. |
| Existing page database/sync | `QuranSyncService`, `QuranDatabase`, `QuranPageService`, and `QuranApiService` have a separate page-data path. | Audit and either adapt these components to the selected edition pack or remove/retire duplicate APIs after proving no consumer remains. |
| Tajweed is Hafs-oriented | The current API/parser requests `text_uthmani_tajweed` and the QCF font pack is not the same as an approved Warsh/Qalun tajweed corpus. | Tajweed support must be explicitly edition-scoped. Never decorate Warsh/Qalun with Hafs markup. |
| Audio is a separate concern | Reciters currently have no reliable riwaya field shared with the edition model. | Text pack availability must not imply that a matching reciter or audio download is available. |

### Baseline measurement caveat

Before changing code, record on a clean, exact commit:

- Android AAB upload size;
- Android `bundletool` device download size for arm64 and at least one other supported ABI;
- universal/debug APK size for diagnosis only;
- iOS archive/App Store thinning measurements where the existing CI/tooling can produce them;
- inventory of Quran-specific assets and generated Flutter asset manifests.

The local arm64 APK at `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` is **145,038,107 bytes (145.04 MB decimal / 138.32 MiB)** with SHA-256 `7057C79CB51175CA59F86282D2B1682EB587E1595C1AB5B2E43D9E5504E5292E`. It was modified at 2026-11-04 20:12 UTC, about two minutes before current HEAD `6ed25b5` (20:14 UTC), so it is a high-quality asset baseline but not an exact-head artifact. ZIP inspection measured all `qcf_quran_plus` package entries at 69,978,337 compressed bytes; removing that entire asset category alone would give a simple arithmetic estimate of about 75.06 MB decimal / 71.58 MiB for this APK, **not** a predicted final build size. The user-provided “138.32 MB” figure is MiB, not decimal MB.

The archived AAB report at [BUNDLE_SIZE_REPORT.md](../build/release-readiness/size-analysis/latest/BUNDLE_SIZE_REPORT.md) was generated on a dirty, non-main commit. Its 183.87 MB AAB size is historical, and its stated 109.33 MB “Play download” must not be treated as a validated delivery measurement: the repository’s release remediation guide records that the prior calculation was derived by subtracting selected AAB entries rather than a valid device-specific `bundletool get-size total` result. Capture a new exact-head AAB and device-spec result before claiming Play Store savings.

The attached proposal’s 48 MB target is not compatible with its own reported component breakdown: its cited 55.29 MB native libraries already exceed that target before Java/Kotlin code or non-Quran assets. The release target should be set from a fresh exact artifact and a separately named measurement (standalone arm64 APK, AAB upload, Play device delivery, or IPA).

---

## 3. Authoritative content, provenance, and data-quality rules

### 3.1 Preferred content authority

Use King Fahd Quran Printing Complex (KFGQPC) developer material as the primary source for Quran text and narration-specific Unicode font data. The Complex describes its developer platform as providing checked, ready-to-use Quran text in multiple computing formats and Unicode fonts for different narrations. Its official material identifies Qalun as a reading used in Tunisia and Libya. The platform announcement is [here](https://qurancomplex.gov.sa/%D9%85%D8%AC%D9%85%D8%B9-%D8%A7%D9%84%D9%85%D9%84%D9%83-%D9%81%D9%87%D8%AF-%D9%84%D8%B7%D8%A8%D8%A7%D8%B9%D8%A9-%D8%A7%D9%84%D9%85%D8%B5%D8%AD%D9%81-%D8%A7%D9%84%D8%B4%D8%B1%D9%8A%D9%81-%D9%8A%D8%AA-2/); the developer platform is linked at [qurancomplex.gov.sa/techquran/dev](https://qurancomplex.gov.sa/techquran/dev). Dedicated Qalun Unicode font details are published [here](https://fonts.qurancomplex.gov.sa/qaloun-reading/); Warsh font details are [here](https://fonts.qurancomplex.gov.sa/warsh-reading/).

**Page-count source discrepancy—do not hardcode either value from a general web page.** A KFGQPC research publication describing its 15-line Warsh and Qalun Mushafs reports 604 numbered pages; the current KFGQPC sales listing reports 640 product pages for editions under those names ([research publication](https://jqrs.qurancomplex.gov.sa/wp-content/uploads/jqrs-docs/28/04-%D9%85%D8%B5%D8%A7%D8%AD%D9%81-%D8%A7%D9%84%D8%B1%D9%88%D8%A7%D9%8A%D8%A7%D8%AA-%D9%81%D9%8A-%D9%85%D8%AC%D9%85%D8%B9-%D8%A7%D9%84%D9%85%D9%84%D9%83-%D9%81%D9%87%D8%AF-%D9%84%D8%B7%D8%A8%D8%A7%D8%B9%D8%A9-%D8%A7%D9%84%D9%85%D8%B5%D8%AD%D9%81-%D8%A7%D9%84%D8%B4%D8%B1%D9%8A%D9%81.pdf), [sales listing](https://qurancomplex.gov.sa/sales/qiraat/)). The exact digital source archive and its page index must determine the page model used in each pack. Distinguish numbered Quran pages from a retail product’s physical page count, and keep the count in edition metadata rather than a global constant.

KFGQPC’s digital Mushaf portal publishes Hafs, Warsh, and Qalun editions as Illustrator vector files, and its usage page permits use of the digital edition in software/computer programs and other listed contexts ([digital Mushaf portal](https://dm.qurancomplex.gov.sa/), [usage rights](https://dm.qurancomplex.gov.sa/rights/)). This is a strong candidate for a faithful optional page-layout pack. The source is AI vector; it does not establish that official WebP/SVG files already exist, nor that a converted 604-page pack will be 42 MB. Conversion, numbering, derivative distribution terms, and actual pack sizes must be verified and measured.

### 3.2 Source acceptance checklist

#### Preliminary official source ledger captured 5 November 2026

| Edition | KFGQPC developer archive metadata | SHA-256 published by KFGQPC | Notes |
|---|---|---|---|
| Hafs ʿan ʿĀṣim | Version 15.0; listed archive size 9.68 MB | `227E6B1564D980F2BD09C2C35EBFB0330AC268C79A7C247CD1AB665BC635F245` | Official developer source package; archive still needs to be obtained and inspected. |
| Warsh ʿan Nāfiʿ | Version 8.0; last updated 1 October 2026; listed archive size 8.49 MB | `D79B0E9D71696E6967A8F9051E62DA87E3AD797E76C6B9D931D66FCF7739BBDA` | Source page lists Unicode ayah text and page/line fields. The archive includes several developer formats and documentation; 8.49 MB is not the final app pack size. |
| Qalun ʿan Nāfiʿ | Version 7.0; last updated 30 September 2022; listed archive size 8.21 MB | `32552185FDA5520EB4CAE741CC01162DC866FE3A224D921F4C182DE4A7B965D9` | Source page lists Unicode ayah text and page/line fields. The archive is older than Warsh’s; inspect the actual archive and update history before release. |

The official developer data schema exposes source page, line start/end, surah number, ayah number, Unicode text, and other metadata. KFGQPC’s dedicated Unicode Qalun font page lists version 3.0 at 0.99 MB (ZIP containing the TTF and a complete Word sample). These archive/font sizes are source-download metadata only; the Phase 2 pack builder must measure the extracted and normalized payload actually shipped. The source ledger is preliminary until the exact archives are obtained and their internal hashes/schema are independently checked. The archive inspector verifies the whole ZIP against this published SHA-256 ledger; an official digest match is necessary provenance evidence, not a substitute for the content review and copyright/redistribution approval gates.

The KFGQPC research paper reports a 6,214-ayah count under the stated Madinan numbering for its Warsh and Qalun descriptions. Preserve the count system and source identity with each pack; do not derive or convert verse numbers from a Hafs constant.

### 3.3 Source acceptance checklist

Before producing a release pack for each narration, record:

- issuing organization and canonical source URL;
- exact narration label in Arabic and English, including the transmitting reader (e.g. Warsh/Qalun `ʿan Nāfiʿ`) where approved by the source;
- source archive filename, version, published/updated date, and official checksum if supplied;
- exact digital page-index semantics and source publication/edition that the page count refers to, especially where official catalog pages disagree;
- font family/version/license/attribution information;
- selected machine-readable source format and its schema;
- declared surah/ayah counts, page count, line metadata, and any numbering conventions;
- transformations made by the pack builder, each reproducible and reviewable;
- verification output and a named human reviewer for the corpus comparison.

Do not pull Quran text from an API endpoint solely because its endpoint, filename, or font looks Arabic. In particular, `quran-simple` is not a valid substitute for a Warsh source. Do not combine Warsh or Qalun text with Hafs normalization, verse-end markers, tajweed markup, or page maps unless the authority confirms those transformations preserve the edition.

### 3.4 Distribution and licensing gate

The official developer platform is the preferred origin. Before hosting a normalized pack on an app-controlled CDN, confirm that the source’s terms allow this form of in-app delivery, retain required attribution, and document the confirmation. If a stable official download endpoint can be consumed directly under its terms, prefer that over maintaining a second content origin. Do not use Quran Foundation API responses to build a prepackaged dataset; its current developer terms restrict prepackaged Quran content and specify Content Sync rules for supported offline content ([Quran Foundation developer terms](https://api-docs.quran.com/legal/developer-terms/)).

No production pack endpoint should be committed to the app until its data rights, attribution, hosting, update, and correction process are recorded. API secrets, if any are ever needed for ancillary services, must not be embedded in mobile binaries.

---

## 4. Product contract and user flows

### 4.1 First install and first visit to Quran

1. The rest of the app remains fully usable when the user has no Quran pack and has no network.
2. Opening the Quran section displays an intentional “download an edition to begin” state, not a blank/error page or endless spinner.
3. The chooser shows Hafs, Warsh, and Qalun as distinct entries with:
   - the exact approved narration name;
   - a short neutral description;
   - source name and content version/date;
   - exact download size and required temporary storage estimate from the manifest;
   - the promise that reading works offline after successful installation;
   - the installed/downloaded status and a clear selection state.
4. Tunisia may receive a **suggestion** for Qalun, but country-based suggestion never silently selects, downloads, or changes the user’s recitation.
5. Do not download the corpus at app launch. Ask only when the Quran feature is opened or from a user-initiated download-management entry.
6. If the user declines, the app remains in the no-pack state and continues to work elsewhere.

### 4.2 Download and install

- Show byte-accurate progress when the server provides a trustworthy content length; otherwise use an indeterminate state with phase labels.
- Support pause/cancel/retry and process interruption. If resumable range requests are unavailable or inconsistent, restart the current part safely rather than append unverified bytes.
- Write to a temporary location. Verify full package hash, internal data hash, schema version, edition ID, font hash, record counts, bounds, and cross-references before activation.
- Install atomically: a failed download or update must leave the previous valid pack available.
- A successful pack becomes the current edition only after the user confirms it or selects it in the chooser. The downloader must not change the current edition as a side effect of completion.
- Once installed, all Quran reading and core search paths must work in airplane mode.

### 4.3 Multiple editions and storage controls

- Allow more than one installed edition; switching is immediate and does not require another download.
- Provide storage management with per-pack size, version, last update, active state, update availability, and delete action.
- The active edition cannot be removed silently. Require a replacement choice or an explicit confirmation that leaves Quran unavailable until another pack is installed.
- Updates are versioned. Keep the previous valid pack until the replacement verifies and the database is opened successfully.
- If the device lacks enough free space for both old and new pack during safe replacement, explain the required space and offer a user-approved remove/reinstall path. Never silently delete bookmarks, notes, audio downloads, or user settings to make room.

### 4.4 Offline and network failure states

Distinguish at least these states: no pack; checking catalog; download queued; downloading; paused; canceled; insufficient storage; network unavailable; server unavailable; hash mismatch; invalid schema; unsupported app/schema; installed; update available; deleting; and recovery after process death. Each failure state must say whether an already installed edition remains readable.

---

## 5. Target architecture

Implement behind interfaces so UI and features stop reading the global `quran` package directly.

### 5.1 Domain model

Introduce an edition identity and metadata model with at least:

- immutable edition ID (`hafs`, `warsh`, `qalun`);
- display label, source/transmission identity, source organization, and attribution;
- source/content version and publication date;
- data schema version and minimum compatible app version;
- package bytes, internal data bytes, font bytes, and required temporary free-space estimate;
- package/data/font SHA-256 values;
- edition-specific surah count, each surah’s valid verse range, and edition-specific page model/count;
- script/font family and rendering capabilities;
- separate capability flags for offline text, search, page grouping, tajweed, and audio mapping.

Do not let a nullable `fontName` or a display label determine the content’s narration. The edition ID, manifest, verified content, and font must agree.

### 5.2 Pack layout and database

The exact on-disk format should be chosen after a small benchmark of query time, file size, startup, and iOS/Android file handling. Recommended first candidate: one immutable, versioned SQLite database per edition plus the exact font file and manifest in one installed pack directory. An alternative compressed JSON format is acceptable only if memory, parse time, search, and partial reads meet the same targets.

Suggested logical tables/indexes:

- `manifest`: source/version/schema/hash/capabilities;
- `surah`: edition ID, source surah number, approved names, verse count, page start/end;
- `ayah`: edition-scoped key, sequence, text exactly as supplied by source, search-normalized text, optional approved transliteration metadata;
- `page`: edition-scoped page number and first/last ayah coordinates;
- `line`: only if source line metadata can be consumed without modifying/corrupting text layout;
- `juz_hizb_quarter`: edition-specific start coordinates;
- `verse_identity_map`: explicit validated mapping to cross-edition bookmark identity where the sources permit a one-to-one map.

The schema must preserve source text byte-for-byte or codepoint-for-codepoint in the display field. Search normalization is a separate derived column and must never be substituted into the reader.

Do not assume all narrations share the same page boundaries, script, Unicode combining behavior, ayah count, search normalization, or tajweed encoding. Every manifest reports actual values. The pack builder must fail closed when required source fields are missing or unsupported.

### 5.3 Service boundaries

Plan for these responsibilities (they may be combined into fewer classes after design review, but the boundaries remain):

1. **EditionCatalog** — reads a signed/pinned remote manifest or trusted official catalog, validates URLs and allowed hosts, returns available edition metadata.
2. **QuranPackDownloader** — streams bytes, reports progress, handles cancellation/resume, storage checks, timeouts, retry/backoff, and temporary files.
3. **QuranPackValidator** — verifies hashes, schema, edition identity, database integrity, record counts, coordinate bounds, and font compatibility.
4. **QuranPackStore** — atomically installs, enumerates, opens, updates, and deletes installed editions; reports storage usage.
5. **QuranContentRepository** — edition-aware read APIs: surah metadata, ayah by coordinate, ayahs by page/range, page from ayah, search, juz/hizb starts, and display metadata.
6. **ReaderEditionController** — manages current edition choice and emits explicit state changes; it never silently falls back to another riwaya.
7. **LegacyMigration** — reads existing bookmark/progress versions and maps stable coordinates without discarding user annotations.

The current service names (`EditionService`, `QuranCacheService`, `QuranSyncService`, `QuranPageService`, `QuranDatabase`, `QuranApiService`) should be inventoried and assigned one of four outcomes: migrate, wrap temporarily, deprecate after call-site migration, or delete after proof of no remaining use. Do not add a second competing downloader or cache layer.

### 5.4 Distribution manifest and trust

The catalog/manifest must be versioned and authenticated. HTTPS alone prevents basic transport tampering but does not prove an archive is the approved Quran. Pin or sign manifest metadata using a documented key-rotation scheme, and verify content hashes before installation. Do not put a private signing key in the app. Define how a bad manifest or compromised pack is revoked and how installed content is handled after revocation.

Never trust a filename, HTTP content type, file extension, announced byte count, or user-controlled path. Enforce maximum byte sizes, decompression limits, path traversal protection, allowed host policy, and atomic file writes. Do not extract arbitrary archive paths into app storage.

---

## 6. Edition-specific reader and feature behavior

### 6.1 Reader presentation strategy

Use two explicitly named presentation capabilities:

1. **Edition text reader:** a continuous, accessible ayah reader using the selected edition’s verified Unicode text and font. This is the baseline common reader for Hafs, Warsh, and Qalun, works offline after pack install, and does not claim pixel parity with a printed Mushaf page.
2. **Exact page-layout reader:** an optional renderer that is enabled only for an edition whose official page and line data, fonts, pagination, headers, and page breaks have passed a reference comparison. The existing QCF 604-page renderer is Hafs-only and remains an optional downloadable layout asset during migration.

For the first release, do not label a generic reflowed page as an exact Medina Mushaf page. KFGQPC page and line metadata may support pagination, and official Illustrator vector pages exist for multiple editions, but the actual mobile raster/vector rendering, page numbering, line breaks, headers, and page geometry need visual and textual parity review. If the exact layout for a riwaya is not validated, keep its reader in the honest text-reader mode while exposing source page references as navigation metadata.

### 6.2 Search

- Build a per-edition index from the selected pack; searching is not an API-only feature.
- Preserve the exact Uthmani display text and a separately normalized search key.
- Define which normalization features are supported (diacritics, tatweel, hamza forms, alef variants, alif maqsurah/ya, punctuation/verse marks) with tests; never mutate displayed scripture to improve search.
- Return results with edition ID, source surah/ayah coordinates, source page if available, and a snippet from that same edition.
- Search indexing must be bounded in memory and avoid loading the entire corpus into widgets.
- Results opened from a different edition must either resolve via a validated cross-edition map or show the edition they refer to and request its pack; never reinterpret the same numeric coordinate without validation.

### 6.3 Bookmarks, reading progress, and migration

- Make stable location the source of truth: edition ID + source surah/ayah coordinate + optional validated cross-edition identity.
- Store page number as a derived, edition-scoped location, not the only bookmark coordinate.
- Preserve current user notes, timestamps, surah bookmarks, audio timestamps, and reading history.
- Migrate existing `page` values as `legacyHafsPage` for display/diagnostics. Use the existing surah/ayah value to reopen content. Do not treat page 1–604 as valid in every edition.
- Old deep links such as `quran/page/{page}` need a compatibility policy. If the selected edition is not Hafs or the Hafs layout pack is absent, prompt to install Hafs or resolve only if a source-backed edition map exists.
- Backup/restore payloads need schema versioning and must preserve the selected edition and stable coordinates without embedding the Quran corpus itself.

### 6.4 Tafsir, translations, and ayah details

- Tafsir and translations remain separate editions/content resources with their own attribution and cache rules; they are not bundled into the base Quran pack by accident.
- Ensure ayah details always render the selected edition’s exact text. Tafsir citation text must not silently render a Hafs-only fallback under a Warsh/Qalun heading.
- Tafsir services that are keyed by numeric surah/ayah must be checked against source numbering for the selected riwaya. If mapping is uncertain, show the source passage only after verified coordinate mapping.
- An uninstalled Quran pack must never trigger an unmarked API fallback that creates a mixed-edition reader.

### 6.5 Tajweed

- The toggle and legend must reflect actual installed capabilities.
- Keep existing Hafs-specific `text_uthmani_tajweed` behavior scoped to Hafs until an authoritative Warsh/Qalun-marked corpus is secured and verified.
- When no approved narration-specific markup is available, disable/omit tajweed coloring for that edition with a clear capability message. Do not derive or interpolate tajweed colors from Hafs.
- Test that switching editions clears stale cached markup and never colors ayahs with the previous edition’s response.

### 6.6 Audio

- Add narration identity to reciter metadata only when the source explicitly provides it. Do not infer riwaya from the reciter’s country, name, or URL pattern.
- Keep audio packs/downloads separate from text/font packs. Show their sizes and licenses separately.
- Confirm recitation rights, direct-link stability, chapter/ayah mapping, and stream/download policy before shipping Warsh or Qalun audio.
- Audio playback, current-ayah highlight, verse boundaries, and page jumps must use the active edition’s validated ayah/page map.
- If the user chooses a text edition without compatible audio, the UI states that clearly and never switches the text edition to match an available reciter.

---

## 7. Migration and compatibility plan

### 7.1 Existing installations

1. Preserve bookmarks, notes, surah bookmarks, last-read surah/ayah, audio files, and preferences.
2. Detect legacy Quran cache keys (`quran_cache_*`) and legacy edition files.
3. Never accept the existing `warsh` downloaded file as verified Warsh; mark it invalid/unavailable and remove it only after the new pack manager can report that state safely.
4. Retain the existing installed app’s Hafs QCF assets during the transition release. New builds may stop bundling them only after download-and-reader acceptance passes.
5. Old transient cached surah JSON may be offered for controlled migration only if its source, version, edition, text integrity, and allowed use are proven. Otherwise, do not import it as canonical data. Keep user annotations; purge stale transient corpus data only after successful migration or explicit documented cleanup.
6. If no valid pack is installed after upgrade, show the download state. Do not make the whole app or prayer features depend on Quran pack availability.

### 7.2 Storage and backup

- Store packs in app-private files, not SharedPreferences and not user-visible external storage by default.
- Decide explicitly whether packs are excluded from cloud/device backup to avoid large backups; user data such as bookmarks and notes continues to follow current backup policy.
- Define cache/pack integrity on app restore, app reinstall, low-storage cleanup, and OS process termination.
- Packs are re-downloadable; user content is not. Keep those lifecycles separate.
- Use a documented deletion policy for old pack versions after successful activation and after a rollback window.

### 7.3 Deep links and favorites integration

- Canonical deep link form should use a stable Surah/Ayah identity and optional edition ID, e.g. an edition-aware verse coordinate, not a raw page number as the sole identifier.
- Existing page links remain accepted under the old Hafs semantics when possible. If not, show a recoverable prompt rather than opening a wrong ayah.
- Favorites that store Quran page/verse references must be audited alongside the Quran feature, especially [favorite_item_launcher.dart](../lib/features/favorites/presentation/widgets/favorite_item_launcher.dart).

---

## 8. Phased implementation roadmap

Each phase is a separate reviewable implementation increment. Keep working tree and user-owned branches intact; do not start coding in this planning step. Respect the repo’s max-file/session limits where they apply. If a phase crosses a 25-file boundary, split it and record the continuation point rather than mixing unrelated migrations.

### Phase 0 — Freeze the specification and capture baseline

**Purpose:** Establish what content exists, what exact product behavior is intended, and what size/quality baselines are real.

**Tasks:**

- Verify clean current branch/commit and capture the current release AAB, bundletool arm64 and second-ABI download sizes, and iOS artifact measurements where available.
- Inventory every Quran text/font/image/metadata asset in the app and generated asset manifests; distinguish bundled data from runtime caches.
- Build a call-site map for all `package:quran/quran.dart` imports and all page-number constants/604 checks.
- Trace `EditionService`, `QuranCacheService`, `QuranSyncService`, `QuranPageService`, `QuranDatabase`, and `QuranApiService` from UI to persistence and API.
- Obtain official Hafs, Warsh, and Qalun developer datasets/fonts; record provenance, hashes, version, schema, and distribution terms in a source ledger. Do not commit the corpus as part of the plan phase.
- Capture representative source pages/verses for textual and visual comparison: beginning, long surah, surah transition, sajdah/verse marks, and end of Quran.

**Exit gate:** Written source ledger accepted; exact current release baseline recorded; no unresolved ambiguity about whether “download” means on-demand local offline storage (recommended) or online-only reading.

### Phase 1 — Define canonical edition model and pack schema

**Purpose:** Prevent the current display-label/API-ID mismatch from recurring.

**Tasks:**

- Specify edition IDs, source identity, schema, source numbering, capability flags, page model, and signed manifest fields.
- Define whether source data’s verse keys map one-to-one across narrations. If yes, record evidence and mapping; if not, define edition-scoped coordinates and non-destructive bookmark behavior.
- Choose SQLite vs compressed JSON with a reproducible benchmark of file size, indexed search, memory, open latency, iOS/Android compatibility, and migration complexity.
- Define the local pack directory structure, atomic activation protocol, retained-version rules, backup exclusion, and recovery behavior.
- Add a non-production test fixture (synthetic/minimal records, never fabricated Quran text) for schema and failure cases.

#### Phase 1 progress and pack contract

| Phase 1 item | Status | Evidence / remaining condition |
|---|---|---|
| Stable edition IDs and source-to-edition binding | Done for the model | `QuranRiwayahId`; manifest and source must carry the same edition ID. The actual transmission still requires source-content review. |
| Strict manifest and JSON Schema | Implemented, pending review | `quran_pack_manifest.dart` and `docs/schemas/quran-pack-manifest-v1.schema.json`; tests cover malformed metadata. The schema cannot prove the Quran text itself. |
| Synthetic no-scripture fixture | Implemented | `test/features/quran/data/quran_pack_manifest_test.dart`; only synthetic metadata and placeholder text in an unrelated cache-isolation test. |
| Known-invalid legacy Warsh route/fallback | Closed in the current path | `quran-simple` is no longer accepted as Warsh; missing Warsh never reads unscoped Hafs cache. Legacy Warsh files are reported but retained inert pending explicit migration/cleanup behavior. |
| Storage-format comparison | Proxy benchmark complete; final choice open | The local Hafs proxy and Python results above are not official source or device metrics. SQLite is a provisional candidate; repeat with KFGQPC packs and Dart on supported Android/iOS devices. |
| Official source archives, their internal schema, and exact text identity | Open | Obtain the actual KFGQPC archives and validate archive hashes, formats, page/line fields, narration identity, and rights before production conversion. |
| On-device database/query/memory benchmark | Open | Benchmark cold-open, random ayah, surah/page range, local search, memory, storage, and update staging on representative Android and iOS devices. |

**Provisional v1 local layout (downloaded files remain local for offline reading):**

```text
Application Support/
  quran_packs/
    <editionId>/
      active.json                         # atomic pointer to active version
      last_known_good.json                # optional recovery pointer
      versions/<packVersion>/
        manifest.json                     # signed manifest used for this version
        content/quran.sqlite               # exact manifest-relative asset path
        fonts/<font-file>                  # only if declared by the manifest
      staging/<operationId>/               # same filesystem as versions/
```

The manifest is fetched over HTTPS from an allow-listed origin; validate its pinned Ed25519 signature over RFC 8785 canonical JSON **before** trusting URLs or size declarations. Download each declared file directly to a fresh staging directory (v1 does not unpack archives), enforce streaming byte limits, then compare exact byte length and SHA-256. Validate SQLite integrity, schema/user version, edition ID, surah/ayah counts, unique keys, coordinate ranges, required indexes, and font metadata against the signed manifest. Reject symlinks, path traversal, undeclared files, mismatched edition content, and unsupported app versions. Do not alter display-text code points during import; search normalization is a separate derived column.

After every asset and content check succeeds, rename the staging directory to `versions/<packVersion>` on the same filesystem. Write a temporary active pointer, flush it, then atomically rename it to `active.json`; only this pointer switch activates an update. Until then the previous active version stays readable. Retain the active version plus one last-known-good version; prune older versions only after activation and a restart/reopen check. On startup, validate pointer targets and recover only to a locally present version whose manifest signature and files revalidate. A failed, interrupted, or low-space update never removes or changes the active pack.

The signed `requiredTemporaryFreeSpaceBytes` is a server-declared minimum, not the sole client-side decision: preflight must also include the new pack, current/retained version bytes, SQLite journal/temp needs, and a safety reserve using locally measured storage. Do not evict the active version to make an update fit. Exclude downloaded pack directories from Android/iOS device backup while preserving user-owned bookmarks, notes, and reading state; verify this policy on both platforms before enabling downloads. Removing a pack must never remove annotations or other editions.

**Phase 1 exit gate:** Keep Phase 1 open until the official source archives have been inspected, source text/coordinates are confirmed immutable and edition-correct, the Android/iOS Dart benchmarks select the storage format, backup/restore behavior is settled, and schema review passes. The path and activation contract above is the current implementation target, not a claim that the downloader/store already exists.

### Phase 2 — Reproducible official data-pack pipeline

**Purpose:** Convert official archives into compact app packs without manual copy/paste or hand-edited scripture.

**Tasks:**

- Create a deterministic build pipeline that consumes separately obtained official source files and emits one pack per edition.
- Record source archive checksums and reject unrecognized source versions.
- Keep source text, source metadata, search-normalized fields, font, and page/line indexes separated.
- Validate Unicode normalization behavior without altering display text; report combining marks and codepoint changes.
- Enforce all source-record counts, coordinate bounds, unique keys, page monotonicity, valid surah references, and font-family identity.
- Emit manifest, pack checksums, report, and exact generated byte sizes.
- Keep source archives and generated production packs out of ordinary application assets and git history unless explicit licensing and repository policy permit them.

**Exit gate:** Two independent builds from the same source produce byte-identical output or documented deterministic-equivalent database content; all content checks pass and source provenance is reviewable.

### Phase 3 — Pack store, downloader, verifier, and catalog

**Purpose:** Ship robust downloading without yet making every Quran screen depend on it.

**Tasks:**

- Implement catalog retrieval, allow-listed HTTPS origin policy, signed/pinned manifest verification, and manifest expiry/error handling.
- Implement download state machine, progress, cancellation, retry, optional resume, storage preflight, and bounded streaming.
- Implement hash/schema/font validation and safe atomic installation.
- Implement list-installed, active-version, update, rollback, delete, and recovery operations.
- Ensure an invalid Warsh mapping/file cannot be installed or marked as an edition pack.
- Add observability that reports error categories and pack version without collecting reading content or personal Quran activity.

**Exit gate:** Fault-injection coverage proves interruption, cancellation, wrong hash, malformed database, path traversal, low storage, failed update, process restart, and rollback do not corrupt the last valid pack.

### Phase 4 — Edition-aware content repository and Hafs compatibility adapter

**Purpose:** Introduce one content API for app features while existing UI still functions.

**Tasks:**

- Define repository methods for surah metadata, ayah text, page/range reads, page lookup, search, juz/hizb lookup, and display labels.
- Add an explicit Hafs adapter that routes current behavior through the new interface while the existing assets remain present.
- Make every result carry edition identity or be bound to an immutable opened pack handle.
- Remove silent edition fallback. Missing Warsh/Qalun data returns an explicit unavailable/not-installed state.
- Update cache keys to include edition and pack version wherever a cache is still appropriate.
- Establish a temporary feature flag/diagnostic path so reviewers can compare old and new repository output on the same Hafs coordinates.

**Exit gate:** Existing Quran UI behaves as before in Hafs mode, and repository comparison shows matching text, metadata, and navigation for the sampled and exhaustive key sets.

### Phase 5 — Download-first user experience and user-controlled edition selection

**Purpose:** Make the new storage behavior understandable and recoverable.

**Tasks:**

- Add first-entry no-pack state, edition chooser, manifest size/source details, download progress, pause/cancel/retry, installed state, and offline confirmation.
- Add a Quran pack management screen/section with active edition, other installed editions, updates, and storage usage.
- Add a country-based suggestion only as a reversible suggestion; no geolocation permission is required to offer it.
- Ensure the Quran tab can recover from missing network, outdated catalog, no free space, invalid pack, or a deleted active pack.
- Keep screen-reader labels, RTL layout, large text, dark mode, tap targets, and the repo’s design tokens consistent.

**Exit gate:** A first-time user can install a pack; an offline user can reopen a valid pack; a user can switch/remove packs without losing annotations; failure messages identify the next action.

### Phase 6 — Migrate reader and all Quran text consumers

**Purpose:** Remove app-level reliance on static Hafs text and global 604 mappings.

**Task groups:**

1. Reader rendering: [quran_page.dart](../lib/features/quran/presentation/quran_page.dart), [mushaf_page_viewer.dart](../lib/features/quran/presentation/widgets/mushaf_page_viewer.dart), [mushaf_single_page.dart](../lib/features/quran/presentation/widgets/mushaf_single_page.dart), reader overlays/settings, and list reader.
2. Search/index/catalog: `quran_api_service.dart`, `quran_reader_index.dart`, search widgets, surah/juz/hizb cards, stats banner, and section headers.
3. Ayah details/actions: details sheet, action sheet, word view, tafsir fallback text, and tajweed services.
4. Supporting screens: bookmarks page/tab, reading history, audio download pages/player labels, deep-link service, and favorites launcher integration.
5. Storage/cache: `QuranCacheService`, `QuranSyncService`, `QuranDatabase`, `QuranPageService`, and any duplicate page cache.

For each consumer, replace direct package calls with an edition-aware repository call, then add a call-site regression check. Remove full text from SharedPreferences caches and keep large content in the versioned local pack database.

**Exit gate:** No runtime Quran screen silently reads bundled Hafs text while Warsh/Qalun is selected; every remaining legacy import is justified, metadata-only, and listed for final cleanup.

### Phase 7 — Migrate bookmarks, history, favorites, backup, and deep links

**Purpose:** Preserve user data across edition-specific pages and data removal.

**Tasks:**

- Version bookmark and last-read storage while preserving notes, timestamps, surah bookmarks, and old records.
- Recompute page display from the active edition when the source provides a valid page map.
- Preserve legacy Hafs page hints but do not validate them as Warsh/Qalun pages.
- Define cross-edition bookmark behavior if verse segmentation differs or a mapping is unavailable.
- Update backup/restore, favorite item navigation, and old page-based deep links.
- Verify app upgrade from a legacy install with no network, with network, with old cached Hafs surahs, and with existing audio files.

**Exit gate:** No user-owned annotation is lost; migration is idempotent; invalid legacy page coordinates cannot crash or navigate to an unrelated verse.

### Phase 8 — Add and verify Warsh and Qalun as real editions

**Purpose:** Enable additional riwayat with verified text, fonts, and edition-specific navigation.

**Tasks:**

- Produce Warsh and Qalun packs from the accepted KFGQPC sources through the Phase 2 build pipeline.
- Verify source text and fonts in Arabic shaping and Flutter across supported iOS and Android versions.
- Validate all verse/metadata/page mappings against source records; explicitly test the printed edition’s 640-page model where represented.
- Add edition-specific search normalization, page counts, juz/hizb boundaries, script markers, and ayah numbering from source data.
- Test switching Hafs ↔ Warsh ↔ Qalun while preserving stable reading position and annotations.
- Do not enable exact-page mode or tajweed mode for an edition unless that capability passed its own reference review.

**Exit gate:** Each edition has a source ledger, manifest, source hash, complete pack-integrity report, full-corpus structural checks, human-reviewed sample comparison, and offline device verification.

### Phase 9 — Decide and implement the compact reader/layout migration

**Purpose:** Remove the roughly 70 MB base-bundle QCF page-font library safely.

**Decision options:**

- **Recommended initial ship:** use the edition text reader for all editions; retain exact current Hafs QCF layout as an optional downloadable layout add-on for users who want it.
- **Promising alternative:** evaluate official per-edition vector Mushaf page archives as optional page-layout packs. Benchmark their actual archive and converted sizes, page indexing, page-open latency, memory, zoom, offline behavior, and text-scale behavior before selecting this path.
- **Later compact exact layout:** build/validate a source-backed page and line renderer for each narration using official data and fonts. Enable it only after line wrapping, page breaks, surah headers, basmalah placement, symbols, and text scale behavior match approved reference samples.
- **Do not ship:** remove the QCF assets and claim equivalent exact Mushaf layout before parity has been proven.

**Tasks:**

- Measure the optional Hafs layout download size separately from Quran text/font pack size.
- Convert QCF font loader from bundle-asset loading to pack-scoped local font loading only if technically and legally supported; otherwise ship it only as a separately declared Hafs layout asset pack.
- Ensure downloaded fonts are unloaded/closed safely when switching or deleting packs; handle platform font cache lifetime.
- Remove `qcf_quran_plus` static text/page data and font assets only after all dependent widgets, helpers, and tests have migrated.
- Remove `quran` package only after all 30 direct-import files and transitive consumers are migrated or replaced by a deliberately retained metadata-only abstraction.

**Exit gate:** New AAB/IPA excludes the old font family and static full Quran data; the optional layout asset, if retained, is not in the base binary; exact new size measurements and behavior parity evidence are attached.

### Phase 10 — Audio, tajweed, ancillary services, and attribution alignment

**Purpose:** Prevent the text edition from being contradicted by other Quran features.

**Tasks:**

- Add explicit narration metadata to reciter catalog only from verified source data.
- Verify licensing and operational stability for each Warsh/Qalun recitation source before adding audio downloads.
- Scope tajweed markup by edition; keep unsupported coloring disabled and accurately described.
- Verify tafsir/translation coordinate mapping against each edition and show source labels.
- Update Credits & Licenses, in-app source information, privacy/storage disclosures if necessary, and data-update procedures.

**Exit gate:** Every visible feature indicates whether its text/audio/markup belongs to the active narration; there is no silent mixed-edition presentation.

### Phase 11 — Remove legacy paths and run release gates

**Purpose:** Prove the size and correctness objective on the exact release commit.

**Tasks:**

- Remove the invalid AlQuranCloud `quran-simple` Warsh mapping and dead/test-only service code after preserving needed generic downloader tests.
- Remove any dead API fallback that could return Hafs into a non-Hafs reader.
- Remove old full corpus assets/dependencies only after repository search, generated asset manifest inspection, and analyzer/build proof.
- Run exhaustive content validation on all pack records; run search, storage, migration, and UI test suites; inspect representative screenshots on iOS and Android.
- Build release AAB/IPA; run bundle analyzer and compare to Phase 0 using exact commit, toolchain, target, ABI, and split profile.
- Re-check attribution, update/revocation procedure, crash recovery, battery/network use, storage, and airplane mode.

**Exit gate:** Release sign-off records base-binary savings, optional pack download sizes, installed storage, no-network behavior, corpus provenance, all test outcomes, known limitations, and exact source commit.

---

## 9. Verification matrix

### 9.1 Dataset and rendering integrity

- Every pack’s source hash, generated hash, manifest ID, font ID, version, and database integrity check agree.
- All records have valid and unique edition-scoped keys; all declared counts match actual records.
- Every page/line/juz/hizb mapping is monotonic and points to valid source coordinates.
- No display text is normalized, truncated, duplicated, omitted, or replaced by search text.
- Compare automated samples and a human-reviewed set for each riwaya at the beginning, middle, surah boundaries, and end.
- Check Arabic diacritics/combining marks, joining behavior, verse markers, basmalah exceptions, waqf signs, and right-to-left ordering on real iOS and Android devices.

### 9.2 Downloader and storage integrity

- fresh download, slow download, network drop, airplane-mode switch, process kill, app restart, cancel, retry, range-resume response mismatch, insufficient space, low disk during install, duplicate tap, concurrent edition download, corrupt archive, wrong hash, valid hash/wrong edition, wrong schema, expired catalog, blocked host, and failed update rollback;
- installed pack remains readable offline after restart and device reboot;
- deleting a pack deletes only its pack files/font cache, not bookmarks, reading history, user notes, audio, or other editions;
- app upgrade from each supported legacy schema migrates once and remains safe if interrupted.

### 9.3 Feature regression

- Quran home/index, surah and ayah navigation, page/verse jump, continuous reader, optional Mushaf layout, search, tafsir, tajweed, bookmarks, last-read, notes, reading history/statistics, favorites, deep links, audio streaming/downloads, background playback, and backup/restore;
- switching edition while viewing, from search results, from a bookmark, and while audio is playing;
- no-pack behavior and unsupported-capability messaging;
- Arabic RTL, screen-reader labels, text scale 1.0/1.5/2.0, dark/light, and low-memory devices.

### 9.4 Release size and performance evidence

Report at minimum:

- base AAB size and store/device delivery size by ABI;
- IPA/archive and App Store thinning size if available;
- Quran text/font pack download and installed size per edition;
- optional exact-layout pack size;
- first Quran-screen time with no pack, installed pack, cold database open, and warmed database;
- peak memory for search and reader startup;
- CPU and storage behavior during install and update;
- offline open time and scroll performance.

Size reporting must compare artifacts built from the same toolchain and equivalent release configuration. Explain differences from the archived 2 November baseline rather than treating them as regressions or gains.

---

## 10. Risks, mitigations, and decisions

| Risk | Severity | Mitigation / decision |
|---|---:|---|
| Quran text is mislabeled or silently mixed between narrations | Critical | Official source ledger; immutable edition ID; no fallback; source and sample review; manifest/text/font consistency validation. |
| Removing QCF fonts harms current Hafs page-reading UX | High | Retain as optional Hafs layout add-on until the replacement is verified; expose reader mode honestly. |
| Warsh/Qalun pagination differs from 604-page Hafs | High | Store edition-specific page metadata; remove global 604 constant; separate edition text reader from exact page renderer. |
| Combining marks render incorrectly on one platform | High | Official Unicode font, real-device matrix, comparison snapshots, and source codepoint diagnostics before enablement. |
| User loses bookmarks or opens the wrong verse after switch | Critical | Stable coordinate model, versioned idempotent migration, legacy page hint, no coordinate guessing. |
| Pack is corrupt, interrupted, or replaced by compromised content | Critical | Signed manifest, pinned keys, hashes, size limits, atomic install, old-version rollback, revocation strategy. |
| Host or official endpoint disappears / changes schema | High | Version-pinned source pipeline, manifest versioning, endpoint monitoring, deterministic pack archive, documented correction/update procedure. |
| Pack download conflicts with source distribution rights | High | Confirm source terms and attribution before publishing a mirror or downloadable pack; do not use restricted API content as a static pack. |
| App still bundles the Quran through an indirect dependency/generated asset | High | Search all imports/assets, inspect Flutter asset manifests and release binary, run bundle analyzer after removal. |
| Tajweed/audio does not match selected riwaya | High | Capability metadata and separate source approvals; disable unsupported capabilities rather than reuse Hafs data. |
| Large pack update needs more free disk than available | Medium | Manifest temporary-space estimate; keep old pack; explain options; no silent deletion. |
| First-use download hurts users on limited data | Medium | Show exact size, defer until Quran entry, optional Wi-Fi-only control, cancel/retry, do not auto-download at startup. |

### Decisions to settle before implementation starts

1. **Offline contract:** This plan assumes a downloaded pack remains local and works indefinitely offline; only pack/catalog updates require connectivity.
2. **Default for Tunisia:** This plan assumes Qalun is suggested but never selected without user action.
3. **Reader layout:** This plan assumes a universal edition text reader first, with exact page layout as a separately validated capability.
4. **Hafs asset policy:** This plan assumes current QCF exact layout becomes an optional large download until a smaller validated layout exists.
5. **Distribution origin:** This plan assumes official KFGQPC content is used, and any normalized mirror is published only after distribution terms and attribution are confirmed.
6. **Audio/tajweed scope:** This plan treats audio and non-Hafs tajweed as follow-up capabilities, not an automatic part of the text-pack launch.

These assumptions are the proposed default so implementation can proceed without blocking on avoidable questions. If the owner chooses a different offline or layout policy, update this plan before Phase 1.

---

## 11. Definition of done

The project is complete only when all of the following are true:

- Base app includes no full Quran ayah corpus and no 604-font QCF library.
- Hafs, Warsh, and Qalun each resolve to distinct, verified data/font packs from an approved source.
- Quran features cannot silently substitute Hafs content for another edition.
- Download, validation, atomic install, rollback, update, delete, and offline read work on Android and iOS.
- User bookmarks, notes, last-read state, favorites, and deep links survive migration and edition changes without coordinate guessing.
- Page navigation and page counts are edition-specific; exact-layout claims are limited to validated layouts.
- Search and display text are separated; display text remains source-accurate.
- Unsupported edition-specific audio/tajweed is clearly unavailable rather than falsely presented as compatible.
- No Quran text, fonts, or data remain in the base binary through indirect package assets, generated assets, or dead static data.
- Release size reduction is measured from exact, reproducible AAB/IPA builds and actual optional-pack sizes are reported.
- Source provenance, attribution, update/correction, rights, checksums, and support procedures are documented.
- Analysis, all relevant automated tests, release builds, device QA, offline QA, and corpus review pass on the final commit; any skipped check is explicitly recorded.

---

## 12. Implementation handoff

**Implementation order from the current checkpoint:** finish Phase 1 verification and source acquisition; build deterministic official-data packs; implement signed catalog/download/validation/atomic install; introduce the edition-aware repository and Hafs adapter; then migrate UI, reader consumers, bookmarks, history, audio/tajweed, and optional page layout. Remove bundled Quran text/fonts/dependencies only after consumer inventory and parity gates pass. The sequencing and gates in Phases 0–11 remain mandatory; this handoff updates their status and must not be read as permission to skip earlier gates.

**Files likely to anchor later phases:**

- Existing reader: `lib/features/quran/presentation/quran_page.dart`, `presentation/widgets/mushaf_page_viewer.dart`, `mushaf_single_page.dart`, overlays, list reader.
- Existing data path: `lib/features/quran/data/services/edition_service.dart`, `quran_cache_service.dart`, `quran_sync_service.dart`, `quran_page_service.dart`, `quran_database.dart`, `quran_api_service.dart`.
- Existing identity and persistence: `data/models/quran_models.dart`, `bookmark_models.dart`, `quran_reader_index.dart`, `services/bookmark_service.dart`, `bookmark_backup_service.dart`, `quran_deep_link_service.dart`.
- Cross-feature references: Quran widgets, `lib/features/favorites/presentation/widgets/favorite_item_launcher.dart`, audio/tafsir/tajweed services.
- Bundled source: `pubspec.yaml`, `packages/qcf_quran_plus/pubspec.yaml`, `packages/qcf_quran_plus/lib/src/data/`, `packages/qcf_quran_plus/assets/fonts/`.
- Existing Quran tests include `edition_service_test.dart`, `mushaf_page_viewer_test.dart`, `mushaf_single_page_test.dart`, `quran_api_service_test.dart`, `quran_reader_index_test.dart`, `quran_sync_service_test.dart`, bookmark suites, audio suites, tajweed suites, and Quran golden tests. Extend these rather than creating a parallel unconnected test structure.

**Current implementation state after the Phase 1 contract slice:** local uncommitted changes add the edition/manifest model, JSON Schema, format-benchmark tool, fail-closed legacy Warsh behavior, and focused regression tests. The Quran corpus, fonts, reader, user data, package dependencies, public release identity, and release assets are unchanged. No commit or push was made. See the checkpoint at the top for current verification status.
