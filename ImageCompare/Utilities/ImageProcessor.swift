import AppKit
import CoreImage
import CoreImage.CIFilterBuiltins

final class ImageProcessor {
    static let shared = ImageProcessor()
    private let context = CIContext()

    private init() {}

    func differenceImage(before: NSImage, after: NSImage, size: CGSize) -> NSImage? {
        guard
            let beforeCG = cgImage(from: before, size: size),
            let afterCG = cgImage(from: after, size: size)
        else { return nil }

        let ciA = CIImage(cgImage: beforeCG)
        let ciB = CIImage(cgImage: afterCG)

        let filter = CIFilter.colorAbsoluteDifference()
        filter.inputImage = ciA
        filter.inputImage2 = ciB

        guard let output = filter.outputImage else { return nil }

        // Boost the diff to make subtle differences visible
        let boosted = output.applyingFilter("CIColorControls", parameters: [
            kCIInputSaturationKey: 3.0,
            kCIInputBrightnessKey: 0.0,
            kCIInputContrastKey: 2.0
        ])

        guard let cgResult = context.createCGImage(boosted, from: boosted.extent) else { return nil }
        return NSImage(cgImage: cgResult, size: size)
    }

    func cgImage(from nsImage: NSImage, size: CGSize) -> CGImage? {
        let targetRect = CGRect(origin: .zero, size: size)
        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(size.width),
            pixelsHigh: Int(size.height),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else { return nil }

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        NSColor.black.setFill()
        targetRect.fill()
        nsImage.draw(in: targetRect, from: .zero, operation: .sourceOver, fraction: 1.0)
        NSGraphicsContext.restoreGraphicsState()

        return rep.cgImage
    }
}
