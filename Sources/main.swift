import AppKit
import HotKey
import WebKit

// MARK: - App Delegate
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var hotKey: HotKey?
    private var geminiWindow: NSWindow?
    private var webView: WKWebView?
    
    // Configuration
    private let geminiURL = URL(string: "https://gemini.google.com/app")!
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        // Hide from Dock
        NSApp.setActivationPolicy(.accessory)
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        setupHotKey()
        setupGeminiWindow()
        print("🚀 Gemini Desktop is running. Press ⌘⇧/ to toggle Gemini window.")
    }
    
    // MARK: - Menu Bar Setup
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "sparkles", accessibilityDescription: "Gemini Toggle")
            button.image?.isTemplate = true
        }
        
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title: "Toggle Gemini (⌘⇧/)", action: #selector(toggleGemini), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Reload", action: #selector(reloadGemini), keyEquivalent: "r"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))
        
        statusItem.menu = menu
    }
    
    // MARK: - HotKey Setup
    private func setupHotKey() {
        hotKey = HotKey(key: .slash, modifiers: [.command, .shift])
        hotKey?.keyDownHandler = { [weak self] in
            self?.toggleGemini()
        }
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
        config.preferences.javaScriptEnabled = true
        
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
