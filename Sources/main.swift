import AppKit
import HotKey
import WebKit

// MARK: - App Delegate
class AppDelegate: NSObject, NSApplicationDelegate {
    private struct HotKeyConfiguration {
        let key: Key
        let modifiers: NSEvent.ModifierFlags
    }

    private struct HotKeyParseError: Error {
        let message: String
    }

    private static let defaultToggleHotKey = HotKeyConfiguration(key: .slash, modifiers: [.command, .shift])
    private static let toggleHotKeyKeyCodeDefaultsKey = "toggleHotKey.keyCode"
    private static let toggleHotKeyModifiersDefaultsKey = "toggleHotKey.modifiers"

    private var statusItem: NSStatusItem!
    private var toggleMenuItem: NSMenuItem?
    private var hotKey: HotKey?
    private var geminiWindow: NSWindow?
    private var webView: WKWebView?
    private var toggleHotKey = AppDelegate.defaultToggleHotKey
    
    // Configuration
    private let geminiURL = URL(string: "https://gemini.google.com/app")!
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        // Hide from Dock
        NSApp.setActivationPolicy(.accessory)
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        loadSavedToggleHotKey()
        setupMainMenu()
        setupMenuBar()
        setupHotKey()
        setupGeminiWindow()
        print("🚀 Gemini Desktop is running. Press \(formattedToggleHotKey()) to toggle Gemini window.")
    }
    
    // MARK: - Main Menu (Edit key equivalents for WebView)
    private func setupMainMenu() {
        let mainMenu = NSMenu()
        
        // Application menu
        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)
        let appMenu = NSMenu()
        appMenuItem.submenu = appMenu
        appMenu.addItem(NSMenuItem(title: "Quit Gemini Desktop", action: #selector(quit), keyEquivalent: "q"))
        
        // Edit menu — so Cmd+A, Cmd+C, Cmd+V, Cmd+X reach the WebView first responder
        let editMenuItem = NSMenuItem()
        mainMenu.addItem(editMenuItem)
        let editMenu = NSMenu(title: "Edit")
        editMenuItem.submenu = editMenu
        editMenu.addItem(NSMenuItem(title: "Cut", action: Selector("cut:"), keyEquivalent: "x"))
        editMenu.addItem(NSMenuItem(title: "Copy", action: Selector("copy:"), keyEquivalent: "c"))
        editMenu.addItem(NSMenuItem(title: "Paste", action: Selector("paste:"), keyEquivalent: "v"))
        editMenu.addItem(NSMenuItem(title: "Select All", action: Selector("selectAll:"), keyEquivalent: "a"))
        
        NSApp.mainMenu = mainMenu
    }
    
    // MARK: - Menu Bar Setup
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "sparkles", accessibilityDescription: "Gemini Toggle")
            button.image?.isTemplate = true
        }
        
        let menu = NSMenu()

        let toggleItem = NSMenuItem(title: toggleMenuTitle(), action: #selector(toggleGemini), keyEquivalent: "")
        toggleItem.target = self
        menu.addItem(toggleItem)
        toggleMenuItem = toggleItem

        let configureHotKeyItem = NSMenuItem(title: "Set Toggle Hotkey...", action: #selector(configureToggleHotKey), keyEquivalent: "")
        configureHotKeyItem.target = self
        menu.addItem(configureHotKeyItem)
        menu.addItem(NSMenuItem.separator())

        let reloadItem = NSMenuItem(title: "Reload", action: #selector(reloadGemini), keyEquivalent: "r")
        reloadItem.target = self
        menu.addItem(reloadItem)
        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem.menu = menu
    }
    
    // MARK: - HotKey Setup
    private func setupHotKey() {
        hotKey = nil
        hotKey = HotKey(key: toggleHotKey.key, modifiers: toggleHotKey.modifiers)
        hotKey?.keyDownHandler = { [weak self] in
            self?.toggleGemini()
        }
    }

    private func formattedToggleHotKey() -> String {
        KeyCombo(key: toggleHotKey.key, modifiers: toggleHotKey.modifiers).description
    }

    private func toggleMenuTitle() -> String {
        "Toggle Gemini (\(formattedToggleHotKey()))"
    }

    private func updateToggleMenuTitle() {
        toggleMenuItem?.title = toggleMenuTitle()
    }

    private func loadSavedToggleHotKey() {
        let defaults = UserDefaults.standard
        guard
            let storedKeyCode = defaults.object(forKey: Self.toggleHotKeyKeyCodeDefaultsKey) as? Int,
            let storedModifiers = defaults.object(forKey: Self.toggleHotKeyModifiersDefaultsKey) as? Int,
            let key = Key(carbonKeyCode: UInt32(storedKeyCode))
        else {
            return
        }

        let modifiers = NSEvent.ModifierFlags(carbonFlags: UInt32(storedModifiers))
        toggleHotKey = HotKeyConfiguration(key: key, modifiers: modifiers)
    }

    private func saveToggleHotKey() {
        let defaults = UserDefaults.standard
        defaults.set(Int(toggleHotKey.key.carbonKeyCode), forKey: Self.toggleHotKeyKeyCodeDefaultsKey)
        defaults.set(Int(toggleHotKey.modifiers.carbonFlags), forKey: Self.toggleHotKeyModifiersDefaultsKey)
    }

    private func applyToggleHotKey(_ configuration: HotKeyConfiguration, persist: Bool) {
        toggleHotKey = configuration

        if persist {
            saveToggleHotKey()
        }

        setupHotKey()
        updateToggleMenuTitle()
        print("⌨️ Toggle hotkey updated to \(formattedToggleHotKey()).")
    }

    private func parseHotKeyInput(_ input: String) -> Result<HotKeyConfiguration, HotKeyParseError> {
        let trimmedInput = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedInput.isEmpty else {
            return .failure(HotKeyParseError(message: "Shortcut cannot be empty."))
        }

        let normalizedInput = trimmedInput
            .replacingOccurrences(of: "⌘", with: " cmd ")
            .replacingOccurrences(of: "⇧", with: " shift ")
            .replacingOccurrences(of: "⌥", with: " option ")
            .replacingOccurrences(of: "⌃", with: " control ")
            .replacingOccurrences(of: "+", with: " ")

        let tokens = normalizedInput
            .split(whereSeparator: { $0.isWhitespace })
            .map { String($0).lowercased() }

        guard !tokens.isEmpty else {
            return .failure(HotKeyParseError(message: "Shortcut cannot be empty."))
        }

        var modifiers: NSEvent.ModifierFlags = []
        var key: Key?

        for token in tokens {
            switch token {
            case "cmd", "command":
                modifiers.insert(.command)
            case "shift":
                modifiers.insert(.shift)
            case "opt", "option", "alt":
                modifiers.insert(.option)
            case "ctrl", "control", "ctl":
                modifiers.insert(.control)
            default:
                guard let parsedKey = Key(string: token) else {
                    return .failure(HotKeyParseError(message: "\"\(token)\" is not a supported key. Try values like /, a-z, 0-9, f1, space, or return."))
                }

                guard key == nil else {
                    return .failure(HotKeyParseError(message: "Please specify only one non-modifier key."))
                }

                key = parsedKey
            }
        }

        guard let parsedKey = key else {
            return .failure(HotKeyParseError(message: "Please include a key to trigger the shortcut, for example: cmd+shift+/."))
        }

        guard !modifiers.isEmpty else {
            return .failure(HotKeyParseError(message: "Please include at least one modifier key: cmd, option, control, or shift."))
        }

        return .success(HotKeyConfiguration(key: parsedKey, modifiers: modifiers))
    }

    private func promptForToggleHotKey(initialValue: String, errorMessage: String?) -> String? {
        let alert = NSAlert()
        alert.messageText = "Set Toggle Hotkey"

        var informativeText = """
        Enter a shortcut like cmd+shift+/ or option+space.
        You can also type symbol form like ⌘⇧/.
        Current shortcut: \(formattedToggleHotKey())
        """

        if let errorMessage {
            informativeText += "\n\n\(errorMessage)"
            alert.alertStyle = .warning
        }

        alert.informativeText = informativeText
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Cancel")

        let inputField = NSTextField(frame: NSRect(x: 0, y: 0, width: 320, height: 24))
        inputField.placeholderString = "cmd+shift+/"
        inputField.stringValue = initialValue
        alert.accessoryView = inputField

        guard alert.runModal() == .alertFirstButtonReturn else {
            return nil
        }

        return inputField.stringValue
    }
    
    // MARK: - Gemini Window Setup
    private func setupGeminiWindow() {
        // Create window
        let screenRect = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1200, height: 800)
        let windowWidth: CGFloat = 1000
        let windowHeight: CGFloat = 700
        let windowX = (screenRect.width - windowWidth) / 2 + screenRect.origin.x
        let windowY = (screenRect.height - windowHeight) / 2 + screenRect.origin.y
        
        let windowRect = NSRect(x: windowX, y: windowY, width: windowWidth, height: windowHeight)
        
        geminiWindow = NSWindow(
            contentRect: windowRect,
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        geminiWindow?.title = "Gemini Desktop"
        geminiWindow?.isReleasedWhenClosed = false
        geminiWindow?.delegate = self
        
        // Create WebView with configuration
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences.allowsContentJavaScript = true
        
        // Enable developer tools for debugging (optional)
        config.preferences.setValue(true, forKey: "developerExtrasEnabled")
        
        webView = WKWebView(frame: .zero, configuration: config)
        webView?.navigationDelegate = self
        webView?.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
        
        geminiWindow?.contentView = webView
        
        // Load Gemini
        let request = URLRequest(url: geminiURL)
        webView?.load(request)
    }
    
    // MARK: - Toggle Logic
    @objc private func toggleGemini() {
        guard let window = geminiWindow else { return }
        
        if window.isVisible {
            window.orderOut(nil)
        } else {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    @objc private func reloadGemini() {
        webView?.reload()
    }
    
    // MARK: - Menu Actions
    @objc private func configureToggleHotKey() {
        var latestInput = ""
        var validationError: String?

        while true {
            guard let input = promptForToggleHotKey(initialValue: latestInput, errorMessage: validationError) else {
                return
            }

            switch parseHotKeyInput(input) {
            case .success(let configuration):
                applyToggleHotKey(configuration, persist: true)
                return
            case .failure(let error):
                latestInput = input
                validationError = error.message
            }
        }
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
}

// MARK: - Window Delegate
extension AppDelegate: NSWindowDelegate {
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        // Hide instead of close
        sender.orderOut(nil)
        return false
    }
}

// MARK: - WebView Navigation Delegate
extension AppDelegate: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("Gemini loaded successfully")
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("Failed to load Gemini: \(error.localizedDescription)")
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        // Allow navigation to Google domains
        if let url = navigationAction.request.url {
            if url.host?.contains("google.com") == true || url.host?.contains("googleapis.com") == true || url.host?.contains("gstatic.com") == true {
                decisionHandler(.allow)
                return
            }
            // Open external links in default browser
            if navigationAction.navigationType == .linkActivated {
                NSWorkspace.shared.open(url)
                decisionHandler(.cancel)
                return
            }
        }
        decisionHandler(.allow)
    }
}

// MARK: - Main Entry Point
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
