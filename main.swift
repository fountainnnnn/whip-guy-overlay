// Whip Guy: a transparent, click-through, always-on-top overlay that draws
// web/index.html over the whole screen. Clicks pass through to the apps below,
// except on the whip guy himself, so he can be dragged, poked and right-clicked.
import Cocoa
import WebKit

final class OverlayPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

final class App: NSObject, NSApplicationDelegate, WKScriptMessageHandler {
    var panel: OverlayPanel!
    var web: WKWebView!
    var status: NSStatusItem!
    var hitRects: [NSRect] = []
    var dragging = false
    var flags: [String: Bool] = ["random": true, "bubbles": true, "sound": true, "hidden": false]
    var speed = 1.0

    func applicationDidFinishLaunching(_ note: Notification) {
        let frame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        panel = OverlayPanel(contentRect: frame, styleMask: [.borderless, .nonactivatingPanel],
                             backing: .buffered, defer: false)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        panel.ignoresMouseEvents = true
        panel.hidesOnDeactivate = false

        let cfg = WKWebViewConfiguration()
        cfg.userContentController.add(self, name: "whip")
        cfg.mediaTypesRequiringUserActionForPlayback = []
        web = WKWebView(frame: NSRect(origin: .zero, size: frame.size), configuration: cfg)
        web.setValue(false, forKey: "drawsBackground")
        web.autoresizingMask = [.width, .height]
        panel.contentView = web
        let dir = Bundle.main.resourceURL!.appendingPathComponent("web")
        web.loadFileURL(dir.appendingPathComponent("index.html"), allowingReadAccessTo: dir)
        panel.orderFrontRegardless()

        status = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        status.button?.title = "🤠"
        status.menu = buildMenu()

        // Let clicks through everywhere except over the whip guy.
        Timer.scheduledTimer(withTimeInterval: 1.0 / 40.0, repeats: true) { [weak self] _ in self?.trackMouse() }
    }

    func trackMouse() {
        let frame = panel.frame
        let m = NSEvent.mouseLocation
        let p = NSPoint(x: m.x - frame.minX, y: frame.maxY - m.y) // web coords, origin top-left
        let over = dragging || hitRects.contains { $0.contains(p) }
        if panel.ignoresMouseEvents == over { panel.ignoresMouseEvents = !over }
    }

    func userContentController(_ c: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any], let type = body["type"] as? String else { return }
        switch type {
        case "rects":
            let list = body["rects"] as? [[Double]] ?? []
            hitRects = list.filter { $0.count == 4 }.map { NSRect(x: $0[0], y: $0[1], width: $0[2], height: $0[3]) }
        case "drag":
            dragging = body["on"] as? Bool ?? false
        case "menu":
            buildMenu().popUp(positioning: nil, at: NSEvent.mouseLocation, in: nil)
        default:
            break
        }
    }

    func buildMenu() -> NSMenu {
        let menu = NSMenu()
        func item(_ title: String, _ action: Selector, _ tag: String = "") -> NSMenuItem {
            let i = NSMenuItem(title: title, action: action, keyEquivalent: "")
            i.target = self
            i.representedObject = tag
            return i
        }
        menu.addItem(item("💥  MEGA ULTRA GIGA WHIP CRACK", #selector(run(_:)), "mega"))
        menu.addItem(item("🤠  Call reinforcements", #selector(run(_:)), "reinforcements"))
        menu.addItem(item("✈️  Request air strike", #selector(run(_:)), "airstrike"))
        menu.addItem(item("🔫  Duel against Claude", #selector(run(_:)), "duel"))
        menu.addItem(.separator())
        for (key, title) in [("random", "Random events"), ("bubbles", "Speech bubbles"), ("sound", "Sound")] {
            let i = item(title, #selector(toggle(_:)), key)
            i.state = flags[key] == true ? .on : .off
            menu.addItem(i)
        }
        menu.addItem(item("Faster", #selector(faster)))
        menu.addItem(item("Slower", #selector(slower)))
        let hide = item(flags["hidden"] == true ? "Show whip guy" : "Hide whip guy", #selector(toggle(_:)), "hidden")
        menu.addItem(hide)
        menu.addItem(.separator())
        menu.addItem(item("Quit Whip Guy", #selector(quit)))
        return menu
    }

    func js(_ s: String) { web.evaluateJavaScript(s, completionHandler: nil) }
    func refreshMenu() { status.menu = buildMenu() }

    @objc func run(_ sender: NSMenuItem) {
        if let name = sender.representedObject as? String { js("window.whip.do('\(name)')") }
    }
    @objc func toggle(_ sender: NSMenuItem) {
        guard let key = sender.representedObject as? String else { return }
        let v = !(flags[key] ?? false)
        flags[key] = v
        js("window.whip.set('\(key)', \(v))")
        refreshMenu()
    }
    @objc func faster() { speed = min(3, speed * 1.4); js("window.whip.set('speed', \(speed))") }
    @objc func slower() { speed = max(0.3, speed / 1.4); js("window.whip.set('speed', \(speed))") }
    @objc func quit() { NSApp.terminate(nil) }
}

let app = NSApplication.shared
let delegate = App()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
