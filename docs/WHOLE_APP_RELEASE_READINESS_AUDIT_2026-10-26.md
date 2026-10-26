# talib_ilm Whole-App Release Readiness Audit

**Audit date:** 26 October 2026  
**Scope:** Repository, release configuration, Flutter app structure, current project guidance, existing audit artifacts, and selected live-source paths.  
**Audit type:** Read-only source/document inspection. No Flutter test, analyzer, build, device, or live-store checks were run in this audit.  
**Overall verdict:** **Not ready to publish.** Product engineering has broad automated coverage and recent fixes, but the current working tree is dirty, release identity/signing/store setup remain owner blockers, consent/onboarding behavior is unresolved, documentation contains conflicting release claims, and current-head gates/device checks were not independently reproduced here.

## Rating scale and interpretation

Ratings are practical readiness scores out of 10, where 10 means strong and currently evidenced for this release, not “perfect.” A high code score does not override an owner-controlled publishing blocker. `Evidence confidence` describes how directly this audit verified the finding: **High** = live source/config or current worktree; **Medium** = detailed retained project evidence, not rerun here; **Low** = historical claim or incomplete evidence.

## Executive scorecard

| Area | Rating | Confidence | Release-readiness view |
|---|---:|---|---|
| Core product coverage and feature breadth | 8/10 | Medium | Broad Islamic knowledge, prayer, Quran, reading, audio, and offline surfaces; feature existence is not proof of every complete user journey. |
| Quran text/reader integrity and offline access | 8/10 | Medium | Large offline Mushaf package and recent edition recovery hardening; full current-head end-to-end and content provenance review not repeated. |
| Prayer calculations, reminders, and background lifecycle | 7/10 | Medium | Extensive boundary/regression work is documented; OEM battery restrictions, reboot/timezone behavior and exact alarm policy remain hardware/version-sensitive. |
| Privacy, permissions, and location consent | 5/10 | High | Location permission can be requested automatically by default; provider boundaries and user-facing explanation/onboarding need a single verified policy. |
| Data persistence, import/export, and recovery | 8/10 | Medium | Atomicity, bounds, UTF-8 and backup recovery have focused tests/docs; current full suite not run. |
| Network and security boundaries | 7/10 | Medium | Byte caps, timeouts, HTTPS policies and cancellation are documented; no independent current-head penetration/dependency/security review was run. |
| Accessibility, RTL, text scaling, and responsive layouts | 7/10 | Medium | RTL and scale coverage is documented; broad static lint warnings remain, and tablet/landscape/assistive-technology evidence is limited. |
| Visual consistency and design system | 7/10 | Medium | Token system and goldens exist; current lint reports advisory debt historically, and several global responsive/accessibility claims need current device proof. |
| Performance, startup, memory, battery, and app size | 6/10 | Medium | Host microbenchmarks exist but are not mobile startup/frame/memory measurements; app bundle is asset-heavy. |
| Maintainability and architecture | 7/10 | Medium | Strong modularization and audit tooling, but repository inventory/report is dated and contradicts current progress notes in places. |
| Automated tests and CI evidence | 7/10 | Medium | Very large historical suite count and pinned workflow are recorded; current checkout’s exact SHA and clean-tree gates are unverified. |
| Android release identity/signing | 2/10 | High | Live Gradle config still uses `com.example.talib_ilm`; production upload key is not evidenced. |
| iOS release readiness | 3/10 | High | Live Xcode project still uses template `com.example.talibIlm`; current iOS archive/signing/device acceptance not evidenced. |
| Store listing, legal/privacy declarations, and launch readiness | 3/10 | High | Draft privacy/data-safety docs exist; public policy URL and completed Play Console declaration are owner actions. |

**Overall engineering readiness: 6.5/10. Publish readiness: 2/10.** The publish score reflects hard external blockers, not a claim that all features are defective.

## Release decision

**Do not publish or upload a production artifact yet.** Before release:

1. Owner selects a permanent Android application ID and confirms iOS bundle ID, then implementation updates all native/channel/resource references and validates upgrade/migration implications.
2. Owner creates and securely backs up the production upload key; implementation verifies an AAB signed by the intended certificate without exposing credentials.
3. Finish and verify first-run permission explanation/deferral behavior. Do not make GPS permission or any location processing appear mandatory for basic prayer-time use.
4. Resolve policy wording against actual geocoder/provider calls, host the privacy policy, and submit Play Data Safety declarations in the owner’s account.
5. Re-run all gates on one clean current commit; perform a fresh physical Android acceptance on that exact build. Decide explicitly whether iOS is in launch scope and complete equivalent iOS signing/build/device checks if so.
6. Resolve conflicting audit/progress claims and remove any launch assertion not backed by evidence with exact commit, command/log, artifact hash, and device details.

## Findings for the implementation agent

Each item includes a concrete outcome and a focused first implementation step. Priorities: **P0** publish blocker or material user trust/safety issue; **P1** high user impact or release evidence gap; **P2** quality and maintainability debt.

### P0 — Release identity and signing are unresolved

**Evidence:** `android/app/build.gradle.kts` sets both namespace and `applicationId` to `com.example.talib_ilm`; `ios/Runner.xcodeproj/project.pbxproj` uses `com.example.talibIlm`. Project release docs say the production signing key, policy URL, and Play Console work are owner-controlled and pending.

**Impact:** A package ID is a permanent store identity and cannot safely be guessed by an agent. Current test-signed output is not the owner’s production artifact. Android and iOS identifiers are inconsistent in style and remain templates.

**Exact resolution:** Owner supplies final Android ID and iOS bundle ID (or explicitly excludes iOS). In a dedicated release-identity task, search every occurrence in Gradle, manifest, Kotlin package declarations/paths, notification channel IDs, `android.resource://` URIs, Xcode project/configs, privacy docs, and native tests. Update only after recording migration impact and checking an existing Play listing. Add a release preflight that fails on `com.example`/known placeholder IDs. Owner configures key material locally/CI secret storage; run release build and inspect certificate SHA-256 against the owner’s recorded fingerprint. Never commit key or passwords.

### P0 — Current working tree is not clean; audit cannot certify a single release revision

**Evidence:** Current branch is `ui/r6a-followup-home-integration`, HEAD `81059ec`; `git status` shows modified `home_page.dart`, golden helper/test/images, and untracked `test/home_page_hierarchy_test.dart`. These files are outside the committed revision.

**Impact:** Test/build evidence associated with a commit does not cover these uncommitted modifications. They may be valid ongoing work, but there is no auditable exact release tree yet.

**Exact resolution:** Owner/developer finishes or explicitly discards the existing changes in their own task; do not reset/stash/delete as part of this audit. Inspect full diff and golden reference/actual/diff images, run focused home tests plus required gates, commit, and repeat final verification on the resulting clean SHA. Include `git status --porcelain` empty proof in the evidence summary.

### P0 — First-run location consent and permission flow is not reconciled

**Evidence:** In `lib/core/services/location_service.dart`, `getLocation({bool autoPrompt = true})` calls `Geolocator.requestPermission()` when permission is denied and `autoPrompt` remains true. `lib/main.dart` starts notification/background initialization before `runApp`. The current UI progress record says R6b first-run onboarding/pre-permission explanations are still a next step. Audit artifacts disagree about remote geocoding: older remediation handoff says platform `placemarkFromCoordinates` can be used before remote consent, while later progress claims opt-out at every provider boundary.

**Impact:** Users may encounter an OS permission prompt without a clear explanation or “not now” path. “Remote lookup off” may not mean no network-capable geocoder depending on the exact active resolver branch. This affects trust and Data Safety statements.

**Exact resolution:** Trace `getLocation`, `_resolvePosition`, `refreshGpsLocation`, Qibla, location settings, startup, notification refresh and background callbacks. Change automatic path to non-interactive (`autoPrompt: false`) until an explicit user action, keeping prayer calculation functional with saved/manual/default coordinates. Add a short owner-approved rationale screen/sheet before requesting permission, with a deferral state that stays usable. Inject platform-geocoder and HTTP providers; tests must assert zero calls when lookup is off, exact disclosed calls when opted in, and no prompt on cold start/background refresh. Update privacy/data-safety drafts only to match proven calls. Do not change Arabic copy without owner review.

### P1 — Documentation is inconsistent about status, counts, and release claims

**Evidence:** `UI_PROGRESS.md` has an October 26 log and recent R101/R6a work. `docs/FINAL_RELEASE_ACCEPTANCE_AND_OWNER_HANDOFF.md` still says release is blocked by R76 and R77, lists older 562 tests/6 allow markers, and mixes a “verified” device matrix with old clean SHA `8612ac9`. `docs/FINAL_HOSTILE_REVIEW_AND_CODE_AUDIT.md` describes R96 evidence at an older baseline and older counts. `docs/CODE_AND_ASSET_INVENTORY_REPORT.md` is dated October 24 and records figures that may be stale. `docs/MASTER_GEMINI_FLASH_3_8_APP_REMEDIATION_GUIDE.md` contains old statements about R61/R62-era defects which later tasks claim fixed.

**Impact:** The next agent can implement already-fixed work or rely on a false release status. “All open issues zero” in one artifact conflicts with owner actions, current progress, and the live dirty tree.

**Exact resolution:** Create one compact `docs/RELEASE_STATUS.md` with `verified at SHA`, dirty/clean state, exact gates and paths, unresolved owner actions, and device scope. Mark prior reports historical/superseded in their first paragraph; do not silently rewrite historical evidence. Regenerate inventory from tracked files and reconcile counts. Link each current claim to a source/test/log or explicitly label it not independently reproduced.

### P1 — Current full gates were not reproduced on this checkout

**Evidence:** This audit ran no Flutter commands. Latest progress entries report `flutter analyze`, UI lint, hundreds of tests and debug APK passing at prior stage points; they are not evidence for the current dirty working tree. CI configuration exists, but its current result for `81059ec` plus uncommitted changes is not established here.

**Impact:** Analyzer/test/build regressions in recent and uncommitted changes remain possible. A passing historical log cannot certify the current tree.

**Exact resolution:** After the working tree is intentionally finalized and clean, run `flutter analyze`, `python tool/ui_lint_v2.py`, `flutter test`, and `flutter build apk --debug` on the same SHA; retain complete logs, durations, exit codes, SDK versions, APK SHA-256, and final test count. Query CI for that exact SHA. If Flutter is unavailable, record it as unverified and do not infer pass from an old APK/log.

### P1 — iOS is not included in the demonstrated release path

**Evidence:** The project contains iOS scaffolding, but this audit found no current iOS archive, App Store signing, TestFlight install, iOS permission review, or named-device acceptance artifact. The iOS bundle identifier remains a template value.

**Impact:** “App ready to publish” is ambiguous across platforms. Android evidence cannot establish iOS plugin, permission, notification, background audio, or store-readiness.

**Exact resolution:** Owner states Android-only or Android+iOS scope. For iOS, set the final bundle ID, verify signing entitlements/capabilities and permission purpose strings against plugin use, build an archive on macOS/Xcode, run on a real iPhone/iPad, and test notifications, audio interruptions/background behavior, location opt-out, file picker/backup, and RTL/text scaling. Add exact Xcode version, build SHA, device/OS, logs/screenshots to release status.

### P1 — Religious content provenance and correctness require a scholarly release review

**Evidence:** The app includes Quran text, hadith grades/citations, adhkar catalogs, prayer calculations, and quiz content. Automated schema/coordinate tests establish structural invariants, not authenticity, transliteration, grading correctness, or scholarly approval. Existing progress entries use words such as “verified/authentic,” but this audit did not independently validate those claims.

**Impact:** Content errors have unusually high trust and reputational cost even when code is technically correct.

**Exact resolution:** Create a content provenance register for every shipped collection: upstream source/edition, license/attribution, reviewer, review date, known grading methodology, and exact dataset checksum. Obtain qualified Arabic-speaking scholarly review for hadith grades, adhkar wording/references, prayer method defaults, and quiz answers. Add mechanical checks for complete references and accidental duplicates, but do not present those checks as scholarly validation. Preserve Quran/Arabic text unless a qualified reviewer authorizes a correction.

### P1 — Bundle is large and performance numbers do not answer mobile experience

**Evidence:** Inventory reports around 100 MB of tracked assets, including roughly 66.8 MB of compressed Mushaf page fonts, 15 MB of PDFs, and duplicate Android/Flutter audio. Runtime baseline JSON says `attached_devices: []` and records host engine microbenchmarks; it does not provide real mobile cold-start/frame-time/memory/battery measurements. Release docs also have historical inconsistent size units/estimates.

**Impact:** Slow first install/update, storage pressure, memory spikes on low-end phones, and battery costs are not represented by microbenchmarks. Users may defer installation before seeing the app’s value.

**Exact resolution:** Build a current release AAB and measure raw artifact bytes; use `bundletool get-size total` for named device specs and label simulated estimates. On a low-end Android device, measure cold/warm startup to first interactive frame, p50/p95 frame time during Home/Quran scroll, peak RSS while switching major screens, long-session memory, download storage, and background battery over a fixed scenario. Establish budgets from baseline; optimize only measured contributors. Keep 604-page offline availability as an explicit product tradeoff; consider optional on-demand editions only if offline guarantee is preserved by design.

### P1 — Accessibility and responsive coverage needs broader practical acceptance

**Evidence:** Project guidance requires RTL, 1.0/1.5/2.0 scale, 48dp tap targets and Semantics. Existing docs cite widget/golden tests and an Android device, but this audit did not inspect every golden or run a screen-reader review. ROUND2 R7 specifically calls for multiple dimensions, landscape/tablet behavior and semantics dumps; those are not documented as complete in the latest progress section.

**Impact:** Narrow phones, tablets, landscape, screen readers, reduce-motion, switch access, and larger system fonts can expose clipped controls or inaccessible actions not found in a standard screenshot.

**Exact resolution:** Add a bounded acceptance matrix for 360×640, 412×915, 800×1280, and landscape, light/dark, RTL, text scales 1/1.5/2, and reduce motion. Exercise Home, Prayer, Quran reader/list, Adhkar, Ilm/book reader, Qibla, Settings/Favorites, backup and audio controls. Assert no overflow and ≥48dp hit targets; inspect semantics tree for reading order, names/roles/selected state and changing counters. Perform TalkBack/VoiceOver manual review; use golden tests as visual comparison only, not a substitute.

### P2 — Advisory visual lint and legacy design debt remain

**Evidence:** Latest entries claim UI lint v2 passes, but an `OK` result permits advisory findings. Historical docs mention 158 FontWeight advisories and older 220/226 warning totals. We did not run current lint. Allow marker count is reported as 8/10 in recent progress, while some reports say 6.

**Impact:** Typography drift and future token bypass remain possible. This is a quality issue, not by itself a store blocker.

**Exact resolution:** Run current `python tool/ui_lint_v2.py` and record exact counts. Group remaining advisory sites by screen/component, review against tokens and goldens, and migrate one bounded UI family per stage. Do not mechanically replace weights or bulk-update goldens. Preserve and justify each allow marker; aim to lower advisory debt without reducing Arabic readability.

### P2 — Global error handler may hide serious platform errors

**Evidence:** In `lib/main.dart`, `PlatformDispatcher.instance.onError` logs and returns `true`, marking all uncaught platform errors handled; no crash reporting or local user recovery is evidenced in the inspected path.

**Impact:** This can prevent process termination for some unhandled errors while leaving the app in an unknown state, and may make production incidents invisible if logs are not collected.

**Exact resolution:** Classify errors by recoverability. Preserve Flutter’s default crash semantics for unknown fatal errors (or forward to an owner-approved crash reporter with privacy review); catch only expected recoverable failures at their owning boundary and surface an actionable retry/error state. Add tests for recoverable service errors and ensure no precise location, backup content, or religious reading data is emitted to logs.

### P2 — Placeholder/empty states may expose incomplete feature areas

**Evidence:** `lib/shared/widgets/app_states.dart` includes an empty-state string saying books will appear “soon”; app strings also include “متن غير متاح / سيتم توفير المتن قريباً”. This may be intentional for catalog gaps; scope was not exhaustively mapped.

**Impact:** Users may encounter content marked as part of the product but not actually available, and cannot distinguish an empty library from a missing download or unsupported item.

**Exact resolution:** Map each placeholder to a reachable product state, test the corresponding route and action, and ensure it communicates why content is absent plus a next step (download, retry, choose another book, or documented catalog gap). Do not alter Arabic copy without owner review.

## Strong areas evidenced by the repository

- Recent work adds atomic backup replacement and fallback for downloaded Quran editions (R99–R101), and a home hierarchy/golden task (R6a).
- The repository has focused tests for bookmarks, edition integrity, network limits, notification scheduling, offline book completeness, and accessibility.
- Release signing is guarded against silent debug-signing fallback in the live Gradle config. This is a valuable safeguard, but it does not supply the owner’s real key.
- Privacy policy and Data Safety preparation documents exist; they still need owner verification and publication.
- The implementation handoff explicitly warns not to trust past reports blindly and identifies evidence gaps. Continue that discipline.

## Audit boundaries and what was not done

This is a broad source/document audit, not a line-by-line review of all Dart/native code, scholarly certification, legal opinion, penetration test, full dependency CVE scan, current CI query, fresh build, or current physical-device run. The “confidence” column prevents historical claims being mistaken for fresh reproduction. No code, Arabic strings, app behavior, or release configuration was changed.

## Recommended implementation order

1. **Owner confirms launch platforms and package identities.**
2. **R6b / permission-consent flow and resolver boundary audit.**
3. **Clean exact-SHA verification and reconcile current release-status documents.**
4. **Production signer and store setup** (owner-controlled; do not exchange secrets in chat).
5. **Physical device acceptance on the final exact build** (Android and iOS if in scope).
6. **Content provenance/scholarly review.**
7. **Accessibility/responsive matrix and measured performance/bundle-size work.**
8. **Advisory visual lint cleanup and placeholder state polish.**

## Suggested handoff prompt for the implementation agent

Read `AGENTS.md`, `DESIGN_SYSTEM.md`, `ROUND2.md`, `UI_PROGRESS.md`, and this report. Recheck the current tree and do not overwrite the existing uncommitted home integration changes. Start with one bounded task: audit and implement the R6b first-run location/notification explanation and deferral flow only after tracing all location callers. Preserve all existing Arabic strings; propose any new Arabic wording for owner approval before adding it. Add tests proving cold start/background refresh do not show permission prompts, “not now” leaves prayer functionality usable, explicit action requests permission only after explanation, and remote/platform geocoder calls follow the chosen consent policy. Update the privacy draft only after behavior is verified. Run actual focused tests and required gates; report exact results and stop after that task.
