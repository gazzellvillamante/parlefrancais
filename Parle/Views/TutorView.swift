import SwiftUI

struct TutorView: View {
    @State private var chat = TutorChat()
    @State private var recognizer = SpeechRecognizer()
    @State private var draft = ""
    @State private var backend = TutorChat.backend
    @AppStorage("level") private var levelRaw = 0
    @AppStorage("speakReplies") private var speakReplies = true

    private var level: Level { Level(rawValue: levelRaw) ?? .beginner }

    var body: some View {
        NavigationStack {
            Group {
                if backend == .unavailable {
                    setupHelp
                } else {
                    conversation
                }
            }
            .navigationTitle("AI Tutor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if backend != .unavailable {
                    Menu {
                        ForEach(TutorScenario.allCases) { scenario in
                            Button {
                                begin(scenario)
                            } label: {
                                Label(scenario.rawValue, systemImage: scenario.icon)
                            }
                        }
                    } label: {
                        Label(chat.scenario.rawValue, systemImage: "theatermasks")
                    }
                }
            }
            .onAppear {
                backend = TutorChat.backend
                if chat.messages.isEmpty { begin(.free) }
            }
            .onDisappear {
                recognizer.cancel()
            }
        }
    }

    private var setupHelp: some View {
        ContentUnavailableView {
            Label("Set up the AI tutor", systemImage: "sparkles")
        } description: {
            Text("""
            The tutor runs free and on-device with Apple Intelligence on iOS 26 (iPhone 15 Pro or newer, \
            with Apple Intelligence turned on).

            On other devices, add your own Claude API key in Settings › AI tutor — you only pay \
            Anthropic for what you use; there's no subscription.
            """)
        }
    }

    private var conversation: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(chat.messages) { message in
                            Bubble(message: message).id(message.id)
                        }
                        if chat.isThinking {
                            HStack {
                                ProgressView()
                                Text("Thinking…").foregroundStyle(.secondary)
                                Spacer()
                            }
                            .padding(.horizontal)
                            .id("thinking")
                        }
                        if let error = chat.errorMessage {
                            Label(error, systemImage: "exclamationmark.triangle")
                                .font(.footnote)
                                .foregroundStyle(.orange)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: chat.messages.count) {
                    if let id = chat.messages.last?.id { withAnimation { proxy.scrollTo(id, anchor: .bottom) } }
                    if speakReplies, let last = chat.messages.last, last.role == .assistant, chat.messages.count > 1 {
                        Speaker.shared.speak(TutorView.frenchPart(of: last.text))
                    }
                }
            }

            Divider()
            inputBar
        }
    }

    private var inputBar: some View {
        VStack(spacing: 6) {
            if recognizer.isRecording {
                Text(recognizer.transcript.isEmpty ? "Listening… speak French" : recognizer.transcript)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
            }
            if let error = recognizer.errorMessage {
                Text(error).font(.caption).foregroundStyle(.orange).padding(.horizontal)
            }
            HStack(spacing: 10) {
                Button {
                    toggleMic()
                } label: {
                    Image(systemName: recognizer.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                        .font(.system(size: 38))
                        .foregroundStyle(recognizer.isRecording ? Color.red : Color.accentColor)
                        .symbolEffect(.pulse, isActive: recognizer.isRecording)
                }
                .disabled(chat.isThinking)

                TextField("Écrivez en français…", text: $draft, axis: .vertical)
                    .lineLimit(1...4)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(sendDraft)

                Button(action: sendDraft) {
                    Image(systemName: "arrow.up.circle.fill").font(.system(size: 32))
                }
                .disabled(draft.trimmingCharacters(in: .whitespaces).isEmpty || chat.isThinking)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    private func begin(_ scenario: TutorScenario) {
        recognizer.cancel()
        chat.start(scenario, level: level)
        if speakReplies { Speaker.shared.speak(scenario.opener) }
    }

    private func sendDraft() {
        let text = draft
        draft = ""
        Task { await chat.send(text) }
    }

    private func toggleMic() {
        if recognizer.isRecording {
            recognizer.stop()
            return
        }
        Task {
            await recognizer.start { heard in
                guard !heard.isEmpty else { return }
                Task { await chat.send(heard) }
            }
        }
    }

    /// Only read aloud the French reply, not the English "💡" correction.
    static func frenchPart(of text: String) -> String {
        text.components(separatedBy: "💡").first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? text
    }
}

private struct Bubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.role == .user { Spacer(minLength: 40) }
            VStack(alignment: .leading, spacing: 6) {
                Text(message.text)
                    .textSelection(.enabled)
                if message.role == .assistant {
                    HStack(spacing: 16) {
                        SpeakButton(text: TutorView.frenchPart(of: message.text))
                        SpeakButton(text: TutorView.frenchPart(of: message.text), slow: true)
                    }
                    .font(.footnote)
                }
            }
            .padding(12)
            .foregroundStyle(message.role == .user ? Color.white : Color.primary)
            .background(message.role == .user ? Color.accentColor : Color.secondary.opacity(0.15),
                        in: RoundedRectangle(cornerRadius: 18))
            if message.role == .assistant { Spacer(minLength: 40) }
        }
        .padding(.horizontal)
    }
}
