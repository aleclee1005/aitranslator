import Foundation

enum Language: String, CaseIterable, Identifiable {
    case chinese = "zh-CN"
    case english = "en-US"
    case japanese = "ja-JP"
    case korean = "ko-KR"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .chinese:  return "中文"
        case .english:  return "English"
        case .japanese: return "日本語"
        case .korean:   return "한국어"
        }
    }

    var llmName: String {
        switch self {
        case .chinese:  return "Chinese (Simplified)"
        case .english:  return "English"
        case .japanese: return "Japanese"
        case .korean:   return "Korean"
        }
    }

    var sttLocale: Locale { Locale(identifier: rawValue) }

    var appleLocale: String {
        switch self {
        case .chinese:  return "zh-Hans"
        case .english:  return "en"
        case .japanese: return "ja"
        case .korean:   return "ko"
        }
    }
}
