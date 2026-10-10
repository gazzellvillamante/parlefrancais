import SwiftData
import SwiftUI

/// Listen → speak → get feedback, one phrase at a time.
struct PracticeSessionView: View {
    let title: String
    let phrases: [Phrase]

    @Environment(\.modelContext) private var context
    @Query private var attempts: [Attempt]

    @State private var index = 0
    @State private var recognizer = SpeechRecognizer()
    @State private var result: PronunciationResult?
    @State private var showTranslation = true
    @State private var finished = false
    @State private var sessionScores: [String: Int] = [:]

    @AppStorage("autoPlay") private var autoPlay = true

    private var phrase: Phrase { phrases[index] }

    var body: some View {
        Group {
            if phrases.isEmpty {
                ContentUnavailableView("Nothing to practise", systemImage: "text.bubble",
                                       description: Text("Add some phrases first."))
            } else if finished {
                summary
            } else {
                practice
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { if autoPlay, !phrases.isEmpty { Speaker.shared.speak(phrase.french) } }
        .onDisappear {
            recognizer.cancel()
            Speaker.shared.stop()
        }
    }

    // MARK: Practice

    private var practice: some View {
        VStack(spacing: 20) {
            ProgressView(value: Double(index + 1), total: Double(phrases.count))
                .padding(.horizontal)

            ScrollView {
                VStack(spacing: 18) {
                    phraseCard
                    if let result { feedback(result) }
                    if let error = recognizer.errorMessage {
                        Label(error, systemImage: "exclamationmark.triangle")
                            .font(.footnote)
                            .foregroundStyle(.orange)
                            .padding(.horizontal)
                    }
                }
                .padding(.horizontal)
            }

            VStack(spacing: 8) {
                Text(recognizer.isRecording ? (recognizer.transcript.isEmpty ? "Listening…" : recognizer.transcript) : "Tap and say the phrase")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .frame(minHeight: 44)

                HStack(spacing: 40) {
                    Button { move(-1) } label: {
                        Image(systemName: "chevron.left").font(.title2)
                    }
                    .disabled(index == 0 || recognizer.isRecording)

                    MicButton(isRecording: recognizer.isRecording, level: recognizer.audioLevel) {
                        toggleRecording()
                    }

                    Button { move(1) } label: {
                        Image(systemName: index == phrases.count - 1 ? "flag.checkered" : "chevron.right").font(.title2)
                    }
                    .disabled(recognizer.isRecording)
                }
            }
            .padding(.bottom)
        }
    }

    private var phraseCard: some View {
        VStack(spacing: 14) {
            FlowLayout(spacing: 6, lineSpacing: 8) {
                if let result {
                    ForEach(result.words) { word in
                        Button { Speaker.shared.speak(word.spoken, slow: true) } label: {
                            Text(word.display)
                                .foregroundStyle(Color.score(word.score))
                        }
                        .buttonStyle(.plain)
                    }
                } else {
                    ForEach(Array(phrase.french.split(separator: " ").enumerated()), id: \.offset) { _, word in
                        Button {
                            Speaker.shared.speak(String(word).trimmingCharacters(in: .punctuationCharacters), slow: true)
                        } label: {
                            Text(String(word))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .font(.system(size: 28, weight: .semibold, design: .rounded))

            if showTranslation {
                Text(phrase.english)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 28) {
                SpeakButton(text: phrase.french)
                SpeakButton(text: phrase.french, slow: true)
                Button {
                    showTranslation.toggle()
                } label: {
                    Image(systemName: showTranslation ? "eye.slash" : "eye")
                }
                .accessibilityLabel(showTranslation ? "Hide translation" : "Show translation")
            }
            .font(.title2)
            .padding(.top, 4)

            if let tip = phrase.tip {
                Label(tip, systemImage: "lightbulb")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(Color.yellow.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
            }

            Text("Tap any word to hear it slowly")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 20))
    }

    private func feedback(_ result: PronunciationResult) -> some View {
        HStack(alignment: .top, spacing: 16) {
            ScoreRing(score: result.score)
            VStack(alignment: .leading, spacing: 6) {
                Text(result.headline).font(.headline)
                if !result.heard.isEmpty {
                    Text("Heard: “\(result.heard)”")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                if !result.missedWords.isEmpty && result.score > 0 {
                    Text("Work on: " + result.missedWords.map(\.spoken).joined(separator: ", "))
                        .font(.subheadline)
                        .foregroundStyle(.red)
                }
                if let best = bestScore, best > 0 {
                    Text("Best: \(best)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
        }
        .padding()
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16))
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private var bestScore: Int? {
        attempts.filter { $0.phraseText == phrase.french }.map(\.score).max()
    }

    // MARK: Summary

    private var summary: some View {
        let scores = phrases.compactMap { sessionScores[$0.french] }
        let average = scores.isEmpty ? 0 : scores.reduce(0, +) / scores.count
        return ScrollView {
            VStack(spacing: 20) {
                ScoreRing(score: average, size: 140)
                    .padding(.top, 30)
                Text(average >= 80 ? "Bravo ! 🎉" : "Bien joué !")
                    .font(.largeTitle.bold())
                Text("You practised \(scores.count) of \(phrases.count) phrases.")
                    .foregroundStyle(.secondary)

                VStack(spacing: 0) {
                    ForEach(Array(phrases.enumerated()), id: \.offset) { _, phrase in
                        HStack {
                            Text(phrase.french)
                            Spacer()
                            if let score = sessionScores[phrase.french] {
                                Text("\(score)").bold().foregroundStyle(Color.score(score))
                            } else {
                                Text("–").foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 10)
                        Divider()
                    }
                }
                .padding()
                .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16))

                Button("Practise again") {
                    sessionScores = [:]
                    result = nil
                    index = 0
                    finished = false
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding()
        }
    }

    // MARK: Actions

    private func toggleRecording() {
        if recognizer.isRecording {
            recognizer.stop()
            return
        }
        let target = phrase.french
        withAnimation { result = nil }
        Task {
            await recognizer.start { heard in
                let scored = PronunciationScorer.score(target: target, heard: heard)
                withAnimation(.spring) { result = scored }
                guard !heard.isEmpty else { return }
                context.insert(Attempt(phraseText: target, heard: heard, score: scored.score))
                sessionScores[target] = max(sessionScores[target] ?? 0, scored.score)
            }
        }
    }

    private func move(_ delta: Int) {
        let next = index + delta
        if next >= phrases.count {
            Speaker.shared.stop()
            finished = true
            return
        }
        guard next >= 0 else { return }
        index = next
        result = nil
        recognizer.errorMessage = nil
        if autoPlay { Speaker.shared.speak(phrase.french) }
    }
}
