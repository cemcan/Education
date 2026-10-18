import SwiftUI

/// The full study card for one word.
struct WordCardView: View {
    let word: VocabWord

    @EnvironmentObject private var state: AppState
    @ObservedObject private var speech = PronunciationService.shared
    @AppStorage(SettingsKey.theme, store: AppSettings.defaults) private var theme: Theme = .midnight

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            header

            CardSection(title: "Definition", systemImage: "text.quote") {
                Text(word.definition)
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
            }

            chipSection("Synonyms", systemImage: "equal.circle", words: word.synonyms, tint: .green)
            chipSection("Antonyms", systemImage: "arrow.left.arrow.right.circle", words: word.antonyms, tint: .red)
            chipSection("Related words", systemImage: "link.circle", words: word.relatedWords, tint: .blue)

            if let etymology = word.etymology, !etymology.isEmpty {
                CardSection(title: "Origin & history", systemImage: "scroll") {
                    Text(etymology)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if !word.examples.isEmpty {
                CardSection(title: "In the wild", systemImage: "quote.opening") {
                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(Array(word.examples.prefix(3).enumerated()), id: \.offset) { _, example in
                            ExampleRow(example: example)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Hero panel in the same style as the widget and wallpaper.
    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center) {
                if !word.partOfSpeech.isEmpty {
                    EyebrowText(text: word.partOfSpeech, color: theme.accent)
                }
                Spacer()
                Button {
                    state.toggleFavorite(word)
                } label: {
                    Image(systemName: state.isFavorite(word) ? "star.fill" : "star")
                        .font(.title3)
                        .foregroundStyle(theme.accent)
                }
                .accessibilityLabel(state.isFavorite(word) ? "Remove from favorites" : "Add to favorites")
            }

            Text(word.word)
                .font(.system(size: 46, weight: .semibold, design: .serif))
                .foregroundStyle(theme.primary)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .padding(.top, 18)

            HStack(spacing: 14) {
                Button {
                    speech.speak(word: word.word, ipa: word.ipa)
                } label: {
                    Image(systemName: speech.speakingText == word.word ? "speaker.wave.3.fill" : "speaker.wave.2.fill")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(theme.isDark ? Color.black.opacity(0.85) : .white)
                        .frame(width: 44, height: 44)
                        .background(theme.accent, in: Circle())
                }
                .accessibilityLabel("Pronounce \(word.word)")

                VStack(alignment: .leading, spacing: 2) {
                    if !word.ipa.isEmpty {
                        Text(word.ipa)
                            .font(.system(.title3, design: .serif))
                            .foregroundStyle(theme.primary)
                    }
                    if !word.phonetic.isEmpty {
                        Text(word.phonetic)
                            .font(.subheadline)
                            .foregroundStyle(theme.secondary)
                    }
                }
            }
            .padding(.top, 10)

            AccentRule(color: theme.accent, width: 32)
                .padding(.top, 18)
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            ThemedBackground(theme: theme, monogram: word.word)
        }
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(color: .black.opacity(0.18), radius: 14, y: 6)
    }

    @ViewBuilder
    private func chipSection(_ title: String, systemImage: String, words: [String], tint: Color) -> some View {
        if !words.isEmpty {
            CardSection(title: title, systemImage: systemImage) {
                FlowLayout(spacing: 8) {
                    ForEach(words, id: \.self) { item in
                        WordChip(text: item, tint: tint, linked: state.repository.entry(named: item))
                    }
                }
            }
        }
    }
}

private struct CardSection<Content: View>: View {
    let title: String
    let systemImage: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .foregroundStyle(.secondary)
            content
        }
    }
}

/// A synonym/antonym/related-word bubble. Becomes a link when the word is also in the list.
private struct WordChip: View {
    let text: String
    let tint: Color
    let linked: VocabWord?

    var body: some View {
        if let linked {
            NavigationLink(value: linked) { label(showsArrow: true) }
                .buttonStyle(.plain)
        } else {
            label(showsArrow: false)
        }
    }

    private func label(showsArrow: Bool) -> some View {
        HStack(spacing: 4) {
            Text(text)
            if showsArrow {
                Image(systemName: "chevron.right").font(.caption2.bold())
            }
        }
        .font(.subheadline)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(tint.opacity(0.14), in: Capsule())
        .foregroundStyle(tint)
    }
}

private struct ExampleRow: View {
    let example: VocabExample
    @ObservedObject private var speech = PronunciationService.shared

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button {
                speech.speak(example.text)
            } label: {
                Image(systemName: speech.speakingText == example.text ? "speaker.wave.3.fill" : "play.circle")
                    .font(.title3)
            }
            .accessibilityLabel("Read example aloud")

            VStack(alignment: .leading, spacing: 6) {
                Text(example.quoted)
                    .font(.system(.body, design: .serif))
                    .fixedSize(horizontal: false, vertical: true)

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    attribution
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Spacer(minLength: 4)
                    Label(example.kind.label, systemImage: example.kind.systemImage)
                        .font(.caption2.weight(.medium))
                        .labelStyle(.titleAndIcon)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.secondary.opacity(0.12), in: Capsule())
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
        .background(.secondary.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))
    }

    /// "— Author, *Source* (year)"
    private var attribution: Text {
        var text = Text("— ")
        if let author = example.author, !author.isEmpty {
            text = text + Text("\(author), ")
        }
        text = text + Text(example.source).italic()
        if let year = example.year {
            text = text + Text(" (\(String(year)))")
        }
        return text
    }
}

#Preview {
    NavigationStack {
        ScrollView { WordCardView(word: .preview).padding() }
    }
    .environmentObject(AppState())
}
