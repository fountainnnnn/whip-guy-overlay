#!/bin/sh
# Builds WhipGuy.app next to this script.
set -e
cd "$(dirname "$0")"
APP=WhipGuy.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cat > "$APP/Contents/Info.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleName</key><string>Whip Guy</string>
  <key>CFBundleIdentifier</key><string>local.whipguy.overlay</string>
  <key>CFBundleExecutable</key><string>WhipGuy</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>0.1</string>
  <key>LSUIElement</key><true/>
  <key>NSHighResolutionCapable</key><true/>
</dict></plist>
EOF
swiftc -O -module-cache-path "${TMPDIR:-/tmp}/whipguy-modcache" main.swift -o "$APP/Contents/MacOS/WhipGuy" -framework Cocoa -framework WebKit
cp -R web "$APP/Contents/Resources/web"
codesign --force --sign - "$APP" >/dev/null 2>&1 || true
echo "built $APP"
