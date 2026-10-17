import Foundation

enum RotationInterval: String, CaseIterable, Identifiable, Codable {
    case hourly, every3Hours, every6Hours, every12Hours, daily

    var id: String { rawValue }

    var seconds: TimeInterval {
        switch self {
        case .hourly: return 3_600
        case .every3Hours: return 3 * 3_600
        case .every6Hours: return 6 * 3_600
        case .every12Hours: return 12 * 3_600
        case .daily: return 24 * 3_600
        }
    }

    var title: String {
        switch self {
        case .hourly: return "Every hour"
        case .every3Hours: return "Every 3 hours"
        case .every6Hours: return "Every 6 hours"
        case .every12Hours: return "Every 12 hours"
        case .daily: return "Once a day"
        }
    }
}

enum VoiceAccent: String, CaseIterable, Identifiable {
    case american = "en-US"
    case british = "en-GB"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .american: return "American"
        case .british: return "British"
        }
    }
}

enum SettingsKey {
    static let interval = "rotationInterval"
    static let skipOffset = "skipOffset"
    static let favorites = "favoriteIDs"
    static let accent = "voiceAccent"
    static let speechRate = "speechRate"
    static let wallpaperTheme = "wallpaperTheme"
}

/// Settings shared between the app and the widget through the App Group container.
enum AppSettings {
    static let appGroup = "group.com.example.grevocab"

    static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroup) ?? .standard
    }

    static var interval: RotationInterval {
        get { defaults.string(forKey: SettingsKey.interval).flatMap(RotationInterval.init) ?? .daily }
        set { defaults.set(newValue.rawValue, forKey: SettingsKey.interval) }
    }

    /// Added to the rotation slot so "Next word" can skip ahead without breaking the schedule.
    static var skipOffset: Int {
        get { defaults.integer(forKey: SettingsKey.skipOffset) }
        set { defaults.set(newValue, forKey: SettingsKey.skipOffset) }
    }

    static var favorites: Set<String> {
        get { Set(defaults.stringArray(forKey: SettingsKey.favorites) ?? []) }
        set { defaults.set(Array(newValue).sorted(), forKey: SettingsKey.favorites) }
    }

    static var accent: VoiceAccent {
        get { defaults.string(forKey: SettingsKey.accent).flatMap(VoiceAccent.init) ?? .american }
        set { defaults.set(newValue.rawValue, forKey: SettingsKey.accent) }
    }

    /// Multiplier applied to the system default speech rate (0.5 – 1.5).
    static var speechRate: Double {
        get {
            let value = defaults.double(forKey: SettingsKey.speechRate)
            return value == 0 ? 0.9 : value
        }
        set { defaults.set(newValue, forKey: SettingsKey.speechRate) }
    }
}
