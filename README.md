# munch-or-dump-app

Munch or Dump mobile app — iOS and Android. Scan a product (barcode, label photo, or receipt) and
get a verdict: **MUNCH · OKAY · TREAT · ENGINEERED · DUMP · BULLSHIT**.

Flutter (Dart) client of the existing [Munch or Dump API](../munch-or-dump-api). It ships no business
logic of its own — the backend is the source of truth. See [`PLAN.md`](PLAN.md) for the full
architecture and the phased build order.

> **Status:** Phase 4 (browse) complete — search with filters, category/brand browse, ingredient
> pages, and "better alternatives" on the Result screen. Phase 3 added history/watchlist/voting,
> Phase 2 the scan loop, Phase 1 the auth spine. Google sign-in is gated pending an iOS OAuth client ID.

## Stack

Flutter 3 · Dart 3 · [Riverpod](https://riverpod.dev) (state) · [go_router](https://pub.dev/packages/go_router)
(navigation) · [dio](https://pub.dev/packages/dio) (networking) · `flutter_secure_storage` (JWT) ·
`json_serializable` (models). Camera/barcode (`mobile_scanner`, `image_picker`), Firebase, and Google
sign-in arrive in their phases (see PLAN.md).

## Requirements

- Flutter SDK (stable) — `flutter doctor` should be green for the platforms you target
- Xcode + CocoaPods for iOS · Android SDK for Android

## Quick start

```bash
make setup          # flutter pub get
make gen            # run codegen (json_serializable → *.g.dart)
make run            # run against config/dev.json
make test           # run the test suite
make analyze        # static analysis
```

Without `make`:

```bash
flutter pub get
dart run build_runner build
flutter run --dart-define-from-file=config/dev.json
```

## Configuration

Environment is selected at build time via `--dart-define-from-file` (no secrets in the binary):

| Key | Meaning |
|-----|---------|
| `ENV` | `dev` or `prod` |
| `API_BASE_URL` | Munch or Dump API base (all paths are `/auth/*` or `/api/*`) |
| `GOOGLE_SERVER_CLIENT_ID` | Google OAuth server client ID (wired in Phase 1) |

`config/dev.json` and `config/prod.json` are committed templates. Put machine-local overrides and any
real client IDs in `config/*.local.json` (gitignored). Defaults in `AppConfig` point at production, so
a bare `flutter test` / `flutter run` works with no defines.

## Project layout

```
lib/
  main.dart                  app entrypoint (ProviderScope)
  app.dart                   MaterialApp.router (theme + router)
  core/
    config/app_config.dart   compile-time env config
    api/                     dio client, auth interceptor, ApiException, TokenStore, MunchApi
    models/                  Verdict enum, User (json_serializable)
    theme/                   AppColors, VerdictPalette (ThemeExtension), AppTheme
    router/app_router.dart   go_router routes
    providers.dart           Riverpod providers (token store, dio, api, router)
  features/
    auth/                    sign-in/register, verify email, forgot/reset, AuthController + repo
    onboarding/              persona/goals/dietary/conditions profile capture
    account/                 signed-in account + profile summary
    home/                    landing screen
    scan/                    barcode (camera + manual) & label-photo scan + ScanService pipeline
    result/                  verdict / ingredients / "For You" + save/watch/community-vote actions
    product/                 product detail by slug (reuses the Result screen)
    history/                 past scans (GET /api/scans)
    watchlist/               saved lists + watched products/brands
    browse/                  search (+filters), categories, brands, ingredient pages
test/                        unit + widget tests
config/                      dart-define environment files
```

## Identity

- Bundle id / application id: `com.munchordump.app`
- Min OS (target): iOS 14+, Android 8 (API 26)+

## Deployment

No auto-deploy yet. Distribution (Fastlane + CI → TestFlight / Play internal testing) is set up at the
end of Phase 1, alongside signing. CI ([.github/workflows/ci.yml](.github/workflows/ci.yml)) runs
format + analyze + test on every PR.
