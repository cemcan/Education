import SwiftUI

/// The Lock Screen wallpaper. `size` is in points; the top ~36% stays clear for the clock
/// and the bottom ~12% for the flashlight/camera buttons.
struct WallpaperView: View {
    let word: VocabWord
    let theme: Theme
    let size: CGSize

    private var unit: CGFloat { size.width / 390 }

    var body: some View {
        ZStack(alignment: .topLeading) {
            ThemedBackground(theme: theme, monogram: word.word)

            VStack(alignment: .leading, spacing: 0) {
                EyebrowText(text: "\(word.partOfSpeech)  ·  GRE", color: theme.accent, size: 12 * unit)

                Text(word.word)
                    .font(.system(size: 56 * unit, weight: .semibold, design: .serif))
                    .foregroundStyle(theme.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .padding(.top, 10 * unit)

                Text([word.ipa, word.phonetic].filter { !$0.isEmpty }.joined(separator: "   "))
                    .font(.system(size: 15 * unit, weight: .regular, design: .serif))
                    .foregroundStyle(theme.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .padding(.top, 2 * unit)

                AccentRule(color: theme.accent, width: 36 * unit, height: 1.5 * unit)
                    .padding(.vertical, 18 * unit)

                Text(word.definition)
                    .font(.system(size: 20 * unit, weight: .regular, design: .serif))
                    .lineSpacing(3 * unit)
                    .foregroundStyle(theme.primary)
                    .lineLimit(4)
                    .minimumScaleFactor(0.8)
                    .fixedSize(horizontal: false, vertical: true)

                if !word.synonyms.isEmpty {
                    HStack(spacing: 8 * unit) {
                        EyebrowText(text: "Syn.", color: theme.accent, size: 10 * unit)
                        Text(word.synonyms.prefix(3).joined(separator: "  ·  "))
                            .font(.system(size: 15 * unit, weight: .medium))
                            .foregroundStyle(theme.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .padding(.top, 14 * unit)
                }

                if let example = word.examples.first {
                    VStack(alignment: .leading, spacing: 8 * unit) {
                        Text(example.quoted)
                            .font(.system(size: 14.5 * unit, design: .serif).italic())
                            .lineSpacing(2 * unit)
                            .foregroundStyle(theme.primary.opacity(0.88))
                            .lineLimit(5)
                            .minimumScaleFactor(0.75)
                        Text("— " + example.plainAttribution)
                            .font(.system(size: 11 * unit, weight: .medium))
                            .foregroundStyle(theme.secondary)
                            .lineLimit(2)
                    }
                    .padding(.leading, 14 * unit)
                    .overlay(alignment: .leading) {
                        Rectangle().fill(theme.accent.opacity(0.75)).frame(width: 1.5 * unit)
                    }
                    .padding(.top, 26 * unit)
                }
            }
            .padding(.horizontal, 34 * unit)
            .frame(width: size.width, height: size.height * 0.52, alignment: .topLeading)
            .offset(y: size.height * 0.36)
        }
        .frame(width: size.width, height: size.height)
        .clipped()
    }
}

#Preview {
    WallpaperView(word: .preview, theme: .midnight, size: CGSize(width: 393, height: 852))
}
