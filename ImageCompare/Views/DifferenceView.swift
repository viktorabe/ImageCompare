import SwiftUI

struct DifferenceView: View {
    let before: NSImage
    let after: NSImage
    let differenceImage: NSImage?
    @Binding var zoomScale: Double
    @Binding var panOffset: CGSize
    let onNeedsCompute: (CGSize) -> Void

    @State private var isDragging = false
    @State private var dragStart: CGPoint = .zero
    @State private var panStart: CGSize = .zero

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black

                if let diff = differenceImage {
                    ImageLayerView(image: diff, containerSize: geo.size, scale: zoomScale, offset: panOffset)
                } else {
                    ProgressView("Computing difference…")
                        .progressViewStyle(.circular)
                        .foregroundStyle(.white)
                }
            }
            .clipped()
            .onAppear { onNeedsCompute(geo.size) }
            .onChange(of: geo.size) { _, new in onNeedsCompute(new) }
            .gesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { value in
                        if !isDragging {
                            isDragging = true
                            dragStart = value.location
                            panStart = panOffset
                        }
                        panOffset = CGSize(
                            width: panStart.width + value.location.x - dragStart.x,
                            height: panStart.height + value.location.y - dragStart.y
                        )
                    }
                    .onEnded { _ in isDragging = false }
            )
            .onScrollWheel { event in
                if event.hasPreciseScrollingDeltas {
                    let delta = Double(event.scrollingDeltaY) * 0.005
                    let oldScale = zoomScale
                    let newScale = max(0.05, min(20.0, zoomScale * (1 - delta * 5)))
                    let scaleFactor = newScale / oldScale
                    panOffset = CGSize(
                        width: panOffset.width * scaleFactor,
                        height: panOffset.height * scaleFactor
                    )
                    zoomScale = newScale
                }
            }
        }
    }
}
