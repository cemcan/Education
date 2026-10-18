import AppIntents
import WidgetKit

/// Skips to the next word. Compiled into both the app and the widget so the
/// widget's interactive button can run it in place (iOS 17+).
struct NextWordIntent: AppIntent {
    static var title: LocalizedStringResource = "Next Vocabulary Word"
    static var description = IntentDescription("Skips ahead to the next vocabulary word.")

    func perform() async throws -> some IntentResult {
        AppSettings.skipOffset += 1
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
