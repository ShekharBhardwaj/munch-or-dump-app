# Backend spec — Sign in with Apple + Account deletion

**Status:** spec / hand-off (no code written). Target repo: **`munch-or-dump-api`** (Python/Lambda/SAM).
**Why now:** both are hard **App Store** requirements once the iOS app ships Google sign-in —
Guideline **4.8** (offer Sign in with Apple when you offer another third-party login) and **5.1.1(v)**
(offer in-app account deletion when you offer account creation).

> **Prime directive — do not break the web.** Every change below is **purely additive**: new routes,
> new *nullable* columns, and (for deletion) transaction logic that only runs on a brand-new code
> path. Nothing an existing web request touches is modified. The "Web-safety invariants" section at
> the bottom is the checklist to hold the line.

Both changes live in the existing **`auth`** Lambda (`functions/auth/handler.py`) — no new function.
They mirror the existing `handle_google_auth` (`functions/auth/handler.py:515`) which is the reference
implementation for shape, verification-fail-closed posture, user create/link, and the
`{token, user}` + `auth_cookie` response.

---

## Reference facts (current backend, as of 2026-07-01)

- **Users table** (`schema.sql`): `id UUID PK`, `email TEXT UNIQUE NOT NULL`, `password_hash TEXT`
  (nullable — already NULL for OAuth accounts), `email_verified`, verification/reset codes,
  `profile JSONB` (persona/goals/dietary/conditions/context live here), `plan TEXT DEFAULT 'free'`,
  `is_banned`, `approved_product_count`, `tier`, `achievements JSONB`, `token_version INTEGER`,
  `created_at`.
- **Token:** `create_token(user_id, email, token_version=0)` → HS256 JWT, 30-day expiry
  (`shared/auth.py:18`). `auth_cookie(token)` / `clear_auth_cookie()` set/clear the `mod_token`
  httpOnly cookie (`shared/response.py:47`). `get_user_from_event(event)` reads the Bearer header
  first, then the cookie (mobile = Bearer, web = cookie).
- **Google handler response** (the shape to copy):
  `success({"token": token, "user": {"id", "email", "plan"}}, cookie=auth_cookie(token))`.
- **Tables with `user_id` → `users(id)`** and their current `ON DELETE`:
  | table | column | ON DELETE | deletion needs |
  |---|---|---|---|
  | `scans` | `user_id` | *(none → RESTRICT)* | **SET NULL** (keep scan for the formula cache; anonymize) |
  | `votes` | `user_id` | *(none → RESTRICT)* | **CASCADE** (personal; remove their votes) |
  | `products` | `created_by_user_id` | *(none → RESTRICT)* | **SET NULL** (keep community product; drop attribution) |
  | `user_watches` | `user_id` | CASCADE ✓ | already handled |
  | `analyze_calls` | `user_id` | SET NULL ✓ | already handled |
  - **Saved lists**: no dedicated `*lists*` table was found in `schema.sql` — saved lists appear to
    live in `users.profile` (JSONB) and therefore die with the row. **Verify at implementation time**
    (`grep -rniE "saved|list" schema.sql functions/lists/handler.py`) and handle any table that turns
    out to carry `user_id`.
  - **Shared / catalog data that must NOT be deleted:** `formulas`, `products`, `brands`,
    `ingredients`, `product_ingredients`. Only the *personal link* is removed.

---

## Feature 1 — Sign in with Apple

### 1.1 New endpoint `POST /auth/apple`
Mirror `/auth/google`. Request body:
```json
{ "identity_token": "<Apple JWT>", "raw_nonce": "<the un-hashed nonce>", "full_name": "Jane Doe" }
```
- `identity_token` — the `credential.identityToken` from the native Apple sheet (required).
- `raw_nonce` — the nonce the app generated (optional but recommended, see 1.3).
- `full_name` — Apple only returns the name on the **first** authorization; the app forwards it if
  present (optional; only used if we add a `display_name` column — see 1.5).

Response — **identical shape to Google**:
```json
{ "token": "<JWT>", "user": { "id": "...", "email": "...", "plan": "free" } }
```
plus `Set-Cookie: mod_token=...` via `auth_cookie(token)`.

### 1.2 Verify the Apple identity token
The identity token is an RS256 JWT signed by Apple. Verify (fail **closed**, like the Google handler
refuses when `GOOGLE_CLIENT_ID` is unset):
1. Fetch Apple's public keys (JWKS) from `https://appleid.apple.com/auth/keys`; pick the key by the
   token header `kid`. Cache the JWKS in-process (module-level, short TTL) — it rarely rotates.
2. Verify **signature** (RS256), `iss == "https://appleid.apple.com"`, `exp` in the future, and
   **`aud` ∈ allowed audiences** (see config below). Rejecting on `aud` is the account-takeover guard,
   exactly as the Google handler pins `GOOGLE_CLIENT_ID`.
3. On any failure → `error("Invalid Apple token", 401)`.

Implementation note: `PyJWT` is already a dependency. Use
`jwt.algorithms.RSAAlgorithm.from_jwk(<matching JWK>)` to build the key, then
`jwt.decode(token, key, algorithms=["RS256"], audience=<allowed>, issuer="https://appleid.apple.com")`.
`cryptography` is required for RS256 — it's already present transitively (via `google-auth`), but add
`cryptography` explicitly to `requirements.txt` to be safe. **No Apple `.p8` private key is needed**
for verifying a login — that key is only for the server-to-server refresh/revoke flow, which this spec
does not use.

### 1.3 Nonce (replay protection — recommended)
Apple stores `SHA256(nonce)` in the token's `nonce` claim when the app passes a hashed nonce to the
native API. Flow: app generates a random `raw_nonce`, passes `SHA256(raw_nonce)` to Apple, and sends
`raw_nonce` to us. Backend recomputes `SHA256(raw_nonce)` and compares to the token's `nonce` claim;
mismatch → 401. If `raw_nonce` is omitted in v1, skip the check (documented trade-off).

### 1.4 User resolution (create / link)
Add `apple_sub` to users and key on it (Apple's `sub` is a stable per-user id):
```sql
ALTER TABLE users ADD COLUMN IF NOT EXISTS apple_sub TEXT UNIQUE;  -- nullable, additive
```
(Postgres allows many NULLs under a UNIQUE, so existing rows are fine.)

Logic:
1. `SELECT id, email, is_banned, plan, token_version FROM users WHERE apple_sub = %s` → if found and
   not banned, sign in.
2. Else if the token carries an `email` → `SELECT ... WHERE email = %s`. If found, **link**: this is an
   existing email/password/Google user adding Apple — set `apple_sub` on that row and sign in.
   (Apple always returns email on the *first* authorization, so linking works on first sign-in.)
3. Else → **create**: `INSERT INTO users (id, email, apple_sub, password_hash, email_verified,
   created_at) VALUES (%s, %s, %s, NULL, TRUE, %s)`. Apple emails are verified. If email is absent
   (a non-first login with no prior `sub` match — rare), reject with a clear message asking the user to
   sign in again so Apple re-sends the email.
4. Reuse the existing `is_banned` guard and `create_token(...)` exactly as Google does.

### 1.5 "Hide My Email" and name (edge cases)
- **Private relay:** email may be `xxxx@privaterelay.appleid.com`. Store as-is; SES mail to it is
  forwarded by Apple (watch-alert / digest emails keep working).
- **Name:** returned by Apple **only on first auth**. The app forwards `full_name`; store it only if we
  add an *optional* `display_name TEXT` column (additive). The app shows no user name today, so this is
  **optional** — safe to skip in v1.

### 1.6 Config / secrets (additive, same mechanism as `GOOGLE_CLIENT_ID`)
- `APPLE_CLIENT_IDS` — comma-separated allowed audiences. For **native iOS**, the `aud` is the app's
  **bundle id** `com.munchordump.app`. If the web ever adds Apple, its `aud` is the Apple **Services
  ID** — add it here too. Fail closed if unset.
- Wire through GitHub Actions secret → SAM `--parameter-overrides` → env var, mirroring the existing
  `GOOGLE_CLIENT_ID` plumbing (`template.yaml`, `shared/config.py`).

### 1.7 `template.yaml`
Add a `POST /auth/apple` API event to the **existing `auth` function** (copy the `/auth/google` event).
No new Lambda, no new IAM.

### 1.8 Mobile integration (`munch-or-dump-app`)
- Add the `sign_in_with_apple` Flutter package. On iOS, request `email` + `fullName` scopes, generate a
  `raw_nonce`, pass `sha256(raw_nonce)` to Apple, then POST `identity_token` + `raw_nonce` +
  first-time `full_name` to `/auth/apple`.
- Add `signInWithApple(...)` to `MunchApi` (mirror `signInWithGoogle`), and an **"Continue with Apple"**
  button on `auth_screen.dart` next to the Google pill (gate it behind an `AppConfig.appleSignInEnabled`
  flag like Google). **HIG:** Apple sign-in must be offered at least as prominently as Google.
- iOS project: enable the **Sign in with Apple** capability (entitlement) in Xcode / provisioning.

### 1.9 App Store note
4.8 requires Apple sign-in be **present and equally prominent** wherever Google is offered, collect
minimal data (name/email only), and not track without consent. The button placement above satisfies
this.

---

## Feature 2 — In-app account deletion

### 2.1 New endpoint `DELETE /api/account`
Auth required (`get_user_from_event`; 401 if absent). Body optional `{ "confirm": true }`.
Response: `{ "deleted": true }` + `clear_auth_cookie()` so the web session drops too.

### 2.2 Deletion logic — **recommend the no-migration transactional approach (B)**
Run in **one transaction** (all-or-nothing), deleting/anonymizing every `user_id` child before the row:
```sql
BEGIN;
  DELETE FROM votes         WHERE user_id = %(uid)s;                     -- personal
  DELETE FROM user_watches  WHERE user_id = %(uid)s;                     -- (also cascades, explicit is fine)
  UPDATE scans          SET user_id = NULL         WHERE user_id = %(uid)s;          -- keep for formula cache
  UPDATE analyze_calls  SET user_id = NULL         WHERE user_id = %(uid)s;          -- keep anonymized rate rows
  UPDATE products       SET created_by_user_id = NULL WHERE created_by_user_id = %(uid)s;  -- keep catalog
  -- <handle any other user_id table discovered by the grep in Reference facts>
  DELETE FROM users     WHERE id = %(uid)s;
COMMIT;
```
Approach (B) needs **no schema change** and is the smallest-blast-radius option — **recommended for v1**.
Approach (A) — adding `ON DELETE SET NULL/CASCADE` to the three RESTRICT constraints so a single
`DELETE FROM users` cascades — is cleaner long-term but requires a constraint migration (drop/recreate
by auto-generated name) and briefly locks those tables; defer unless desired.

**Do not delete shared/catalog rows** (`formulas`, `products`, `brands`, `ingredients`,
`product_ingredients`) — only the personal links.

### 2.3 Token invalidation
After the row is gone, `get_user_from_event` can't resolve the JWT's `sub` → existing tokens are inert.
Returning `clear_auth_cookie()` drops the web cookie immediately.

### 2.4 Abuse / safety
- Authed-only; the endpoint is naturally scoped to `self` (uses the caller's id, never a path param).
- Optional defense-in-depth: for password accounts, require the current password in the body before
  deleting. Not required by the guideline; keep v1 simple (authed `DELETE`).
- Consider adding it to the existing auth rate-limit bucket.

### 2.5 `template.yaml`
Add a `DELETE /api/account` (or `/auth/account`) event to the **existing `auth` function**.

### 2.6 Mobile integration
- `MunchApi.deleteAccount()` → `DELETE /api/account`.
- In `account_screen.dart`, add a **"Delete account"** row (red/`concernHigh`) below sign-out → a
  confirmation dialog ("This permanently deletes your account and all your data. This can't be
  undone.") → on success, call `signOut()` and route home. Follow the app's safety rules: destructive,
  irreversible, so require an explicit confirm tap.

### 2.7 App Store note
5.1.1(v): because the app supports account creation (email + Google + Apple), an in-app deletion path
is **mandatory**. A support-email link is not sufficient; it must be initiated in-app.

---

## Web-safety invariants — the "do not break the web" checklist

The web (`munch-or-dump-ui/src/api/client.js`) calls only: `/auth/me`, `/auth/profile`, `/auth/google`,
`/auth/logout`, `/api/lists`, `/api/watches` (+ admin). None are modified below. To keep the web flow
intact, the backend PR must:

1. **Add, never edit** the existing `/auth/*` handlers. Do not change the request/response shape of
   login, register, google, verify-email, resend, forgot/reset-password, me, profile, or logout.
2. **Do not touch** `create_token`, the JWT payload (`{sub,email,exp,iat,...}`), `auth_cookie`,
   `clear_auth_cookie`, or the `mod_token` cookie name/attributes. New handlers reuse them unchanged.
3. **Users columns are additive & nullable:** `apple_sub TEXT UNIQUE` (and optional `display_name
   TEXT`). Do **not** rename, drop, repurpose, or add NOT-NULL to any existing column. Existing
   `SELECT id, email, plan, ...` queries keep working.
4. **Prefer deletion approach (B)** (no schema/FK change). If (A) is chosen later, ON DELETE rules only
   fire on the new deletion path and never change existing read/write behavior — but (B) is zero-risk.
5. **New routes are additive** template.yaml events on the existing `auth` Lambda. The web client never
   calls `/auth/apple` or `DELETE /api/account`, so its behavior is unchanged. (The web *may* adopt both
   later by adding methods to `client.js` — out of scope here.)
6. **Keep the API↔web contract in sync only where the web changes** — since the web isn't changed here,
   no `client.js` edit is required for these features.

---

## Suggested implementation order (backend PR — remember: push to `main` auto-deploys)

1. Branch off `munch-or-dump-api` `main` (never commit straight to main).
2. Schema: `ALTER TABLE users ADD COLUMN IF NOT EXISTS apple_sub TEXT UNIQUE;` (idempotent, in
   `schema.sql`). Apply to Neon.
3. `handle_apple_auth` in `functions/auth/handler.py` + route in `lambda_handler` + `template.yaml`
   event + `APPLE_CLIENT_IDS` config + `cryptography` in `requirements.txt`.
4. `handle_delete_account` + route + `template.yaml` event.
5. Verify the **web still works** end-to-end (login via Google + email, `/auth/me`, profile, logout)
   against the deploy — the invariants above should make this a no-op, but confirm.
6. Mobile PR (`munch-or-dump-app`): `sign_in_with_apple`, Apple button, `deleteAccount()` + settings row.
7. Both need a real **Apple Developer account** (Sign in with Apple capability + provisioning) — the
   current blocker on the mobile side.

## Still blocked on you (can't do without accounts/keys)
- Apple Developer Program membership → enable Sign in with Apple capability, app id + provisioning.
- Decide whether to store a display name (adds the optional `display_name` column).
- Decide (A) FK-cascade vs (B) transactional delete — spec recommends **(B)** for v1.
