import SwiftUI
import AppKit

// MARK: - Clip shape

private struct LeftClip: Shape {
    var fraction: Double
    var animatableData: Double {
        get { fraction }
        set { fraction = newValue }
    }
    func path(in rect: CGRect) -> Path {
        Path(CGRect(x: 0, y: 0, width: rect.width * fraction, height: rect.height))
    }
}

// MARK: - Main view

struct SliderCompareView: View {
    let before: NSImage
    let after: NSImage
    @Binding var sliderPosition: Double
    @Binding var zoomScale: Double
    @Binding var panOffset: CGSize

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            ZStack {
                ImageLayerView(image: after,  containerSize: size, scale: zoomScale, offset: panOffset)
                ImageLayerView(image: before, containerSize: size, scale: zoomScale, offset: panOffset)
                    .clipShape(LeftClip(fraction: sliderPosition))

                dividerLine(at: size.width * sliderPosition, height: size.height)
                handleView(x: size.width * sliderPosition, y: size.height / 2)
                labels

                // Single NSView on top handles all mouse + scroll events
                SliderInteractionLayer(
                    sliderFraction: sliderPosition,
                    zoomScale: zoomScale,
                    panOffset: panOffset,
                    onSlider: { sliderPosition = $0 },
                    onPan:    { panOffset = $0 },
                    onZoom:   { scale, pan in zoomScale = scale; panOffset = pan }
                )
            }
        }
        .clipped()
    }

    private func dividerLine(at x: CGFloat, height: CGFloat) -> some View {
        Rectangle()
            .fill(Color.white)
            .frame(width: 2, height: height)
            .shadow(color: .black.opacity(0.5), radius: 3)
            .position(x: x, y: height / 2)
            .allowsHitTesting(false)
    }

    private func handleView(x: CGFloat, y: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(.white)
                .frame(width: 42, height: 42)
                .shadow(color: .black.opacity(0.35), radius: 5, x: 0, y: 2)
            HStack(spacing: 4) {
                Image(systemName: "chevron.left")
                Image(systemName: "chevron.right")
            }
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(.black.opacity(0.55))
        }
        .position(x: x, y: y)
        .allowsHitTesting(false)
    }

    private var labels: some View {
        HStack {
            Text("BEFORE").opacity(sliderPosition > 0.12 ? 1 : 0)
            Spacer()
            Text("AFTER").opacity(sliderPosition < 0.88 ? 1 : 0)
        }
        .font(.caption2.bold())
        .foregroundStyle(.white)
        .shadow(color: .black.opacity(0.6), radius: 2)
        .padding(.horizontal, 12).padding(.top, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .allowsHitTesting(false)
    }
}

// MARK: - Interaction NSViewRepresentable

private struct SliderInteractionLayer: NSViewRepresentable {
    let sliderFraction: Double
    let zoomScale: Double
    let panOffset: CGSize
    let onSlider: (Double) -> Void
    let onPan: (CGSize) -> Void
    let onZoom: (Double, CGSize) -> Void

    func makeNSView(context: Context) -> InteractionNSView {
        let v = InteractionNSView()
        v.configure(onSlider: onSlider, onPan: onPan, onZoom: onZoom)
        return v
    }

    func updateNSView(_ nsView: InteractionNSView, context: Context) {
        nsView.syncedFraction = sliderFraction
        nsView.syncedZoom     = zoomScale
        nsView.syncedPan      = panOffset
        nsView.configure(onSlider: onSlider, onPan: onPan, onZoom: onZoom)
    }
}

// MARK: - AppKit interaction view

final class InteractionNSView: NSView {
    // Synced from SwiftUI on every update
    var syncedFraction: Double = 0.5
    var syncedZoom:     Double = 1.0
    var syncedPan:      CGSize = .zero

    private var onSlider: ((Double) -> Void)?
    private var onPan:    ((CGSize) -> Void)?
    private var onZoom:   ((Double, CGSize) -> Void)?

    private var mode: DragMode = .none
    private var mouseStart: CGPoint = .zero
    private var panAtStart: CGSize  = .zero

    private enum DragMode { case none, slider, pan }

    func configure(
        onSlider: @escaping (Double) -> Void,
        onPan:    @escaping (CGSize) -> Void,
        onZoom:   @escaping (Double, CGSize) -> Void
    ) {
        self.onSlider = onSlider
        self.onPan    = onPan
        self.onZoom   = onZoom
    }

    override var acceptsFirstResponder: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    // Convert AppKit local point to SwiftUI coordinate (flip Y)
    private func swiftUIPoint(_ p: CGPoint) -> CGPoint {
        CGPoint(x: p.x, y: bounds.height - p.y)
    }

    private func localPoint(_ event: NSEvent) -> CGPoint {
        convert(event.locationInWindow, from: nil)
    }

    override func mouseDown(with event: NSEvent) {
        let loc = localPoint(event)
        let sliderX = bounds.width * syncedFraction
        if abs(loc.x - sliderX) < 48 {
            mode = .slider
        } else {
            mode = .pan
            mouseStart = loc
            panAtStart = syncedPan
        }
    }

    override func mouseDragged(with event: NSEvent) {
        let loc = localPoint(event)
        switch mode {
        case .slider:
            let fraction = max(0, min(1, loc.x / max(1, bounds.width)))
            onSlider?(fraction)
        case .pan:
            let dx =  loc.x - mouseStart.x
            let dy = -(loc.y - mouseStart.y)   // AppKit Y is inverted vs SwiftUI
            onPan?(CGSize(width: panAtStart.width + dx, height: panAtStart.height + dy))
        case .none:
            break
        }
    }

    override func mouseUp(with event: NSEvent) { mode = .none }

    override func scrollWheel(with event: NSEvent) {
        guard event.hasPreciseScrollingDeltas else { return }
        let loc    = swiftUIPoint(localPoint(event))
        let delta  = Double(event.scrollingDeltaY)
        let factor = 1.0 - delta * 0.01
        applyZoom(factor: factor, cursorSwiftUI: loc)
    }

    override func magnify(with event: NSEvent) {
        let loc = swiftUIPoint(localPoint(event))
        applyZoom(factor: 1.0 + Double(event.magnification), cursorSwiftUI: loc)
    }

    private func applyZoom(factor: Double, cursorSwiftUI: CGPoint) {
        let newZoom = max(0.05, min(20.0, syncedZoom * factor))
        let ratio   = newZoom / syncedZoom
        let cx = cursorSwiftUI.x - bounds.width  / 2
        let cy = cursorSwiftUI.y - bounds.height / 2
        let newPan = CGSize(
            width:  (syncedPan.width  + cx) * ratio - cx,
            height: (syncedPan.height + cy) * ratio - cy
        )
        onZoom?(newZoom, newPan)
    }

    // Transparent — only here for event capture
    override func draw(_ dirtyRect: NSRect) {}
    override var isOpaque: Bool { false }
}

// MARK: - Shared image layer (used by other modes too)

struct ImageLayerView: View {
    let image: NSImage
    let containerSize: CGSize
    let scale: Double
    let offset: CGSize

    var body: some View {
        Image(nsImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: containerSize.width, height: containerSize.height)
            .scaleEffect(scale, anchor: .center)
            .offset(offset)
    }
}

// MARK: - Scroll wheel bridge (used by SideBySide / Overlay / Difference modes)

struct ScrollWheelModifier: ViewModifier {
    let action: (NSEvent) -> Void
    func body(content: Content) -> some View {
        content.overlay(ScrollWheelView(action: action))
    }
}

private struct ScrollWheelView: NSViewRepresentable {
    let action: (NSEvent) -> Void
    func makeNSView(context: Context) -> PassthroughScrollView {
        let v = PassthroughScrollView(); v.action = action; return v
    }
    func updateNSView(_ nsView: PassthroughScrollView, context: Context) { nsView.action = action }
}

final class PassthroughScrollView: NSView {
    var action: ((NSEvent) -> Void)?
    // Pass mouse events through so SwiftUI gestures still work in other modes
    override func hitTest(_ point: NSPoint) -> NSView? { nil }
    override func scrollWheel(with event: NSEvent) { action?(event) }
    override func magnify(with event: NSEvent)     { action?(event) }
}

extension View {
    func onScrollWheel(_ action: @escaping (NSEvent) -> Void) -> some View {
        modifier(ScrollWheelModifier(action: action))
    }
}

// MARK: - Cursor modifier (unused in slider mode but kept for other uses)

struct CursorModifier: ViewModifier {
    let cursor: NSCursor
    func body(content: Content) -> some View { content.overlay(CursorView(cursor: cursor)) }
}
private struct CursorView: NSViewRepresentable {
    let cursor: NSCursor
    func makeNSView(context: Context) -> CursorNSView { let v = CursorNSView(); v.cursor = cursor; return v }
    func updateNSView(_ nsView: CursorNSView, context: Context) { nsView.cursor = cursor }
}
final class CursorNSView: NSView {
    var cursor: NSCursor = .arrow
    override func resetCursorRects() { addCursorRect(bounds, cursor: cursor) }
}
extension View {
    func cursor(_ cursor: NSCursor) -> some View { modifier(CursorModifier(cursor: cursor)) }
}
