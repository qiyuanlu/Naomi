import AppKit

final class PetView: NSView {
    var sprite: NSImage?
    var pose: PetPresentation = .sprite
    var elapsed: TimeInterval = 0
    var onDrag: ((NSEvent) -> Void)?
    var onDrop: (() -> Void)?
    var controls: NSMenu?
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override func accessibilityPerformPress() -> Bool {
        showControls()
        return true
    }
    override func draw(_ dirtyRect: NSRect) {
        NSColor.clear.setFill()
        dirtyRect.fill(using: .copy)
        guard let sprite else { return }
        if pose == .sprite {
            sprite.draw(in: bounds, from: .zero, operation: .sourceOver, fraction: 1)
            return
        }
        let breath = pose == .sleeping ? sin(elapsed * .pi / 2) : 0
        let available = bounds.insetBy(dx: bounds.width * 0.025, dy: bounds.height * 0.025)
        let scale = min(available.width / sprite.size.width, available.height / sprite.size.height)
        let w = sprite.size.width * scale
        let h = sprite.size.height * scale * (1 + breath * 0.018)
        let rect = NSRect(x: bounds.midX-w/2, y: available.minY, width: w, height: h)
        sprite.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1)
        guard pose == .sleeping else { return }
        // Vector effects stay inside the transparent window and breathe slowly.
        let bubbleSize = bounds.width * (0.095 + 0.015 * breath)
        let bubbleRect = NSRect(x: rect.minX + rect.width * 0.31,
                                y: rect.minY + rect.height * 0.30,
                                width: bubbleSize, height: bubbleSize)
        let bubble = NSBezierPath(ovalIn: bubbleRect)
        NSColor(calibratedRed: 0.72, green: 0.87, blue: 1, alpha: 0.48).setFill(); bubble.fill()
        NSColor.white.withAlphaComponent(0.85).setStroke(); bubble.lineWidth = 0.8; bubble.stroke()
        for i in 0..<3 {
            let progress = (elapsed / 3 + Double(i) / 3).truncatingRemainder(dividingBy: 1)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.roundedSleepFont(size: bounds.width * (0.075 + progress * 0.035)),
                .foregroundColor: NSColor(calibratedRed: 0.40, green: 0.55, blue: 0.70, alpha: sin(progress * .pi))]
            (i == 0 ? "Z" : "z").draw(at: NSPoint(x: bounds.width * (0.48 + progress * 0.22),
                y: rect.maxY + bounds.height * (0.015 + progress * 0.16)), withAttributes: attributes)
        }
    }
    override func mouseDown(with event: NSEvent) { onDrag?(event) }
    override func mouseDragged(with event: NSEvent) { onDrag?(event) }
    override func mouseUp(with event: NSEvent) { onDrop?() }
    override func rightMouseDown(with event: NSEvent) {
        showControls()
    }
    func showControls() {
        guard let controls, let window else { return }
        let visible = window.screen?.visibleFrame ?? window.frame
        let menuSize = controls.size
        // Position the compact menu above the pet, fully inside the usable display.
        let anchor = NSPoint(
            x: max(visible.minX + 6, min(window.frame.midX - menuSize.width/2, visible.maxX - menuSize.width - 6)),
            y: min(visible.maxY - 6, window.frame.maxY + menuSize.height + 6))
        let point = convert(window.convertPoint(fromScreen: anchor), from: nil)
        controls.popUp(positioning: nil, at: point, in: self)
    }
}

private extension NSFont {
    static func roundedSleepFont(size: CGFloat) -> NSFont {
        NSFont.systemFont(ofSize: size, weight: .semibold)
    }
}
