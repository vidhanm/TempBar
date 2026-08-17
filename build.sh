#!/bin/sh
set -e
cd "$(dirname "$0")"
APP=TempBar.app
rm -rf "$APP"; mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp assets/TempBar.icns "$APP/Contents/Resources/"
swiftc -O -framework AppKit -framework IOKit Sensors.swift main.swift -o "$APP/Contents/MacOS/TempBar"
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleName</key><string>TempBar</string>
<key>CFBundleIdentifier</key><string>com.tempbar.app</string>
<key>CFBundleExecutable</key><string>TempBar</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>1.0</string>
<key>CFBundleIconFile</key><string>TempBar</string>
<key>NSAppleEventsUsageDescription</key><string>TempBar uses System Events to manage its Launch at Login setting.</string>
<key>LSUIElement</key><true/>
<key>LSMinimumSystemVersion</key><string>14.0</string>
</dict></plist>
PLIST
codesign --force --sign - "$APP"
echo "Built $APP"
