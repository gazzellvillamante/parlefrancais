import Foundation

/// Analysis of every saved attempt: trends, activity, and the words and
/// French sounds the learner keeps getting wrong.
struct ProgressAnalytics {
    struct DayStat: Identifiable {
        let day: Date
        let average: Double
        let count: Int
        var id: Date { day }
    }

    struct Trend {
        let thisWeekAverage: Int?
        let lastWeekAverage: Int?
        let thisWeekCount: Int
        let lastWeekCount: Int

        var scoreChange: Int? {
            guard let now = thisWeekAverage, let before = lastWeekAverage else { return nil }
            return now - before
        }
    }

    struct WordIssue: Identifiable {
        let word: String
        let misses: Int
        let attempts: Int
        var id: String { word }
        var missRate: Double { Double(misses) / Double(max(attempts, 1)) }
    }

    struct SoundIssue: Identifiable {
        let lesson: SoundLesson
        let misses: Int
        let total: Int
        let missedWords: [String]
        var id: String { lesson.id }
        var missRate: Double { Double(misses) / Double(max(total, 1)) }
    }

    struct PhraseStat: Identifiable {
        let text: String
        let english: String
        let best: Int
        let latest: Int
        let attempts: Int
        var id: String { text }
    }

    struct UnitStat: Identifiable {
        let unit: LessonUnit
        let average: Int
        let attempts: Int
        var id: String { unit.id }
    }

    struct TimeOfDayStat: Identifiable {
        let label: String
        let average: Int
        let count: Int
        var id: String { label }
    }

    /// Minimum attempts before personalised advice is shown.
    static let minimumAttempts = 5

    let totalAttempts: Int
    let daily: [DayStat]
    let trend: Trend
    /// Average gain from the first attempt at a phrase to the best one.
    let averageImprovement: Int?
    let weakWords: [WordIssue]
    let weakSounds: [SoundIssue]
    let weakPhrases: [PhraseStat]
    let unitStats: [UnitStat]
    let timeOfDay: [TimeOfDayStat]
    let practiceDays: Set<Date>

    var hasEnoughData: Bool { totalAttempts >= Self.minimumAttempts }
    var bestTimeOfDay: TimeOfDayStat? {
        timeOfDay.filter { $0.count >= 3 }.max { $0.average < $1.average }
    }

    init(attempts: [Attempt], calendar: Calendar = .current, now: Date = .now) {
        totalAttempts = attempts.count
        let today = calendar.startOfDay(for: now)

        // Daily averages, last 30 days.
        let monthStart = calendar.date(byAdding: .day, value: -29, to: today)!
        let byDay = Dictionary(grouping: attempts.filter { $0.date >= monthStart }) { calendar.startOfDay(for: $0.date) }
        daily = byDay.map { day, items in
            DayStat(day: day, average: Double(items.map(\.score).reduce(0, +)) / Double(items.count), count: items.count)
        }
        .sorted { $0.day < $1.day }
        practiceDays = Set(attempts.map { calendar.startOfDay(for: $0.date) })

        // This week vs last week.
        let weekStart = calendar.date(byAdding: .day, value: -6, to: today)!
        let lastWeekStart = calendar.date(byAdding: .day, value: -13, to: today)!
        let thisWeek = attempts.filter { $0.date >= weekStart }
        let lastWeek = attempts.filter { $0.date >= lastWeekStart && $0.date < weekStart }
        trend = Trend(thisWeekAverage: Self.average(thisWeek.map(\.score)),
                      lastWeekAverage: Self.average(lastWeek.map(\.score)),
                      thisWeekCount: thisWeek.count,
                      lastWeekCount: lastWeek.count)

        // Per-phrase history.
        let byPhrase = Dictionary(grouping: attempts, by: \.phraseText)
        let english = Dictionary(PhraseLibrary.allPhrases.map { ($0.french, $0.english) }, uniquingKeysWith: { a, _ in a })
        var gains: [Int] = []
        var phraseStats: [PhraseStat] = []
        for (text, items) in byPhrase {
            let sorted = items.sorted { $0.date < $1.date }
            let best = sorted.map(\.score).max() ?? 0
            if sorted.count >= 2, let first = sorted.first { gains.append(best - first.score) }
            phraseStats.append(PhraseStat(text: text, english: english[text] ?? "", best: best,
                                          latest: sorted.last?.score ?? 0, attempts: sorted.count))
        }
        averageImprovement = Self.average(gains)
        weakPhrases = phraseStats
            .filter { $0.best < ProgressSummary.masteryThreshold }
            .sorted { ($0.best, -$0.attempts) < ($1.best, -$1.attempts) }
            .prefix(8).map { $0 }

        // Per-unit averages.
        unitStats = PhraseLibrary.units.compactMap { unit in
            let scores = unit.phrases.flatMap { byPhrase[$0.french] ?? [] }.map(\.score)
            guard let average = Self.average(scores) else { return nil }
            return UnitStat(unit: unit, average: average, attempts: scores.count)
        }

        // Time of day.
        let buckets: [(String, ClosedRange<Int>)] = [("Morning", 5...11), ("Afternoon", 12...16), ("Evening", 17...21)]
        let byBucket = Dictionary(grouping: attempts) { attempt -> String in
            let hour = calendar.component(.hour, from: attempt.date)
            return buckets.first { $0.1.contains(hour) }?.0 ?? "Night"
        }
        timeOfDay = (buckets.map(\.0) + ["Night"]).compactMap { label in
            guard let items = byBucket[label], let average = Self.average(items.map(\.score)) else { return nil }
            return TimeOfDayStat(label: label, average: average, count: items.count)
        }

        // Word and sound analysis: re-score recent attempts word by word.
        var wordTotals: [String: (misses: Int, attempts: Int)] = [:]
        var soundTotals: [String: (misses: Int, total: Int, words: [String])] = [:]
        for attempt in attempts.sorted(by: { $0.date > $1.date }).prefix(400) where !attempt.heard.isEmpty {
            let result = PronunciationScorer.score(target: attempt.phraseText, heard: attempt.heard)
            for word in result.words {
                let key = word.spoken.lowercased()
                guard key.count > 1 else { continue }
                let missed = word.score < 0.6
                var w = wordTotals[key] ?? (0, 0)
                w.attempts += 1
                if missed { w.misses += 1 }
                wordTotals[key] = w

                for sound in SoundDetector.sounds(in: key) {
                    var s = soundTotals[sound] ?? (0, 0, [])
                    s.total += 1
                    if missed {
                        s.misses += 1
                        if !s.words.contains(key) { s.words.append(key) }
                    }
                    soundTotals[sound] = s
                }
            }
        }

        weakWords = wordTotals
            .filter { $0.value.misses > 0 }
            .map { WordIssue(word: $0.key, misses: $0.value.misses, attempts: $0.value.attempts) }
            .sorted { ($0.missRate, $0.misses) > ($1.missRate, $1.misses) }
            .prefix(12).map { $0 }

        let lessons = Dictionary(uniqueKeysWithValues: SoundLibrary.lessons.map { ($0.id, $0) })
        weakSounds = soundTotals.compactMap { id, value -> SoundIssue? in
            guard let lesson = lessons[id], value.total >= 3, value.misses > 0 else { return nil }
            return SoundIssue(lesson: lesson, misses: value.misses, total: value.total, missedWords: Array(value.words.prefix(6)))
        }
        .sorted { $0.missRate > $1.missRate }
    }

    private static func average(_ values: [Int]) -> Int? {
        values.isEmpty ? nil : values.reduce(0, +) / values.count
    }

    /// Plain-language advice, most important first.
    var recommendations: [String] {
        var tips: [String] = []
        if let sound = weakSounds.first, sound.missRate >= 0.25 {
            tips.append("Biggest focus: \(sound.lesson.title) \(sound.lesson.symbol). \(sound.misses) of \(sound.total) words with this sound weren't understood — open its drill below.")
        }
        if let word = weakWords.first, word.attempts >= 2 {
            tips.append("“\(word.word)” was misheard \(word.misses) of \(word.attempts) times — tap it below to hear it slowly, then repeat.")
        }
        if let change = trend.scoreChange {
            if change >= 5 {
                tips.append("Your scores are up \(change) points on last week. Keep it going!")
            } else if change <= -5 {
                tips.append("Scores dipped \(-change) points this week — try slowing down and using the 🐢 slow playback before speaking.")
            }
        }
        if trend.thisWeekCount < trend.lastWeekCount / 2, trend.lastWeekCount > 0 {
            tips.append("You practised less this week (\(trend.thisWeekCount) vs \(trend.lastWeekCount) phrases). Short daily sessions beat long weekly ones.")
        }
        if let best = bestTimeOfDay, timeOfDay.count > 1 {
            tips.append("You score best in the \(best.label.lowercased()) (average \(best.average)).")
        }
        if let weakest = unitStats.filter({ $0.attempts >= 3 }).min(by: { $0.average < $1.average }), weakest.average < 70 {
            tips.append("Your weakest unit is “\(weakest.unit.title)” (average \(weakest.average)). Revisit it once more.")
        }
        return tips
    }
}

/// Spots which French sounds a written word contains, by spelling.
/// It's a heuristic — French spelling is regular enough for practice advice.
enum SoundDetector {
    private static let vowels = Set("aeiouyéèêëàâîïôûùœ")

    static func sounds(in word: String) -> Set<String> {
        let w = word.lowercased().replacingOccurrences(of: "’", with: "'")
        var found = Set<String>()

        if w.contains("r") { found.insert("r") }
        if w.contains("gn") { found.insert("gn") }
        if w.contains("ch") || w.contains("j") || hasSoftG(w) { found.insert("j") }
        if w.contains("ill") || hasVowelY(w) { found.insert("ill") }
        if w.contains("ou") || w.contains("où") || w.contains("oû") { found.insert("u") }
        if w.contains("eu") || w.contains("œu") { found.insert(w.range(of: #"(eu|œu)[rlfn]"#, options: .regularExpression) != nil ? "oe" : "eu") }
        // "ai" sounds like è, except in the nasal "ain"/"aim" ("pain", "faim").
        if w.contains("é") || w.contains("è") || w.contains("ê")
            || w.range(of: #"ai([^nm]|$|[nm][aeiouyéè])"#, options: .regularExpression) != nil { found.insert("e") }

        // Nasal vowels: vowel + n/m not followed by a vowel or another n/m.
        if hasNasal(w, ["ain", "ein", "ien", "in", "im", "un", "um", "yn"]) { found.insert("in") }
        if hasNasal(w, ["on", "om"]) { found.insert("on") }
        if hasNasal(w, ["an", "am", "en", "em"], excluding: ["ien"]) { found.insert("an") }

        if hasFrenchU(w) { found.insert("y") }
        return found
    }

    /// A lone "u" (not part of ou/eu/au/qu/gu or a nasal "un").
    private static func hasFrenchU(_ w: String) -> Bool {
        let chars = Array(w)
        for (i, c) in chars.enumerated() where c == "u" || c == "û" {
            let previous = i > 0 ? chars[i - 1] : " "
            let next = i + 1 < chars.count ? chars[i + 1] : " "
            if "oeaqgœ".contains(previous) { continue }
            if (next == "n" || next == "m") && (i + 2 >= chars.count || !vowels.contains(chars[i + 2])) { continue }
            return true
        }
        return false
    }

    private static func hasSoftG(_ w: String) -> Bool {
        w.range(of: #"g[eiyéè]"#, options: .regularExpression) != nil
    }

    private static func hasVowelY(_ w: String) -> Bool {
        w.range(of: #"[aeiou]y[aeiou]"#, options: .regularExpression) != nil
    }

    private static func hasNasal(_ w: String, _ patterns: [String], excluding: [String] = []) -> Bool {
        for pattern in patterns {
            var searchStart = w.startIndex
            while let range = w.range(of: pattern, range: searchStart..<w.endIndex) {
                searchStart = w.index(after: range.lowerBound)
                // Skip matches that are really part of an excluded spelling ("bien" isn't "an").
                if excluding.contains(where: { ex in
                    guard let exRange = w.range(of: ex) else { return false }
                    return exRange.overlaps(range)
                }) { continue }
                // A preceding vowel means a different spelling ("ain", "oin") already handled.
                if range.lowerBound > w.startIndex, pattern.count == 2 {
                    let before = w.index(before: range.lowerBound)
                    let previous = w[before]
                    // "oin" is nasal; the "u" in "qu"/"gu" is silent ("quand").
                    let silentU = previous == "u" && before > w.startIndex && "qg".contains(w[w.index(before: before)])
                    if vowels.contains(previous) && !(previous == "o" && pattern.hasPrefix("i")) && !silentU { continue }
                }
                if range.upperBound == w.endIndex { return true }
                let next = w[range.upperBound]
                if !vowels.contains(next) && next != "n" && next != "m" && next != "h" { return true }
            }
        }
        return false
    }
}
