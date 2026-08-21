#!/bin/bash
# Packages Spicey.app into Spicey.dmg (drag-to-Applications installer).
# Run ./scripts/build-app.sh first.
set -euo pipefail
cd "$(dirname "$0")/.."

APP="Spicey.app"
DMG="Spicey.dmg"
STAGE="$(mktemp -d)"

if [ ! -d "$APP" ]; then
    echo "error: $APP not found — run ./scripts/build-app.sh first" >&2
    exit 1
fi

trap 'rm -rf "$STAGE"' EXIT

cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"

rm -f "$DMG"
hdiutil create -volname "Spicey" -srcfolder "$STAGE" -ov -format UDZO "$DMG"

echo "Done: $DMG"
