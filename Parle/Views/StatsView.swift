import Charts
import SwiftData
import SwiftUI

struct StatsView: View {
    @Query(sort: \Attempt.date, order: .reverse) private var attempts: [Attempt]

    private struct DayPoint: Identifiable {
        let day: Date
        let average: Double
        let count: Int
        var id: Date { day }
    }

    var body: some View {
        let summary = ProgressSummary(attempts: attempts)
        NavigationStack {
            List {
                Section {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        StatTile(value: "\(summary.streak)", label: "Day streak", icon: "flame.fill", color: .orange)
                        StatTile(value: "\(summary.mastered(PhraseLibrary.allPhrases))", label: "Phrases mastered", icon: "checkmark.seal.fill", color: .green)
                        StatTile(value: "\(summary.totalAttempts)", label: "Phrases spoken", icon: "mic.fill", color: .blue)
                        StatTile(value: "\(summary.averageScore)", label: "Average score", icon: "target", color: .purple)
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }

                Section("Last 14 days") {
                    let points = dailyPoints()
                    if points.isEmpty {
                        Text("Practise a few phrases to see your progress here.")
                            .foregroundStyle(.secondary)
                    } else {
                        Chart(points) { point in
                            BarMark(x: .value("Day", point.day, unit: .day), y: .value("Average score", point.average))
                                .foregroundStyle(Color.score(Int(point.average)))
                                .cornerRadius(4)
                        }
                        .chartYScale(domain: 0...100)
                        .frame(height: 180)
                        .padding(.vertical, 8)
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
                    ForEach(attempts.prefix(30)) { attempt in
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
            .navigationTitle("Progress")
        }
    }

    private func dailyPoints() -> [DayPoint] {
        let calendar = Calendar.current
        let start = calendar.date(byAdding: .day, value: -13, to: calendar.startOfDay(for: .now))!
        let recent = attempts.filter { $0.date >= start }
        let grouped = Dictionary(grouping: recent) { calendar.startOfDay(for: $0.date) }
        return grouped.map { day, items in
            DayPoint(day: day, average: Double(items.map(\.score).reduce(0, +)) / Double(items.count), count: items.count)
        }
        .sorted { $0.day < $1.day }
    }
}

private struct StatTile: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon).foregroundStyle(color)
            Text(value).font(.title.bold()).monospacedDigit()
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16))
    }
}
