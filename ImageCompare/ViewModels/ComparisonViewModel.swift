import AppKit
import SwiftUI
import Combine

@MainActor
final class ComparisonViewModel: ObservableObject {
    @Published var beforeImage: NSImage?
    @Published var afterImage: NSImage?
    @Published var beforeFileName: String = ""
    @Published var afterFileName: String = ""
    @Published var mode: ComparisonMode = .slider
    @Published var sliderPosition: Double = 0.5
    @Published var overlayOpacity: Double = 0.5
    @Published var zoomScale: Double = 1.0
    @Published var panOffset: CGSize = .zero
    @Published var differenceImage: NSImage?

    private var differenceTask: Task<Void, Never>?

    var hasImages: Bool { beforeImage != nil || afterImage != nil }
    var hasBothImages: Bool { beforeImage != nil && afterImage != nil }

    var zoomLabel: String {
        String(format: "%.0f%%", zoomScale * 100)
    }

    func loadBefore(_ url: URL) {
        guard let img = NSImage(contentsOf: url) else { return }
        beforeImage = img
        beforeFileName = url.lastPathComponent
        invalidateDifference()
    }

    func loadAfter(_ url: URL) {
        guard let img = NSImage(contentsOf: url) else { return }
        afterImage = img
        afterFileName = url.lastPathComponent
        invalidateDifference()
    }

    func swap() {
        let tmpImg = beforeImage
        let tmpName = beforeFileName
        beforeImage = afterImage
        beforeFileName = afterFileName
        afterImage = tmpImg
        afterFileName = tmpName
        invalidateDifference()
    }

    func resetZoom() {
        withAnimation(.spring(response: 0.3)) {
            zoomScale = 1.0
            panOffset = .zero
        }
    }

    func zoomIn() {
        withAnimation(.spring(response: 0.2)) {
            zoomScale = min(zoomScale * 1.25, 20.0)
        }
    }

    func zoomOut() {
        withAnimation(.spring(response: 0.2)) {
            zoomScale = max(zoomScale / 1.25, 0.05)
        }
    }

    func applyZoomDelta(_ delta: Double, anchor: CGPoint, in size: CGSize) {
        let oldScale = zoomScale
        let newScale = max(0.05, min(20.0, zoomScale * (1 + delta)))
        let scaleFactor = newScale / oldScale

        // Adjust pan so zoom is anchored at cursor position
        let anchorX = anchor.x - size.width / 2
        let anchorY = anchor.y - size.height / 2
        panOffset = CGSize(
            width: (panOffset.width + anchorX) * scaleFactor - anchorX,
            height: (panOffset.height + anchorY) * scaleFactor - anchorY
        )
        zoomScale = newScale
    }

    func cycleSliderPosition() {
        if sliderPosition < 0.1 {
            sliderPosition = 0.5
        } else if sliderPosition < 0.9 {
            sliderPosition = 1.0
        } else {
            sliderPosition = 0.0
        }
    }

    func computeDifferenceIfNeeded(size: CGSize) {
        guard hasBothImages, mode == .difference else {
            differenceImage = nil
            return
        }
        guard size.width > 0, size.height > 0 else { return }

        differenceTask?.cancel()
        let before = beforeImage!
        let after = afterImage!

        differenceTask = Task.detached(priority: .userInitiated) {
            let result = ImageProcessor.shared.differenceImage(before: before, after: after, size: size)
            await MainActor.run { [weak self] in
                self?.differenceImage = result
            }
        }
    }

    private func invalidateDifference() {
        differenceImage = nil
    }

    func openBeforePanel() {
        openImagePanel { [weak self] url in
            self?.loadBefore(url)
        }
    }

    func openAfterPanel() {
        openImagePanel { [weak self] url in
            self?.loadAfter(url)
        }
    }

    private func openImagePanel(completion: @escaping (URL) -> Void) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.jpeg, .png, .heic, .tiff, .webP, .image]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        if panel.runModal() == .OK, let url = panel.url {
            completion(url)
        }
    }

    func exportCurrentView(snapshot: NSImage?) {
        guard let image = snapshot else { return }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png]
        panel.nameFieldStringValue = "comparison.png"
        if panel.runModal() == .OK, let url = panel.url {
            if let tiff = image.tiffRepresentation,
               let bitmap = NSBitmapImageRep(data: tiff),
               let pngData = bitmap.representation(using: .png, properties: [:]) {
                try? pngData.write(to: url)
            }
        }
    }
}
