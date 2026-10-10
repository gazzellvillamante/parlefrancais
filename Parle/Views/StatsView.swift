import Charts
import SwiftData
import SwiftUI

struct StatsView: View {
    enum Page: String, CaseIterable, Identifiable {
        case overview = "Overview"
        case improve = "Improve"
        var id: String { rawValue }
    }

    @Query(sort: \Attempt.date, order: .reverse) private var attempts: [Attempt]
    // "-progressPage Improve" on launch opens the Improve page (used for screenshots).
    @State private var page = Page(rawValue: UserDefaults.standard.string(forKey: "progressPage") ?? "") ?? .overview
    @State private var analytics: ProgressAnalytics?

    var body: some View {
        NavigationStack {
            List {
                Picker("View", selection: $page) {
                    ForEach(Page.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)

                if let analytics {
                    switch page {
                    case .overview: OverviewSections(attempts: attempts, analytics: analytics)
                    case .improve: ImproveSections(analytics: analytics)
                    }
                } else {
                    ProgressView().frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Progress")
            // Re-analyse only when attempts change, not on every redraw.
            .task(id: attempts.count) {
                analytics = ProgressAnalytics(attempts: attempts)
            }
        }
    }
}

// MARK: - Overview

private struct OverviewSections: View {
    let attempts: [Attempt]
    let analytics: ProgressAnalytics

    @State private var range = 14

    var body: some View {
        let summary = ProgressSummary(attempts: attempts)

        Section {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                StatTile(value: "\(summary.streak)", label: "Day streak", icon: "flame.fill", color: .orange)
                StatTile(value: "\(summary.averageScore)", label: "Avg score", icon: "target", color: .purple)
                StatTile(value: "\(summary.totalAttempts)", label: "Spoken", icon: "mic.fill", color: .blue)
                StatTile(value: "\(summary.mastered(PhraseLibrary.allPhrases))", label: "Mastered", icon: "checkmark.seal.fill", color: .green)
                StatTile(value: analytics.averageImprovement.map { "+\($0)" } ?? "–", label: "Avg gain", icon: "arrow.up.right", color: .teal)
                StatTile(value: "\(analytics.practiceDays.count)", label: "Days", icon: "calendar", color: .pink)
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
        } footer: {
            Text("Avg gain: how many points your best attempt beats your first try on the same phrase.")
        }

        Section("This week vs last week") {
            TrendRow(title: "Average score",
                     now: analytics.trend.thisWeekAverage.map { "\($0)" } ?? "–",
                     before: analytics.trend.lastWeekAverage.map { "\($0)" } ?? "–",
                     change: analytics.trend.scoreChange)
            TrendRow(title: "Phrases spoken",
                     now: "\(analytics.trend.thisWeekCount)",
                     before: "\(analytics.trend.lastWeekCount)",
                     change: analytics.trend.thisWeekCount - analytics.trend.lastWeekCount)
        }

        Section {
            Picker("Range", selection: $range) {
                Text("14 days").tag(14)
                Text("30 days").tag(30)
            }
            .pickerStyle(.segmented)

            let start = Calendar.current.date(byAdding: .day, value: -(range - 1), to: Calendar.current.startOfDay(for: .now))!
            let points = analytics.daily.filter { $0.day >= start }
            if points.isEmpty {
                Text("Practise a few phrases to see your scores here.").foregroundStyle(.secondary)
            } else {
                Text("Average score").font(.caption).foregroundStyle(.secondary)
                Chart(points) { point in
                    LineMark(x: .value("Day", point.day, unit: .day), y: .value("Score", point.average))
                        .interpolationMethod(.monotone)
                    PointMark(x: .value("Day", point.day, unit: .day), y: .value("Score", point.average))
                        .foregroundStyle(Color.score(Int(point.average)))
                }
                .chartYScale(domain: 0...100)
                .chartXScale(domain: start...Date.now)
                .frame(height: 160)

                Text("Phrases spoken").font(.caption).foregroundStyle(.secondary)
                Chart(points) { point in
                    BarMark(x: .value("Day", point.day, unit: .day), y: .value("Phrases", point.count))
                        .foregroundStyle(Color.accentColor.gradient)
                        .cornerRadius(3)
                }
                .chartXScale(domain: start...Date.now)
                .frame(height: 110)
            }
        } header: {
            Text("Scores over time")
        }

        Section("Practice calendar") {
            ActivityCalendar(practiceDays: analytics.practiceDays, daily: analytics.daily)
                .padding(.vertical, 6)
        }

        if !analytics.unitStats.isEmpty {
            Section("Average score by unit") {
                ForEach(analytics.unitStats.sorted { $0.average > $1.average }) { stat in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Label(stat.unit.title, systemImage: stat.unit.icon)
                            Spacer()
                            Text("\(stat.average)").bold().foregroundStyle(Color.score(stat.average)).monospacedDigit()
                        }
                        ProgressView(value: Double(stat.average), total: 100)
                            .tint(Color.score(stat.average))
                        Text("\(stat.attempts) attempts").font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }
        }

        if analytics.timeOfDay.count > 1 {
            Section {
                Chart(analytics.timeOfDay) { slot in
                    BarMark(x: .value("Time", slot.label), y: .value("Average", slot.average))
                        .foregroundStyle(Color.score(slot.average))
                        .annotation(position: .top) {
                            Text("\(slot.average)").font(.caption2).foregroundStyle(.secondary)
                        }
                }
                .chartYScale(domain: 0...100)
                .frame(height: 140)
            } header: {
                Text("Best time to practise")
            } footer: {
                if let best = analytics.bestTimeOfDay {
                    Text("You score highest in the \(best.label.lowercased()).")
                }
            }
        }

        Section("By level") {
            ForEach(Level.allCases) { level in
                let phrases = PhraseLibrary.units(for: level).flatMap(\.phrases)
                let mastered = summary.mastered(phrases)
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("\(level.title) · \(level.cefr)")
                        Spacer()
                        Text("\(mastered)/\(phrases.count)").foregroundStyle(.secondary).monospacedDigit()
                    }
                    ProgressView(value: Double(mastered), total: Double(max(phrases.count, 1)))
                }
            }
        }

        Section("Recent") {
            if attempts.isEmpty {
                Text("No attempts yet.").foregroundStyle(.secondary)
            }
            ForEach(attempts.prefix(20)) { attempt in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(attempt.phraseText)
                        Text(attempt.date, format: .relative(presentation: .named))
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("\(attempt.score)").bold().foregroundStyle(Color.score(attempt.score))
                }
            }
        }
    }
}

private struct TrendRow: View {
    let title: String
    let now: String
    let before: String
    let change: Int?

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(before).foregroundStyle(.secondary).monospacedDigit()
            Image(systemName: "arrow.right").font(.caption).foregroundStyle(.secondary)
            Text(now).bold().monospacedDigit()
            if let change, change != 0 {
                Label("\(abs(change))", systemImage: change > 0 ? "arrow.up" : "arrow.down")
                    .labelStyle(.titleAndIcon)
                    .font(.caption.bold())
                    .foregroundStyle(change > 0 ? Color.green : Color.red)
            }
        }
    }
}

/// GitHub-style grid of the last five weeks, darker = more practice.
private struct ActivityCalendar: View {
    let practiceDays: Set<Date>
    let daily: [ProgressAnalytics.DayStat]

    var body: some View {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let counts = Dictionary(uniqueKeysWithValues: daily.map { ($0.day, $0.count) })
        // Start on the first weekday, five weeks back.
        let weekday = calendar.component(.weekday, from: today)
        let offset = (weekday - calendar.firstWeekday + 7) % 7
        let start = calendar.date(byAdding: .day, value: -(offset + 28), to: today)!
        let days = (0..<35).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
        let symbols = calendar.veryShortWeekdaySymbols
        let orderedSymbols = Array(symbols[(calendar.firstWeekday - 1)...] + symbols[..<(calendar.firstWeekday - 1)])

        VStack(spacing: 6) {
            HStack(spacing: 6) {
                ForEach(Array(orderedSymbols.enumerated()), id: \.offset) { _, symbol in
                    Text(symbol).font(.caption2).foregroundStyle(.secondary).frame(maxWidth: .infinity)
                }
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6) {
                ForEach(days, id: \.self) { day in
                    let count = counts[day] ?? (practiceDays.contains(day) ? 1 : 0)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(day > today ? Color.clear : color(for: count))
                        .overlay {
                            if day == today {
                                RoundedRectangle(cornerRadius: 4).stroke(Color.primary.opacity(0.5), lineWidth: 1.5)
                            }
                        }
                        .aspectRatio(1, contentMode: .fit)
                        .accessibilityLabel("\(day.formatted(date: .abbreviated, time: .omitted)): \(count) phrases")
                }
            }
            HStack(spacing: 4) {
                Spacer()
                Text("Less").font(.caption2).foregroundStyle(.secondary)
                ForEach([0, 3, 8, 15], id: \.self) { n in
                    RoundedRectangle(cornerRadius: 2).fill(color(for: n)).frame(width: 10, height: 10)
                }
                Text("More").font(.caption2).foregroundStyle(.secondary)
            }
        }
    }

    private func color(for count: Int) -> Color {
        switch count {
        case 0: Color.secondary.opacity(0.12)
        case 1...4: Color.accentColor.opacity(0.35)
        case 5...11: Color.accentColor.opacity(0.65)
        default: Color.accentColor
        }
    }
}

// MARK: - Improve

private struct ImproveSections: View {
    let analytics: ProgressAnalytics

    var body: some View {
        if !analytics.hasEnoughData {
            Section {
                ContentUnavailableView {
                    Label("Keep practising", systemImage: "chart.bar.doc.horizontal")
                } description: {
                    Text("Say at least \(ProgressAnalytics.minimumAttempts) phrases and Parle will show you which sounds and words to work on. You've done \(analytics.totalAttempts) so far.")
                }
            }
        } else {
            let tips = analytics.recommendations
            Section {
                if tips.isEmpty {
                    Label("Nothing stands out — you're pronouncing everything well. Try a harder unit!", systemImage: "hands.clap")
                }
                ForEach(Array(tips.enumerated()), id: \.offset) { _, tip in
                    Label(tip, systemImage: "lightbulb")
                }
            } header: {
                Text("Coach's notes")
            }

            Section {
                if analytics.weakSounds.isEmpty {
                    Text("No sound is giving you consistent trouble yet. 🎉").foregroundStyle(.secondary)
                }
                ForEach(analytics.weakSounds.prefix(5)) { issue in
                    NavigationLink {
                        SoundLessonView(lesson: issue.lesson)
                    } label: {
                        SoundIssueRow(issue: issue)
                    }
                }
            } header: {
                Text("Sounds to work on")
            } footer: {
                Text("Worked out from the words the speech recogniser didn't understand. Tap a sound for a drill.")
            }

            if !analytics.weakWords.isEmpty {
                Section {
                    FlowLayout(spacing: 8, lineSpacing: 8) {
                        ForEach(analytics.weakWords) { word in
                            Button {
                                Speaker.shared.speak(word.word, slow: true)
                            } label: {
                                HStack(spacing: 4) {
                                    Text(word.word).font(.body.weight(.semibold))
                                    Text("\(word.misses)/\(word.attempts)").font(.caption2).foregroundStyle(.secondary)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.score(1 - word.missRate).opacity(0.18), in: Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)

                    NavigationLink {
                        PracticeSessionView(title: "Tricky words",
                                            phrases: analytics.weakWords.map { Phrase(french: $0.word, english: "Missed \($0.misses) of \($0.attempts) times") })
                    } label: {
                        Label("Practise these words", systemImage: "mic.fill").foregroundStyle(Color.accentColor)
                    }
                } header: {
                    Text("Words you miss most")
                } footer: {
                    Text("Tap a word to hear it slowly. The number shows misses out of attempts.")
                }
            }

            if !analytics.weakPhrases.isEmpty {
                Section {
                    ForEach(analytics.weakPhrases) { stat in
                        NavigationLink {
                            PracticeSessionView(title: "Practice", phrases: [Phrase(french: stat.text, english: stat.english)])
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(stat.text)
                                    Text("\(stat.attempts) tries · last \(stat.latest)")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                ScoreRing(score: stat.best, size: 36)
                            }
                        }
                    }
                    NavigationLink {
                        PracticeSessionView(title: "Review",
                                            phrases: analytics.weakPhrases.map { Phrase(french: $0.text, english: $0.english) })
                    } label: {
                        Label("Review all \(analytics.weakPhrases.count)", systemImage: "arrow.counterclockwise")
                            .foregroundStyle(Color.accentColor)
                    }
                } header: {
                    Text("Phrases to review")
                } footer: {
                    Text("Your best score on these is still under \(ProgressSummary.masteryThreshold).")
                }
            }
        }
    }
}

private struct SoundIssueRow: View {
    let issue: ProgressAnalytics.SoundIssue

    var body: some View {
        HStack(spacing: 12) {
            Text(issue.lesson.symbol)
                .font(.system(.headline, design: .serif))
                .frame(width: 56, height: 40)
                .background(Color.score(1 - issue.missRate).opacity(0.18), in: RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 4) {
                Text(issue.lesson.title).font(.headline)
                ProgressView(value: issue.missRate)
                    .tint(Color.score(1 - issue.missRate))
                Text("Missed in \(issue.misses) of \(issue.total) words: \(issue.missedWords.joined(separator: ", "))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct StatTile: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Image(systemName: icon).foregroundStyle(color)
            Text(value).font(.title2.bold()).monospacedDigit().minimumScaleFactor(0.6).lineLimit(1)
            Text(label).font(.caption).foregroundStyle(.secondary).lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 14))
    }
}
