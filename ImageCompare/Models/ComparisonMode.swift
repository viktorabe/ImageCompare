import Foundation

enum ComparisonMode: String, CaseIterable, Identifiable {
    case slider = "Slider"
    case sideBySide = "Side by Side"
    case overlay = "Overlay"
    case difference = "Difference"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .slider: return "rectangle.split.2x1"
        case .sideBySide: return "square.split.2x1"
        case .overlay: return "square.2.layers.3d"
        case .difference: return "waveform.path.ecg"
        }
    }

    var keyboardShortcut: String {
        switch self {
        case .slider: return "1"
        case .sideBySide: return "2"
        case .overlay: return "3"
        case .difference: return "4"
        }
    }
}
