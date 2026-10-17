import SwiftUI
import WidgetKit

@main
struct GREVocabApp: App {
    @StateObject private var state = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(state)
                .onOpenURL { state.handle(url: $0) }
        }
    }
}

enum AppTab: Hashable {
    case today, browse, wallpaper, settings
}

/// App-wide state. Persistent values live in the App Group so the widget sees them too.
final class AppState: ObservableObject {
    @Published var selectedTab: AppTab = .today
    @Published var deepLinkedWord: VocabWord?
    @Published private(set) var currentWord: VocabWord?
    @Published private(set) var favorites: Set<String>

    let repository = WordRepository.shared

    init() {
        favorites = AppSettings.favorites
        currentWord = WordRotation.currentWord()
    }

    /// Re-reads shared state, e.g. after the widget's "next" button changed the offset.
    func refresh() {
        favorites = AppSettings.favorites
        currentWord = WordRotation.currentWord()
    }

    func nextWord() {
        AppSettings.skipOffset += 1
        WidgetCenter.shared.reloadAllTimelines()
        refresh()
    }

    func rotationSettingsChanged() {
        WidgetCenter.shared.reloadAllTimelines()
        refresh()
    }

    func isFavorite(_ word: VocabWord) -> Bool { favorites.contains(word.id) }

    func toggleFavorite(_ word: VocabWord) {
        if favorites.contains(word.id) {
            favorites.remove(word.id)
        } else {
            favorites.insert(word.id)
        }
        AppSettings.favorites = favorites
    }

    /// Handles grevocab://word/<id>
    func handle(url: URL) {
        guard url.scheme == "grevocab", url.host == "word" else { return }
        let id = url.pathComponents.dropFirst().first?.removingPercentEncoding ?? ""
        guard let word = repository.word(id: id) else { return }
        refresh()
        if word.id == currentWord?.id {
            selectedTab = .today
        } else {
            deepLinkedWord = word
        }
    }
}
