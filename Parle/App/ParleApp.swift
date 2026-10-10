import SwiftData
import SwiftUI

@main
struct ParleApp: App {
    @AppStorage("hasOnboarded") private var hasOnboarded = false

    var body: some Scene {
        WindowGroup {
            if hasOnboarded {
                RootView()
            } else {
                OnboardingView()
            }
        }
        .modelContainer(for: [Attempt.self, CustomPhrase.self])
    }
}

struct RootView: View {
    // "-startTab N" on launch opens a given tab (used for screenshots).
    @State private var tab = UserDefaults.standard.integer(forKey: "startTab")
    #if DEBUG
    @Environment(\.modelContext) private var context
    #endif

    var body: some View {
        #if DEBUG
        if let unit = DemoData.requestedUnit {
            // "-openUnit greetings" jumps straight into a practice session.
            NavigationStack { PracticeSessionView(title: unit.title, phrases: unit.phrases) }
        } else {
            tabs.task { DemoData.seedIfRequested(context) }
        }
        #else
        tabs
        #endif
    }

    private var tabs: some View {
        TabView(selection: $tab) {
            LearnView()
                .tabItem { Label("Learn", systemImage: "book") }
                .tag(0)
            PracticeZoneView()
                .tabItem { Label("Sounds", systemImage: "waveform") }
                .tag(1)
            TutorView()
                .tabItem { Label("Tutor", systemImage: "bubble.left.and.text.bubble.right") }
                .tag(2)
            StatsView()
                .tabItem { Label("Progress", systemImage: "chart.line.uptrend.xyaxis") }
                .tag(3)
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(4)
        }
    }
}
