# GeminiToggle

A lightweight macOS menu bar app that lets you toggle Google Gemini with a global hotkey. Gemini runs in an embedded WebView, so there's no Dock icon clutter.

## Features

- **Global Hotkey**: Press `⌘⇧/` (Command + Shift + /) to toggle Gemini
- **Menu Bar App**: Runs quietly in your menu bar with a sparkles icon
- **No Dock Icon**: The app and Gemini window are completely hidden from the Dock
- **Native WebView**: Gemini runs embedded in the app - no separate browser needed
- **Lightweight**: Native Swift app with minimal resource usage

## Screenshot

Press `⌘⇧/` and Gemini appears. Press again to hide.

## Installation

### Build from Source

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/gemini-toggle.git
cd gemini-toggle

# Make build script executable
chmod +x build.sh

# Build the app
./build.sh

# Move to Applications
mv GeminiToggle.app /Applications/
```

### Quick Run (Development)

```bash
swift run
```

## Setup

### Grant Accessibility Permissions

For the global hotkey to work system-wide:

1. Open **System Settings** → **Privacy & Security** → **Accessibility**
2. Click **+** and add **GeminiToggle**
3. Enable the toggle

### Launch at Login (Optional)

1. Open **System Settings** → **General** → **Login Items**
2. Click **+** under "Open at Login"
3. Select **GeminiToggle.app**

## Usage

| Action | Result |
|--------|--------|
| `⌘⇧/` | Toggle Gemini window visibility |
| Menu bar icon → Reload | Refresh the Gemini page |
| Menu bar icon → Quit | Exit the app |

## Customization

### Change the Hotkey

Edit `Sources/main.swift` and modify the `setupHotKey()` function:

```swift
// Example: Change to ⌘⌥G
hotKey = HotKey(key: .g, modifiers: [.command, .option])
```

Available keys: `.space`, `.a` through `.z`, `.f1` through `.f12`, `.slash`, etc.
Available modifiers: `.command`, `.option`, `.control`, `.shift`

### Change Window Size

Edit the window dimensions in `setupGeminiWindow()`:

```swift
let windowWidth: CGFloat = 1000  // Change width
let windowHeight: CGFloat = 700  // Change height
```

## Requirements

- macOS 13.0 (Ventura) or later
- Internet connection for Gemini

## How It Works

1. The app runs as a menu bar application (no Dock icon)
2. It creates a native WebView that loads Gemini
3. The global hotkey toggles the window visibility
4. When hidden, the window is just off-screen - Gemini stays loaded

## Troubleshooting

### Hotkey doesn't work
- Ensure Accessibility permissions are granted in System Settings
- Try removing and re-adding the app in Accessibility settings
- Restart the app after granting permissions

### Gemini won't load
- Check your internet connection
- Click "Reload" from the menu bar icon
- Make sure you're signed into Google

### Window appears but is blank
- Wait a few seconds for the page to load
- Try clicking "Reload" from the menu

## License

MIT License - Feel free to modify and distribute.

## Credits

- Uses [HotKey](https://github.com/soffes/HotKey) by Sam Soffes for global hotkey support
