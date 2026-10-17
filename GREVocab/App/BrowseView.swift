import SwiftUI

struct BrowseView: View {
    @EnvironmentObject private var state: AppState
    @State private var query = ""
    @State private var favoritesOnly = false

    private var filtered: [VocabWord] {
        state.repository.words.filter { word in
            if favoritesOnly && !state.isFavorite(word) { return false }
            guard !query.isEmpty else { return true }
            return word.word.localizedCaseInsensitiveContains(query)
                || word.definition.localizedCaseInsensitiveContains(query)
                || word.synonyms.contains { $0.localizedCaseInsensitiveContains(query) }
        }
    }

    var body: some View {
        NavigationStack {
            List(filtered) { word in
                NavigationLink(value: word) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(word.word).font(.headline)
                            Text(word.partOfSpeech).font(.caption).foregroundStyle(.secondary)
                            Spacer()
                            if state.isFavorite(word) {
                                Image(systemName: "star.fill").foregroundStyle(.yellow).font(.caption)
                            }
                        }
                        Text(word.definition)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    .padding(.vertical, 2)
                }
            }
            .listStyle(.plain)
            .overlay {
                if filtered.isEmpty {
                    if favoritesOnly && query.isEmpty {
                        ContentUnavailableView("No favorites yet",
                                               systemImage: "star",
                                               description: Text("Tap the star on a word to save it here."))
                    } else {
                        ContentUnavailableView.search(text: query)
                    }
                }
            }
            .searchable(text: $query, prompt: "Search words, meanings, synonyms")
            .navigationTitle("\(state.repository.words.count) Words")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        favoritesOnly.toggle()
                    } label: {
                        Image(systemName: favoritesOnly ? "star.fill" : "star")
                    }
                    .accessibilityLabel(favoritesOnly ? "Show all words" : "Show favorites only")
                }
            }
            .navigationDestination(for: VocabWord.self) { WordDetailView(word: $0) }
        }
    }
}
