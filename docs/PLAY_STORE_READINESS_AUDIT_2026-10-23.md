# Play Store readiness audit — 23 October 2026

**Verdict: NOT READY for production submission.** The project has substantial functionality and test coverage, but release identity/signing, target SDK, privacy disclosures, permission onboarding, and trustworthy visual verification need work first. This session audits only; it changes no application code, configuration, dependencies, data, or Arabic strings.

## Scope and evidence limits

- Audited checkout: `main`, `18e1202`; working tree initially clean. Read `AGENTS.md`, `DESIGN_SYSTEM.md`, `ROUND2.md`, `UI_PROGRESS.md`, the historical `.agent/UI_UX_AUDIT_REPORT.md`, `.agent/AGENT_DESIGN_BRIEF.md`, and relevant application sources. The `.agent` audit refers to `5b7b1c1`, so its findings are historical, not evidence of today's defects.
- This is a broad static and existing-artifact audit, not exhaustive execution of every feature or line-by-line scholarly verification. No app was launched, no live screenshots captured, no performance profiling performed, no Play Console account inspected, and no external content availability exhaustively tested.
- Found 80 test files and 236 PNGs under `test/golden` (counts are files, not passing tests or independent screen cases).
- Flutter analyze, tests, and debug build were attempted, but all are UNVERIFIED: SDK cache access is denied. Direct invocation of the installed Flutter snapshot reproduced: `Flutter failed to open a file at "C:\Users\pc\flutter\bin\cache\lockfile".` The initial wrapper attempts hung and were interrupted. No fresh AAB or size-analysis build was produced.
- Git branch creation failed: `fatal: cannot lock ref 'refs/heads/ui/r30-release-readiness-audit': Unable to create 'D:/Projects/talib_ilm-main/.git/refs/heads/ui/r30-release-readiness-audit.lock': Permission denied`. No commit, completion tag, or push was possible. Existing history was untouched.

## Priority findings

Priority meanings: P0 = submission/trust blocker; P1 = fix or explicitly resolve before production; P2 = hardening/maintenance. Findings distinguish observed facts from risks needing runtime confirmation.

| ID | Priority | Finding and evidence | Required resolution |
|---|---|---|---|
| R01 | P0 | `android/app/build.gradle.kts:35` sets `targetSdk = 34`. Both inspected release APKs confirm target 34, despite compile SDK 36. Current Play policy requires API 36 for new mobile submissions from 31 August 2026. | Migrate to target 36 and test Android behavior changes; compile SDK alone does not satisfy this. |
| R02 | P0 | `android/app/build.gradle.kts:44` signs release with debug configuration. `apksigner verify --print-certs` confirms `CN=Android Debug` on both APKs. | Create a protected upload key, configure release signing and Play App Signing, and verify the final signed AAB. Never commit keys/passwords. |
| R03 | P1 | `android/app/build.gradle.kts:31`, manifest package, Kotlin package paths, and audio channel ID still use `com.example.talib_ilm`. This is a template identity, not proof Google universally rejects that prefix. | Choose the permanent developer-owned application ID before creating the store app; inventory native references and installation/widget migration consequences. |
| R04 | P0 | Privacy text at `lib/features/more/presentation/credits_and_licenses_page.dart:231` says coordinates stay local and networking is limited to Quran.com/EveryAyah. `lib/core/services/location_service.dart:485` sends latitude/longitude to BigDataCloud when native geocoding throws (`:573`). Radio, Shamela, YouTube and other content hosts also exist. | Correct the policy/disclosures and Data safety inventory, or remove the remote location fallback in a separately authorized implementation. Do not declare “no data leaves device.” Provider request metadata/retention also needs review. |
| R05 | P1 | In-app privacy text exists, but a public privacy URL, developer contact, retention/deletion terms, and completed Play disclosures were not evidenced in this checkout. | Publish an accurate accessible policy and complete Console declarations. Account state is unknown, not assumed absent. |
| R06 | P1 | Manifest declares both `USE_EXACT_ALARM` and `SCHEDULE_EXACT_ALARM`, plus `USE_FULL_SCREEN_INTENT`; notification service actually requests full-screen notifications. These permissions have restricted eligibility/review requirements. | Establish the app's qualifying alarm use case or adopt user-granted alternatives; implement denial fallbacks and verify full-screen access. Prayer functionality alone is not a guarantee of policy approval. |
| R07 | P1 | `lib/shared/navigation/app_shell.dart:75` starts notification initialization independently of onboarding at `:78`; `_initPrayerNotifications` requests permissions at `:108`. The dialog's “later” choice does not gate this concurrent path. | Make permission requests follow explicit onboarding acceptance. Confirm clean-install, deny, deny permanently, later, and re-enable flows. Dialog timing needs device reproduction. |
| R08 | P1 | Five opened golden PNGs render Arabic text/icons as boxes: nav bar, Home hero, quick actions, Ilm book card, Quran surah card. `test/golden/golden_test_helper.dart` does not load real fonts; no FontLoader setup was found in golden sources. | Load UI/sacred/icon fonts in the harness, regenerate, inspect real glyphs, and capture full screens. Existing reviewed samples cannot prove Arabic layout quality. This does not establish that installed-app fonts are broken. |
| R09 | P1 | `lib/app/app.dart:62` caps system text scaling at 1.5. Most golden pairs test light 1.0/dark 1.5, not the complete themes × scales matrix. | Resolve the old design spec's 1.5 cap against the later 2.0 accessibility requirement; validate 1.0/1.5/2.0 on both themes, small screens, landscape, and tablet. |
| R10 | P1 | Measured contrast failures: light search hint `#787169` on muted `#F4EFE6` = 4.20:1; dark nav secondary text `#7A7268` on raised `#0F0F0F` = 4.05:1. Actual uses: `search_bar_widget.dart:107`, `nav_bar.dart:183`. | Propose corrected semantic tokens and prove >=4.5:1 before changing them. Icons have a different 3:1 threshold. |
| R11 | P2 | Border/surface pairs measure only 1.35:1 light, 1.16:1 dark. | Audit where borders are essential to identify interactive controls; those need >=3:1. Decorative card dividers do not automatically have the same requirement. |
| R12 | P1 | Standard UI lint prints OK with 248 warnings; strict lint exits 1: 220 font-weight literals, 14 numeric spacers, 8 RTL alignment warnings, 6 gradients. Seven allow markers. | Triage actual defects, clear strict gate where required, and stop interpreting normal-mode OK as full compliance. |
| R13 | P2 | Lint is line-based and misses `Duration(minutes: 1)` in `home_page.dart:74`, token-referenced `fontFamily:` overrides, multi-line patterns, and semantics/layout issues. Theme files are excluded, including a legacy 11sp style at `app_text_styles.dart:291` (direct screen usage of that specific style was not established). | Use lint as a guard, not proof of minimum text size, accessibility, architecture, or visual quality; reconcile legacy theme APIs. |
| R14 | P1 | No `.github/workflows/ci.yml` or tracked workflow was found. `tool/ui_lint.sh` remains a separate v1 implementation, contrary to planned R9 delegation to v2. | Add reproducible CI with pinned Flutter, analyze, tests, lint and debug/release gates; establish a protected release workflow. |
| R15 | P1 | `pubspec.yaml` has no explicit app `version:`. Existing APKs contain versionName `1.0`, versionCode `2001`; source alone does not explain the code used by prior builds. No validated AAB was found. | Set an explicit release version/code and document build flags. Ensure the next code exceeds any already uploaded code. Build an AAB for new Play publication. |
| R16 | P2 | Home hero runs a one-second `Timer.periodic` and setState (`home_hero_card.dart:79,88`). Shell uses TickerMode but that does not pause Dart timers. Home minute refresh also lacks an inactive-tab guard; foreground prayer service timers stop on shell dispose, not pause. | Measure offscreen/background work and pause unnecessary UI timers. Preserve required prayer scheduling. Battery impact is a hypothesis until profiled. |
| R17 | P2 | `main.dart` globally handles platform errors with debugPrint and returns true, and catches background-audio initialization failure. Multiple unawaited initialization paths exist. | Define observable release diagnostics and recoverable startup/audio states. Logging is not proof of recovery; validate failures without silently losing features. Do not add telemetry without disclosure review. |
| R18 | P2 | Native manifest enables cleartext traffic globally. Debug mode also deliberately bypasses certificate validation, guarded by kDebugMode in both main and helper. | Inventory runtime media URLs and restrict cleartext to any necessary hosts. Do not misreport the guarded certificate bypass as an active release TLS vulnerability. |
| R19 | P2 | Backup import uses `String.fromCharCodes(file.bytes!)` at `backup_restore_sheet.dart:73`, which misdecodes UTF-8 Arabic. Validator casts `decoded['app'] as String?` at `bookmark_backup_service.dart:108`, which throws on malformed non-string values. | Use UTF-8 decoding, type-safe validation, size limits, and Arabic round-trip/malformed import tests. The import UI catches exceptions, so this is not established as an uncaught app crash. |
| R20 | P2 | Downloader uses `httpClient.send`/stream consumption without an explicit timeout (`quran_audio_downloader.dart:305–320`) and treats existing nonempty files as valid. | Add bounded requests and content/integrity checks; test stalls, truncated responses, cancellation, low storage and process death. Atomic temporary-file rename and pause/cancel support are positive existing measures. |
| R21 | P1 | Third-party audio, books, video, fonts, Quran package and Syncfusion viewer require a distribution-rights/license inventory. An attribution page and vendored package LICENSE exist, but do not establish permission for every asset or a valid commercial/community Syncfusion entitlement. | Record source, license, attribution and redistribution rights; verify terms. No infringement conclusion is asserted by this audit. |
| R22 | P2 | 19 application Dart files exceed 600 lines, including book view (895), bookmark sheet (835), and ayah tabs (827); theme palette is 1272 lines. Vendored Quran data alone is 105650 lines. | Split files before future restyling per project rules. Do not mechanically split generated data merely to satisfy presentation-file guidance. |

## APK size: the approximately 140 MB report is accurate

There are different release artifacts; they must not be confused with a freshly reproduced build.

| Artifact | Bytes | Decimal MB | MiB | SHA-256 |
|---|---:|---:|---:|---|
| Root `talib-ilm.apk` | 143437040 | 143.44 | 136.79 | `b1262795f25c08b034cfbb4c8025829f06108f252e6b066f23c8c8736b853f78` |
| `build/app/outputs/flutter-apk/talib_ilm.apk` | 142217811 | 142.22 | 135.63 | `b64cddc67277b698be1d14ddbcf6620b6d204dd3b86c7e181b8b7ae2bc2ff7c6` |

Both have ARM64 only, package `com.example.talib_ilm`, minimum SDK 24, target 34, version 1.0/2001, and an Android Debug certificate. The build-folder APK matches the ARM64 release APK's size; the root APK is different. Artifact source freshness is not proven by file timestamps.

Measured compressed ZIP payload in the root APK (alignment/signature overhead means rows do not exactly equal file size):

| Payload | MiB | Interpretation |
|---|---:|---|
| Vendored Quran package assets | 66.74 | Approximately half the APK; 608 asset entries. On disk, 65.53 MiB is gzipped tajweed page fonts, already compressed. |
| `libapp.so` | 41.75 | Compiled Dart; unusually substantial, needs Flutter size treemap. The other APK has 43.88 MiB. |
| Flutter engine | 10.59 | Native runtime; do not expect to eliminate it. |
| Other Flutter assets | 6.63 | App JSON, fonts, branding and audio. |
| Other Android entries | 10.71 | DEX/resources/audio and other files. |

**What will help:** produce `flutter build apk --release --target-platform android-arm64 --analyze-size` and inspect the Dart treemap; review bundled data reachability before choosing changes. Consider optional downloadable tajweed fonts only if losing first-install offline availability is acceptable, with integrity/versioning/cache management. This changes behavior and is outside this audit's implementation scope. No precise saving is promised.

**What will not solve it:** architecture splitting is already present in these artifacts. Gzipping the already-gzipped fonts again will not materially help. App Bundles are required for new Play apps and optimize delivery, but do not automatically remove common Quran assets. Smaller Cairo weights/branding alone will not remove tens of MiB. Adhan MP3s appear both in Flutter assets and Android raw resources: roughly 3.67 MiB per set; both paths may be needed for different playback mechanisms, so verify consumers before deduplicating.

The debug APK is 248.18 MiB and is not a production-size benchmark. Repository-only PDFs total several MiB but are not declared as a Flutter asset directory; do not count their removal as release-size savings without bundle evidence.

## 16 KB compatibility: encouraging artifact evidence, incomplete release gate

- Both release APKs pass `zipalign -c -P 16 4` using Android build-tools 36.0.0.
- ELF PT_LOAD alignment is 65536 for `libapp.so`/`libflutter.so` and 16384 for `libdatastore_shared_counter.so` in both APKs.
- AGP is 8.11.1. These checks support correct native alignment in the inspected APKs. They do not establish that a newly generated AAB or all runtime behavior works on a 16 KB device. Validate the actual release AAB in Play and test a 16 KB environment.

## Existing strengths and reproduced checks

- Real theme extension and shared components, Arabic RTL root, lazily loaded tabs with TickerMode, user-facing notification onboarding, manual-location support, offline audio download management, and bookmark backup validation/merge functionality are present.
- All nine local app TTF files have TrueType signatures (`00010000`), unlike the historical HTML-font problem. Signature inspection is not a full font integrity/shaping test.
- All 12 JSON files under `assets/data` parse successfully. Hadith data has 2358 entries and no duplicate IDs.
- `python tool/audit_hadith_quality.py` reports zero instances in its six typo/title/honorific heuristics. This is not authentication of every narration or scholarly approval.
- `python tool/ui_lint_v2.py`: exit 0; no FAIL rules; 248 warnings. `--strict --top 10`: exit 1; 248 violations.
- `python tool/contrast.py` was run with six actual foreground/background pairs; failures are listed above. Running the checker without arguments only prints usage and proves nothing about the entire palette.
- Five existing goldens were visually opened: `nav_bar_light`, `home_hero_dark_1_5`, `home_quick_actions_light_1_0`, `ilm_book_card_dark_1_5`, `quran_surah_card_light_1_0`. All have placeholder glyphs. None is a live screenshot; remaining 231 PNGs were not visually reviewed.
- `flutter analyze`, `flutter test`, `flutter build apk --debug`: attempted, blocked by SDK write permissions. Existing historical successful checks in UI_PROGRESS were not reproduced. v1 shell lint, dependency-upgrade/vulnerability audit, Android lint, device QA and a new release build were not run.

## Ordered release plan

1. Restore an executable verification environment and Git write access; rerun all mandatory checks. Commit/push this audit separately from fixes.
2. Decide permanent application ID, developer identity, Play account type, countries/age audience, and release version. Back up upload credentials securely.
3. Fix target SDK/release signing, generate a reproducible signed AAB, inspect merged manifest and 16 KB compatibility. Revalidate widgets, media foreground service, alarms, edge-to-edge and back navigation after migration.
4. Resolve location privacy mismatch, third-party inventory, exact-alarm/full-screen permissions and onboarding ordering. Publish the policy and complete Data safety, app content, foreground-service and other applicable Console declarations.
5. Repair golden fonts and deterministic clocks, fix measured contrast and 2.0 scaling, then perform full-screen device QA. Existing `DEVICE_TEST_CHECKLIST.md` is a starting checklist, not completed evidence.
6. Profile startup/frame time/memory/battery and measure release treemap before optimizing. Choose whether offline tajweed fonts are a mandatory first-install feature.
7. Verify license/content rights; prepare actual Arabic screenshots, icon, feature graphic, descriptions, support contact and policy URL. No tracked `store/` assets were found; external work may exist.
8. Upload to internal testing and review Play's pre-launch report. For personal developer accounts created after 13 November 2023, complete at least 12 continuously opted-in closed testers for 14 days and apply for production access. Account type/date are unknown here.

## Required device acceptance evidence

Record device/OS/build hash and actual pass/fail for: clean install and upgrade; airplane-mode reading; permission grant/deny/later; location unavailable/manual city/timezone/DST; adhan with screen off, reboot, battery saver and force stop behavior; notification tap routes; widget add/resize/theme/countdown; radio/Quran/mutun competing audio and headphone/call interruptions; download cancellation/retry/low storage; Arabic bookmark backup round trip; reader last position/repeat modes; TalkBack/reduce motion; all main screens in both themes at 1.0/1.5/2.0 on small/large phones and landscape/tablet. Treat Android force-stop restrictions as platform behavior to explain, not a scheduling promise the app can bypass.

## Official sources checked during this audit

- [Current target API requirements](https://support.google.com/googleplay/android-developer/answer/11926878): API 36 from 31 August 2026 for new mobile apps/updates; do not assume an extension applies.
- [Sensitive permission policy](https://support.google.com/googleplay/android-developer/answer/16558241): exact alarms and full-screen intents require qualifying use and appropriate consent/review.
- [User data/privacy policy](https://support.google.com/googleplay/android-developer/answer/10144311): accurate public policy URL and in-app policy/disclosure obligations.
- [Android App Bundles](https://developer.android.com/guide/app-bundle): new Play apps publish as AABs.
- [16 KB requirement](https://android-developers.googleblog.com/2025/05/prepare-play-apps-for-devices-with-16kb-page-size.html): compatibility requirement for native-code applications targeting Android 15+.
- [Personal account testing requirements](https://support.google.com/googleplay/android-developer/answer/14151465): conditional 12 testers/14 days production-access gate.

## Open issues / owner actions

All R01–R22 remain unresolved by design: this is an audit, not a repair stage. The SDK and `.git` write restrictions prevent fresh verification and the required audit commit/push. Use an owner-writable Flutter installation and repository, then rerun checks before tagging any stage complete. Do not interpret earlier “Open Issues: None” entries as present release certification.
