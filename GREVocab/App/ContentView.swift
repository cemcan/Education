import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var state: AppState
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TabView(selection: $state.selectedTab) {
            TodayView()
                .tabItem { Label("Today", systemImage: "text.book.closed") }
                .tag(AppTab.today)

            BrowseView()
                .tabItem { Label("Browse", systemImage: "list.bullet") }
                .tag(AppTab.browse)

            WallpaperScreen()
                .tabItem { Label("Wallpaper", systemImage: "iphone") }
                .tag(AppTab.wallpaper)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(AppTab.settings)
        }
        .sheet(item: $state.deepLinkedWord) { word in
            NavigationStack {
                WordDetailView(word: word)
                    .navigationDestination(for: VocabWord.self) { WordDetailView(word: $0) }
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { state.deepLinkedWord = nil }
                        }
                    }
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { state.refresh() }
        }
    }
}

#Preview {
    ContentView().environmentObject(AppState())
}
