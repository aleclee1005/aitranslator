import Foundation

class TranslationService {
    static func translate(text: String, from source: Language, to target: Language) async throws -> String {
        let system = "/no_think You are a professional meeting interpreter. Translate the following \(source.llmName) text to \(target.llmName). Output ONLY the translation, nothing else."
        do {
            return try await GroqClient.complete(system: system, user: text, maxTokens: 500)
        } catch let e as GroqError {
            throw TranslationError(from: e)
        }
    }
}

enum TranslationError: LocalizedError {
    case missingAPIKey, noResponse, apiError(String)

    init(from error: GroqError) {
        switch error {
        case .missingAPIKey:     self = .missingAPIKey
        case .noResponse:        self = .noResponse
        case .apiError(let msg): self = .apiError(msg)
        }
    }

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return String(localized: "Groq API Key is not set. Please enter it in Settings.")
        case .noResponse:
            return String(localized: "No translation response. Please try again.")
        case .apiError(let msg):
            return "\(String(localized: "API Error")): \(msg)"
        }
    }
}
