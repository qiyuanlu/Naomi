import Foundation
import CoreGraphics
struct Track {
    let minX: CGFloat
    let maxX: CGFloat
    let y: CGFloat
    init(screen: CGRect, visible: CGRect, size: CGSize) {
        minX = max(screen.minX, visible.minX) + 4
        maxX = max(minX, min(screen.maxX, visible.maxX) - size.width - 4)
        y = max(screen.minY + 3, visible.minY) - size.height * 5 / 208
    }
    func clamp(_ x: CGFloat) -> CGFloat { min(max(x, minX), maxX) }
}
