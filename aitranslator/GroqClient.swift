import Foundation

struct GroqClient {
    private static let endpoint = URL(string: "https://api.groq.com/openai/v1/chat/completions")!
    private static let model    = "qwen/qwen3-32b"
    private static let timeout: TimeInterval = 30

    static func complete(
        system: String,
        user: String,
        maxTokens: Int = 500
    ) async throws -> String {
        guard let apiKey = KeychainService.load(key: "groq_api_key"), !apiKey.isEmpty else {
            throw GroqError.missingAPIKey
        }

        var request = URLRequest(url: endpoint, timeoutInterval: timeout)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": system],
                ["role": "user",   "content": user]
            ],
            "max_tokens": maxTokens,
            "temperature": 0.3,
            "reasoning_effort": "none"
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let err  = json["error"] as? [String: Any],
               let msg  = err["message"] as? String {
                throw GroqError.apiError(msg)
            }
            throw GroqError.apiError("HTTP \(http.statusCode)")
        }

        let decoded = try JSONDecoder().decode(Response.self, from: data)
        guard let content = decoded.choices.first?.message.content, !content.isEmpty else {
            throw GroqError.noResponse
        }
        return stripThinkTags(content).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func stripThinkTags(_ text: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: "<think>[\\s\\S]*?</think>") else {
            return text
        }
        var result = regex.stringByReplacingMatches(
            in: text, range: NSRange(text.startIndex..., in: text), withTemplate: ""
        )
        if let range = result.range(of: "<think>") {
            result = String(result[..<range.lowerBound])
        }
        return result
    }

    private struct Response: Decodable {
        struct Choice: Decodable {
            struct Message: Decodable { let content: String }
            let message: Message
        }
        let choices: [Choice]
    }
}

enum GroqError: LocalizedError {
    case missingAPIKey, noResponse, apiError(String)
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return String(localized: "Groq API Key is not set. Please enter it in Settings.")
        case .noResponse:
            return String(localized: "No response. Please try again.")
        case .apiError(let msg):
            return "\(String(localized: "API Error")): \(msg)"
        }
    }
}
