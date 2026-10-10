import SwiftData
import SwiftUI

/// Welcome → self-assessment → quick speaking check → reminder.
struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @AppStorage("level") private var levelRaw = 0
    @AppStorage("reminderEnabled") private var reminderEnabled = false
    @AppStorage("reminderHour") private var reminderHour = 19
    @AppStorage("reminderMinute") private var reminderMinute = 0

    // "-onboardingStep N" on launch opens a given page (used for screenshots).
    @State private var step = UserDefaults.standard.integer(forKey: "onboardingStep")
    @State private var selfLevel: Level = .beginner
    @State private var reminderTime = Calendar.current.date(from: DateComponents(hour: 19, minute: 0)) ?? .now

    var body: some View {
        VStack {
            switch step {
            case 0: welcome
            case 1: levelPicker
            case 2: PlacementCheck(selfLevel: selfLevel) { level in
                    levelRaw = level.rawValue
                    withAnimation { step = 3 }
                }
            default: reminder
            }
        }
        .padding()
        .animation(.easeInOut, value: step)
    }

    private var welcome: some View {
        OnboardingPage {
            Text("🇫🇷").font(.system(size: 90))
            Text("Parle").font(.system(size: 48, weight: .bold, design: .rounded))
            Text("Your French pronunciation coach.\nListen, speak, and get instant feedback.")
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 14) {
                Label("Real phrases for real situations", systemImage: "text.bubble")
                Label("Instant word-by-word pronunciation scores", systemImage: "waveform.badge.mic")
                Label("Drills for tricky French sounds", systemImage: "mouth")
                Label("Chat with an AI tutor out loud", systemImage: "sparkles")
            }
            .padding(.top)
        } footer: {
            primaryButton("Commencer") { step = 1 }
        }
    }

    private var levelPicker: some View {
        OnboardingPage {
            Text("How's your French?")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
            ForEach(Level.allCases) { level in
                Button {
                    selfLevel = level
                } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(level.title).font(.headline)
                            Text(level.blurb).font(.subheadline).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: selfLevel == level ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(Color.accentColor)
                            .font(.title2)
                    }
                    .padding()
                    .background(Color.secondary.opacity(selfLevel == level ? 0.18 : 0.08), in: RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
            }
        } footer: {
            primaryButton("Continue") { step = 2 }
        }
    }

    private var reminder: some View {
        OnboardingPage {
            Image(systemName: "bell.badge")
                .font(.system(size: 64))
                .foregroundStyle(Color.accentColor)
            Text("A little every day").font(.largeTitle.bold()).multilineTextAlignment(.center)
            Text("Five minutes of speaking a day beats an hour once a week. When should we remind you?")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            DatePicker("Reminder time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                .datePickerStyle(.wheel)
                .labelsHidden()
        } footer: {
            primaryButton("Remind me") {
                let parts = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
                reminderHour = parts.hour ?? 19
                reminderMinute = parts.minute ?? 0
                Task {
                    reminderEnabled = await Reminders.schedule(hour: reminderHour, minute: reminderMinute)
                    hasOnboarded = true
                }
            }
            Button("Not now") { hasOnboarded = true }
                .padding(.bottom)
        }
    }

    private func primaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: { withAnimation { action() } }) {
            Text(title).font(.headline).frame(maxWidth: .infinity).padding(.vertical, 6)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
    }
}

/// Centres its content when it fits; scrolls it (e.g. with large text) when
/// it doesn't. The footer buttons always stay visible.
private struct OnboardingPage<Content: View, Footer: View>: View {
    @ViewBuilder let content: Content
    @ViewBuilder let footer: Footer

    var body: some View {
        VStack(spacing: 12) {
            ViewThatFits(in: .vertical) {
                VStack(spacing: 22) {
                    Spacer(minLength: 0)
                    content
                    Spacer(minLength: 0)
                }
                ScrollView {
                    VStack(spacing: 22) { content }
                        .padding(.vertical)
                }
            }
            footer
        }
    }
}

/// Three phrases of increasing difficulty to suggest a starting level.
private struct PlacementCheck: View {
    let selfLevel: Level
    let onDone: (Level) -> Void

    @Environment(\.modelContext) private var context
    @State private var index = 0
    @State private var scores: [Int] = []
    @State private var recognizer = SpeechRecognizer()
    @State private var last: PronunciationResult?

    private let phrases = PhraseLibrary.placementPhrases

    var body: some View {
        OnboardingPage {
            Text("Quick level check").font(.largeTitle.bold()).multilineTextAlignment(.center)
            Text("Say each phrase out loud. It takes 30 seconds.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if index < phrases.count {
                let phrase = phrases[index]
                Text("\(index + 1) of \(phrases.count)").font(.caption).foregroundStyle(.secondary)
                VStack(spacing: 10) {
                    Text(phrase.french)
                        .font(.title.weight(.semibold))
                        .multilineTextAlignment(.center)
                    Text(phrase.english).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    HStack(spacing: 24) {
                        SpeakButton(text: phrase.french)
                        SpeakButton(text: phrase.french, slow: true)
                    }
                    .font(.title2)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(.background.secondary, in: RoundedRectangle(cornerRadius: 20))

                if let last {
                    HStack {
                        ScoreRing(score: last.score, size: 48)
                        Text(last.headline).font(.headline)
                    }
                }
                if let error = recognizer.errorMessage {
                    Text(error).font(.footnote).foregroundStyle(.orange).multilineTextAlignment(.center)
                }
            }
        } footer: {
            if index < phrases.count {
                Text(recognizer.isRecording ? (recognizer.transcript.isEmpty ? "Listening…" : recognizer.transcript) : " ")
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                MicButton(isRecording: recognizer.isRecording, level: recognizer.audioLevel) {
                    record(phrases[index])
                }
            }
            Button("Skip — use \(selfLevel.title)") {
                recognizer.cancel()
                onDone(selfLevel)
            }
            .padding(.bottom)
        }
        .onDisappear { recognizer.cancel() }
    }

    private func record(_ phrase: Phrase) {
        if recognizer.isRecording {
            recognizer.stop()
            return
        }
        Task {
            await recognizer.start { heard in
                let result = PronunciationScorer.score(target: phrase.french, heard: heard)
                last = result
                guard !heard.isEmpty else { return }
                context.insert(Attempt(phraseText: phrase.french, heard: heard, score: result.score))
                scores.append(result.score)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    last = nil
                    index += 1
                    if index >= phrases.count { onDone(placement()) }
                }
            }
        }
    }

    /// Blend the measured result with what the learner told us.
    private func placement() -> Level {
        let passed = scores.filter { $0 >= 70 }.count
        let measured = Level(rawValue: min(passed, Level.advanced.rawValue)) ?? .beginner
        // Don't push someone far above their own estimate from three phrases.
        let capped = min(measured, Level(rawValue: selfLevel.rawValue + 1) ?? .advanced)
        return max(capped, selfLevel == .beginner ? .beginner : Level(rawValue: selfLevel.rawValue - 1) ?? .beginner)
    }
}
