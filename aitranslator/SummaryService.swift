import Foundation

class SummaryService {
    static func summarize(entries: [TranscriptEntry], in language: Language) async throws -> String {
        let transcript = entries.enumerated().map { i, e in
            "\(i + 1). \(e.original) → \(e.translation)"
        }.joined(separator: "\n")

        let system = "/no_think You are a professional meeting secretary. Based on the transcript, write a structured meeting summary in \(language.llmName) with these sections: Key Topics, Key Decisions, Action Items. Be concise and professional."

        do {
            return try await GroqClient.complete(system: system, user: transcript, maxTokens: 800)
        } catch let e as GroqError {
            throw SummaryError(from: e)
        }
    }
}

enum SummaryError: LocalizedError {
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
            return String(localized: "No summary response. Please try again.")
        case .apiError(let msg):
            return "\(String(localized: "API Error")): \(msg)"
        }
    }
}
