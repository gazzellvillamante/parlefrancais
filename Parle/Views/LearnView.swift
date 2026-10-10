import SwiftData
import SwiftUI

struct LearnView: View {
    @Query private var attempts: [Attempt]
    @Query(sort: \CustomPhrase.createdAt, order: .reverse) private var customPhrases: [CustomPhrase]
    @AppStorage("level") private var levelRaw = 0
    @AppStorage("dailyGoal") private var dailyGoal = 10

    private var level: Level { Level(rawValue: levelRaw) ?? .beginner }

    var body: some View {
        let summary = ProgressSummary(attempts: attempts)
        NavigationStack {
            List {
                Section {
                    TodayCard(summary: summary, goal: dailyGoal)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }

                Section {
                    if let next = recommendedUnit(summary) {
                        NavigationLink {
                            PracticeSessionView(title: next.title, phrases: next.phrases)
                        } label: {
                            UnitRow(unit: next, mastered: summary.mastered(next.phrases), highlight: true)
                        }
                    }
                    NavigationLink {
                        PracticeSessionView(title: "Review", phrases: reviewPhrases(summary))
                    } label: {
                        Label {
                            VStack(alignment: .leading) {
                                Text("Review weak phrases")
                                Text("\(reviewPhrases(summary).count) phrases scored under \(ProgressSummary.masteryThreshold)")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "arrow.counterclockwise")
                        }
                    }
                    .disabled(reviewPhrases(summary).isEmpty)
                    NavigationLink {
                        MyPhrasesView()
                    } label: {
                        Label {
                            VStack(alignment: .leading) {
                                Text("My phrases")
                                Text("\(customPhrases.count) saved")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "text.badge.plus")
                        }
                    }
                } header: {
                    Text("Up next")
                }

                ForEach(orderedLevels, id: \.self) { lvl in
                    Section {
                        ForEach(PhraseLibrary.units(for: lvl)) { unit in
                            NavigationLink {
                                PracticeSessionView(title: unit.title, phrases: unit.phrases)
                            } label: {
                                UnitRow(unit: unit, mastered: summary.mastered(unit.phrases))
                            }
                        }
                    } header: {
                        Text("\(lvl.title) · \(lvl.cefr)\(lvl == level ? "  ★ your level" : "")")
                    }
                }
            }
            .navigationTitle("Parle")
        }
    }

    /// The user's level first, then the rest in order.
    private var orderedLevels: [Level] {
        [level] + Level.allCases.filter { $0 != level }
    }

    private func recommendedUnit(_ summary: ProgressSummary) -> LessonUnit? {
        let candidates = PhraseLibrary.units.filter { $0.level >= level } + PhraseLibrary.units.filter { $0.level < level }
        return candidates.first { summary.mastered($0.phrases) < $0.phrases.count }
    }

    private func reviewPhrases(_ summary: ProgressSummary) -> [Phrase] {
        var seen = Set<String>()
        return (PhraseLibrary.allPhrases + customPhrases.map(\.phrase)).filter {
            guard let best = summary.bestScores[$0.french], best < ProgressSummary.masteryThreshold else { return false }
            return seen.insert($0.french).inserted
        }
    }
}

struct UnitRow: View {
    let unit: LessonUnit
    let mastered: Int
    var highlight = false

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: unit.icon)
                .font(.title3)
                .frame(width: 44, height: 44)
                .background((highlight ? Color.accentColor : Color.secondary).opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
                .foregroundStyle(highlight ? Color.accentColor : Color.primary)
            VStack(alignment: .leading, spacing: 4) {
                Text(highlight ? "Continue: \(unit.title)" : unit.title).font(.headline)
                Text(unit.subtitle).font(.caption).foregroundStyle(.secondary)
                ProgressView(value: Double(mastered), total: Double(max(1, unit.phrases.count)))
                    .tint(mastered == unit.phrases.count ? .green : .accentColor)
            }
            Text("\(mastered)/\(unit.phrases.count)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct TodayCard: View {
    let summary: ProgressSummary
    let goal: Int

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Today").font(.caption).foregroundStyle(.white.opacity(0.8))
                Text("\(min(summary.practicedToday, goal)) / \(goal) phrases")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                ProgressView(value: Double(min(summary.practicedToday, goal)), total: Double(max(goal, 1)))
                    .tint(.white)
            }
            Spacer()
            VStack(spacing: 2) {
                Image(systemName: "flame.fill")
                    .font(.title)
                    .foregroundStyle(summary.streak > 0 ? Color.orange : Color.white.opacity(0.5))
                Text("\(summary.streak)")
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                Text(summary.streak == 1 ? "day" : "days")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .padding()
        .background(
            LinearGradient(colors: [Color(red: 0, green: 0.33, blue: 0.66), Color(red: 0.1, green: 0.2, blue: 0.5)],
                           startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 20)
        )
    }
}

struct MyPhrasesView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \CustomPhrase.createdAt, order: .reverse) private var customPhrases: [CustomPhrase]
    @Query private var attempts: [Attempt]
    @State private var showingAdd = false

    var body: some View {
        let summary = ProgressSummary(attempts: attempts)
        List {
            if customPhrases.isEmpty {
                ContentUnavailableView {
                    Label("No phrases yet", systemImage: "text.badge.plus")
                } description: {
                    Text("Add sentences you want to say — for a trip, a meeting, or your favourite song.")
                } actions: {
                    Button("Add a phrase") { showingAdd = true }
                        .buttonStyle(.borderedProminent)
                }
            } else {
                Section {
                    NavigationLink {
                        PracticeSessionView(title: "My phrases", phrases: customPhrases.map(\.phrase))
                    } label: {
                        Label("Practise all \(customPhrases.count)", systemImage: "play.fill")
                            .font(.headline)
                    }
                }
                Section {
                    ForEach(customPhrases) { item in
                        NavigationLink {
                            PracticeSessionView(title: "Practice", phrases: [item.phrase])
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.french)
                                    if !item.english.isEmpty {
                                        Text(item.english).font(.caption).foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                if let best = summary.bestScores[item.french] {
                                    Text("\(best)").bold().foregroundStyle(Color.score(best))
                                }
                            }
                        }
                    }
                    .onDelete { offsets in
                        for offset in offsets { context.delete(customPhrases[offset]) }
                    }
                }
            }
        }
        .navigationTitle("My phrases")
        .toolbar {
            Button { showingAdd = true } label: { Image(systemName: "plus") }
        }
        .sheet(isPresented: $showingAdd) { AddPhraseSheet() }
    }
}

struct AddPhraseSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var french = ""
    @State private var english = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("En français…", text: $french, axis: .vertical)
                        .autocorrectionDisabled()
                    TextField("Meaning (optional)", text: $english, axis: .vertical)
                } footer: {
                    Text("Tip: you can paste several phrases, one per line, to add them all at once.")
                }
                if !french.isEmpty {
                    Section {
                        SpeakButton(text: french, label: "Hear it")
                    }
                }
            }
            .navigationTitle("New phrase")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(french.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func save() {
        let lines = french.split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        let meaning = english.trimmingCharacters(in: .whitespacesAndNewlines)
        for line in lines {
            context.insert(CustomPhrase(french: line, english: lines.count == 1 ? meaning : ""))
        }
        dismiss()
    }
}
