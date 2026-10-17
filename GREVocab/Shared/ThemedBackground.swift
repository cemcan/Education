import SwiftUI

/// Layered background: base gradient, a soft corner light, an oversized serif
/// monogram of the word's first letter, a gentle vignette and fine paper grain.
/// Everything is drawn in code, so it renders identically in the app, in widgets
/// and in the exported wallpaper at any size.
struct ThemedBackground: View {
    let theme: Theme
    /// Letter drawn as a faint watermark; nil for none.
    var monogram: String? = nil
    /// Paper grain. Cheap, but skip it in very small surfaces.
    var grain: Bool = true

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let longSide = max(size.width, size.height)

            ZStack {
                theme.gradient

                RadialGradient(colors: [theme.glow.opacity(theme.glowOpacity), .clear],
                               center: UnitPoint(x: 0.88, y: 0.04),
                               startRadius: 0,
                               endRadius: longSide * 0.75)

                // A second, cooler light low on the opposite side gives depth.
                RadialGradient(colors: [theme.accent.opacity(theme.isDark ? 0.10 : 0.07), .clear],
                               center: UnitPoint(x: 0.0, y: 1.0),
                               startRadius: 0,
                               endRadius: longSide * 0.6)

                if let letter = monogram?.prefix(1).uppercased() {
                    Text(letter)
                        .font(.system(size: size.width * 1.15, weight: .regular, design: .serif))
                        .foregroundStyle(theme.primary.opacity(theme.isDark ? 0.045 : 0.06))
                        .fixedSize()
                        .position(x: size.width * 0.80, y: size.height * 0.52)
                        .accessibilityHidden(true)
                }

                if grain {
                    PaperGrain(dark: theme.isDark)
                }

                // Vignette pulls the eye to the centre.
                RadialGradient(colors: [.clear, .black.opacity(theme.isDark ? 0.35 : 0.10)],
                               center: .center,
                               startRadius: longSide * 0.35,
                               endRadius: longSide * 0.85)
            }
            .frame(width: size.width, height: size.height)
            .clipped()
        }
        .ignoresSafeArea()
    }
}

/// Deterministic speckle so the texture is identical on every render.
private struct PaperGrain: View {
    let dark: Bool

    var body: some View {
        Canvas { context, size in
            var rng = GrainRNG(seed: 0xC0FFEE)
            let count = Int(size.width * size.height / 90)
            let light = Color.white.opacity(dark ? 0.035 : 0.25)
            let shade = Color.black.opacity(dark ? 0.08 : 0.035)
            for _ in 0..<min(count, 40_000) {
                let x = rng.unit() * size.width
                let y = rng.unit() * size.height
                let d = 0.6 + rng.unit() * 0.9
                let rect = CGRect(x: x, y: y, width: d, height: d)
                context.fill(Path(ellipseIn: rect), with: .color(rng.unit() < 0.5 ? light : shade))
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct GrainRNG {
    var state: UInt64
    init(seed: UInt64) { state = seed }

    mutating func unit() -> CGFloat {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return CGFloat(state >> 40) / CGFloat(1 << 24)
    }
}

/// Small-caps style label used above headwords: "ADJECTIVE · GRE".
struct EyebrowText: View {
    let text: String
    let color: Color
    var size: CGFloat = 11

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: size, weight: .semibold))
            .tracking(size * 0.18)
            .foregroundStyle(color)
    }
}

/// A short accent rule, like the line under a chapter title.
struct AccentRule: View {
    let color: Color
    var width: CGFloat = 28
    var height: CGFloat = 1.5

    var body: some View {
        Capsule().fill(color).frame(width: width, height: height)
    }
}

#Preview {
    ZStack(alignment: .bottomLeading) {
        ThemedBackground(theme: .midnight, monogram: "laconic")
        Text("laconic").font(.system(size: 48, design: .serif)).foregroundStyle(.white).padding(32)
    }
}
