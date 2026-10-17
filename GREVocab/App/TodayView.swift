import SwiftUI

struct TodayView: View {
    @EnvironmentObject private var state: AppState

    var body: some View {
        NavigationStack {
            Group {
                if let word = state.currentWord {
                    ScrollView {
                        WordCardView(word: word)
                            .padding()
                            .padding(.bottom, 60)
                    }
                    .safeAreaInset(edge: .bottom) {
                        Button {
                            withAnimation { state.nextWord() }
                        } label: {
                            Label("Next word", systemImage: "arrow.forward")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                    }
                } else {
                    ContentUnavailableView("No words available",
                                           systemImage: "text.book.closed",
                                           description: Text("The bundled word list could not be loaded."))
                }
            }
            .navigationTitle("Today")
            .navigationDestination(for: VocabWord.self) { WordDetailView(word: $0) }
        }
    }
}

/// A single word on its own screen (Browse, deep links, linked synonyms).
/// The enclosing NavigationStack provides the `VocabWord` destination.
struct WordDetailView: View {
    let word: VocabWord

    var body: some View {
        ScrollView {
            WordCardView(word: word).padding()
        }
        .navigationTitle(word.word)
        .navigationBarTitleDisplayMode(.inline)
    }
}
