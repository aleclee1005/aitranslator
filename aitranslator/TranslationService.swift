import Foundation

class TranslationService {
    private static let model = "qwen/qwen3-32b"

    static func translate(text: String, from source: Language, to target: Language) async throws -> String {
        guard let apiKey = KeychainService.load(key: "groq_api_key"), !apiKey.isEmpty else {
            throw TranslationError.missingAPIKey
        }

        var request = URLRequest(url: URL(string: "https://api.groq.com/openai/v1/chat/completions")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let systemPrompt = "/no_think You are a professional meeting interpreter. Translate the following \(source.llmName) text to \(target.llmName). Output ONLY the translation, nothing else."

        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": text]
            ],
            "max_tokens": 500,
            "temperature": 0.3,
            "reasoning_effort": "none"
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        let raw = String(data: data, encoding: .utf8) ?? ""
        print("🤖 Translation raw: \(raw)")

        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = json["error"] as? [String: Any],
               let msg = error["message"] as? String {
                throw TranslationError.apiError(msg)
            }
            throw TranslationError.apiError("HTTP \(http.statusCode)")
        }

        let decoded = try JSONDecoder().decode(GroqResponse.self, from: data)
        guard let content = decoded.choices.first?.message.content, !content.isEmpty else {
            throw TranslationError.noResponse
        }
        return stripThinkTags(content).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func stripThinkTags(_ text: String) -> String {
        var result = text
        while let start = result.range(of: "<think>"),
              let end = result.range(of: "</think>", range: start.upperBound..<result.endIndex) {
            result.removeSubrange(start.lowerBound...end.upperBound)
        }
        // Also strip unclosed <think> block (still thinking when truncated)
        if let start = result.range(of: "<think>") {
            result = String(result[result.startIndex..<start.lowerBound])
        }
        return result
    }
}

private struct GroqResponse: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable { let content: String }
        let message: Message
    }
    let choices: [Choice]
}

enum TranslationError: LocalizedError {
    case missingAPIKey
    case noResponse
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:       return "Groq API Key 未设置，请在设置页面填入。"
        case .noResponse:          return "翻译无响应，请重试。"
        case .apiError(let msg):   return "API 错误：\(msg)"
        }
    }
}
