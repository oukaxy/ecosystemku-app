# EcosystemKu Flutter Shell UI — Implementation Plan

> **For agentic workers:** Use superpowers:subagent-driven-development or superpowers:executing-plans. Steps use checkbox syntax.

**Goal:** Build the Flutter Android shell for EcosystemKu (Asisten, Apps, Setelan) with design tokens, Drift data layer, Live2D Rem via WebView, Apps Hub snapshot, and functional Settings.

**Architecture:** `StatefulShellRoute.indexedStack` + Riverpod + Drift. UI reads providers only; repositories own Drift; `AiClient` owns http; `BackupService` owns io/archive. Live2D is a transparent WebView served by `InAppLocalhostServer`, driven by a JS bridge.

**Tech Stack:** Flutter stable, Dart 3, Riverpod, go_router, Drift, flutter_inappwebview, flutter_secure_storage, archive, file_picker, share_plus, path_provider, fl_chart, cryptography, intl, html, url_launcher.

**Spec:** `mahfud.md` (Bagian 4–11, 13–15) and `docs/design/*.html` (visual reference only; ignore SVG Rem, hardcoded chat, dummy numbers).

## Global Constraints

- Dark tokens: bg `#0F0E0C`, surface `#1A1917`, surfaceAlt `#232220`, border `#FFFFFF0F`, text `#F0EFE9`, textMuted `#9A9994`, textSubtle `#6B6A67`, danger `#F87171`, success `#4ADE80`, warning `#FBBF24`.
- Accents: Asisten `#5B9CF6`, Daily OS `#2F8F83`, IdeKu `#6366F1`, Kronik `#C9A84C`, CuciMoney+ `#2F5D8A`, LinkKu `#8B5CF6`.
- DM Serif Display for headers/large numbers; DM Sans for UI/chat; Lora for Kronik quotes.
- Radius 12/16/20; spacing 4/8/12/16/24/32; touch target 48dp; animation 150–250ms; respect `MediaQuery.disableAnimationsOf`.
- Safe to `TextScaler.linear(1.3)` without overflow.
- Money is integer rupiah. IDs stay TEXT. Dates `YYYY-MM-DD` local.
- UI must not import `http`, `dart:io`, or `drift`.
- API keys only in `flutter_secure_storage`; never logged, backed up, or shown in full (max last 4 chars).
- Android only, minSdk 26.
- Files > ~400 lines split by responsibility. No comments except `why` / `shortcut:`.
- Verification: GitHub Actions only (aarch64 host has no Flutter SDK).

## Review Focus

1. Leaving Asisten must `setPaused(true)` + `stopAudio()`; returning must not autoplay.
2. Today's expense excludes transfers (`transferPair` empty).
3. API keys absent from backup bytes, logs, errors, and post-save UI.
4. No overflow at textScale 1.3.
5. Bottom nav hidden on `/app/:id`; root back requires double press.

---

## Task 1 — Scaffold, Fonts, Tokens, Theme, CI

**Files:** `app/pubspec.yaml`, `app/analysis_options.yaml`, `app/lib/main.dart`, `app/lib/app.dart`, `app/lib/core/theme/{tokens,app_theme,app_skin}.dart`, `app/assets/fonts/*`, `app/tool/bootstrap_android.sh`, `.github/workflows/android.yml`, `app/test/core/theme/*`, `app/test/smoke_test.dart`.

**Interfaces:**
- `EcosystemTokens` with `bg, surface, surfaceAlt, border, text, textMuted, textSubtle, danger, success, warning`; `static const dark/light`.
- `EcosystemAccents` static const `assistant, dailyOs, ideku, kronik, cucimoney, linkku`.
- `EcosystemRadii.sm/md/lg = 12/16/20`; `EcosystemSpacing.x1..x8`.
- `Duration resolveDuration(BuildContext, Duration)`.
- `AppColors extends ThemeExtension<AppColors>` with `tokens`, `accents`, `static of(context)`.
- `EcosystemTheme.dark()` / `.light()`.
- `const kApiBase = String.fromEnvironment('ECOSYSTEMKU_API_BASE', defaultValue: 'https://ecosystemku.vercel.app')`.

**Tests:** exact hex values; DM Serif on display/headline, DM Sans on body; scaffold background; render at textScale 1.3 without exception.

**Steps:** write tests → implement → download fonts → bootstrap script → CI → run analyze/test/build in CI.

---

## Task 2 — Design System Widgets

**Files:** `app/lib/core/widgets/*.dart`, `app/test/core/widgets/*.dart`.

**Interfaces:** `EcosystemScaffold`, `EcosystemCard`, `SectionHeader`, `EmptyState`, `ConfirmSheet.show`, `AppSnackBar.show`, `StatTile`, `SearchField`, `LoadingSkeleton`, `GlassPanel`, `BadgePill`, `AccentIconBadge`, `AppTile`.

**Tests:** dark/light, textScale 1.0/1.3, loading/error/retry, confirm result, 48dp targets.

---

## Task 3 — Drift Schema, DAOs, Clock

**Files:** `app/lib/core/db/database.dart`, `clock.dart`, `tables/{ideas,daily_os,kronik,finance,linkku,profile_meta}.dart`, `daos/*.dart`, `app/test/core/db/*`.

**Tables:** exactly mahfud Bagian 5.2. `schemaVersion = 1`. DAOs expose `getAll/watchAll/upsert/deleteById` plus domain queries. `Clock` injectable; `todayString`.

**Tests:** insert/read per domain; transfer pair invariant; `recalculateBalances` diff 0; schema v1 migration; local date.

---

## Task 4 — Repositories, Summaries, Providers

**Files:** `app/lib/features/{daily_os,ideku,kronik,cucimoney,linkku}/data/*_repository.dart`, `app/lib/features/settings/data/{profile_repository,settings_repository}.dart`, `app/lib/core/providers.dart`, tests.

**Interfaces:** `DailyOsSummary`, `FinanceSummary`, `IdekuSummary`, `KronikSummary`; providers per card; `refreshSnapshots()`.

- `FinanceRepository.summary(day)`: balance sum; expense `direction='out' AND date=day AND (transferPair IS NULL OR transferPair='')`.
- Habit total counts non-archived habits active that day; streak walks back ≤365, skips unscheduled days.
- Kronik: today's non-archived entry else latest.

**Tests:** transfer excluded; habit/streak cases; error isolation; empty DB zeros.

---

## Task 5 — Secure Keys, LinkKu Crypto, Backup v3

**Files:** `app/lib/core/security/*`, `app/lib/core/backup/*`, `app/test/core/security/*`, `app/test/core/backup/*`, `app/test/fixtures/crypto/linkku_v1.json`.

**Interfaces:** `SecureStore` + Flutter/InMemory impls; `AiProvider`; `SecureKeys.save/read/masked/has/deleteAll`; `LinkCrypto.hashPin/encryptPrivate/decryptPrivate`; `BackupService.export/inspect/import`.

- ZIP v3 structure exactly mahfud 6.1; include savings; exclude API keys; private links as encrypted `ep`; auto-backup before import; merge by id + newer timestamp; replace clears domain.
- Generate WebCrypto-compatible fixture with Node.

**Tests:** mask last 4; key absent from ZIP bytes; roundtrip counts/savings/private link; merge/replace; crypto vector; corrupt ZIP leaves data.

---

## Task 6 — Router and Shell

**Files:** `app/lib/core/router/app_router.dart`, `app/lib/features/shell/*`, `app/test/features/shell/*`.

**Interfaces:** routes `/assistant`, `/apps`, `/settings`, `/app/:appId` on root navigator; `StatefulShellRoute.indexedStack`; labels Asisten/Apps/Setelan; `AssistantEngine.attach/setVisible`; double-back `PopScope`.

**Tests:** labels/switch; nav hidden on sub-app; leaving tab 0 pauses+stops audio; double back; textScale 1.3.

---

## Task 7 — Apps Hub

**Files:** `app/lib/features/apps_hub/**`, `app/lib/core/utils/{format,money,date}.dart`, tests.

**Interfaces:** `EcosystemApp`, `AppTarget` (tab/route/external), 7-app catalog, `GreetingData`, snapshot cards with per-card providers and skeleton/error, 4-column `AppLauncherGrid`, Hesych via `url_launcher`.

**Tests:** greeting by hour; id-ID date; transfer excluded; card error isolation; refresh; route taps; 1.3 no overflow.

---

## Task 8 — Asisten, Live2D, Chat

**Files:** `app/assets/live2d/**`, `app/tool/sync-live2d.sh`, `app/lib/features/assistant/**`, `app/lib/core/ai/**`, tests.

**Interfaces:** `Live2DBridge` (`init`, `setExpression`, `setSpeaking`, `playAudio`, `stopAudio`, `setMuted`, `setPaused`, `tapZone`); `Live2DView` transparent WebView with localhost server and copied assets; adapter uses existing `assistant/characters/rem` model; `AssistantPage` 58/42 stage/chat; `ChatPanel` glass; `AssistantController` memory history, streaming, stop, tags; `AiClient.chatStream/tts`; SSE parser; TTS chunker.

**Tests:** SSE deltas/partial/error; tag dangling; TTS ≤500/4; bridge JSON; pause+stop on hidden; assets/checksums; chat widget states; 1.3 no overflow.

---

## Task 9 — Setelan

**Files:** `app/lib/features/settings/**`, tests.

**Interfaces:** sections profile, AI keys, backup, notifications, appearance, data, about. Masked keys; secure storage; backup without keys; typed-name delete + cascade; theme mode in `app_meta`; notification times persisted (scheduling deferred); about version/links.

**Tests:** masked; key absent from backup; cascade delete; theme persistence; wrong typed name no delete; 1.3 no overflow.

---

## Task 10 — Polish and CI Verification

- Push milestones A (1–5), B (6–9), C (10) to GitHub Actions; fix analyze/test/build failures.
- `dart format .` in CI; `flutter analyze`; `flutter test`; `flutter build apk --debug`.
- Final audit: no forbidden imports in UI; no secrets; file sizes; touch targets; text scale.
- Update `mahfud.md` checkboxes only after CI is green.

## Scope Boundaries

- Legacy web import (v2/single JSON) deferred.
- Notifications scheduling deferred to Daily OS phase.
- Sub-app screens are placeholders.
- Personal Fish TTS deferred.
- Login/onboarding not in this plan.

## Risks

- No local Flutter SDK: CI-only verification.
- Live2D runtime redistribution license unresolved.
- Drift generated files produced by CI `build_runner`, not committed.
- Android wrapper generated by `flutter create` + patch script.
