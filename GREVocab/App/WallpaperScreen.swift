import SwiftUI
import UIKit

struct WallpaperScreen: View {
    @EnvironmentObject private var state: AppState
    @AppStorage(SettingsKey.wallpaperTheme, store: AppSettings.defaults) private var theme: WallpaperTheme = .midnight

    @State private var image: UIImage?
    @State private var statusMessage: String?
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    themePicker
                    preview
                    actions
                    if let statusMessage {
                        Text(statusMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    ShortcutGuide()
                }
                .padding()
            }
            .navigationTitle("Wallpaper")
            .task(id: renderKey) { await rerender() }
        }
    }

    /// Re-render whenever the theme or the current word changes.
    private var renderKey: String { "\(theme.rawValue)-\(state.currentWord?.id ?? "")" }

    private var themePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(WallpaperTheme.allCases) { option in
                    Button {
                        theme = option
                    } label: {
                        VStack(spacing: 6) {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(option.gradient)
                                .frame(width: 54, height: 80)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(option == theme ? Color.accentColor : .clear, lineWidth: 3)
                                )
                            Text(option.title).font(.caption)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(option == theme ? .isSelected : [])
                }
            }
            .padding(.horizontal, 4)
        }
    }

    private var preview: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                RoundedRectangle(cornerRadius: 24)
                    .fill(.secondary.opacity(0.15))
                    .aspectRatio(9.0 / 19.5, contentMode: .fit)
                    .overlay(ProgressView())
            }
        }
        .frame(maxHeight: 460)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(radius: 8, y: 4)
    }

    private var actions: some View {
        HStack(spacing: 12) {
            Button {
                Task { await save() }
            } label: {
                Label("Save to Photos", systemImage: "square.and.arrow.down")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(image == nil || isSaving)

            if let image {
                let shareImage = Image(uiImage: image)
                ShareLink(item: shareImage,
                          preview: SharePreview(state.currentWord?.word ?? "Wallpaper", image: shareImage)) {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .controlSize(.large)
    }

    private func rerender() async {
        guard let word = state.currentWord else { return }
        let selected = theme
        let rendered = await MainActor.run { WallpaperRenderer.render(word: word, theme: selected) }
        image = rendered
    }

    private func save() async {
        guard let image else { return }
        isSaving = true
        defer { isSaving = false }
        do {
            try await WallpaperRenderer.saveToPhotos(image)
            statusMessage = "Saved. Open Photos, tap Share › Use as Wallpaper — or automate it with the steps below."
        } catch {
            statusMessage = error.localizedDescription
        }
    }
}

/// Step-by-step instructions for the Shortcuts automation that sets the wallpaper.
private struct ShortcutGuide: View {
    @Environment(\.openURL) private var openURL

    private let steps: [(String, String)] = [
        ("clock", "Open the Shortcuts app › Automation › New Automation › Time of Day. Pick a time (e.g. 7:00 AM), Daily, and choose “Run Immediately”."),
        ("text.book.closed", "Add the action “Get Vocabulary Wallpaper” (search for GRE Vocab). Optionally tap Theme to choose one."),
        ("photo.on.rectangle", "Add “Set Wallpaper Photo” (called “Set Wallpaper” on older iOS). Choose Lock Screen and pass in the image from the previous step."),
        ("eye.slash", "Expand “Set Wallpaper Photo” and turn OFF “Show Preview” (and “Crop to Subject”), so it runs without asking."),
        ("repeat", "Rotating more than once a day? Add one automation per change time, matching the interval in Settings."),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Change your wallpaper automatically", systemImage: "wand.and.stars")
                .font(.headline)

            Text("iOS doesn’t let apps set the wallpaper themselves, but a one-time Shortcuts automation can do it for you every day.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: 12) {
                    Text("\(index + 1)")
                        .font(.subheadline.bold())
                        .frame(width: 26, height: 26)
                        .background(Color.accentColor.opacity(0.15), in: Circle())
                    VStack(alignment: .leading, spacing: 2) {
                        Image(systemName: step.0).foregroundStyle(.tint)
                        Text(step.1)
                            .font(.subheadline)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            Button {
                if let url = URL(string: "shortcuts://") { openURL(url) }
            } label: {
                Label("Open Shortcuts", systemImage: "arrow.up.forward.app")
            }
            .buttonStyle(.bordered)

            Text("Tip: also add the GRE Vocab widget to your Lock Screen (long-press the Lock Screen › Customize › Add Widgets) — it updates on its own.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
    }
}
