import SwiftUI
import AppKit

struct SideBySideView: View {
    let before: NSImage
    let after: NSImage
    @Binding var zoomScale: Double
    @Binding var panOffset: CGSize

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 1) {
                SyncedImageView(
                    image: before,
                    label: "BEFORE",
                    containerSize: CGSize(width: geo.size.width / 2 - 0.5, height: geo.size.height),
                    zoomScale: $zoomScale,
                    panOffset: $panOffset
                )

                Rectangle()
                    .fill(Color(nsColor: .separatorColor))
                    .frame(width: 1)

                SyncedImageView(
                    image: after,
                    label: "AFTER",
                    containerSize: CGSize(width: geo.size.width / 2 - 0.5, height: geo.size.height),
                    zoomScale: $zoomScale,
                    panOffset: $panOffset
                )
            }
        }
        .clipped()
    }
}

private struct SyncedImageView: View {
    let image: NSImage
    let label: String
    let containerSize: CGSize
    @Binding var zoomScale: Double
    @Binding var panOffset: CGSize

    @State private var isDragging = false
    @State private var dragStart: CGPoint = .zero
    @State private var panStart: CGSize = .zero

    var body: some View {
        ZStack(alignment: .topLeading) {
            ImageLayerView(image: image, containerSize: containerSize, scale: zoomScale, offset: panOffset)
                .clipped()

            Text(label)
                .font(.caption2).bold()
                .padding(.horizontal, 6).padding(.vertical, 3)
                .background(.ultraThinMaterial, in: Capsule())
                .padding(10)
        }
        .frame(width: containerSize.width, height: containerSize.height)
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
