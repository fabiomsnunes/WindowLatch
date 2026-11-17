#!/usr/bin/env bash
# Signs WindowLatch.app with the stable self-signed "WindowLatch Release" certificate.
#
# macOS ties the Accessibility grant to the app's designated requirement. An ad-hoc
# signature makes that requirement the binary's own hash, so every new build looks like
# a different app and users have to grant Accessibility again. Signing every release
# with the same certificate pins the requirement to the certificate instead, and the
# grant survives updates. Changing the certificate breaks that for every user, which is
# why its fingerprint is pinned here and checked after signing.
#
# Usage: SIGNING_KEYCHAIN=<path> scripts/sign-app.sh <path/to/WindowLatch.app>
set -euo pipefail

readonly CERT_SHA1="6677765CD4BD5C85108B1B925E74FA3039E12A27"
readonly APP="${1:?usage: sign-app.sh <path/to/WindowLatch.app>}"
readonly KEYCHAIN="${SIGNING_KEYCHAIN:?SIGNING_KEYCHAIN must point to the keychain holding the certificate}"

sign() {
  codesign --force --options runtime --timestamp=none \
    --preserve-metadata=entitlements \
    --keychain "$KEYCHAIN" --sign "$CERT_SHA1" "$1"
}

# Nested code first (find -depth lists children before their parent): a bundle's
# signature covers what it contains, so it has to be signed last. Autoupdate is the
# Sparkle helper executable, which has no bundle extension to match on.
while IFS= read -r nested; do
  sign "$nested"
done < <(
  find "$APP/Contents" -depth \( -name '*.framework' -o -name '*.xpc' -o -name '*.app' -o -name '*.dylib' \
    -o \( -name Autoupdate -type f \) \) -print
)
sign "$APP"

codesign --verify --deep --strict --verbose=2 "$APP"

requirement="$(codesign -d -r- "$APP" 2>&1)"
expected="certificate leaf = H\"$(tr '[:upper:]' '[:lower:]' <<<"$CERT_SHA1")\""
if [[ "$requirement" != *"$expected"* ]]; then
  echo "Designated requirement is not pinned to the release certificate:" >&2
  echo "$requirement" >&2
  exit 1
fi
echo "Signed with WindowLatch Release ($CERT_SHA1)"
