# Google Sign-In — setup

The code is fully wired (`lib/features/auth/google_auth_service.dart`, the "Continue
with Google" button on the sign-in screen). It stays **hidden until configured** — the
button only appears when `GOOGLE_SERVER_CLIENT_ID` is set. To turn it on you need OAuth
client IDs from Google Cloud and one iOS `Info.plist` entry. No app code changes.

## How it works
1. The app runs the native Google sheet and gets an **OpenID `id_token`**.
2. It POSTs that to the backend `POST /auth/google { id_token }`.
3. The backend verifies the token's **audience** equals its `GOOGLE_CLIENT_ID` and returns the app JWT.

So the token's audience must match the backend. We achieve that by passing the backend's
**web** client ID as `serverClientId` to the iOS SDK — the returned `id_token` is then minted
for that audience.

## 1. Create OAuth client IDs (Google Cloud Console → APIs & Services → Credentials)
- **Web client ID** — this must be the **same** value as the backend's `GOOGLE_CLIENT_ID`
  env var (the one `/auth/google` verifies against). If the backend already has one, reuse it.
- **iOS client ID** — create an *iOS* OAuth client; bundle id `com.munchordump.app`.
  Google gives you a **client ID** and a **reversed client ID** (`com.googleusercontent.apps.XXXXX`).

## 2. Put the IDs in the app config
Edit `config/dev.json` / `config/prod.json` (or, to keep them out of git, a gitignored
`config/*.local.json` and run with that file):

```json
{
  "GOOGLE_SERVER_CLIENT_ID": "<WEB client id>.apps.googleusercontent.com",
  "GOOGLE_IOS_CLIENT_ID":    "<iOS client id>.apps.googleusercontent.com"
}
```

## 3. Add the iOS URL scheme
The OAuth callback needs the **reversed iOS client ID** as a URL scheme in
`ios/Runner/Info.plist` (inside the top `<dict>`):

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.googleusercontent.apps.XXXXX</string>
    </array>
  </dict>
</array>
```

## 4. (Android, later) `google-services.json`
For Android, add an **Android** OAuth client and drop `google-services.json` into
`android/app/`; `GOOGLE_IOS_CLIENT_ID` is iOS-only and can stay empty there.

## Verify
`flutter run --dart-define-from-file=config/dev.json` → the sign-in screen now shows
"Continue with Google" → tapping it opens the Google sheet → you land signed in.
