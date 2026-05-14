import Translation
import Foundation

@MainActor
@Observable
class AppleTranslationService {
    var configuration: TranslationSession.Configuration?
    private(set) var taskID = UUID()

    private var pendingText = ""
    private var continuation: CheckedContinuation<String, Error>?

    func translate(text: String, from source: Language, to target: Language) async throws -> String {
        try await withCheckedThrowingContinuation { cont in
            continuation = cont
            pendingText = text
            configuration = TranslationSession.Configuration(
                source: Locale.Language(identifier: source.appleLocale),
                target: Locale.Language(identifier: target.appleLocale)
            )
            taskID = UUID()
        }
    }

    func handleSession(_ session: TranslationSession) async {
        guard !pendingText.isEmpty, let cont = continuation else { return }
        continuation = nil
        let text = pendingText
        pendingText = ""
        do {
            let response = try await session.translate(text)
            cont.resume(returning: response.targetText)
        } catch {
            cont.resume(throwing: error)
        }
    }
}

enum AppleTranslationError: LocalizedError {
    case unavailable
    var errorDescription: String? {
        String(localized: "Apple Translation is not available on this device.")
    }
}
