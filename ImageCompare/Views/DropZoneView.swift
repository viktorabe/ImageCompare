import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct DropZoneView: View {
    let label: String
    let image: NSImage?
    let fileName: String
    let onDrop: (URL) -> Void
    let onOpen: () -> Void

    @State private var isTargeted = false

    private let supportedTypes: [UTType] = [.jpeg, .png, .heic, .tiff, .webP, .image]

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(borderColor, style: StrokeStyle(lineWidth: 2, dash: image == nil ? [6, 4] : []))
                    )

                if let image = image {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding(4)
                } else {
                    emptyState
                }
            }
            .frame(minHeight: 120)
            .onDrop(of: supportedTypes, isTargeted: $isTargeted) { providers in
                handleDrop(providers)
            }
            .animation(.easeInOut(duration: 0.15), value: isTargeted)

            HStack {
                Text(fileName.isEmpty ? label : fileName)
                    .font(.caption)
                    .foregroundStyle(fileName.isEmpty ? .secondary : .primary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer()
                Button("Open") { onOpen() }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
            .padding(.top, 6)
            .padding(.horizontal, 2)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "photo.badge.plus")
                .font(.system(size: 28))
                .foregroundStyle(.secondary)
            Text("Drop image here")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }

    private var backgroundColor: Color {
        if isTargeted { return Color.accentColor.opacity(0.1) }
        return Color(nsColor: .controlBackgroundColor)
    }

    private var borderColor: Color {
        if isTargeted { return .accentColor }
        return image == nil ? Color(nsColor: .separatorColor) : .clear
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        let types = supportedTypes.compactMap { $0.identifier as String? }
        for type in types {
            if provider.hasItemConformingToTypeIdentifier(type) {
                provider.loadItem(forTypeIdentifier: type) { item, _ in
                    DispatchQueue.main.async {
                        if let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                            onDrop(url)
                        } else if let url = item as? URL {
                            onDrop(url)
                        }
                    }
                }
                return true
            }
        }
        return false
    }
}
