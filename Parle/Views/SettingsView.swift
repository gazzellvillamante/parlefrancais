import AVFoundation
import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var context

    @AppStorage("level") private var levelRaw = 0
    @AppStorage("dailyGoal") private var dailyGoal = 10
    @AppStorage("autoPlay") private var autoPlay = true
    @AppStorage("speakReplies") private var speakReplies = true
    @AppStorage(Speaker.rateKey) private var speechRate = 1.0
    @AppStorage(Speaker.voiceKey) private var voiceIdentifier = ""
    @AppStorage("reminderEnabled") private var reminderEnabled = false
    @AppStorage("reminderHour") private var reminderHour = 19
    @AppStorage("reminderMinute") private var reminderMinute = 0
    @AppStorage("preferClaude") private var preferClaude = false
    @AppStorage("claudeModel") private var claudeModel = ClaudeClient.defaultModel
    @AppStorage("confirmEveryPaidMessage") private var confirmEveryPaidMessage = false
    @AppStorage("hasOnboarded") private var hasOnboarded = true

    @State private var apiKey = Keychain.read(Keychain.claudeKey) ?? ""
    @State private var confirmReset = false
    @State private var notificationsDenied = false

    private var reminderTime: Binding<Date> {
        Binding {
            Calendar.current.date(from: DateComponents(hour: reminderHour, minute: reminderMinute)) ?? .now
        } set: { date in
            let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
            reminderHour = parts.hour ?? 19
            reminderMinute = parts.minute ?? 0
            Task { await updateReminder() }
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Learning") {
                    Picker("Level", selection: $levelRaw) {
                        ForEach(Level.allCases) { level in
                            Text("\(level.title) (\(level.cefr))").tag(level.rawValue)
                        }
                    }
                    Stepper("Daily goal: \(dailyGoal) phrases", value: $dailyGoal, in: 5...50, step: 5)
                    Toggle("Play phrase automatically", isOn: $autoPlay)
                }

                Section {
                    Picker("Voice", selection: $voiceIdentifier) {
                        Text("Automatic").tag("")
                        ForEach(Speaker.frenchVoices, id: \.identifier) { voice in
                            Text("\(voice.name) · \(voice.language)\(qualityLabel(voice))").tag(voice.identifier)
                        }
                    }
                    VStack(alignment: .leading) {
                        Text("Speaking speed: \(speechRate, format: .percent.precision(.fractionLength(0)))")
                        Slider(value: $speechRate, in: 0.6...1.3, step: 0.05)
                    }
                    Button("Test voice") { Speaker.shared.speak("Bonjour ! Je suis ravi de parler français avec vous.") }
                } header: {
                    Text("Voice")
                } footer: {
                    Text("For a far more natural voice, download an Enhanced or Premium French voice in iOS Settings › Accessibility › Spoken Content › Voices › French.")
                }

                Section {
                    Toggle("Daily reminder", isOn: $reminderEnabled)
                        .onChange(of: reminderEnabled) { Task { await updateReminder() } }
                    if reminderEnabled {
                        DatePicker("Time", selection: reminderTime, displayedComponents: .hourAndMinute)
                    }
                    if notificationsDenied {
                        Text("Notifications are turned off for Parle in iOS Settings.")
                            .font(.caption).foregroundStyle(.orange)
                    }
                } header: {
                    Text("Reminders")
                }

                Section {
                    LabeledContent("Active", value: TutorChat.backend.label)
                    LabeledContent("Apple Intelligence", value: TutorChat.onDeviceAvailable ? "Available" : "Not available")
                    SecureField("Claude API key (optional)", text: $apiKey)
                        .textContentType(.password)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .onSubmit { Keychain.save(apiKey.trimmingCharacters(in: .whitespacesAndNewlines), for: Keychain.claudeKey) }
                        .onChange(of: apiKey) {
                            Keychain.save(apiKey.trimmingCharacters(in: .whitespacesAndNewlines), for: Keychain.claudeKey)
                        }
                    if !apiKey.isEmpty {
                        Picker("Claude model", selection: $claudeModel) {
                            ForEach(ClaudeClient.models) { model in
                                Text("\(model.name) · \(model.typicalMessageCost)/reply").tag(model.id)
                            }
                        }
                        Toggle("Ask before every paid message", isOn: $confirmEveryPaidMessage)
                        LabeledContent("Spent this month (estimate)",
                                       value: "\(SpendTracker.format(SpendTracker.thisMonth)) · \(SpendTracker.messagesThisMonth) replies")
                        if TutorChat.onDeviceAvailable {
                            Toggle("Use Claude instead of on-device", isOn: $preferClaude)
                        }
                    }
                    Toggle("Read tutor replies aloud", isOn: $speakReplies)
                } header: {
                    Text("AI tutor")
                } footer: {
                    Text("The on-device tutor is free and private. A Claude key (from console.anthropic.com) is stored in your Keychain and billed per use by Anthropic — no subscription. Parle always asks before the first paid message of each conversation. Your exact bill is on the Usage page at console.anthropic.com.")
                }

                Section {
                    Button("Redo level check") { hasOnboarded = false }
                    Button("Reset all progress", role: .destructive) { confirmReset = true }
                } footer: {
                    Text("Parle is a personal, subscription-free practice app. Everything stays on this device.")
                }
            }
            .navigationTitle("Settings")
            .confirmationDialog("Delete all your attempts and scores?", isPresented: $confirmReset, titleVisibility: .visible) {
                Button("Reset progress", role: .destructive) {
                    try? context.delete(model: Attempt.self)
                }
            }
        }
    }

    private func qualityLabel(_ voice: AVSpeechSynthesisVoice) -> String {
        switch voice.quality {
        case .premium: " · Premium"
        case .enhanced: " · Enhanced"
        default: ""
        }
    }

    private func updateReminder() async {
        if reminderEnabled {
            let granted = await Reminders.schedule(hour: reminderHour, minute: reminderMinute)
            notificationsDenied = !granted
            if !granted { reminderEnabled = false }
        } else {
            Reminders.cancel()
        }
    }
}
