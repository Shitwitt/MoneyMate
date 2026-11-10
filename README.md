# MoneyMate

A local-first, offline Android expense manager built with Flutter. Every amount is
stored as **integer minor units** (paise/cents) inside a `Money` value object — never
a `double` — so totals stay exact. There is no network at runtime: v1 ships without
the `INTERNET` permission.

## Status

Phase 0 — project scaffold, theme tokens, `Money`/`Period` core, CI.

| Phase | Scope | State |
| --- | --- | --- |
| 0 | Repo, Flutter project, lint, CI, folder skeleton, theme tokens, Money/Period | in progress |
| 1+ | Database, transactions, budgets, analytics, ... | not started |

See `App-Blueprint.md` for the full product and build plan (source of truth).

## Stack

Flutter stable / Dart 3, Material 3, Riverpod (`flutter_riverpod` + codegen from
Phase 1), `go_router` (`moneymanager://` deep links), Drift + SQLite, `freezed` +
`json_serializable`, `fl_chart`, `flutter_secure_storage` + `local_auth` (PIN /
biometrics), local notifications, WorkManager, home widgets, `printing`/`pdf`,
`csv`, `share_plus`, `file_picker`, `image_picker`.

## Architecture

```text
lib/
  app/        MaterialApp, router, theme tokens (seed #00696D, M3 shapes)
  core/       Money, Currency, Period, Result, extensions, formatters
  data/       Drift database, DAOs, repositories, backup
  domain/     Models and pure business services (unit-tested)
  features/   One folder per feature: presentation / application / domain
  shared/     Reusable widgets
test/         Unit + widget tests (mirrors lib/)
```

Rules enforced by review (and CI):

1. Money is `int` minor units behind `Money`; no `double.parse`, no money maths in widgets.
2. UI never imports Drift — `Screen → Riverpod provider → repository → DAO`.
3. Material 3 tokens only (no hard-coded hex in widgets), 48 dp targets, semantics
   labels, works at 200% text scale and with animations disabled.
4. One public widget per file, files under ~250 lines.

## Commands

```bash
flutter pub get
flutter analyze          # must report 0 issues
flutter test             # unit + widget tests
dart format .
flutter build apk --debug
```

## CI

`.github/workflows/ci.yml` runs on every push and on pull requests to `main`:
Java 17 + Flutter stable, `pub get`, `analyze`, `test`, `build apk --debug`, uploads
the debug APK as an artifact, and asserts the release manifest declares no
permissions.

## Android

- `minSdk 26`, `targetSdk 35`, Java 17, Kotlin DSL Gradle build.
- Deep links: `moneymanager://add`, `moneymanager://home`, `moneymanager://budget/:id`.
- The Gradle wrapper (`gradlew`, `gradle-wrapper.jar`) is intentionally not committed;
  the Flutter tool injects it during a build.
