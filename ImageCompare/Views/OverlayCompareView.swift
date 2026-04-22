import SwiftUI

struct OverlayCompareView: View {
    let before: NSImage
    let after: NSImage
    @Binding var opacity: Double
    @Binding var zoomScale: Double
    @Binding var panOffset: CGSize

    @State private var isDragging = false
    @State private var dragStart: CGPoint = .zero
    @State private var panStart: CGSize = .zero

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ImageLayerView(image: before, containerSize: geo.size, scale: zoomScale, offset: panOffset)
                ImageLayerView(image: after, containerSize: geo.size, scale: zoomScale, offset: panOffset)
                    .opacity(opacity)

                // Opacity control
                VStack {
                    Spacer()
                    HStack {
                        Text("0%").font(.caption2).foregroundStyle(.secondary)
                        Slider(value: $opacity)
                            .frame(width: 160)
                        Text("100%").font(.caption2).foregroundStyle(.secondary)
                        Text("\(Int(opacity * 100))%")
                            .font(.caption2.monospacedDigit())
                            .frame(width: 34, alignment: .trailing)
                    }
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
                    .padding(.bottom, 16)
                }
            }
            .clipped()
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
