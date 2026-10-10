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
    var body: some View {
        TabView {
            LearnView()
                .tabItem { Label("Learn", systemImage: "book") }
            PracticeZoneView()
                .tabItem { Label("Sounds", systemImage: "waveform") }
            TutorView()
                .tabItem { Label("Tutor", systemImage: "bubble.left.and.text.bubble.right") }
            StatsView()
                .tabItem { Label("Progress", systemImage: "chart.line.uptrend.xyaxis") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}
