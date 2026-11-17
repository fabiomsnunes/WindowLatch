#!/usr/bin/env bash
# Writes the Sparkle appcast for one release: a feed with a single item pointing at the
# release's .dmg, signed with the EdDSA key whose public half is SUPublicEDKey.
#
# The feed is published as a release asset, so SUFeedURL
# (releases/latest/download/appcast.xml) always serves the newest release's feed.
#
# Usage: SPARKLE_BIN=<dir with sign_update> SPARKLE_ED_KEY_FILE=<file> \
#        scripts/make-appcast.sh <tag> <path/to/WindowLatch.app> <path/to/dmg> <out appcast.xml>
set -euo pipefail

readonly TAG="${1:?tag}" APP="${2:?app}" DMG="${3:?dmg}" OUT="${4:?output}"
readonly REPO_URL="https://github.com/fabiomsnunes/WindowLatch"

plist() { /usr/libexec/PlistBuddy -c "Print :$1" "$APP/Contents/Info.plist"; }

bundle_version="$(plist CFBundleVersion)"
short_version="$(plist CFBundleShortVersionString)"
minimum_system="$(plist LSMinimumSystemVersion)"
if [[ "v$short_version" != "$TAG" ]]; then
  echo "Tag $TAG does not match the app version $short_version" >&2
  exit 1
fi

# Sparkle offers an update only when the build number (CFBundleVersion) goes up, so a
# release that bumps MARKETING_VERSION alone would reach nobody. Releases before 1.1.0
# have no appcast; then there is nothing to compare against.
if published_feed="$(curl -fsSL "$REPO_URL/releases/latest/download/appcast.xml" 2>/dev/null)"; then
  published_build="$(sed -n 's:.*<sparkle\:version>\(.*\)</sparkle\:version>.*:\1:p' <<<"$published_feed" | head -1)"
  if [[ -n "$published_build" ]] && ((bundle_version <= published_build)); then
    echo "CURRENT_PROJECT_VERSION ($bundle_version) must be above the published build ($published_build)" >&2
    exit 1
  fi
fi

# Prints: sparkle:edSignature="..." length="..."
enclosure_signature="$("${SPARKLE_BIN:?}/sign_update" --ed-key-file "${SPARKLE_ED_KEY_FILE:?}" "$DMG")"

cat > "$OUT" <<XML
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
  <channel>
    <title>WindowLatch</title>
    <item>
      <title>WindowLatch $short_version</title>
      <pubDate>$(LC_ALL=C date -u "+%a, %d %b %Y %H:%M:%S +0000")</pubDate>
      <sparkle:version>$bundle_version</sparkle:version>
      <sparkle:shortVersionString>$short_version</sparkle:shortVersionString>
      <sparkle:minimumSystemVersion>$minimum_system</sparkle:minimumSystemVersion>
      <sparkle:fullReleaseNotesLink>$REPO_URL/releases/tag/$TAG</sparkle:fullReleaseNotesLink>
      <enclosure url="$REPO_URL/releases/download/$TAG/$(basename "$DMG")" type="application/octet-stream" $enclosure_signature/>
    </item>
  </channel>
</rss>
XML
echo "Wrote $OUT for $short_version (build $bundle_version)"
