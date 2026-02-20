import Foundation
import CoreImage
import UIKit

// MARK: - Glyph Survey

/// A survey created by the originator and delivered via cycling QR codes.
/// Contains questions with multiple choice or rating options.
/// Responses come back as static QR codes scanned from respondents' devices.
struct GlyphSurvey: Codable, Identifiable, Equatable {
    let id: String              // Unique survey ID — links responses to this survey
    let title: String
    let questions: [SurveyQuestion]
    let createdAt: Date
    let expiresAt: Date?        // Absolute deadline — after this, survey can't be submitted (nil = no window)
    
    init(title: String, questions: [SurveyQuestion], expiresAt: Date? = nil) {
        self.id = String(UUID().uuidString.prefix(8))
        self.title = title
        self.questions = questions
        self.createdAt = Date()
        self.expiresAt = expiresAt
    }
    
    /// Whether this survey's time window has passed.
    var isWindowExpired: Bool {
        guard let expiresAt else { return false }
        return Date() > expiresAt
    }
    
    static func == (lhs: GlyphSurvey, rhs: GlyphSurvey) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Survey Question

struct SurveyQuestion: Codable, Identifiable {
    let id: String
    let text: String
    let type: QuestionType
    let options: [String]?      // For multiple choice
    let maxRating: Int?         // For rating (e.g. 5 stars)
    
    init(text: String, type: QuestionType, options: [String]? = nil, maxRating: Int? = nil) {
        self.id = String(UUID().uuidString.prefix(6))
        self.text = text
        self.type = type
        self.options = options
        self.maxRating = maxRating
    }
    
    enum QuestionType: String, Codable {
        case multipleChoice = "mc"
        case rating = "rating"
        case text = "text"
    }
}

// MARK: - Survey Response

/// A single respondent's answers to a survey.
/// Wire format: `GLYR:<base64(json)>` — fits in a single static QR code.
struct SurveyResponse: Codable, Identifiable {
    let id: String
    let surveyId: String        // Links back to the originating survey
    let answers: [SurveyAnswer]
    let submittedAt: Date
    
    static let magicPrefix = "GLYR:"
    
    init(surveyId: String, answers: [SurveyAnswer]) {
        self.id = String(UUID().uuidString.prefix(8))
        self.surveyId = surveyId
        self.answers = answers
        self.submittedAt = Date()
    }
    
    // MARK: - Encode → QR String (Encrypted)
    
    /// Encodes this response into an encrypted string for QR embedding.
    /// Format: GLYRE:<key-hex>:<nonce-hex>:<ciphertext-base64>
    func encode() -> String? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        guard let jsonData = try? encoder.encode(self) else { return nil }
        let plainPayload = Self.magicPrefix + jsonData.base64EncodedString()
        // Encrypt the payload
        return GlyphCrypto.encryptSurveyResponse(plainPayload) ?? plainPayload
    }
    
    // MARK: - Decode ← QR String
    
    /// Decodes a QR string back into a SurveyResponse.
    /// Handles both encrypted (GLYRE:) and legacy plaintext (GLYR:) formats.
    static func decode(from string: String) -> SurveyResponse? {
        // Try encrypted format first
        if GlyphCrypto.isEncryptedSurveyResponse(string) {
            return GlyphCrypto.decryptSurveyResponse(string)
        }
        
        // Legacy plaintext fallback
        guard string.hasPrefix(magicPrefix) else { return nil }
        let payload = String(string.dropFirst(magicPrefix.count))
        guard let data = Data(base64Encoded: payload) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return try? decoder.decode(SurveyResponse.self, from: data)
    }
    
    /// Quick check — is this raw string a survey response (encrypted or legacy)?
    static func isSurveyResponse(_ string: String) -> Bool {
        string.hasPrefix(magicPrefix) || GlyphCrypto.isEncryptedSurveyResponse(string)
    }
    
    // MARK: - QR Code Generation (single static QR)
    
    func generateQRCode() -> UIImage? {
        guard let qrString = encode() else { return nil }
        let data = Data(qrString.utf8)
        
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")
        
        guard let ciImage = filter.outputImage else { return nil }
        let extent = ciImage.extent
        guard extent.width > 0, extent.height > 0 else { return nil }
        
        let scale = 600.0 / extent.size.width
        guard scale.isFinite, scale > 0 else { return nil }
        
        let translated = ciImage.transformed(by: CGAffineTransform(
            translationX: -extent.origin.x, y: -extent.origin.y))
        let scaled = translated.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        
        let ctx = CIContext(options: [.useSoftwareRenderer: false])
        guard let cg = ctx.createCGImage(scaled, from: scaled.extent.integral) else { return nil }
        return UIImage(cgImage: cg)
    }
}

// MARK: - Survey Answer

struct SurveyAnswer: Codable {
    let questionId: String
    let choiceIndex: Int?       // For multiple choice (0-based)
    let ratingValue: Int?       // For rating (1..maxRating)
    let textValue: String?      // For free text
}

// MARK: - Survey Store

/// Persists created surveys and their collected responses to local storage.
/// Storage layout:
///   Documents/GlyphSurveys/
///     surveys.json            — array of GlyphSurvey
///     responses.json          — array of SurveyResponse
///
class SurveyStore: ObservableObject {
    static let shared = SurveyStore()
    
    @Published var surveys: [GlyphSurvey] = []
    @Published var responses: [SurveyResponse] = []
    
    private let fileManager = FileManager.default
    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .secondsSince1970
        e.outputFormatting = .prettyPrinted
        return e
    }()
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .secondsSince1970
        return d
    }()
    
    private var storeDir: URL {
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("GlyphSurveys", isDirectory: true)
    }
    
    private var surveysURL: URL { storeDir.appendingPathComponent("surveys.json") }
    private var responsesURL: URL { storeDir.appendingPathComponent("responses.json") }
    
    init() {
        try? fileManager.createDirectory(at: storeDir, withIntermediateDirectories: true)
        load()
    }
    
    // MARK: - Surveys
    
    /// Save a new survey.
    @discardableResult
    func save(survey: GlyphSurvey) -> GlyphSurvey {
        surveys.insert(survey, at: 0)
        persistSurveys()
        #if DEBUG
        print("📋 Saved survey: \"\(survey.title)\" (id: \(survey.id), \(survey.questions.count) questions)")
        #endif
        return survey
    }
    
    /// Delete a survey and all its responses.
    func delete(survey: GlyphSurvey) {
        surveys.removeAll { $0.id == survey.id }
        responses.removeAll { $0.surveyId == survey.id }
        persistSurveys()
        persistResponses()
    }
    
    /// Find a survey by ID.
    func survey(byId id: String) -> GlyphSurvey? {
        surveys.first { $0.id == id }
    }
    
    // MARK: - Responses
    
    /// Record a scanned response.
    @discardableResult
    func record(response: SurveyResponse) -> Bool {
        // Verify this response matches a known survey
        guard surveys.contains(where: { $0.id == response.surveyId }) else {
            #if DEBUG
            print("⚠️ Response for unknown survey: \(response.surveyId)")
            #endif
            return false
        }
        
        // Don't record duplicate responses (same response ID)
        guard !responses.contains(where: { $0.id == response.id }) else {
            #if DEBUG
            print("⚠️ Duplicate response: \(response.id)")
            #endif
            return false
        }
        
        responses.insert(response, at: 0)
        persistResponses()
        
        #if DEBUG
        print("📥 Recorded response for survey \(response.surveyId) (total: \(responsesFor(surveyId: response.surveyId).count))")
        #endif
        return true
    }
    
    /// Get all responses for a specific survey.
    func responsesFor(surveyId: String) -> [SurveyResponse] {
        responses.filter { $0.surveyId == surveyId }
    }
    
    /// Get response count for a survey.
    func responseCount(for surveyId: String) -> Int {
        responses.filter { $0.surveyId == surveyId }.count
    }
    
    // MARK: - Analytics
    
    /// Aggregate results for a specific question across all responses.
    func results(for question: SurveyQuestion, surveyId: String) -> QuestionResults {
        let surveyResponses = responsesFor(surveyId: surveyId)
        let answers = surveyResponses.compactMap { r in
            r.answers.first { $0.questionId == question.id }
        }
        
        switch question.type {
        case .multipleChoice:
            var counts: [Int: Int] = [:]
            let optionCount = question.options?.count ?? 0
            for i in 0..<optionCount { counts[i] = 0 }
            for a in answers {
                if let idx = a.choiceIndex { counts[idx, default: 0] += 1 }
            }
            return .multipleChoice(optionCounts: counts, total: answers.count)
            
        case .rating:
            let values = answers.compactMap { $0.ratingValue }
            let avg = values.isEmpty ? 0 : Double(values.reduce(0, +)) / Double(values.count)
            var dist: [Int: Int] = [:]
            for v in 1...(question.maxRating ?? 5) { dist[v] = 0 }
            for v in values { dist[v, default: 0] += 1 }
            return .rating(average: avg, distribution: dist, total: values.count)
            
        case .text:
            let texts = answers.compactMap { $0.textValue }.filter { !$0.isEmpty }
            return .text(responses: texts)
        }
    }
    
    /// Aggregated results enum.
    enum QuestionResults {
        case multipleChoice(optionCounts: [Int: Int], total: Int)
        case rating(average: Double, distribution: [Int: Int], total: Int)
        case text(responses: [String])
    }
    
    // MARK: - Persistence
    
    private func load() {
        if let data = try? Data(contentsOf: surveysURL) {
            surveys = (try? decoder.decode([GlyphSurvey].self, from: data)) ?? []
        }
        if let data = try? Data(contentsOf: responsesURL) {
            responses = (try? decoder.decode([SurveyResponse].self, from: data)) ?? []
        }
        #if DEBUG
        print("📋 Loaded \(surveys.count) surveys, \(responses.count) responses")
        #endif
    }
    
    private func persistSurveys() {
        guard let data = try? encoder.encode(surveys) else { return }
        try? data.write(to: surveysURL, options: .atomic)
    }
    
    private func persistResponses() {
        guard let data = try? encoder.encode(responses) else { return }
        try? data.write(to: responsesURL, options: .atomic)
    }
}
