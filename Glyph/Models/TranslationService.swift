import Foundation
import Translation

// MARK: - Translation Service

/// On-device translation powered by Apple's Translation framework.
/// Supports 46+ languages with full offline capability after download.
/// iOS 17.4+ required.
@Observable
final class TranslationService {
    
    // MARK: - Types
    
    struct Message: Identifiable {
        let id = UUID()
        let speaker: Speaker
        let originalText: String
        var translatedText: String?
        let sourceLanguage: Locale.Language
        let targetLanguage: Locale.Language
        let timestamp: Date = .now
    }
    
    enum Speaker: String, CaseIterable {
        case personA = "Person A"
        case personB = "Person B"
    }
    
    struct SupportedLanguage: Identifiable, Hashable {
        let id: String                    // BCP-47 code
        let language: Locale.Language
        let displayName: String
        let nativeName: String
        let region: String                // Geographic region for grouping
        let isEndangered: Bool            // Flag for rare/endangered languages
    }
    
    enum TranslationError: LocalizedError {
        case unavailable
        case downloadRequired(Locale.Language)
        case translationFailed(String)
        case sameLanguage
        
        var errorDescription: String? {
            switch self {
            case .unavailable:
                return "Translation is not available on this device."
            case .downloadRequired(let lang):
                return "Language pack for \(lang.minimalIdentifier) needs to be downloaded."
            case .translationFailed(let msg):
                return "Translation failed: \(msg)"
            case .sameLanguage:
                return "Source and target languages are the same."
            }
        }
    }
    
    // MARK: - State
    
    var messages: [Message] = []
    var languageA: Locale.Language = Locale.Language(identifier: "en")
    var languageB: Locale.Language = Locale.Language(identifier: "es")
    var activeSpeaker: Speaker = .personA
    var isTranslating = false
    var errorMessage: String?
    var availableLanguages: [SupportedLanguage] = []
    var downloadedLanguages: Set<String> = []
    
    // MARK: - Language Catalog
    
    /// Comprehensive language list covering major world languages, regional
    /// languages, and endangered/remote languages. These map to Apple's
    /// Translation framework language codes where supported, and serve as
    /// targets for future corpus expansion.
    static let allLanguages: [SupportedLanguage] = [
        // ── Major World Languages ──────────────────────────
        SupportedLanguage(id: "en", language: .init(identifier: "en"), displayName: "English", nativeName: "English", region: "Global", isEndangered: false),
        SupportedLanguage(id: "es", language: .init(identifier: "es"), displayName: "Spanish", nativeName: "Español", region: "Global", isEndangered: false),
        SupportedLanguage(id: "fr", language: .init(identifier: "fr"), displayName: "French", nativeName: "Français", region: "Global", isEndangered: false),
        SupportedLanguage(id: "de", language: .init(identifier: "de"), displayName: "German", nativeName: "Deutsch", region: "Europe", isEndangered: false),
        SupportedLanguage(id: "it", language: .init(identifier: "it"), displayName: "Italian", nativeName: "Italiano", region: "Europe", isEndangered: false),
        SupportedLanguage(id: "pt", language: .init(identifier: "pt"), displayName: "Portuguese", nativeName: "Português", region: "Global", isEndangered: false),
        SupportedLanguage(id: "zh-Hans", language: .init(identifier: "zh-Hans"), displayName: "Chinese (Simplified)", nativeName: "中文", region: "East Asia", isEndangered: false),
        SupportedLanguage(id: "zh-Hant", language: .init(identifier: "zh-Hant"), displayName: "Chinese (Traditional)", nativeName: "繁體中文", region: "East Asia", isEndangered: false),
        SupportedLanguage(id: "ja", language: .init(identifier: "ja"), displayName: "Japanese", nativeName: "日本語", region: "East Asia", isEndangered: false),
        SupportedLanguage(id: "ko", language: .init(identifier: "ko"), displayName: "Korean", nativeName: "한국어", region: "East Asia", isEndangered: false),
        SupportedLanguage(id: "ar", language: .init(identifier: "ar"), displayName: "Arabic", nativeName: "العربية", region: "Middle East & North Africa", isEndangered: false),
        SupportedLanguage(id: "hi", language: .init(identifier: "hi"), displayName: "Hindi", nativeName: "हिन्दी", region: "South Asia", isEndangered: false),
        SupportedLanguage(id: "ru", language: .init(identifier: "ru"), displayName: "Russian", nativeName: "Русский", region: "Eurasia", isEndangered: false),
        
        // ── European Languages ─────────────────────────────
        SupportedLanguage(id: "pl", language: .init(identifier: "pl"), displayName: "Polish", nativeName: "Polski", region: "Europe", isEndangered: false),
        SupportedLanguage(id: "nl", language: .init(identifier: "nl"), displayName: "Dutch", nativeName: "Nederlands", region: "Europe", isEndangered: false),
        SupportedLanguage(id: "tr", language: .init(identifier: "tr"), displayName: "Turkish", nativeName: "Türkçe", region: "Eurasia", isEndangered: false),
        SupportedLanguage(id: "uk", language: .init(identifier: "uk"), displayName: "Ukrainian", nativeName: "Українська", region: "Europe", isEndangered: false),
        SupportedLanguage(id: "el", language: .init(identifier: "el"), displayName: "Greek", nativeName: "Ελληνικά", region: "Europe", isEndangered: false),
        SupportedLanguage(id: "ro", language: .init(identifier: "ro"), displayName: "Romanian", nativeName: "Română", region: "Europe", isEndangered: false),
        SupportedLanguage(id: "cs", language: .init(identifier: "cs"), displayName: "Czech", nativeName: "Čeština", region: "Europe", isEndangered: false),
        SupportedLanguage(id: "sv", language: .init(identifier: "sv"), displayName: "Swedish", nativeName: "Svenska", region: "Europe", isEndangered: false),
        SupportedLanguage(id: "da", language: .init(identifier: "da"), displayName: "Danish", nativeName: "Dansk", region: "Europe", isEndangered: false),
        SupportedLanguage(id: "fi", language: .init(identifier: "fi"), displayName: "Finnish", nativeName: "Suomi", region: "Europe", isEndangered: false),
        SupportedLanguage(id: "hu", language: .init(identifier: "hu"), displayName: "Hungarian", nativeName: "Magyar", region: "Europe", isEndangered: false),
        SupportedLanguage(id: "sk", language: .init(identifier: "sk"), displayName: "Slovak", nativeName: "Slovenčina", region: "Europe", isEndangered: false),
        SupportedLanguage(id: "hr", language: .init(identifier: "hr"), displayName: "Croatian", nativeName: "Hrvatski", region: "Europe", isEndangered: false),
        SupportedLanguage(id: "bg", language: .init(identifier: "bg"), displayName: "Bulgarian", nativeName: "Български", region: "Europe", isEndangered: false),
        SupportedLanguage(id: "ca", language: .init(identifier: "ca"), displayName: "Catalan", nativeName: "Català", region: "Europe", isEndangered: false),
        SupportedLanguage(id: "lt", language: .init(identifier: "lt"), displayName: "Lithuanian", nativeName: "Lietuvių", region: "Europe", isEndangered: false),
        SupportedLanguage(id: "sl", language: .init(identifier: "sl"), displayName: "Slovenian", nativeName: "Slovenščina", region: "Europe", isEndangered: false),
        
        // ── South & Southeast Asian Languages ──────────────
        SupportedLanguage(id: "bn", language: .init(identifier: "bn"), displayName: "Bengali", nativeName: "বাংলা", region: "South Asia", isEndangered: false),
        SupportedLanguage(id: "ta", language: .init(identifier: "ta"), displayName: "Tamil", nativeName: "தமிழ்", region: "South Asia", isEndangered: false),
        SupportedLanguage(id: "te", language: .init(identifier: "te"), displayName: "Telugu", nativeName: "తెలుగు", region: "South Asia", isEndangered: false),
        SupportedLanguage(id: "mr", language: .init(identifier: "mr"), displayName: "Marathi", nativeName: "मराठी", region: "South Asia", isEndangered: false),
        SupportedLanguage(id: "ur", language: .init(identifier: "ur"), displayName: "Urdu", nativeName: "اردو", region: "South Asia", isEndangered: false),
        SupportedLanguage(id: "vi", language: .init(identifier: "vi"), displayName: "Vietnamese", nativeName: "Tiếng Việt", region: "Southeast Asia", isEndangered: false),
        SupportedLanguage(id: "th", language: .init(identifier: "th"), displayName: "Thai", nativeName: "ไทย", region: "Southeast Asia", isEndangered: false),
        SupportedLanguage(id: "id", language: .init(identifier: "id"), displayName: "Indonesian", nativeName: "Bahasa Indonesia", region: "Southeast Asia", isEndangered: false),
        SupportedLanguage(id: "ms", language: .init(identifier: "ms"), displayName: "Malay", nativeName: "Bahasa Melayu", region: "Southeast Asia", isEndangered: false),
        SupportedLanguage(id: "tl", language: .init(identifier: "tl"), displayName: "Tagalog", nativeName: "Tagalog", region: "Southeast Asia", isEndangered: false),
        SupportedLanguage(id: "km", language: .init(identifier: "km"), displayName: "Khmer", nativeName: "ខ្មែរ", region: "Southeast Asia", isEndangered: false),
        SupportedLanguage(id: "my", language: .init(identifier: "my"), displayName: "Burmese", nativeName: "မြန်မာ", region: "Southeast Asia", isEndangered: false),
        SupportedLanguage(id: "lo", language: .init(identifier: "lo"), displayName: "Lao", nativeName: "ລາວ", region: "Southeast Asia", isEndangered: false),
        SupportedLanguage(id: "ne", language: .init(identifier: "ne"), displayName: "Nepali", nativeName: "नेपाली", region: "South Asia", isEndangered: false),
        SupportedLanguage(id: "si", language: .init(identifier: "si"), displayName: "Sinhala", nativeName: "සිංහල", region: "South Asia", isEndangered: false),
        
        // ── African Languages ──────────────────────────────
        SupportedLanguage(id: "sw", language: .init(identifier: "sw"), displayName: "Swahili", nativeName: "Kiswahili", region: "East Africa", isEndangered: false),
        SupportedLanguage(id: "am", language: .init(identifier: "am"), displayName: "Amharic", nativeName: "አማርኛ", region: "East Africa", isEndangered: false),
        SupportedLanguage(id: "yo", language: .init(identifier: "yo"), displayName: "Yoruba", nativeName: "Yorùbá", region: "West Africa", isEndangered: false),
        SupportedLanguage(id: "zu", language: .init(identifier: "zu"), displayName: "Zulu", nativeName: "isiZulu", region: "Southern Africa", isEndangered: false),
        SupportedLanguage(id: "ha", language: .init(identifier: "ha"), displayName: "Hausa", nativeName: "Hausa", region: "West Africa", isEndangered: false),
        SupportedLanguage(id: "ig", language: .init(identifier: "ig"), displayName: "Igbo", nativeName: "Igbo", region: "West Africa", isEndangered: false),
        SupportedLanguage(id: "rw", language: .init(identifier: "rw"), displayName: "Kinyarwanda", nativeName: "Kinyarwanda", region: "Central Africa", isEndangered: false),
        SupportedLanguage(id: "so", language: .init(identifier: "so"), displayName: "Somali", nativeName: "Soomaali", region: "East Africa", isEndangered: false),
        SupportedLanguage(id: "mg", language: .init(identifier: "mg"), displayName: "Malagasy", nativeName: "Malagasy", region: "Indian Ocean", isEndangered: false),
        SupportedLanguage(id: "xh", language: .init(identifier: "xh"), displayName: "Xhosa", nativeName: "isiXhosa", region: "Southern Africa", isEndangered: false),
        SupportedLanguage(id: "sn", language: .init(identifier: "sn"), displayName: "Shona", nativeName: "chiShona", region: "Southern Africa", isEndangered: false),
        
        // ── Middle Eastern & Caucasian ─────────────────────
        SupportedLanguage(id: "fa", language: .init(identifier: "fa"), displayName: "Persian", nativeName: "فارسی", region: "Middle East", isEndangered: false),
        SupportedLanguage(id: "he", language: .init(identifier: "he"), displayName: "Hebrew", nativeName: "עברית", region: "Middle East", isEndangered: false),
        SupportedLanguage(id: "ka", language: .init(identifier: "ka"), displayName: "Georgian", nativeName: "ქართული", region: "Caucasus", isEndangered: false),
        SupportedLanguage(id: "hy", language: .init(identifier: "hy"), displayName: "Armenian", nativeName: "Հայերեն", region: "Caucasus", isEndangered: false),
        SupportedLanguage(id: "az", language: .init(identifier: "az"), displayName: "Azerbaijani", nativeName: "Azərbaycan", region: "Caucasus", isEndangered: false),
        SupportedLanguage(id: "kk", language: .init(identifier: "kk"), displayName: "Kazakh", nativeName: "Қазақ", region: "Central Asia", isEndangered: false),
        SupportedLanguage(id: "uz", language: .init(identifier: "uz"), displayName: "Uzbek", nativeName: "Oʻzbek", region: "Central Asia", isEndangered: false),
        SupportedLanguage(id: "mn", language: .init(identifier: "mn"), displayName: "Mongolian", nativeName: "Монгол", region: "East Asia", isEndangered: false),
        
        // ── Indigenous & Endangered Languages ──────────────
        SupportedLanguage(id: "qu", language: .init(identifier: "qu"), displayName: "Quechua", nativeName: "Runa Simi", region: "South America", isEndangered: true),
        SupportedLanguage(id: "ay", language: .init(identifier: "ay"), displayName: "Aymara", nativeName: "Aymar aru", region: "South America", isEndangered: true),
        SupportedLanguage(id: "gn", language: .init(identifier: "gn"), displayName: "Guarani", nativeName: "Avañe'ẽ", region: "South America", isEndangered: true),
        SupportedLanguage(id: "mi", language: .init(identifier: "mi"), displayName: "Māori", nativeName: "Te Reo Māori", region: "Oceania", isEndangered: true),
        SupportedLanguage(id: "haw", language: .init(identifier: "haw"), displayName: "Hawaiian", nativeName: "ʻŌlelo Hawaiʻi", region: "Oceania", isEndangered: true),
        SupportedLanguage(id: "sm", language: .init(identifier: "sm"), displayName: "Samoan", nativeName: "Gagana Sāmoa", region: "Oceania", isEndangered: false),
        SupportedLanguage(id: "to", language: .init(identifier: "to"), displayName: "Tongan", nativeName: "Lea fakatonga", region: "Oceania", isEndangered: false),
        SupportedLanguage(id: "fj", language: .init(identifier: "fj"), displayName: "Fijian", nativeName: "Na Vosa Vakaviti", region: "Oceania", isEndangered: false),
        SupportedLanguage(id: "ty", language: .init(identifier: "ty"), displayName: "Tahitian", nativeName: "Reo Tahiti", region: "Oceania", isEndangered: true),
        SupportedLanguage(id: "iu", language: .init(identifier: "iu"), displayName: "Inuktitut", nativeName: "ᐃᓄᒃᑎᑐᑦ", region: "Arctic", isEndangered: true),
        SupportedLanguage(id: "oj", language: .init(identifier: "oj"), displayName: "Ojibwe", nativeName: "Anishinaabemowin", region: "North America", isEndangered: true),
        SupportedLanguage(id: "chr", language: .init(identifier: "chr"), displayName: "Cherokee", nativeName: "ᏣᎳᎩ", region: "North America", isEndangered: true),
        SupportedLanguage(id: "nv", language: .init(identifier: "nv"), displayName: "Navajo", nativeName: "Diné bizaad", region: "North America", isEndangered: true),
        SupportedLanguage(id: "cy", language: .init(identifier: "cy"), displayName: "Welsh", nativeName: "Cymraeg", region: "Europe", isEndangered: true),
        SupportedLanguage(id: "gd", language: .init(identifier: "gd"), displayName: "Scottish Gaelic", nativeName: "Gàidhlig", region: "Europe", isEndangered: true),
        SupportedLanguage(id: "ga", language: .init(identifier: "ga"), displayName: "Irish", nativeName: "Gaeilge", region: "Europe", isEndangered: true),
        SupportedLanguage(id: "br", language: .init(identifier: "br"), displayName: "Breton", nativeName: "Brezhoneg", region: "Europe", isEndangered: true),
        SupportedLanguage(id: "eu", language: .init(identifier: "eu"), displayName: "Basque", nativeName: "Euskara", region: "Europe", isEndangered: true),
    ]
    
    // MARK: - Init
    
    init() {
        availableLanguages = Self.allLanguages
    }
    
    // MARK: - Translation
    
    // Note: Actual on-device translation is triggered by the SwiftUI
    // `.translationTask` modifier in TranslationView. This service manages
    // conversation state; the view layer owns the TranslationSession lifecycle.
    
    /// Sends a message from the active speaker and prepares it for translation.
    func sendMessage(text: String) -> Message {
        let (source, target): (Locale.Language, Locale.Language) = activeSpeaker == .personA
            ? (languageA, languageB)
            : (languageB, languageA)
        
        let message = Message(
            speaker: activeSpeaker,
            originalText: text,
            translatedText: nil,
            sourceLanguage: source,
            targetLanguage: target
        )
        
        messages.append(message)
        return message
    }
    
    /// Updates a message with its translation result.
    func updateTranslation(for messageID: UUID, with translatedText: String) {
        if let index = messages.firstIndex(where: { $0.id == messageID }) {
            messages[index].translatedText = translatedText
        }
    }
    
    /// Swaps the two conversation languages.
    func swapLanguages() {
        let temp = languageA
        languageA = languageB
        languageB = temp
    }
    
    /// Clears the conversation history.
    func clearConversation() {
        messages.removeAll()
    }
    
    // MARK: - Language Helpers
    
    /// Returns a display name for a language code.
    func displayName(for language: Locale.Language) -> String {
        Self.allLanguages.first(where: { $0.language.minimalIdentifier == language.minimalIdentifier })?.displayName
            ?? language.minimalIdentifier
    }
    
    /// Returns the native name for a language code.
    func nativeName(for language: Locale.Language) -> String {
        Self.allLanguages.first(where: { $0.language.minimalIdentifier == language.minimalIdentifier })?.nativeName
            ?? language.minimalIdentifier
    }
    
    /// Returns languages grouped by region.
    var languagesByRegion: [String: [SupportedLanguage]] {
        Dictionary(grouping: availableLanguages, by: \.region)
    }
    
    /// Returns only endangered/remote languages.
    var endangeredLanguages: [SupportedLanguage] {
        availableLanguages.filter(\.isEndangered)
    }
    
    /// Filters available languages by search query.
    func searchLanguages(query: String) -> [SupportedLanguage] {
        guard !query.isEmpty else { return availableLanguages }
        let q = query.lowercased()
        return availableLanguages.filter {
            $0.displayName.lowercased().contains(q) ||
            $0.nativeName.lowercased().contains(q) ||
            $0.region.lowercased().contains(q) ||
            $0.id.lowercased().contains(q)
        }
    }
}
