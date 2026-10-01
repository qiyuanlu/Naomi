import AppKit

final class PetPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
final class PetApp: NSObject, NSApplicationDelegate {
    var panel: PetPanel!
    let view = PetView()
    var status: NSStatusItem!
    var timer: Timer?
    var environmentTimer: Timer?
    var frames: [[NSImage]] = []
    var sleepingImage: NSImage!
    var carriedImage: NSImage!
    var screen: NSScreen!
    var direction: CGFloat = 1
    var x: CGFloat = 0
    var width: CGFloat = 112
    var paused = false
    var sleeping = false
    var passThrough = false
    var dragging = false
    var dragOffset = NSPoint.zero
    var row = 0
    var behavior = PetBehavior()
    var didDrag = false
    var downPoint = NSPoint.zero
    var clickLeftHalf = true
    var frameIndex = 0
    var lastTime = ProcessInfo.processInfo.systemUptime
    var animationElapsed: TimeInterval = 0
    var pauseItem: NSMenuItem!
    var passthroughItem: NSMenuItem!
    var sizeItems: [NSMenuItem] = []
    var size: CGSize { CGSize(width: width, height: width * 208 / 192) }
    var track: Track { Track(screen: screen.frame, visible: screen.visibleFrame, size: size) }
    func applicationDidFinishLaunching(_ notification: Notification) {
        guard let url = Bundle.main.url(forResource: "spritesheet-extended", withExtension: "png"),
              let source = NSImage(contentsOf: url), let cg = source.cgImage(forProposedRect: nil, context: nil, hints: nil), cg.width == 1536, cg.height == 2288 else {
            let alert = NSAlert(); alert.messageText = "糯米的动画素材缺失或损坏"; alert.runModal(); NSApp.terminate(nil); return
        }
        for (r, count) in [6,8,8,4,5].enumerated() {
            frames.append((0..<count).map { c in
                let crop = cg.cropping(to: CGRect(x: c*192, y: r*208, width: 192, height: 208))!
                return NSImage(cgImage: crop, size: CGSize(width: 192, height: 208))
            })
        }
        guard let sleepURL = Bundle.main.url(forResource: "sleeping", withExtension: "png"),
              let carryURL = Bundle.main.url(forResource: "carried", withExtension: "png"),
              let sleepImage = NSImage(contentsOf: sleepURL), let carryImage = NSImage(contentsOf: carryURL) else {
            NSApp.terminate(nil); return
        }
        sleepingImage = sleepImage; carriedImage = carryImage
        screen = NSScreen.main ?? NSScreen.screens[0]
        panel = PetPanel(contentRect: CGRect(origin: .zero, size: size), styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.isOpaque = false; panel.backgroundColor = .clear; panel.hasShadow = false
        panel.level = .floating; panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        panel.isReleasedWhenClosed = false; panel.contentView = view
        panel.title = "糯米桌面伙伴"
        view.setAccessibilityElement(true)
        view.setAccessibilityRole(.button)
        view.setAccessibilityLabel("糯米控制菜单")
        view.onDrag = { [weak self] event in self?.drag(event) }
        view.onDrop = { [weak self] in self?.drop() }
        x = track.minX + (track.maxX-track.minX) * 0.35
        makeMenu(); place(); render(); panel.orderFrontRegardless()
        NotificationCenter.default.addObserver(self, selector: #selector(screenChanged), name: NSApplication.didChangeScreenParametersNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(sleepNow), name: NSWorkspace.screensDidSleepNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(wakeNow), name: NSWorkspace.screensDidWakeNotification, object: nil)
        environmentTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in self?.refreshEnvironment() }
        environmentTimer?.tolerance = 0.5
        schedule()
    }
    func makeMenu() {
        status = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        status.button?.title = "糯米 🐾"
        let menu = NSMenu()
        let title = NSMenuItem(title: "糯米", action: nil, keyEquivalent: ""); menu.addItem(title)
        menu.addItem(.separator())
        pauseItem = add(menu, "暂停", #selector(togglePause))
        let sizes = NSMenu(); let parent = NSMenuItem(title: "大小", action: nil, keyEquivalent: ""); parent.submenu = sizes; menu.addItem(parent)
        for (label, value) in [("小",80),("中",112),("大",152)] {
            let item = add(sizes, label, #selector(resizePet(_:))); item.tag = value; item.state = value == 112 ? .on : .off; sizeItems.append(item)
        }
        passthroughItem = add(menu, "穿透点击", #selector(togglePassthrough))
        add(menu, "移到鼠标屏幕", #selector(moveToPointer))
        add(menu, "回到底边", #selector(resetPosition))
        passthroughItem.toolTip = "开启后鼠标可穿过小猫；从菜单栏关闭后可点击和拖动。"
        menu.addItem(.separator()); add(menu, "退出", #selector(quit))
        status.menu = menu
        view.controls = menu
    }
    @discardableResult func add(_ menu: NSMenu, _ title: String, _ action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: ""); item.target = self; menu.addItem(item); return item
    }
    func schedule() {
        timer?.invalidate(); timer = nil
        guard !paused && !sleeping && !dragging else { return }
        lastTime = ProcessInfo.processInfo.systemUptime
        let interval = behavior.mood == .resting ? 1.0 : (row == 1 || row == 2 ? 1.0/24 : 1.0/8)
        let t = Timer(timeInterval: interval, repeats: true) { [weak self] _ in self?.tick() }
        t.tolerance = interval * 0.2; RunLoop.main.add(t, forMode: .common); timer = t
    }
    func tick() {
        let now = ProcessInfo.processInfo.systemUptime
        let dt = min(2, now-lastTime); lastTime = now
        let previous = behavior.mood
        behavior.advance(dt); animationElapsed += dt
        if behavior.mood == .runningRight || behavior.mood == .runningLeft {
            direction = behavior.mood == .runningRight ? 1 : -1
            x += direction * 80 * min(dt, 0.1)
            if x >= track.maxX || x <= track.minX { x = track.clamp(x); behavior.stopAtEdge() }
            place()
        }
        if previous != behavior.mood { animationElapsed = 0; frameIndex = 0; updatePose(); schedule() }
        else { updatePose() }
    }
    func updatePose() {
        switch behavior.mood {
        case .runningRight: row = 1; frameIndex = Int(animationElapsed * 8) % 8
        case .runningLeft: row = 2; frameIndex = Int(animationElapsed * 8) % 8
        case .sitting:
            row = 0
            let blink = animationElapsed.truncatingRemainder(dividingBy: 5)
            frameIndex = blink < 4.25 ? 0 : min(5, Int((blink-4.25)*8))
        case .resting: row = 4; frameIndex = 0
        case .asleep: row = 0; frameIndex = 3
        }
        render()
    }
    func render() {
        let pose = PetPresentation(mood: behavior.mood, isCarried: dragging && didDrag)
        let next = pose == .carried ? carriedImage! : pose == .lying || pose == .sleeping ? sleepingImage! : frames[row][frameIndex % frames[row].count]
        let changed = view.sprite !== next || view.pose != pose
        view.pose = pose; view.elapsed = animationElapsed
        if changed || pose == .sleeping { view.sprite = next; view.needsDisplay = true }
    }
    func place() { x = track.clamp(x); panel.setFrame(CGRect(x: x, y: track.y, width: size.width, height: size.height), display: true) }
    func drag(_ event: NSEvent) {
        let mouse = NSEvent.mouseLocation
        if event.type == .leftMouseDown {
            dragging = true; didDrag = false; downPoint = mouse
            dragOffset = NSPoint(x: mouse.x-panel.frame.minX, y: mouse.y-panel.frame.minY)
            clickLeftHalf = dragOffset.x < size.width/2
            schedule(); return
        }
        if !didDrag && hypot(mouse.x-downPoint.x, mouse.y-downPoint.y) > 4 {
            didDrag = true
            // The pointer holds the nape while the relaxed body hangs underneath.
            dragOffset = NSPoint(x: size.width * 0.52, y: size.height * 0.73)
            render()
        }
        if didDrag { panel.setFrameOrigin(NSPoint(x: mouse.x-dragOffset.x, y: mouse.y-dragOffset.y)) }
    }
    func drop() {
        dragging = false
        if didDrag {
            screen = NSScreen.screens.first { $0.frame.contains(NSEvent.mouseLocation) } ?? screen
            x = panel.frame.minX; behavior.settle(); place()
        } else if !paused { behavior.poke(leftHalf: clickLeftHalf) }
        animationElapsed = 0; updatePose(); schedule()
    }
    func refreshEnvironment() {
        guard panel != nil, !dragging else { return }
        if !NSScreen.screens.contains(where: { $0 == screen }) { screen = NSScreen.main ?? NSScreen.screens[0] }
        place()
    }
    @objc func screenChanged() { refreshEnvironment() }
    @objc func sleepNow() { sleeping = true; schedule() }
    @objc func wakeNow() { sleeping = false; refreshEnvironment(); schedule() }
    @objc func togglePause() { paused.toggle(); pauseItem.title = paused ? "继续" : "暂停"; schedule() }
    @objc func togglePassthrough() { passThrough.toggle(); panel.ignoresMouseEvents = passThrough; passthroughItem.state = passThrough ? .on : .off }
    @objc func resizePet(_ sender: NSMenuItem) { width = CGFloat(sender.tag); for item in sizeItems { item.state = item === sender ? .on : .off }; place() }
    @objc func moveToPointer() { screen = NSScreen.screens.first { $0.frame.contains(NSEvent.mouseLocation) } ?? screen; x = NSEvent.mouseLocation.x-size.width/2; place() }
    @objc func resetPosition() { x = track.minX + (track.maxX-track.minX)/2; place() }
    @objc func quit() { NSApp.terminate(nil) }
    func applicationWillTerminate(_ notification: Notification) { timer?.invalidate(); environmentTimer?.invalidate() }
}
let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate = PetApp()
app.delegate = delegate
app.run()
