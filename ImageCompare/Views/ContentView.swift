import SwiftUI
import AppKit

struct ContentView: View {
    @StateObject private var vm = ComparisonViewModel()
    @State private var snapshotImage: NSImage?

    var body: some View {
        VStack(spacing: 0) {
            // Drop zones (shown when no images or collapsed to thin bar when both loaded)
            if !vm.hasBothImages {
                HStack(spacing: 16) {
                    DropZoneView(
                        label: "Before",
                        image: vm.beforeImage,
                        fileName: vm.beforeFileName,
                        onDrop: { vm.loadBefore($0) },
                        onOpen: { vm.openBeforePanel() }
                    )
                    DropZoneView(
                        label: "After",
                        image: vm.afterImage,
                        fileName: vm.afterFileName,
                        onDrop: { vm.loadAfter($0) },
                        onOpen: { vm.openAfterPanel() }
                    )
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(nsColor: .windowBackgroundColor))
            }

            // Thin image strip when both images loaded
            if vm.hasBothImages {
                HStack(spacing: 12) {
                    miniThumb(image: vm.beforeImage, name: vm.beforeFileName, label: "Before") {
                        vm.openBeforePanel()
                    }
                    Divider().frame(height: 32)
                    miniThumb(image: vm.afterImage, name: vm.afterFileName, label: "After") {
                        vm.openAfterPanel()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(Color(nsColor: .windowBackgroundColor))
            }

            Divider()

            // Main comparison area
            Group {
                if vm.hasBothImages {
                    comparisonContent
                } else {
                    EmptyStateView(
                        onOpenBefore: { vm.openBeforePanel() },
                        onOpenAfter: { vm.openAfterPanel() }
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .toolbar { toolbarContent }
        .onKeyboardShortcut(KeyboardShortcut("1", modifiers: .command)) { vm.mode = .slider }
        .onKeyboardShortcut(KeyboardShortcut("2", modifiers: .command)) { vm.mode = .sideBySide }
        .onKeyboardShortcut(KeyboardShortcut("3", modifiers: .command)) { vm.mode = .overlay }
        .onKeyboardShortcut(KeyboardShortcut("4", modifiers: .command)) { vm.mode = .difference }
        .onKeyboardShortcut(KeyboardShortcut("s", modifiers: .command)) { vm.swap() }
        .onKeyboardShortcut(KeyboardShortcut("0", modifiers: .command)) { vm.resetZoom() }
        .onKeyboardShortcut(KeyboardShortcut("+", modifiers: .command)) { vm.zoomIn() }
        .onKeyboardShortcut(KeyboardShortcut("-", modifiers: .command)) { vm.zoomOut() }
        .onKeyboardShortcut(KeyboardShortcut("e", modifiers: .command)) { vm.exportCurrentView(snapshot: snapshotImage) }
    }

    @ViewBuilder
    private var comparisonContent: some View {
        switch vm.mode {
        case .slider:
            SliderCompareView(
                before: vm.beforeImage!,
                after: vm.afterImage!,
                sliderPosition: $vm.sliderPosition,
                zoomScale: $vm.zoomScale,
                panOffset: $vm.panOffset
            )
            .background(Color.black)

        case .sideBySide:
            SideBySideView(
                before: vm.beforeImage!,
                after: vm.afterImage!,
                zoomScale: $vm.zoomScale,
                panOffset: $vm.panOffset
            )
            .background(Color.black)

        case .overlay:
            OverlayCompareView(
                before: vm.beforeImage!,
                after: vm.afterImage!,
                opacity: $vm.overlayOpacity,
                zoomScale: $vm.zoomScale,
                panOffset: $vm.panOffset
            )
            .background(Color.black)

        case .difference:
            DifferenceView(
                before: vm.beforeImage!,
                after: vm.afterImage!,
                differenceImage: vm.differenceImage,
                zoomScale: $vm.zoomScale,
                panOffset: $vm.panOffset,
                onNeedsCompute: { size in vm.computeDifferenceIfNeeded(size: size) }
            )
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        // Mode picker
        ToolbarItem(placement: .principal) {
            Picker("Mode", selection: $vm.mode) {
                ForEach(ComparisonMode.allCases) { mode in
                    Label(mode.rawValue, systemImage: mode.systemImage).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 320)
        }

        // Left side actions
        ToolbarItemGroup(placement: .navigation) {
            Button(action: { vm.openBeforePanel() }) {
                Label("Open Before", systemImage: "photo.badge.plus")
            }
            .help("Open Before Image (⌘O)")

            Button(action: { vm.openAfterPanel() }) {
                Label("Open After", systemImage: "photo.badge.arrow.up")
            }
            .help("Open After Image (⌘⇧O)")

            Button(action: { vm.swap() }) {
                Label("Swap", systemImage: "arrow.left.arrow.right")
            }
            .help("Swap Before/After (⌘S)")
            .disabled(!vm.hasBothImages)
        }

        // Right side zoom
        ToolbarItemGroup(placement: .automatic) {
            Button(action: { vm.zoomOut() }) {
                Image(systemName: "minus.magnifyingglass")
            }
            .help("Zoom Out (⌘-)")
            .disabled(!vm.hasBothImages)

            Text(vm.zoomLabel)
                .font(.callout.monospacedDigit())
                .frame(width: 48, alignment: .center)
                .onTapGesture { vm.resetZoom() }

            Button(action: { vm.zoomIn() }) {
                Image(systemName: "plus.magnifyingglass")
            }
            .help("Zoom In (⌘+)")
            .disabled(!vm.hasBothImages)

            Button(action: { vm.resetZoom() }) {
                Image(systemName: "arrow.up.left.and.down.right.magnifyingglass")
            }
            .help("Fit to View (⌘0)")
            .disabled(!vm.hasBothImages)
        }
    }

    private func miniThumb(image: NSImage?, name: String, label: String, onTap: @escaping () -> Void) -> some View {
        HStack(spacing: 6) {
            if let image = image {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 28, height: 28)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            VStack(alignment: .leading, spacing: 0) {
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(name.isEmpty ? "Untitled" : name)
                    .font(.caption)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(maxWidth: 120, alignment: .leading)
            }
            Button("Change") { onTap() }
                .buttonStyle(.borderless)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Keyboard shortcut helper

private struct KeyboardShortcutModifier: ViewModifier {
    let shortcut: KeyboardShortcut
    let action: () -> Void

    func body(content: Content) -> some View {
        content.background(
            Button("") { action() }
                .keyboardShortcut(shortcut)
                .hidden()
        )
    }
}

extension View {
    func onKeyboardShortcut(_ shortcut: KeyboardShortcut, action: @escaping () -> Void) -> some View {
        modifier(KeyboardShortcutModifier(shortcut: shortcut, action: action))
    }
}
