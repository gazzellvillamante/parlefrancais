import Foundation

struct WordScore: Identifiable, Hashable {
    let id: Int
    /// The word as written in the target phrase (with punctuation).
    let display: String
    /// The word stripped of punctuation, for text-to-speech.
    let spoken: String
    /// 0...1
    let score: Double
}

struct PronunciationResult: Hashable {
    let target: String
    let heard: String
    let score: Int
    let words: [WordScore]

    var headline: String {
        switch score {
        case 90...: "Excellent !"
        case 75..<90: "Très bien !"
        case 50..<75: "Pas mal — try again"
        case 1..<50: "Keep practising"
        default: "I didn't catch that"
        }
    }

    var missedWords: [WordScore] { words.filter { $0.score < 0.6 } }
}

/// Compares what speech recognition heard with the target phrase.
///
/// Speech recognition only returns words, so the score reflects how
/// intelligible each word was to a French recogniser: words that were
/// mis-heard are usually the ones that were mispronounced.
enum PronunciationScorer {
    private static let french = Locale(identifier: "fr_FR")

    private static let spellOut: NumberFormatter = {
        let f = NumberFormatter()
        f.locale = french
        f.numberStyle = .spellOut
        return f
    }()

    static func score(target: String, heard: String) -> PronunciationResult {
        let displayWords = target.split(whereSeparator: { $0.isWhitespace }).map(String.init)
        // Each display word may contain several tokens ("l'homme" -> "l", "homme").
        var targetTokens: [String] = []
        var owner: [Int] = []
        for (index, word) in displayWords.enumerated() {
            for token in tokens(word) {
                targetTokens.append(token)
                owner.append(index)
            }
        }
        let heardTokens = tokens(heard)
        // Near-misses ("roue" for "rue") are real mistakes, so only close
        // matches keep a high score.
        let tokenScores = align(targetTokens, heardTokens).map { s in
            s >= 0.95 ? s : max(0, (s - 0.5) / 0.5) * 0.8
        }

        var words: [WordScore] = []
        for (index, word) in displayWords.enumerated() {
            let scores = zip(owner, tokenScores).filter { $0.0 == index }.map { $0.1 }
            let spoken = word.trimmingCharacters(in: .punctuationCharacters.union(.symbols))
            // Pure punctuation ("!", "?") carries no score of its own.
            guard !scores.isEmpty else {
                words.append(WordScore(id: index, display: word, spoken: spoken, score: 1))
                continue
            }
            words.append(WordScore(id: index, display: word, spoken: spoken,
                                   score: scores.reduce(0, +) / Double(scores.count)))
        }

        let overall = tokenScores.isEmpty ? 0 : tokenScores.reduce(0, +) / Double(tokenScores.count)
        // Penalise lots of extra words a little (rambling or a different sentence).
        let extra = max(0, heardTokens.count - targetTokens.count)
        let penalty = targetTokens.isEmpty ? 0 : min(0.3, Double(extra) / Double(targetTokens.count) * 0.3)
        let final = Int((max(0, overall - penalty) * 100).rounded())

        return PronunciationResult(target: target, heard: heard, score: heardTokens.isEmpty ? 0 : final, words: words)
    }

    /// Lower-cased, accent-folded word tokens, with digits spelled out.
    static func tokens(_ text: String) -> [String] {
        let raw = text
            .lowercased()
            .replacingOccurrences(of: "’", with: "'")
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }

        var result: [String] = []
        for token in raw {
            if let number = Int(token), let words = spellOut.string(from: NSNumber(value: number)) {
                result.append(contentsOf: tokens(words))
            } else {
                result.append(token.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: french))
            }
        }
        return result
    }

    /// Needleman–Wunsch style alignment maximising total similarity.
    /// Returns a 0...1 score for each target token.
    private static func align(_ target: [String], _ heard: [String]) -> [Double] {
        let n = target.count, m = heard.count
        guard n > 0 else { return [] }
        guard m > 0 else { return Array(repeating: 0, count: n) }

        var sim = Array(repeating: Array(repeating: 0.0, count: m), count: n)
        for i in 0..<n {
            for j in 0..<m { sim[i][j] = similarity(target[i], heard[j]) }
        }

        var dp = Array(repeating: Array(repeating: 0.0, count: m + 1), count: n + 1)
        for i in 1...n {
            for j in 1...m {
                var best = max(dp[i - 1][j], dp[i][j - 1])
                if sim[i - 1][j - 1] >= 0.5 {
                    best = max(best, dp[i - 1][j - 1] + sim[i - 1][j - 1])
                }
                dp[i][j] = best
            }
        }

        var scores = Array(repeating: 0.0, count: n)
        var i = n, j = m
        while i > 0 && j > 0 {
            let s = sim[i - 1][j - 1]
            if s >= 0.5 && dp[i][j] == dp[i - 1][j - 1] + s {
                scores[i - 1] = s
                i -= 1; j -= 1
            } else if dp[i][j] == dp[i - 1][j] {
                i -= 1
            } else {
                j -= 1
            }
        }
        return scores
    }

    private static func similarity(_ a: String, _ b: String) -> Double {
        if a == b { return 1 }
        // Homophones the recogniser may pick instead ("vin"/"vingt", "parlé"/"parler").
        if soundKey(a) == soundKey(b) { return 0.95 }
        let longest = max(a.count, b.count)
        guard longest > 0 else { return 1 }
        return 1 - Double(levenshtein(Array(a), Array(b))) / Double(longest)
    }

    /// A rough French phonetic key: merges common spellings of the same sound
    /// and drops usually-silent endings.
    private static func soundKey(_ word: String) -> String {
        var s = word
        let replacements = [("eaux", "o"), ("eau", "o"), ("aux", "o"), ("au", "o"), ("ph", "f"), ("qu", "k"),
                            ("ch", "§"), ("h", ""), ("§", "ch"), ("ai", "e"), ("ei", "e")]
        for (from, to) in replacements {
            s = s.replacingOccurrences(of: from, with: to)
        }
        for suffix in ["ez", "er", "et"] where s.count > 3 && s.hasSuffix(suffix) {
            s = String(s.dropLast(2)) + "e"
            break
        }
        while s.count > 1, let last = s.last, "stxdzpg".contains(last) { s.removeLast() }
        if s.count > 2, s.hasSuffix("e") { s.removeLast() }
        var collapsed = ""
        for c in s where collapsed.last != c { collapsed.append(c) }
        return collapsed
    }

    private static func levenshtein(_ a: [Character], _ b: [Character]) -> Int {
        if a.isEmpty { return b.count }
        if b.isEmpty { return a.count }
        var previous = Array(0...b.count)
        var current = Array(repeating: 0, count: b.count + 1)
        for i in 1...a.count {
            current[0] = i
            for j in 1...b.count {
                let cost = a[i - 1] == b[j - 1] ? 0 : 1
                current[j] = min(previous[j] + 1, current[j - 1] + 1, previous[j - 1] + cost)
            }
            swap(&previous, &current)
        }
        return previous[b.count]
    }
}
