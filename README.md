# Gemini Desktop

A lightweight macOS menu bar app that lets you toggle Google Gemini with a global hotkey. Gemini runs in an embedded WebView, so there's no Dock icon clutter.

## Features

- **Global Hotkey**: Toggle Gemini with a configurable shortcut (default: `⌘⇧/`)
- **Tray Hotkey Config**: Change the toggle shortcut directly from the menu bar
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
git clone https://github.com/IINemo/gemini-desktop.git
cd gemini-desktop

# Make build script executable
chmod +x build.sh

# Build the app
./build.sh

# Move to Applications
mv "Gemini Desktop.app" /Applications/
```

### Quick Run (Development)

```bash
swift run
```

## Setup

### Grant Accessibility Permissions

For the global hotkey to work system-wide:

1. Open **System Settings** → **Privacy & Security** → **Accessibility**
2. Click **+** and add **Gemini Desktop**
3. Enable the toggle

### Launch at Login (Optional)

1. Open **System Settings** → **General** → **Login Items**
2. Click **+** under "Open at Login"
3. Select **Gemini Desktop.app**

## Usage

| Action | Result |
|--------|--------|
| Configured toggle shortcut (default: `⌘⇧/`) | Toggle Gemini window visibility |
| Menu bar icon → Set Toggle Hotkey... | Change and save the global shortcut |
| Menu bar icon → Reload | Refresh the Gemini page |
| Menu bar icon → Quit | Exit the app |

## Customization

### Change the Hotkey

You can change the hotkey directly from the tray menu:

1. Click the Gemini menu bar icon
2. Select **Set Toggle Hotkey...**
3. Enter a shortcut (examples: `cmd+shift+/`, `option+space`, `⌘⇧/`)
4. Click **Save**

The new shortcut is applied immediately and saved for the next launch.

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
