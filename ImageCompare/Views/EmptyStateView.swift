import SwiftUI

struct EmptyStateView: View {
    let onOpenBefore: () -> Void
    let onOpenAfter: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "rectangle.split.2x1")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
                .symbolRenderingMode(.hierarchical)

            VStack(spacing: 6) {
                Text("No Images Loaded")
                    .font(.title2.bold())
                Text("Drop images onto the zones above, or use the Open buttons.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 12) {
                Button("Open Before Image") { onOpenBefore() }
                    .keyboardShortcut("o", modifiers: .command)
                Button("Open After Image") { onOpenAfter() }
                    .keyboardShortcut("o", modifiers: [.command, .shift])
            }
            .buttonStyle(.bordered)

            VStack(alignment: .leading, spacing: 6) {
                shortcutRow("⌘1–4", "Switch comparison mode")
                shortcutRow("⌘S", "Swap before / after")
                shortcutRow("⌘0", "Reset zoom")
                shortcutRow("Space", "Cycle slider position")
            }
            .font(.caption)
            .foregroundStyle(.tertiary)
            .padding(.top, 4)
        }
        .padding(40)
        .frame(maxWidth: 420)
    }

    private func shortcutRow(_ shortcut: String, _ description: String) -> some View {
        HStack(spacing: 8) {
            Text(shortcut)
                .monospacedDigit()
                .frame(width: 60, alignment: .trailing)
            Text(description)
        }
    }
}
