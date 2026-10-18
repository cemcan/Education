import AppIntents
import UniformTypeIdentifiers

/// Shortcuts action: returns today's word as a wallpaper image, ready for "Set Wallpaper Photo".
struct GetWordWallpaperIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Vocabulary Wallpaper"
    static var description = IntentDescription(
        "Creates a Lock Screen wallpaper image for the current word. Pass it to “Set Wallpaper Photo”."
    )

    @Parameter(title: "Theme")
    var theme: Theme?

    static var parameterSummary: some ParameterSummary {
        Summary("Get vocabulary wallpaper in \(\.$theme)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<IntentFile> {
        guard let word = WordRotation.currentWord() else {
            throw WallpaperIntentError.noWords
        }
        guard let image = WallpaperRenderer.render(word: word, theme: theme ?? .saved),
              let data = image.pngData() else {
            throw WallpaperIntentError.renderFailed
        }
        let file = IntentFile(data: data, filename: "gre-\(word.id).png", type: .png)
        return .result(value: file)
    }
}

enum WallpaperIntentError: Error, CustomLocalizedStringResourceConvertible {
    case noWords, renderFailed

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .noWords: return "No vocabulary words are available."
        case .renderFailed: return "The wallpaper image could not be created."
        }
    }
}

struct VocabShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: GetWordWallpaperIntent(),
            phrases: ["Get \(.applicationName) wallpaper", "Make a \(.applicationName) wallpaper"],
            shortTitle: "Vocabulary Wallpaper",
            systemImageName: "photo"
        )
        AppShortcut(
            intent: NextWordIntent(),
            phrases: ["Next word in \(.applicationName)", "Skip \(.applicationName) word"],
            shortTitle: "Next Word",
            systemImageName: "arrow.forward.circle"
        )
    }
}
