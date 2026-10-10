import Foundation
import SwiftData

/// A French phrase to practise. Identity is the French text, so attempts,
/// custom phrases and built-in content all link up by the same key.
struct Phrase: Identifiable, Hashable {
    let french: String
    let english: String
    var tip: String? = nil

    var id: String { french }
}

enum Level: Int, CaseIterable, Identifiable, Comparable {
    case beginner, elementary, intermediate, advanced

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .beginner: "Beginner"
        case .elementary: "Elementary"
        case .intermediate: "Intermediate"
        case .advanced: "Advanced"
        }
    }

    var blurb: String {
        switch self {
        case .beginner: "I'm just starting out"
        case .elementary: "I know some basic phrases"
        case .intermediate: "I can hold a simple conversation"
        case .advanced: "I want to sound more natural"
        }
    }

    var cefr: String {
        switch self {
        case .beginner: "A1"
        case .elementary: "A2"
        case .intermediate: "B1"
        case .advanced: "B2+"
        }
    }

    static func < (lhs: Level, rhs: Level) -> Bool { lhs.rawValue < rhs.rawValue }
}

struct LessonUnit: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let icon: String
    let level: Level
    let phrases: [Phrase]
}

/// One spoken attempt at a phrase.
@Model
final class Attempt {
    var phraseText: String
    var heard: String
    var score: Int
    var date: Date

    init(phraseText: String, heard: String, score: Int, date: Date = .now) {
        self.phraseText = phraseText
        self.heard = heard
        self.score = score
        self.date = date
    }
}

/// A sentence the user added themselves.
@Model
final class CustomPhrase {
    var french: String
    var english: String
    var createdAt: Date

    init(french: String, english: String, createdAt: Date = .now) {
        self.french = french
        self.english = english
        self.createdAt = createdAt
    }

    var phrase: Phrase { Phrase(french: french, english: english) }
}

/// Derived statistics over all attempts.
struct ProgressSummary {
    let bestScores: [String: Int]
    let streak: Int
    let practicedToday: Int
    let totalAttempts: Int
    let averageScore: Int

    static let masteryThreshold = 80

    init(attempts: [Attempt], calendar: Calendar = .current) {
        var best: [String: Int] = [:]
        for a in attempts { best[a.phraseText] = max(best[a.phraseText] ?? 0, a.score) }
        bestScores = best
        totalAttempts = attempts.count
        averageScore = attempts.isEmpty ? 0 : attempts.map(\.score).reduce(0, +) / attempts.count

        let today = calendar.startOfDay(for: .now)
        practicedToday = attempts.filter { calendar.startOfDay(for: $0.date) == today }.count

        let days = Set(attempts.map { calendar.startOfDay(for: $0.date) })
        var streak = 0
        // A streak stays alive today even if the user hasn't practised yet.
        var day = days.contains(today) ? today : calendar.date(byAdding: .day, value: -1, to: today)!
        while days.contains(day) {
            streak += 1
            day = calendar.date(byAdding: .day, value: -1, to: day)!
        }
        self.streak = streak
    }

    func mastered(_ phrases: [Phrase]) -> Int {
        phrases.filter { (bestScores[$0.french] ?? 0) >= Self.masteryThreshold }.count
    }

    func isMastered(_ phrase: Phrase) -> Bool {
        (bestScores[phrase.french] ?? 0) >= Self.masteryThreshold
    }
}
