import UIKit

/// An 8-bit sRGB pixel read back from a rendered image.
struct Pixel: Equatable, CustomStringConvertible {
    var red: UInt8
    var green: UInt8
    var blue: UInt8
    var alpha: UInt8

    static let red = Pixel(red: 255, green: 0, blue: 0, alpha: 255)
    static let green = Pixel(red: 0, green: 255, blue: 0, alpha: 255)
    static let blue = Pixel(red: 0, green: 0, blue: 255, alpha: 255)
    static let white = Pixel(red: 255, green: 255, blue: 255, alpha: 255)
    static let clear = Pixel(red: 0, green: 0, blue: 0, alpha: 0)

    var description: String { "rgba(\(red), \(green), \(blue), \(alpha))" }
}

extension UIImage {
    /// Reads the pixel at a position in *points* (the image's own coordinate space).
    func pixel(atPointX x: CGFloat, y: CGFloat) -> Pixel? {
        guard let cgImage else { return nil }
        let px = Int(x * scale)
        let py = Int(y * scale)
        guard px >= 0, py >= 0, px < cgImage.width, py < cgImage.height else { return nil }

        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else { return nil }
        var bytes = [UInt8](repeating: 0, count: 4)
        let drawn = bytes.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(
                data: buffer.baseAddress,
                width: 1,
                height: 1,
                bitsPerComponent: 8,
                bytesPerRow: 4,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return false }
            context.interpolationQuality = .none
            // CoreGraphics' origin is bottom-left: shift so that pixel (px, py) lands in the 1×1 context.
            context.draw(cgImage, in: CGRect(
                x: -px,
                y: -(cgImage.height - 1 - py),
                width: cgImage.width,
                height: cgImage.height
            ))
            return true
        }
        guard drawn else { return nil }
        return Pixel(red: bytes[0], green: bytes[1], blue: bytes[2], alpha: bytes[3])
    }
}
