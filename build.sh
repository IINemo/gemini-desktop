#!/bin/bash

set -e

echo "🔨 Building GeminiToggle..."

# Build the release version
swift build -c release

# Create app bundle
APP_NAME="GeminiToggle"
APP_DIR="$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "📦 Creating app bundle..."

# Clean previous build
rm -rf "$APP_DIR"

# Create directory structure
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Copy executable
cp ".build/release/GeminiToggle" "$MACOS_DIR/"

# Create Info.plist
cat > "$CONTENTS_DIR/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>GeminiToggle</string>
    <key>CFBundleIdentifier</key>
    <string>com.geminitoggle.app</string>
    <key>CFBundleName</key>
    <string>GeminiToggle</string>
    <key>CFBundleDisplayName</key>
    <string>GeminiToggle</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSAppleEventsUsageDescription</key>
    <string>GeminiToggle needs to control other applications to toggle the Gemini window.</string>
</dict>
</plist>
EOF

echo "✅ Build complete!"
echo ""
echo "📍 App bundle created at: $(pwd)/$APP_DIR"
echo ""
echo "To install:"
echo "  1. Move $APP_DIR to /Applications"
echo "  2. Open System Settings → Privacy & Security → Accessibility"
echo "  3. Add GeminiToggle to the list and enable it"
echo "  4. Launch the app"
echo ""
echo "Or run directly: open $APP_DIR"

