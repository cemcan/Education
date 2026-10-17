import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var state: AppState

    @AppStorage(SettingsKey.interval, store: AppSettings.defaults) private var interval: RotationInterval = .daily
    @AppStorage(SettingsKey.accent, store: AppSettings.defaults) private var accent: VoiceAccent = .american
    @AppStorage(SettingsKey.speechRate, store: AppSettings.defaults) private var speechRate: Double = 0.9

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("New word", selection: $interval) {
                        ForEach(RotationInterval.allCases) { Text($0.title).tag($0) }
                    }
                } header: {
                    Text("Rotation")
                } footer: {
                    Text("The app, widgets and wallpaper all show the same word and change on this schedule.")
                }

                Section("Pronunciation") {
                    Picker("Accent", selection: $accent) {
                        ForEach(VoiceAccent.allCases) { Text($0.title).tag($0) }
                    }
                    VStack(alignment: .leading) {
                        Text("Speed")
                        Slider(value: $speechRate, in: 0.5...1.5, step: 0.05) {
                            Text("Speed")
                        } minimumValueLabel: {
                            Image(systemName: "tortoise")
                        } maximumValueLabel: {
                            Image(systemName: "hare")
                        }
                    }
                    Button {
                        PronunciationService.shared.speak(state.currentWord?.word ?? "laconic")
                    } label: {
                        Label("Test voice", systemImage: "speaker.wave.2")
                    }
                }

                Section {
                    LabeledContent("Words", value: "\(state.repository.words.count)")
                    LabeledContent("Favorites", value: "\(state.favorites.count)")
                } header: {
                    Text("Library")
                }

                Section {
                    Text("Example sentences are quoted verbatim from real texts: public-domain literature (via Project Gutenberg), the Reuters-21578 newswire collection (1987), and U.S. presidential inaugural and State of the Union addresses. Each example shows its source.")
                    Text("Definitions, synonyms and word histories are written for GRE study. Pronunciation uses Apple’s on-device voices, so it works offline.")
                } header: {
                    Text("About & credits")
                }
                .font(.footnote)
            }
            .navigationTitle("Settings")
            .onChange(of: interval) { _, _ in state.rotationSettingsChanged() }
        }
    }
}
