import AVFoundation
import SwiftUI
import WidgetKit

struct SettingsView: View {
    @EnvironmentObject private var state: AppState

    @AppStorage(SettingsKey.interval, store: AppSettings.defaults) private var interval: RotationInterval = .daily
    @AppStorage(SettingsKey.accent, store: AppSettings.defaults) private var accent: VoiceAccent = .american
    @AppStorage(SettingsKey.speechRate, store: AppSettings.defaults) private var speechRate: Double = 1.0
    @AppStorage(SettingsKey.voiceIdentifier, store: AppSettings.defaults) private var voiceIdentifier = ""
    @AppStorage(SettingsKey.useIPA, store: AppSettings.defaults) private var useIPA = true
    @AppStorage(SettingsKey.theme, store: AppSettings.defaults) private var theme: Theme = .midnight

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

                Section {
                    Picker("Theme", selection: $theme) {
                        ForEach(Theme.allCases) { Text($0.title).tag($0) }
                    }
                } header: {
                    Text("Appearance")
                } footer: {
                    Text("Used by the word card, the widgets and the wallpaper.")
                }

                Section {
                    Picker("Accent", selection: $accent) {
                        ForEach(VoiceAccent.allCases) { Text($0.title).tag($0) }
                    }
                    Picker("Voice", selection: $voiceIdentifier) {
                        Text("Best available").tag("")
                        ForEach(PronunciationService.availableVoices(for: accent), id: \.identifier) { voice in
                            Text("\(voice.name) · \(voice.quality.label)").tag(voice.identifier)
                        }
                    }
                    VStack(alignment: .leading) {
                        Text("Speed")
                        Slider(value: $speechRate, in: 0.6...1.4, step: 0.05) {
                            Text("Speed")
                        } minimumValueLabel: {
                            Image(systemName: "tortoise")
                        } maximumValueLabel: {
                            Image(systemName: "hare")
                        }
                    }
                    Toggle("Dictionary pronunciation (IPA)", isOn: $useIPA)
                    Button {
                        if let word = state.currentWord {
                            PronunciationService.shared.speak(word: word.word, ipa: word.ipa)
                        }
                    } label: {
                        Label("Test voice", systemImage: "speaker.wave.2")
                    }
                } header: {
                    Text("Pronunciation")
                } footer: {
                    Text(PronunciationService.hasOnlyBasicVoices
                         ? "For a natural, human-sounding voice, download one free: iPhone Settings › Accessibility › Spoken Content › Voices › English, then pick a voice marked Premium or Enhanced (e.g. Ava, Zoe or Evan). It appears here once downloaded."
                         : "Premium and Enhanced voices sound the most natural. Download more in iPhone Settings › Accessibility › Spoken Content › Voices › English.")
                }
                .onChange(of: accent) { _, _ in voiceIdentifier = "" }

                Section {
                    LabeledContent("Words", value: "\(state.repository.words.count)")
                    LabeledContent("Favorites", value: "\(state.favorites.count)")
                } header: {
                    Text("Library")
                }

                Section {
                    Text("Example sentences are quoted verbatim from real texts: news from BBC News (2004–05), Reuters (1987) and the Australian Broadcasting Corporation; public-domain literature (via Project Gutenberg); and U.S. presidential inaugural and State of the Union addresses. Each example shows its source.")
                    Text("Definitions, synonyms and word histories are written for GRE study. Pronunciation uses Apple’s on-device voices and follows each word’s IPA transcription, so it works offline.")
                } header: {
                    Text("About & credits")
                }
                .font(.footnote)
            }
            .navigationTitle("Settings")
            .onChange(of: interval) { _, _ in state.rotationSettingsChanged() }
            .onChange(of: theme) { _, _ in WidgetCenter.shared.reloadAllTimelines() }
        }
    }
}
