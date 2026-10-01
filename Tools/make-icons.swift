import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
let sourceURL = URL(fileURLWithPath: "assets/Nuomi-icon-source.png")
let source = CGImageSourceCreateWithURL(sourceURL as CFURL, nil)!
let image = CGImageSourceCreateImageAtIndex(source, 0, nil)!
let sizes = [(16,1),(16,2),(32,1),(32,2),(128,1),(128,2),(256,1),(256,2),(512,1),(512,2)]
for (points, scale) in sizes {
    let pixels = points*scale
    let context = CGContext(data: nil, width: pixels, height: pixels, bitsPerComponent: 8, bytesPerRow: pixels*4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    context.interpolationQuality = .high
    let fit = CGFloat(pixels)*0.90/max(CGFloat(image.width), CGFloat(image.height))
    let width = CGFloat(image.width)*fit, height = CGFloat(image.height)*fit
    context.draw(image, in: CGRect(x:(CGFloat(pixels)-width)/2, y:(CGFloat(pixels)-height)/2, width:width, height:height))
    let suffix = scale == 2 ? "@2x" : ""
    let file = URL(fileURLWithPath:"assets/Nuomi.iconset/icon_\(points)x\(points)\(suffix).png")
    let destination = CGImageDestinationCreateWithURL(file as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(destination, context.makeImage()!, nil)
    precondition(CGImageDestinationFinalize(destination))
}
print("Created ten transparent PNG representations; only proportional resizing and padding applied.")
