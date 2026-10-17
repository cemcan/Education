import SwiftUI

/// The Lock Screen wallpaper. `size` is in points; the top ~36% stays clear for the clock
/// and the bottom ~14% for the flashlight/camera buttons.
struct WallpaperView: View {
    let word: VocabWord
    let theme: WallpaperTheme
    let size: CGSize

    private var unit: CGFloat { size.width / 390 }

    var body: some View {
        ZStack(alignment: .topLeading) {
            theme.gradient

            VStack(alignment: .leading, spacing: 14 * unit) {
                HStack(alignment: .firstTextBaseline, spacing: 10 * unit) {
                    Text(word.partOfSpeech.uppercased())
                        .font(.system(size: 13 * unit, weight: .semibold))
                        .tracking(1.5)
                        .foregroundStyle(theme.accent)
                    Spacer()
                    Text("GRE")
                        .font(.system(size: 11 * unit, weight: .bold))
                        .tracking(2)
                        .foregroundStyle(theme.secondary)
                }

                VStack(alignment: .leading, spacing: 4 * unit) {
                    Text(word.word)
                        .font(.system(size: 50 * unit, weight: .bold, design: .serif))
                        .foregroundStyle(theme.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    Text([word.ipa, word.phonetic].filter { !$0.isEmpty }.joined(separator: "  ·  "))
                        .font(.system(size: 16 * unit, design: .monospaced))
                        .foregroundStyle(theme.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }

                Text(word.definition)
                    .font(.system(size: 19 * unit, weight: .regular, design: .serif))
                    .foregroundStyle(theme.primary)
                    .lineLimit(4)
                    .minimumScaleFactor(0.8)
                    .fixedSize(horizontal: false, vertical: true)

                if !word.synonyms.isEmpty {
                    Text("≈ " + word.synonyms.prefix(3).joined(separator: ", "))
                        .font(.system(size: 15 * unit, weight: .medium))
                        .foregroundStyle(theme.accent)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }

                if let example = word.examples.first {
                    VStack(alignment: .leading, spacing: 6 * unit) {
                        Text(example.quoted)
                            .font(.system(size: 14 * unit, design: .serif).italic())
                            .foregroundStyle(theme.primary.opacity(0.9))
                            .lineLimit(5)
                            .minimumScaleFactor(0.75)
                        Text("— " + example.plainAttribution)
                            .font(.system(size: 11 * unit))
                            .foregroundStyle(theme.secondary)
                            .lineLimit(2)
                    }
                    .padding(.leading, 12 * unit)
                    .overlay(alignment: .leading) {
                        Rectangle().fill(theme.accent.opacity(0.7)).frame(width: 2 * unit)
                    }
                    .padding(.top, 6 * unit)
                }
            }
            .padding(.horizontal, 32 * unit)
            .frame(width: size.width, height: size.height * 0.50, alignment: .topLeading)
            .offset(y: size.height * 0.36)
        }
        .frame(width: size.width, height: size.height)
        .clipped()
    }
}

#Preview {
    WallpaperView(word: .preview, theme: .midnight, size: CGSize(width: 393, height: 852))
}
