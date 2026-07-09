#!/usr/bin/env bash
# Munch or Dump — build, sign, and upload to TestFlight in one command.
#
#   ./tool/release.sh            # build + sign + upload the current pubspec version
#   ./tool/release.sh --bump     # auto-increment the build number (1.0.0+4 -> 1.0.0+5),
#                                # commit the bump, then build + sign + upload
#
# Requirements (one-time, already set up on this Mac):
#   - App Store Connect API key at ~/.appstoreconnect/private_keys/AuthKey_<KEY_ID>.p8
#     (the .p8 is the ONLY secret; Key ID / Issuer ID / Team ID below are public identifiers)
#   - Xcode command line tools + Flutter
#
# After upload: App Store Connect processes ~10-30 min, then TestFlight offers the
# update automatically (export compliance is declared in Info.plist — no manual step).

set -euo pipefail
cd "$(dirname "$0")/.."

KEY_ID="${ASC_KEY_ID:-HUZMB96CFK}"
ISSUER_ID="${ASC_ISSUER_ID:-17c3d467-c867-42ce-b7d8-ff5665ee19fe}"
TEAM_ID="${APPLE_TEAM_ID:-66BV6SH279}"
KEY_PATH="$HOME/.appstoreconnect/private_keys/AuthKey_${KEY_ID}.p8"

[ -f "$KEY_PATH" ] || { echo "ERROR: API key not found at $KEY_PATH"; exit 1; }
[ -f dart_defines.json ] || { echo "ERROR: dart_defines.json missing (Google sign-in would silently disappear)"; exit 1; }

if [ "${1:-}" = "--bump" ]; then
  CUR=$(grep '^version:' pubspec.yaml | sed 's/version: //')
  BASE="${CUR%+*}"; NUM="${CUR#*+}"; NEXT="$BASE+$((NUM + 1))"
  sed -i '' "s/^version: $CUR/version: $NEXT/" pubspec.yaml
  echo "==> bumped $CUR -> $NEXT"
  git add pubspec.yaml && git commit -m "chore: build $NEXT" && git push origin HEAD
fi

VERSION=$(grep '^version:' pubspec.yaml | sed 's/version: //')
echo "==> building $VERSION"
rm -rf build/ios/ipa build/ios/archive

# Step 1: archive. flutter's own export step fails (no local distribution cert) — expected.
flutter build ipa --dart-define-from-file=dart_defines.json || true
[ -d build/ios/archive/Runner.xcarchive ] || { echo "ERROR: archive failed"; exit 1; }

# Step 2: export a signed IPA using the ASC API key (cloud-mints the distribution cert).
cat > build/ExportOptions.plist <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>method</key>
	<string>app-store-connect</string>
	<key>signingStyle</key>
	<string>automatic</string>
	<key>teamID</key>
	<string>${TEAM_ID}</string>
</dict>
</plist>
EOF
echo "==> exporting signed IPA"
xcodebuild -exportArchive \
  -archivePath build/ios/archive/Runner.xcarchive \
  -exportPath build/ios/ipa \
  -exportOptionsPlist build/ExportOptions.plist \
  -allowProvisioningUpdates \
  -authenticationKeyPath "$KEY_PATH" \
  -authenticationKeyID "$KEY_ID" \
  -authenticationKeyIssuerID "$ISSUER_ID" | grep -E "EXPORT|Exported" || true
IPA=$(ls build/ios/ipa/*.ipa)
echo "==> uploading $IPA"

# Step 3: upload to App Store Connect / TestFlight.
xcrun altool --upload-app --type ios -f "$IPA" --apiKey "$KEY_ID" --apiIssuer "$ISSUER_ID"
echo "==> DONE — $VERSION uploaded. TestFlight will offer it after Apple processes (~10-30 min)."
