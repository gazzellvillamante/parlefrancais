import SwiftUI

struct PracticeZoneView: View {
    var body: some View {
        NavigationStack {
            List {
                ForEach(SoundLesson.Kind.allCases, id: \.self) { kind in
                    Section(kind.rawValue) {
                        ForEach(SoundLibrary.lessons.filter { $0.kind == kind }) { lesson in
                            NavigationLink {
                                SoundLessonView(lesson: lesson)
                            } label: {
                                HStack(spacing: 14) {
                                    Text(lesson.symbol)
                                        .font(.system(.headline, design: .serif))
                                        .frame(width: 64, height: 40)
                                        .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
                                    Text(lesson.title)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Practice Zone")
        }
    }
}

struct SoundLessonView: View {
    let lesson: SoundLesson

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Text(lesson.symbol)
                        .font(.system(size: 44, weight: .bold, design: .serif))
                    Text(lesson.explanation)
                }
                .padding(.vertical, 6)
            }

            Section("How to make it") {
                ForEach(Array(lesson.howTo.enumerated()), id: \.offset) { number, step in
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text("\(number + 1)")
                            .font(.caption.bold())
                            .frame(width: 22, height: 22)
                            .background(Color.accentColor.opacity(0.15), in: Circle())
                        Text(step)
                    }
                }
            }

            Section("Examples — tap to listen") {
                ForEach(lesson.examples) { example in
                    Button {
                        Speaker.shared.speak(example.french, slow: true)
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(example.french).font(.headline)
                                Text(example.english).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "speaker.wave.2").foregroundStyle(Color.accentColor)
                        }
                    }
                    .tint(.primary)
                }
                NavigationLink {
                    PracticeSessionView(title: lesson.title, phrases: lesson.examples)
                } label: {
                    Label("Say these yourself", systemImage: "mic.fill")
                        .font(.headline)
                        .foregroundStyle(Color.accentColor)
                }
            }

            if !lesson.pairs.isEmpty {
                Section {
                    ForEach(lesson.pairs, id: \.self) { pair in
                        HStack {
                            pairButton(pair.a)
                            Text("vs").foregroundStyle(.secondary)
                            pairButton(pair.b)
                        }
                    }
                    NavigationLink {
                        ListeningQuizView(pairs: lesson.pairs, title: lesson.title)
                    } label: {
                        Label("Listening quiz", systemImage: "ear")
                            .font(.headline)
                            .foregroundStyle(Color.accentColor)
                    }
                    NavigationLink {
                        PracticeSessionView(title: "Minimal pairs",
                                            phrases: lesson.pairs.flatMap { [Phrase(french: $0.a, english: "vs \($0.b)"), Phrase(french: $0.b, english: "vs \($0.a)")] })
                    } label: {
                        Label("Say the pairs", systemImage: "mic.fill")
                            .font(.headline)
                            .foregroundStyle(Color.accentColor)
                    }
                } header: {
                    Text("Minimal pairs")
                } footer: {
                    Text("Words that differ by just this sound. Train your ear to hear the difference, then your mouth to make it.")
                }
            }
        }
        .navigationTitle(lesson.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func pairButton(_ word: String) -> some View {
        Button {
            Speaker.shared.speak(word, slow: true)
        } label: {
            Text(word)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.accentColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}

/// Plays one word of a minimal pair; the learner picks which one they heard.
struct ListeningQuizView: View {
    let pairs: [MinimalPair]
    let title: String

    @State private var current: MinimalPair?
    @State private var answer = ""
    @State private var picked: String?
    @State private var correct = 0
    @State private var total = 0

    var body: some View {
        VStack(spacing: 28) {
            Text("\(correct) / \(total)")
                .font(.title.bold().monospacedDigit())
                .padding(.top, 30)

            Button {
                Speaker.shared.speak(answer)
            } label: {
                Image(systemName: "speaker.wave.3.fill")
                    .font(.system(size: 44))
                    .frame(width: 120, height: 120)
                    .background(Color.accentColor.opacity(0.15), in: Circle())
            }
            Text("Which word did you hear?").foregroundStyle(.secondary)

            if let current {
                HStack(spacing: 16) {
                    choice(current.a)
                    choice(current.b)
                }
                .padding(.horizontal)
            }

            if picked != nil {
                Button("Next") { next() }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
            }
            Spacer()
        }
        .navigationTitle("Listening quiz")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { if current == nil { next() } }
    }

    private func choice(_ word: String) -> some View {
        let isAnswer = word == answer
        let background: Color = {
            guard let picked else { return Color.secondary.opacity(0.12) }
            if isAnswer { return .green.opacity(0.3) }
            return picked == word ? .red.opacity(0.3) : Color.secondary.opacity(0.12)
        }()
        return Button {
            guard picked == nil else { Speaker.shared.speak(word); return }
            picked = word
            total += 1
            if isAnswer { correct += 1 }
        } label: {
            Text(word)
                .font(.title2.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 22)
                .background(background, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .sensoryFeedback(isAnswer ? .success : .error, trigger: picked) { _, new in new == word }
    }

    private func next() {
        guard let pair = pairs.randomElement() else { return }
        current = Bool.random() ? pair : MinimalPair(a: pair.b, b: pair.a)
        answer = Bool.random() ? pair.a : pair.b
        picked = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { Speaker.shared.speak(answer) }
    }
}
