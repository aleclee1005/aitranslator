import SwiftData
import Foundation

@Model
class Session {
    var date: Date
    var mode: String
    var sourceLanguage: String
    var targetLanguage: String
    var summary: String?
    @Relationship(deleteRule: .cascade, inverse: \TranscriptEntry.session)
    var entries: [TranscriptEntry] = []

    init(mode: RecognitionMode, sourceLanguage: Language, targetLanguage: Language) {
        self.date = Date()
        self.mode = mode.rawValue
        self.sourceLanguage = sourceLanguage.rawValue
        self.targetLanguage = targetLanguage.rawValue
    }

    var recognitionMode: RecognitionMode {
        RecognitionMode(rawValue: mode) ?? .personal
    }
    var sourceLang: Language { Language(rawValue: sourceLanguage) ?? .chinese }
    var targetLang: Language { Language(rawValue: targetLanguage) ?? .english }
}

@Model
class TranscriptEntry {
    var timestamp: Date
    var original: String
    var translation: String
    var session: Session?

    init(original: String, translation: String) {
        self.timestamp = Date()
        self.original = original
        self.translation = translation
    }
}
