import AppIntents
import SwiftUI

enum WallpaperTheme: String, CaseIterable, Identifiable, AppEnum {
    case midnight, parchment, ocean, sunset

    var id: String { rawValue }

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Wallpaper Theme"

    static var caseDisplayRepresentations: [WallpaperTheme: DisplayRepresentation] = [
        .midnight: "Midnight",
        .parchment: "Parchment",
        .ocean: "Ocean",
        .sunset: "Sunset",
    ]

    var title: String {
        switch self {
        case .midnight: return "Midnight"
        case .parchment: return "Parchment"
        case .ocean: return "Ocean"
        case .sunset: return "Sunset"
        }
    }

    var gradient: LinearGradient {
        let colors: [Color]
        switch self {
        case .midnight:
            colors = [Color(red: 0.05, green: 0.06, blue: 0.14), Color(red: 0.16, green: 0.13, blue: 0.32)]
        case .parchment:
            colors = [Color(red: 0.97, green: 0.94, blue: 0.86), Color(red: 0.89, green: 0.82, blue: 0.68)]
        case .ocean:
            colors = [Color(red: 0.02, green: 0.20, blue: 0.33), Color(red: 0.05, green: 0.47, blue: 0.55)]
        case .sunset:
            colors = [Color(red: 0.42, green: 0.13, blue: 0.33), Color(red: 0.95, green: 0.48, blue: 0.33)]
        }
        return LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
    }

    var primary: Color {
        self == .parchment ? Color(red: 0.20, green: 0.14, blue: 0.08) : .white
    }

    var secondary: Color {
        primary.opacity(0.75)
    }

    var accent: Color {
        switch self {
        case .midnight: return Color(red: 0.62, green: 0.70, blue: 1.0)
        case .parchment: return Color(red: 0.55, green: 0.27, blue: 0.10)
        case .ocean: return Color(red: 0.55, green: 0.95, blue: 0.88)
        case .sunset: return Color(red: 1.0, green: 0.86, blue: 0.55)
        }
    }

    static var saved: WallpaperTheme {
        AppSettings.defaults.string(forKey: SettingsKey.wallpaperTheme).flatMap(WallpaperTheme.init) ?? .midnight
    }
}
