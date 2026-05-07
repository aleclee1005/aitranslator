import Foundation

@Observable
class AppSettings {
    static let shared = AppSettings()

    var sourceLanguage: Language {
        didSet { UserDefaults.standard.set(sourceLanguage.rawValue, forKey: "sourceLanguage") }
    }

    var targetLanguage: Language {
        didSet { UserDefaults.standard.set(targetLanguage.rawValue, forKey: "targetLanguage") }
    }

    private init() {
        let src = UserDefaults.standard.string(forKey: "sourceLanguage") ?? Language.chinese.rawValue
        let tgt = UserDefaults.standard.string(forKey: "targetLanguage") ?? Language.english.rawValue
        sourceLanguage = Language(rawValue: src) ?? .chinese
        targetLanguage = Language(rawValue: tgt) ?? .english
    }
}
