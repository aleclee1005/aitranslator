import Foundation

enum TranslationEngine: String {
    case apple = "apple"
    case groq  = "groq"
}

enum RecognitionMode: String {
    case personal = "personal"
    case meeting  = "meeting"
}

@Observable
class AppSettings {
    static let shared = AppSettings()

    var sourceLanguage: Language {
        didSet { UserDefaults.standard.set(sourceLanguage.rawValue, forKey: "sourceLanguage") }
    }

    var targetLanguage: Language {
        didSet { UserDefaults.standard.set(targetLanguage.rawValue, forKey: "targetLanguage") }
    }

    var translationEngine: TranslationEngine {
        didSet { UserDefaults.standard.set(translationEngine.rawValue, forKey: "translationEngine") }
    }

    var recognitionMode: RecognitionMode {
        didSet { UserDefaults.standard.set(recognitionMode.rawValue, forKey: "recognitionMode") }
    }

    var retentionDays: Int {
        didSet { UserDefaults.standard.set(retentionDays, forKey: "retentionDays") }
    }

    private init() {
        let src  = UserDefaults.standard.string(forKey: "sourceLanguage")    ?? Language.chinese.rawValue
        let tgt  = UserDefaults.standard.string(forKey: "targetLanguage")    ?? Language.english.rawValue
        let eng  = UserDefaults.standard.string(forKey: "translationEngine") ?? TranslationEngine.apple.rawValue
        let mode = UserDefaults.standard.string(forKey: "recognitionMode")   ?? RecognitionMode.personal.rawValue
        let ret  = UserDefaults.standard.object(forKey: "retentionDays") as? Int ?? 30
        sourceLanguage    = Language(rawValue: src)          ?? .chinese
        targetLanguage    = Language(rawValue: tgt)          ?? .english
        translationEngine = TranslationEngine(rawValue: eng) ?? .apple
        recognitionMode   = RecognitionMode(rawValue: mode)  ?? .personal
        retentionDays     = ret
    }
}
