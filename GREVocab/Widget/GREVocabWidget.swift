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
    var theme: Theme = .midnight
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
        VocabEntry(date: date, word: WordRotation.currentWord(at: date) ?? .preview, theme: .saved)
    }
}

// MARK: - Views

struct VocabWidgetView: View {
    let entry: VocabEntry
    @Environment(\.widgetFamily) private var family
    @Environment(\.widgetRenderingMode) private var renderingMode

    private var word: VocabWord { entry.word }
    private var theme: Theme { entry.theme }
    /// In tinted/vibrant modes iOS recolours everything, so keep the background plain.
    private var isFullColor: Bool { renderingMode == .fullColor }

    var body: some View {
        content
            .widgetURL(word.deepLink)
            .containerBackground(for: .widget) {
                if isAccessory || !isFullColor {
                    Color.clear
                } else {
                    ThemedBackground(theme: theme, monogram: word.word, grain: family != .systemSmall)
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

    // MARK: Lock Screen

    private var circular: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 1) {
                Text(String(word.word.prefix(1)).uppercased())
                    .font(.system(size: 20, weight: .semibold, design: .serif))
                    .widgetAccentable()
                Text(word.word)
                    .font(.system(size: 9, weight: .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .padding(.horizontal, 4)
            }
        }
    }

    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 1) {
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text(word.word)
                    .font(.system(.headline, design: .serif))
                    .widgetAccentable()
                Text(abbreviatedPOS)
                    .font(.caption2.italic())
                    .foregroundStyle(.secondary)
            }
            .lineLimit(1)
            Text(word.definition)
                .font(.caption)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Home Screen

    private var small: some View {
        VStack(alignment: .leading, spacing: 0) {
            topBar(compact: true)
            Spacer(minLength: 4)
            headword(size: 26)
            AccentRule(color: accent, width: 20)
                .padding(.vertical, 6)
            Text(word.definition)
                .font(.system(size: 12, design: .serif))
                .foregroundStyle(primary.opacity(0.9))
                .lineLimit(3)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var medium: some View {
        VStack(alignment: .leading, spacing: 0) {
            topBar(compact: false)
            Spacer(minLength: 4)
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                headword(size: 30)
                Text(word.ipa)
                    .font(.system(size: 13, design: .serif))
                    .foregroundStyle(secondary)
                    .lineLimit(1)
            }
            AccentRule(color: accent, width: 24)
                .padding(.vertical, 7)
            Text(word.definition)
                .font(.system(size: 14, design: .serif))
                .foregroundStyle(primary.opacity(0.92))
                .lineLimit(2)
            synonymsLine.padding(.top, 6)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var large: some View {
        VStack(alignment: .leading, spacing: 0) {
            topBar(compact: false)
            headword(size: 40).padding(.top, 14)
            Text([word.ipa, word.phonetic].filter { !$0.isEmpty }.joined(separator: "   "))
                .font(.system(size: 13, design: .serif))
                .foregroundStyle(secondary)
                .lineLimit(1)
            AccentRule(color: accent, width: 28)
                .padding(.vertical, 12)
            Text(word.definition)
                .font(.system(size: 16, design: .serif))
                .foregroundStyle(primary.opacity(0.94))
                .lineLimit(3)
            synonymsLine.padding(.top, 8)
            Spacer(minLength: 10)
            if let example = word.examples.first {
                VStack(alignment: .leading, spacing: 5) {
                    Text(example.quoted)
                        .font(.system(size: 13, design: .serif).italic())
                        .foregroundStyle(primary.opacity(0.85))
                        .lineLimit(4)
                    Text("— " + example.plainAttribution)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(secondary)
                        .lineLimit(1)
                }
                .padding(.leading, 10)
                .overlay(alignment: .leading) {
                    Rectangle().fill(accent.opacity(0.75)).frame(width: 1.5)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func topBar(compact: Bool) -> some View {
        HStack(alignment: .center) {
            EyebrowText(text: compact ? abbreviatedPOS : "\(word.partOfSpeech)  ·  GRE",
                        color: accent, size: compact ? 9 : 10)
                .lineLimit(1)
            Spacer(minLength: 4)
            Button(intent: NextWordIntent()) {
                Image(systemName: "arrow.forward")
                    .font(.system(size: compact ? 10 : 11, weight: .semibold))
                    .foregroundStyle(primary.opacity(0.85))
                    .frame(width: compact ? 22 : 26, height: compact ? 22 : 26)
                    .background(primary.opacity(0.12), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Next word")
        }
    }

    private func headword(size: CGFloat) -> some View {
        Text(word.word)
            .font(.system(size: size, weight: .semibold, design: .serif))
            .foregroundStyle(primary)
            .lineLimit(1)
            .minimumScaleFactor(0.55)
            .widgetAccentable()
    }

    @ViewBuilder
    private var synonymsLine: some View {
        if !word.synonyms.isEmpty {
            Text(word.synonyms.prefix(3).joined(separator: "  ·  "))
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(accent)
                .lineLimit(1)
        }
    }

    // Colours fall back to the system's when iOS tints the widget.
    private var primary: Color { isFullColor ? theme.primary : .primary }
    private var secondary: Color { isFullColor ? theme.secondary : .secondary }
    private var accent: Color { isFullColor ? theme.accent : .primary }

    private var abbreviatedPOS: String {
        switch word.partOfSpeech.lowercased() {
        case "adjective": return "adj."
        case "noun": return "noun"
        case "verb": return "verb"
        case "adverb": return "adv."
        default: return word.partOfSpeech
        }
    }
}

#Preview(as: .systemMedium) {
    VocabWidget()
} timeline: {
    VocabEntry(date: .now, word: .preview)
    VocabEntry(date: .now, word: .preview, theme: .ivory)
}

#Preview(as: .accessoryRectangular) {
    VocabWidget()
} timeline: {
    VocabEntry(date: .now, word: .preview)
}
