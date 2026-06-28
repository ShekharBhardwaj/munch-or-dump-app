# Munch or Dump — Mobile App Architecture Plan

> Status: **proposal, awaiting approval.** No app code exists yet — this repo currently holds only
> `README.md` and the stock Flutter `.gitignore`. This document is the blueprint to build against.
> Once approved, the first PR scaffolds the project and the API/auth layer (Phase 0–1 below).

The mobile app is the **third repo** in the Munch or Dump workspace, alongside
[`munch-or-dump-ui/`](../munch-or-dump-ui) (React web SPA) and
[`munch-or-dump-api/`](../munch-or-dump-api) (Python/Lambda backend). It is a **client of the
existing API** — it ships no business logic of its own. The backend contract is the source of truth;
the web client's [`src/api/client.js`](../munch-or-dump-ui/src/api/client.js) is the reference for
every endpoint shape.

---

## 1. Goals & non-goals

**Goals**
- Native iOS + Android app from one Flutter/Dart codebase.
- First-class **scan** experience — barcode live-scan, label photo, receipt — which is where mobile
  beats the web app (real camera, haptics, offline history, share sheet, push).
- Feature parity with the web app's **consumer** surface (scan, result, browse, account, watchlist,
  history, game), minus web-only concerns (SEO/OG pages, iframe embed, admin console).
- Reuse the existing API **unchanged** wherever possible; flag the few places that need a small
  backend addition (push device tokens, deep-link config).

**Non-goals (v1)**
- Admin console (`/Admin`) — stays web-only.
- Server-rendered SEO/OG pages, `/embed/*` — irrelevant on mobile.
- Offline-first sync / write queue — out of scope; the app is online-first with a read cache.
- A second auth system — we reuse the API's JWT exactly.

---

## 2. Stack decisions

Flutter is already implied by the committed `.gitignore` and was confirmed. Concrete choices below —
each is a recommendation with a one-line rationale, not a survey.

| Concern | Choice | Why |
|---|---|---|
| Language / SDK | **Flutter 3.x (stable), Dart 3** | Confirmed. One codebase, native camera/barcode plugins. |
| State management | **Riverpod 2** (`flutter_riverpod` + `riverpod_generator`) | `AsyncNotifier` maps 1:1 onto the web app's React Query server-state model; compile-safe, testable, no `BuildContext` coupling. |
| Navigation | **go_router** | Declarative routes + deep links / universal links (needed for shared `/p/:slug` product links). |
| Networking | **dio** + a hand-written typed client mirroring `munchAPI` | Interceptors for Bearer auth + 401 + 429 handling. We mirror the JS client's surface so the contract stays legible. |
| Models / JSON | **freezed** + **json_serializable** | Immutable models, codegen `fromJson`, exhaustive `when` for the verdict enum. |
| Secure token store | **flutter_secure_storage** | JWT lives in iOS Keychain / Android Keystore — never plaintext. (Web stores it in `localStorage`; mobile does better.) |
| Barcode scan | **mobile_scanner** | MLKit (Android) / Vision (iOS) under the hood; fast live EAN/UPC detection. |
| Photo / receipt capture | **image_picker** (v1) → **camera** (custom UI later) | Capture or pick label/receipt images; v1 keeps it simple. |
| Image upload | **dio** raw `PUT` to the S3 presigned URL | Matches the existing two-step upload (Content-Type must equal what was signed). |
| Google sign-in | **google_sign_in** | Returns an `idToken` we POST to `/auth/google` (same endpoint the web uses). |
| Local read cache | **hive** (history/watchlist snapshots) + **cached_network_image** | Snappy relaunch, offline viewing of past scans; not a write store. |
| Env / flavors | **`--dart-define`** for `API_BASE_URL`, `GOOGLE_*`; Flutter **flavors** for dev/prod bundle IDs | No secrets in git; prod points at the API Gateway URL. |
| Analytics / crash | **Firebase** (Crashlytics + Analytics) | Crash alerts + usage funnels; the same Firebase SDK doubles as the push channel below, so push is one integration not two. |
| Notifications (later) | **firebase_messaging** (FCM, incl. APNs) | Powers watch-alerts as push instead of email — **needs a new backend endpoint** (see §9). |
| Lint / format | **flutter_lints** (or `very_good_analysis`) + `dart format` | Baseline hygiene. |
| Testing | `flutter_test` (unit/widget), **mocktail**, `integration_test` | API client + key flows under test. |

**Rejected alternatives (brief):** Bloc (more boilerplate than Riverpod for this app's async-read
shape); Provider (too low-level); retrofit codegen for the client (the hand-written mirror of
`munchAPI` is clearer and easier to keep in lock-step with the JS source of truth); GetX (opinionated,
weaker testing story).

---

## 3. Project structure

Feature-first layout — each screen owns its UI, controllers, and widgets; cross-cutting concerns live
in `core/`.

```
lib/
  main.dart                      ← bootstraps flavor, DI (ProviderScope), router
  app.dart                       ← MaterialApp.router, theme, locale
  core/
    api/
      api_client.dart            ← dio instance + base URL + interceptors
      auth_interceptor.dart      ← attaches Bearer; on 401 clears token + routes to login
      munch_api.dart             ← the typed mirror of munchAPI (auth/entities/lists/watches/...)
      api_exception.dart         ← wraps status + body (parity with web's err.status/err.data)
    auth/
      auth_repository.dart        ← login/register/google/logout/me; token persistence
      auth_controller.dart        ← Riverpod AsyncNotifier<AuthState> (≈ web AuthContext)
      token_store.dart            ← flutter_secure_storage wrapper
    models/                       ← freezed models: User, ScanResult, Verdict, Product, Brand,
                                     Ingredient, Category, Vote, Watch, ReceiptJob, NewsPost, ...
    theme/                        ← colors, verdict palette, typography, dark mode
    router/                       ← go_router config + deep-link (app/universal link) handling
    widgets/                      ← shared widgets (VerdictBadge, ScoreRing, IngredientRow, ...)
  features/
    scan/                         ← live barcode + label/receipt capture, IdentificationEngine
    result/                       ← verdict banner, ingredient breakdown, alternatives, voting, share
    history/                      ← past scans (hive cache + /api/scans)
    search/                       ← product search + filters
    product/ brand/ ingredient/ category/   ← catalog detail screens
    account/                      ← profile, persona/goals/dietary, onboarding
    watchlist/                    ← saved + watched products/brands
    game/                         ← "munch or dump?" guessing game
    onboarding/                   ← first-run persona/goals/dietary capture
test/
integration_test/
```

---

## 4. API client layer

A single `MunchApi` class mirrors the web `munchAPI` surface so the two clients stay recognizably the
same. Backend base URL: prod `https://1406mo0ze0.execute-api.us-east-1.amazonaws.com/Prod`
(injected via `--dart-define=API_BASE_URL=...`). All paths are `/auth/*` or `/api/*`.

**Auth:** a dio interceptor reads the JWT from secure storage and sets
`Authorization: Bearer <token>`. **Mobile uses the Bearer header, not the cookie** — confirmed
supported by the backend (`shared/auth.py::_token_from_event` checks the Authorization header first).
No `credentials: include`, no cookie jar needed.

**Error handling parity:** non-2xx → throw `ApiException(status, body)`. `401` → clear token, emit
unauthenticated, route to login (there is **no refresh-token flow** — a 401 means re-auth, same as
web). `429` → surface a friendly "you've hit today's scan limit" (analyze is capped at **30/user/24h**
authed, 10/IP/24h anonymous).

**Surface to implement (from `client.js`):**
- `auth`: `me()`, `login(email,pw)`, `register(...)`, `verifyEmail`, `forgotPassword`,
  `resetPassword`, `google(idToken)`, `updateProfile(...)`, `logout()` — login/register/google/verify
  all return `{ token, user }` in the body.
- `entities`: `ProductScan.create()` (the two-step pipeline below), `Product.{list,search,get}`,
  `Brand.{list,filter,get}`, `Ingredient.filter`, `Category.{list,get}`, `ProductVote.{list,create}`.
- `lists.{get,save,unsave}`, `watches.{list,add,remove}`, `barcodeScan.analyze(barcode)`,
  `receipt.{start,plan,status}`, `game.getLineup`, `news.{list,get}`, `stats.get`,
  `uploadFile(bytes,contentType)` (presigned), `identifyProduct(fileUrls)`.
- **Skip on mobile:** `admin.*`, `banner.set/clear`, `settings.*` (admin), `integrations` framing.

---

## 5. Auth flow (mobile specifics)

1. **Launch:** read token from secure storage → if present, `GET /auth/me`. Valid → authed; 401 →
   clear + show login. (Mirrors web `AuthContext` mount.)
2. **Email/password:** `POST /auth/login` → store `token`, set user.
3. **Register:** `POST /auth/register` → email verification → `POST /auth/verify-email` returns a
   token for the freshly verified account.
4. **Google:** native `google_sign_in` → `idToken` → `POST /auth/google {id_token}` → store token.
   (Requires iOS/Android OAuth client IDs in Google Cloud — see §9.)
5. **Onboarding:** if `me()` returns a profile missing `persona`/`goals`/`dietary`, show the
   onboarding flow and `PATCH /auth/profile` (mirrors web `OnboardingModal`).
6. **Logout:** `POST /auth/logout` (bumps `token_version`, server-side revoke) → wipe secure storage.

The app can also run **anonymously** — scanning by barcode and viewing catalog pages work without
auth (anonymous analyze is rate-limited per-IP). Saving lists, watches, and history require sign-in.

---

## 6. The core scan flow (the headline feature)

Three input modes, all converging on the verdict result. This is where mobile should feel premium —
live camera, haptics on detection, instant cached verdicts.

**A. Barcode (fastest path)**
1. `mobile_scanner` live preview → detect EAN/UPC → haptic.
2. `POST /api/analyze { barcode }` (the `barcodeScan.analyze` shortcut — no images needed).
3. `found:false` → fall back to "snap the label" (mode B). `found:true` → Result screen.

**B. Label photo**
1. Capture/pick image(s) (`image_picker`, JPEG/PNG/WebP only — the upload endpoint rejects others).
2. For each image: `POST /api/upload-url {filename, content_type}` → `PUT` bytes to the returned
   `upload_url` with the **exact** `Content-Type` → keep `file_url`.
3. `POST /api/scans { file_urls, identity? }` → `{ scan_id, ingredients, barcode? }`.
4. `POST /api/analyze { ingredients, scan_id, barcode, product_name, brand, category, file_urls }`.
5. `found:false` → "couldn't read the ingredients, try again" (HTTP 422 in the web client). Else →
   Result. Show `cache_hit` subtly (instant vs "analyzing…").

**C. Receipt** (async job)
1. Upload receipt image (presigned, as above) → `POST /api/receipt { file_url }` → `{ job_id }`.
2. Poll `GET /api/receipt/{job_id}` until `status` done → list of items with verdicts (respects
   `is_premium` / `free_limit`). Pre-shop "plan" mode: `POST /api/receipt { items }`.

**Result screen** renders: `VerdictBadge` (MUNCH / OKAY / TREAT / ENGINEERED / DUMP / BULLSHIT),
score 0–90 ring, ingredient breakdown, healthier alternatives, "For You" personalized notes,
community voting (`ProductVote`), save/watch actions, and a native **share sheet** (deep link to
`/p/:slug`).

**Scan UX details:** request camera permission with a rationale screen; debounce duplicate barcode
reads; optimistic "analyzing…" with the two-step pipeline behind one spinner; write each completed
scan into the hive history cache.

---

## 7. Screen map (web route → mobile screen, with v1 priority)

| Web route | Mobile screen | v1? |
|---|---|---|
| `/Scan` | Scan (barcode/photo/receipt tabs) | ✅ core |
| `/Result/:id` | Result / Verdict | ✅ core |
| `/p/:slug` | Product detail | ✅ core |
| `/Login` + onboarding | Auth + onboarding | ✅ core |
| `/History` | History (auth) | ✅ |
| `/Account` | Account/profile (auth) | ✅ |
| `/Search` | Search + filters | ✅ |
| `/Watchlist` | Watchlist (auth) | ✅ |
| `/Verdicts` (Examples) | Verdicts explainer | ✅ |
| `/Brands`, `/brand/:slug` | Brands + detail | ⬜ v1.1 |
| `/categories`, `/category/:slug` | Categories + detail | ⬜ v1.1 |
| `/ingredients/:slug` | Ingredient detail | ⬜ v1.1 |
| `/Compare` | Compare products | ⬜ v1.1 |
| `/Game` | Munch-or-Dump game | ⬜ v1.1 |
| `/Receipt` | Receipt scan/plan | ⬜ v1.1 |
| `/news`, `/news/:slug` | News feed | ⬜ v1.2 |
| `/About` `/HowItWorks` `/Support` `/Legal` `/Privacy` | Static/info (in-app or webview) | ⬜ v1.2 |
| `/Admin`, `/embed/*` | — | ❌ excluded |

---

## 8. Design system

- Map the brand palette and the **6 verdict colors** into a Flutter `ThemeExtension` so a
  `VerdictBadge`/`ScoreRing` reads one source of truth. Pull exact hex values from the web app's
  Tailwind config / verdict components to stay visually consistent.
- Light + dark mode (web uses `next-themes`); follow system by default.
- Material 3 base, but a custom, brand-led component set — not stock Material — to feel "super
  premium." Framer-Motion-style transitions via Flutter's animation framework + `flutter_animate`.

---

## 9. Backend / infra touch-points (small, flagged early)

Most of the app needs **zero** backend change. The exceptions:

1. **Push notifications (watch alerts).** The backend currently emails watch alerts; there is **no
   device-token registration endpoint**. To do push we'd add e.g. `POST /api/devices {token,
   platform}` + a send path in the watch-alert flow. → Defer to v1.2; design the watchlist so email
   alerts work in v1 without it.
2. **Deep links / universal links.** To open shared `/p/:slug` links in the app we need an Apple
   `apple-app-site-association` file and Android `assetlinks.json` served from the web domain
   (Amplify), plus associated-domains entitlements. → Coordinate with the UI repo's hosting.
3. **Google OAuth client IDs.** Need separate iOS and Android OAuth client IDs in Google Cloud
   (the web `GOOGLE_CLIENT_ID` won't authorize native apps). Backend `/auth/google` already verifies
   the `id_token`, but its `GOOGLE_CLIENT_ID` audience check may need to accept the mobile client IDs.
4. **CORS** does not apply to native apps (no browser origin), so the `CORS_ORIGINS=*` hardening work
   is independent of mobile.

None of these block Phase 0–2.

---

## 10. Phased build order

- **Phase 0 — Scaffold.** `flutter create` (org `com.munchordump`, iOS/Android), flavors (dev/prod),
  CI lint+test, theme skeleton, go_router shell, Riverpod `ProviderScope`. → runnable empty app.
- **Phase 1 — API + auth spine.** `MunchApi` + dio interceptors, `token_store`, `auth_repository`/
  `auth_controller`, email + Google login, `me()` bootstrap, onboarding. **+ Distribution setup at
  end of phase:** Fastlane + CI → TestFlight / Play internal testing (gets Apple's certificate/
  provisioning fiddliness out of the way once there's something installable). → can sign in on a real
  phone.
- **Phase 2 — Scan → Result (vertical slice).** Barcode live-scan + analyze, label-photo upload
  pipeline, Result screen with verdict/score/ingredients/alternatives. → the core loop works E2E.
- **Phase 3 — User surface.** History (hive cache), Account/profile, Watchlist, save lists, voting.
- **Phase 4 — Browse.** Search + filters, Product/Brand/Category/Ingredient detail, Compare.
- **Phase 5 — Extras.** Receipt mode, Game, News, static/info screens, share/deep-links.
- **Phase 6 — Polish & ship.** Push (if §9.1 lands), animations, app icons/splash, store listings,
  TestFlight / Play internal testing, store submission.

---

## 11. Decisions — locked (2026-06-28)

1. **Bundle identifier:** `com.munchordump.app` · **display name:** "Munch or Dump". (Permanent on
   the stores — chosen before first build.)
2. **Min OS:** **iOS 14+**, **Android 8 / API 26+** — covers ~95%+ of active devices without
   inheriting legacy-device pain.
3. **Distribution:** set up **at the end of Phase 1** (not now) — real installable app early, without
   front-loading all of Apple's certificate setup before there's anything to run.
4. **Analytics / crash:** **Firebase** (Crashlytics + Analytics) — also doubles as the push channel
   for §9.1, so push later is one integration, not two.
5. **State management:** **Riverpod 2** — less boilerplate and mirrors the web app's React Query
   server-state model.

---

## 12. Risks & watch-items

- **No refresh tokens** — 30-day JWT then hard re-auth; acceptable, but make the re-login moment
  graceful (preserve the in-progress scan).
- **Rate limits** (analyze 30/user/24h) — a heavy scanner can hit the cap; handle 429 with a clear
  message, and lean on the formula cache (`cache_hit`) being effectively free.
- **Rate limiter fails open** (per backend audit) — not a mobile concern but means abuse protection
  is weaker than the numbers suggest; don't design the app to rely on it.
- **S3 presigned PUT Content-Type must match** what was signed, or the upload 403s — the client must
  send the exact `content_type` it requested the URL with.
- **Keeping two clients in sync** — when the API contract changes, both `munch-or-dump-ui`'s
  `client.js` and this app's `MunchApi` must change. Worth a shared CHANGELOG note per contract change.
```
