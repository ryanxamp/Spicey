#!/bin/bash
# Builds Spicey.app: the SwiftUI shell + the spice-gtk display helper.
#
# NOTE: the helper links directly against Homebrew's spice-gtk dylibs
# (absolute /opt/homebrew paths, not vendored into the bundle). That's
# fine as long as Homebrew's spice-gtk stays installed on this Mac —
# it's the simplest thing that works. If you ever want a fully
# self-contained .app you can hand to another Mac, that's a separate,
# heavier step (dylibbundler + GTK module/schema data) — ask and we'll
# add it.
set -euo pipefail
cd "$(dirname "$0")/.."

APP="Spicey.app"
CONTENTS="$APP/Contents"

echo "==> Building spicey-display helper"
make -C helper

echo "==> Building Spicey (swift, release)"
swift build -c release

echo "==> Assembling $APP"
rm -rf "$APP"
mkdir -p "$CONTENTS/MacOS" "$CONTENTS/Resources"

cp .build/release/Spicey "$CONTENTS/MacOS/Spicey"
cp Resources/Info.plist "$CONTENTS/Info.plist"
cp Resources/Spicey.icns "$CONTENTS/Resources/Spicey.icns"
cp helper/spicey-display "$CONTENTS/Resources/spicey-display"

echo "==> Ad-hoc signing"
codesign --force --deep --sign - "$APP"

echo "==> Registering with Launch Services"
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$PWD/$APP"

echo "Done: $APP"
