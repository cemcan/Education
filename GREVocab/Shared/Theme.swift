import AppIntents
import SwiftUI

/// The visual style shared by the widgets, the app's word card and the wallpaper image.
/// Palettes are deliberately muted: a deep base, one soft light source and a single
/// metallic accent, in the manner of a well-printed book jacket.
enum Theme: String, CaseIterable, Identifiable, AppEnum {
    case midnight, ivory, forest, graphite

    var id: String { rawValue }

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Theme"

    static var caseDisplayRepresentations: [Theme: DisplayRepresentation] = [
        .midnight: "Midnight Ink",
        .ivory: "Ivory Paper",
        .forest: "Library Green",
        .graphite: "Graphite",
    ]

    var title: String {
        switch self {
        case .midnight: return "Midnight Ink"
        case .ivory: return "Ivory Paper"
        case .forest: return "Library Green"
        case .graphite: return "Graphite"
        }
    }

    /// Top and bottom of the base gradient.
    var baseColors: [Color] {
        switch self {
        case .midnight: return [Color(hex: 0x0B1026), Color(hex: 0x1A1640)]
        case .ivory: return [Color(hex: 0xF8F3E8), Color(hex: 0xEBE1CC)]
        case .forest: return [Color(hex: 0x0C211C), Color(hex: 0x1B3D33)]
        case .graphite: return [Color(hex: 0x111216), Color(hex: 0x24262D)]
        }
    }

    /// Colour of the soft light falling from the upper corner.
    var glow: Color {
        switch self {
        case .midnight: return Color(hex: 0x5B6CFF)
        case .ivory: return Color(hex: 0xFFFFFF)
        case .forest: return Color(hex: 0x6FB59A)
        case .graphite: return Color(hex: 0x7C8BA8)
        }
    }

    var glowOpacity: Double { self == .ivory ? 0.9 : 0.32 }

    var primary: Color {
        self == .ivory ? Color(hex: 0x231B14) : Color(hex: 0xF5F2EA)
    }

    var secondary: Color { primary.opacity(0.68) }

    /// Gold leaf on the dark themes, oxblood ink on paper.
    var accent: Color {
        switch self {
        case .midnight: return Color(hex: 0xE2C58C)
        case .ivory: return Color(hex: 0x8C2F2B)
        case .forest: return Color(hex: 0xD9C892)
        case .graphite: return Color(hex: 0xA9C4FF)
        }
    }

    var isDark: Bool { self != .ivory }

    var gradient: LinearGradient {
        LinearGradient(colors: baseColors, startPoint: .top, endPoint: .bottom)
    }

    /// The theme chosen in the app; the widget reads it from the App Group.
    static var saved: Theme {
        get { AppSettings.defaults.string(forKey: SettingsKey.theme).flatMap(Theme.init) ?? .midnight }
        set { AppSettings.defaults.set(newValue.rawValue, forKey: SettingsKey.theme) }
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255)
    }
}
