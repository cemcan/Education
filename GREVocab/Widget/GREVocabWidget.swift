import AppIntents
import SwiftUI
import WidgetKit

@main
struct GREVocabWidgetBundle: WidgetBundle {
    var body: some Widget {
        VocabWidget()
    }
}

struct VocabWidget: Widget {
    let kind = "VocabWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: VocabProvider()) { entry in
            VocabWidgetView(entry: entry)
        }
        .configurationDisplayName("GRE Word")
        .description("A new GRE vocabulary word on your Lock Screen or Home Screen.")
        .supportedFamilies([
            .accessoryInline, .accessoryRectangular, .accessoryCircular,
            .systemSmall, .systemMedium, .systemLarge,
        ])
    }
}

// MARK: - Timeline

struct VocabEntry: TimelineEntry {
    let date: Date
    let word: VocabWord
}

struct VocabProvider: TimelineProvider {
    func placeholder(in context: Context) -> VocabEntry {
        VocabEntry(date: Date(), word: .preview)
    }

    func getSnapshot(in context: Context, completion: @escaping (VocabEntry) -> Void) {
        completion(entry(at: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<VocabEntry>) -> Void) {
        let now = Date()
        // One entry now, then one at each upcoming rotation boundary.
        var entries = [entry(at: now)]
        entries += WordRotation.upcomingBoundaries(after: now, count: 24).map { entry(at: $0) }
        completion(Timeline(entries: entries, policy: .atEnd))
    }

    private func entry(at date: Date) -> VocabEntry {
        VocabEntry(date: date, word: WordRotation.currentWord(at: date) ?? .preview)
    }
}

// MARK: - Views

struct VocabWidgetView: View {
    let entry: VocabEntry
    @Environment(\.widgetFamily) private var family

    private var word: VocabWord { entry.word }

    var body: some View {
        content
            .widgetURL(word.deepLink)
            .containerBackground(for: .widget) {
                if isAccessory {
                    Color.clear
                } else {
                    LinearGradient(colors: [Color(red: 0.07, green: 0.08, blue: 0.18),
                                            Color(red: 0.18, green: 0.15, blue: 0.36)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                }
            }
    }

    private var isAccessory: Bool {
        family == .accessoryInline || family == .accessoryRectangular || family == .accessoryCircular
    }

    @ViewBuilder
    private var content: some View {
        switch family {
        case .accessoryInline:
            Text("\(word.word) · \(word.synonyms.first ?? word.partOfSpeech)")
        case .accessoryCircular:
            circular
        case .accessoryRectangular:
            rectangular
        case .systemSmall:
            small
        case .systemLarge:
            large
        default:
            medium
        }
    }

    private var circular: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 0) {
                Text("GRE").font(.system(size: 9, weight: .bold))
                Text(word.word)
                    .font(.system(size: 13, weight: .semibold, design: .serif))
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)
                    .padding(.horizontal, 3)
            }
        }
    }

    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 1) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(word.word)
                    .font(.headline)
                    .widgetAccentable()
                Text(abbreviatedPOS)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .lineLimit(1)
            Text(word.definition)
                .font(.caption)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var small: some View {
        VStack(alignment: .leading, spacing: 6) {
            header(compact: true)
            Text(word.definition)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.9))
                .lineLimit(4)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var medium: some View {
        VStack(alignment: .leading, spacing: 6) {
            header(compact: false)
            Text(word.definition)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.92))
                .lineLimit(3)
            Spacer(minLength: 0)
            synonymsLine
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var large: some View {
        VStack(alignment: .leading, spacing: 10) {
            header(compact: false)
            Text(word.definition)
                .font(.body)
                .foregroundStyle(.white.opacity(0.92))
                .lineLimit(4)
            synonymsLine
            if let example = word.examples.first {
                VStack(alignment: .leading, spacing: 4) {
                    Text(example.quoted)
                        .font(.system(.callout, design: .serif).italic())
                        .foregroundStyle(.white.opacity(0.88))
                        .lineLimit(5)
                    Text("— " + example.plainAttribution)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.6))
                        .lineLimit(1)
                }
                .padding(.top, 4)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func header(compact: Bool) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(word.word)
                    .font(.system(compact ? .title3 : .title2, design: .serif).bold())
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text(compact ? abbreviatedPOS : [word.ipa, word.partOfSpeech].filter { !$0.isEmpty }.joined(separator: "  ·  "))
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.65))
                    .lineLimit(1)
            }
            Spacer(minLength: 4)
            Button(intent: NextWordIntent()) {
                Image(systemName: "arrow.forward.circle.fill")
                    .font(compact ? .body : .title3)
                    .foregroundStyle(.white.opacity(0.85))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Next word")
        }
    }

    @ViewBuilder
    private var synonymsLine: some View {
        if !word.synonyms.isEmpty {
            Text("≈ " + word.synonyms.prefix(3).joined(separator: ", "))
                .font(.caption.weight(.medium))
                .foregroundStyle(Color(red: 0.62, green: 0.70, blue: 1.0))
                .lineLimit(1)
        }
    }

    private var abbreviatedPOS: String {
        switch word.partOfSpeech.lowercased() {
        case "adjective": return "adj."
        case "noun": return "n."
        case "verb": return "v."
        case "adverb": return "adv."
        default: return word.partOfSpeech
        }
    }
}

#Preview(as: .systemMedium) {
    VocabWidget()
} timeline: {
    VocabEntry(date: .now, word: .preview)
}

#Preview(as: .accessoryRectangular) {
    VocabWidget()
} timeline: {
    VocabEntry(date: .now, word: .preview)
}
