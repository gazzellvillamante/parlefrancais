#if DEBUG
import Foundation
import SwiftData

/// Fills an empty store with three weeks of realistic practice so screens can
/// be checked in the simulator. Launch with `-seedDemoData YES`. Debug builds only.
enum DemoData {
    static var requestedUnit: LessonUnit? {
        guard let id = UserDefaults.standard.string(forKey: "openUnit") else { return nil }
        return PhraseLibrary.units.first { $0.id == id }
    }

    static func seedIfRequested(_ context: ModelContext) {
        guard UserDefaults.standard.bool(forKey: "seedDemoData") else { return }
        let existing = (try? context.fetchCount(FetchDescriptor<Attempt>())) ?? 0
        guard existing == 0 else { return }

        var rng = SeededGenerator(seed: 42)
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let phrases = PhraseLibrary.units.prefix(8).flatMap(\.phrases)

        for daysAgo in (0..<21).reversed() {
            // Skip a few days so the calendar and streak look real.
            if [4, 9, 10, 15].contains(daysAgo) { continue }
            guard let day = calendar.date(byAdding: .day, value: -daysAgo, to: today) else { continue }
            // Skill improves over time: fewer slips on recent days.
            let slipRate = 0.12 + Double(daysAgo) * 0.012
            for _ in 0..<Int.random(in: 4...12, using: &rng) {
                guard let phrase = phrases.randomElement(using: &rng) else { continue }
                let heard = mispronounce(phrase.french, slipRate: slipRate, rng: &rng)
                let hour = [8, 9, 13, 18, 19, 20, 22].randomElement(using: &rng) ?? 19
                let date = calendar.date(bySettingHour: hour, minute: Int.random(in: 0...59, using: &rng), second: 0, of: day) ?? day
                let score = PronunciationScorer.score(target: phrase.french, heard: heard).score
                context.insert(Attempt(phraseText: phrase.french, heard: heard, score: score, date: date))
            }
        }
        try? context.save()
    }

    /// Simulates typical learner errors: French R, u/ou and nasal vowels.
    private static func mispronounce(_ text: String, slipRate: Double, rng: inout SeededGenerator) -> String {
        text.split(separator: " ").map { word -> String in
            var w = String(word).lowercased().trimmingCharacters(in: .punctuationCharacters)
            guard Double.random(in: 0...1, using: &rng) < slipRate * 2 else { return w }
            if w.contains("r") { w = w.replacingOccurrences(of: "r", with: "l") }
            else if w.contains("u") && !w.contains("ou") { w = w.replacingOccurrences(of: "u", with: "ou") }
            else if w.hasSuffix("on") { w = String(w.dropLast()) }
            else if w.contains("an") { w = w.replacingOccurrences(of: "an", with: "a") }
            return w
        }.joined(separator: " ")
    }
}

struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}
#endif
