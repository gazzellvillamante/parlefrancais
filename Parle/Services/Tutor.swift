import Foundation
import Observation
import Security
#if canImport(FoundationModels)
import FoundationModels
#endif

struct ChatMessage: Identifiable, Equatable {
    enum Role { case user, assistant }
    let id = UUID()
    let role: Role
    let text: String
}

enum TutorScenario: String, CaseIterable, Identifiable {
    case free = "Free chat"
    case cafe = "At the café"
    case meeting = "Meeting someone"
    case directions = "Asking directions"
    case hotel = "Hotel check-in"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .free: "bubble.left.and.bubble.right"
        case .cafe: "cup.and.saucer"
        case .meeting: "person.2"
        case .directions: "map"
        case .hotel: "bed.double"
        }
    }

    var setup: String {
        switch self {
        case .free: "Have a relaxed conversation about the learner's day, interests and plans."
        case .cafe: "Role-play: you are a waiter in a Paris café and the learner is a customer ordering."
        case .meeting: "Role-play: you have just met the learner at a party in Lyon. Get to know each other."
        case .directions: "Role-play: you are a passer-by in Paris and the learner is a lost tourist asking for directions."
        case .hotel: "Role-play: you are a hotel receptionist in Nice and the learner is checking in."
        }
    }

    var opener: String {
        switch self {
        case .free: "Salut ! Comment ça va aujourd'hui ?"
        case .cafe: "Bonjour ! Qu'est-ce que je vous sers ?"
        case .meeting: "Salut ! Je m'appelle Camille. Et toi, comment tu t'appelles ?"
        case .directions: "Bonjour ! Vous avez l'air perdu. Je peux vous aider ?"
        case .hotel: "Bonsoir et bienvenue ! Vous avez une réservation ?"
        }
    }
}

enum TutorError: LocalizedError {
    case notConfigured
    case refused
    case api(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured: "No AI tutor is set up. See Settings › AI tutor."
        case .refused: "The tutor couldn't answer that. Try rephrasing."
        case .api(let message): message
        }
    }
}

enum TutorBackend: Equatable {
    case onDevice
    case claude
    case unavailable

    var label: String {
        switch self {
        case .onDevice: "Apple Intelligence (on-device, free)"
        case .claude: "Claude (your API key)"
        case .unavailable: "Not configured"
        }
    }
}

@Observable
final class TutorChat {
    private(set) var messages: [ChatMessage] = []
    private(set) var isThinking = false
    var errorMessage: String?
    private(set) var scenario: TutorScenario = .free

    @ObservationIgnored private var onDeviceSession: AnyObject?

    static var onDeviceAvailable: Bool {
        #if DEBUG
        // Mimics devices without Apple Intelligence, e.g. iPhone 14 Pro.
        if UserDefaults.standard.bool(forKey: "simulateNoAppleIntelligence") { return false }
        #endif
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            if case .available = SystemLanguageModel.default.availability { return true }
        }
        #endif
        return false
    }

    static var backend: TutorBackend {
        let preferClaude = UserDefaults.standard.bool(forKey: "preferClaude")
        let hasKey = !(Keychain.read(Keychain.claudeKey) ?? "").isEmpty
        if hasKey && (preferClaude || !onDeviceAvailable) { return .claude }
        if onDeviceAvailable { return .onDevice }
        return .unavailable
    }

    func start(_ scenario: TutorScenario, level: Level) {
        self.scenario = scenario
        errorMessage = nil
        onDeviceSession = nil
        messages = [ChatMessage(role: .assistant, text: scenario.opener)]
        currentLevel = level
    }

    @ObservationIgnored private var currentLevel: Level = .beginner

    private var instructions: String {
        """
        You are Parle, a warm, encouraging French conversation partner and pronunciation coach.
        The learner's level is \(currentLevel.title) (\(currentLevel.cefr)). \(scenario.setup)
        The learner usually speaks into a microphone, so their messages are speech-recognition \
        transcripts. Words that look wrong or out of place were probably mispronounced — when \
        you spot one, gently point it out and explain how to pronounce the intended word.
        Rules:
        - Reply in natural French suited to the learner's level, in 1–3 short sentences, and \
        end with a question to keep the conversation going.
        - If the learner made a mistake (grammar, vocabulary or likely pronunciation), add a \
        new line starting with "💡" and give a brief correction in English.
        - If the learner writes in English, help them say it in French.
        - Never use markdown headings or bullet lists.
        """
    }

    func send(_ text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isThinking else { return }
        messages.append(ChatMessage(role: .user, text: trimmed))
        isThinking = true
        errorMessage = nil
        defer { isThinking = false }

        do {
            let reply: String
            switch Self.backend {
            case .onDevice: reply = try await replyOnDevice(trimmed)
            case .claude: reply = try await replyWithClaude()
            case .unavailable: throw TutorError.notConfigured
            }
            messages.append(ChatMessage(role: .assistant, text: reply.trimmingCharacters(in: .whitespacesAndNewlines)))
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func replyOnDevice(_ text: String) async throws -> String {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            let session: LanguageModelSession
            if let existing = onDeviceSession as? LanguageModelSession {
                session = existing
            } else {
                // Seed the transcript with the opener so the model knows the context.
                session = LanguageModelSession(instructions: instructions + "\nYou opened the conversation with: \"\(scenario.opener)\"")
                onDeviceSession = session
            }
            let response = try await session.respond(to: text)
            return response.content
        }
        #endif
        throw TutorError.notConfigured
    }

    private func replyWithClaude() async throws -> String {
        guard let key = Keychain.read(Keychain.claudeKey), !key.isEmpty else { throw TutorError.notConfigured }
        let model = UserDefaults.standard.string(forKey: "claudeModel") ?? ClaudeClient.defaultModel
        // The API requires the conversation to start with a user turn.
        var history = messages
        if history.first?.role == .assistant {
            history.insert(ChatMessage(role: .user, text: "(Start the conversation.)"), at: 0)
        }
        return try await ClaudeClient(apiKey: key, model: model).reply(system: instructions, history: history)
    }
}

// MARK: - Claude Messages API

struct ClaudeClient {
    /// Haiku is fast and inexpensive, and plenty for conversation practice.
    static let defaultModel = "claude-haiku-5-5"
    struct Model: Identifiable {
        let id: String
        let name: String
        /// US dollars per million tokens (Anthropic list prices, Oct 2026).
        let inputPrice: Double
        let outputPrice: Double
        /// Typical cost of one tutor reply in a short conversation.
        let typicalMessageCost: String

        func cost(inputTokens: Int, outputTokens: Int) -> Double {
            (Double(inputTokens) * inputPrice + Double(outputTokens) * outputPrice) / 1_000_000
        }
    }

    static func model(_ id: String) -> Model {
        models.first { $0.id == id } ?? models[0]
    }

    static var selectedModel: Model {
        model(UserDefaults.standard.string(forKey: "claudeModel") ?? defaultModel)
    }

    static let models: [Model] = [
        Model(id: "claude-haiku-5-5", name: "Claude Haiku 5.5 (cheapest)",
              inputPrice: 0.10, outputPrice: 0.50, typicalMessageCost: "about $0.0002"),
        Model(id: "claude-sonnet-5-5", name: "Claude Sonnet 5.5",
              inputPrice: 2, outputPrice: 10, typicalMessageCost: "about $0.004"),
        Model(id: "claude-opus-5-5", name: "Claude Opus 5.5 (smartest)",
              inputPrice: 4, outputPrice: 20, typicalMessageCost: "about $0.007"),
    ]
    /// Models that accept server-side refusal fallbacks.
    private static let fallbackModels: Set<String> = ["claude-opus-5-5", "claude-sonnet-5-5"]

    let apiKey: String
    let model: String

    private struct Response: Decodable {
        struct Block: Decodable {
            let type: String
            let text: String?
        }
        struct Usage: Decodable {
            let input_tokens: Int
            let output_tokens: Int
        }
        let content: [Block]
        let stop_reason: String?
        let usage: Usage?
    }

    private struct APIErrorBody: Decodable {
        struct Detail: Decodable { let message: String }
        let error: Detail
    }

    func reply(system: String, history: [ChatMessage]) async throws -> String {
        var request = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
        request.httpMethod = "POST"
        request.timeoutInterval = 120
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        var body: [String: Any] = [
            "model": model,
            "max_tokens": 16000,
            "system": system,
            "output_config": ["effort": "low"],
            "messages": history.map { ["role": $0.role == .user ? "user" : "assistant", "content": $0.text] },
        ]
        if Self.fallbackModels.contains(model) {
            request.setValue("server-side-fallback-2026-07-01", forHTTPHeaderField: "anthropic-beta")
            body["fallbacks"] = "default"
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw TutorError.api("No response from Claude.") }
        guard http.statusCode == 200 else {
            let message = (try? JSONDecoder().decode(APIErrorBody.self, from: data))?.error.message
            throw TutorError.api("Claude error \(http.statusCode): \(message ?? "unknown error")")
        }

        let decoded = try JSONDecoder().decode(Response.self, from: data)
        if let usage = decoded.usage {
            // Every completed request is billed, even a refusal, so record it first.
            SpendTracker.record(Self.model(model).cost(inputTokens: usage.input_tokens, outputTokens: usage.output_tokens))
        }
        if decoded.stop_reason == "refusal" { throw TutorError.refused }
        let text = decoded.content.filter { $0.type == "text" }.compactMap(\.text).joined()
        guard !text.isEmpty else { throw TutorError.api("Claude returned an empty reply.") }
        return text
    }
}

// MARK: - Spending

/// Running estimate of Claude API spending this calendar month, worked out
/// from the token counts Claude returns. The exact bill is in the Anthropic Console.
enum SpendTracker {
    private static let monthKey = "spendMonth"
    private static let totalKey = "spendTotal"
    private static let countKey = "spendMessages"

    private static var currentMonth: String {
        let parts = Calendar.current.dateComponents([.year, .month], from: .now)
        return "\(parts.year ?? 0)-\(parts.month ?? 0)"
    }

    private static func resetIfNewMonth() {
        let defaults = UserDefaults.standard
        if defaults.string(forKey: monthKey) != currentMonth {
            defaults.set(currentMonth, forKey: monthKey)
            defaults.set(0.0, forKey: totalKey)
            defaults.set(0, forKey: countKey)
        }
    }

    static func record(_ cost: Double) {
        resetIfNewMonth()
        let defaults = UserDefaults.standard
        defaults.set(defaults.double(forKey: totalKey) + cost, forKey: totalKey)
        defaults.set(defaults.integer(forKey: countKey) + 1, forKey: countKey)
    }

    static var thisMonth: Double {
        resetIfNewMonth()
        return UserDefaults.standard.double(forKey: totalKey)
    }

    static var messagesThisMonth: Int {
        resetIfNewMonth()
        return UserDefaults.standard.integer(forKey: countKey)
    }

    static func format(_ dollars: Double) -> String {
        dollars < 0.01 && dollars > 0 ? String(format: "$%.4f", dollars) : String(format: "$%.2f", dollars)
    }
}

// MARK: - Keychain

enum Keychain {
    static let claudeKey = "claudeAPIKey"
    private static let service = "com.personal.parlefrancais"

    static func read(_ account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func save(_ value: String, for account: String) {
        let base: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(base as CFDictionary)
        guard !value.isEmpty else { return }
        var add = base
        add[kSecValueData as String] = Data(value.utf8)
        add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        SecItemAdd(add as CFDictionary, nil)
    }
}
