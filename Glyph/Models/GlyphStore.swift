import Foundation
import UIKit

// MARK: - Glyph Store

/// Persists received messages, images, and web experiences to the app's
/// local documents directory. No iCloud, no Photo Library — everything
/// stays within the app sandbox.
///
/// Storage layout:
///   Documents/GlyphLibrary/
///     index.json              — array of SavedGlyph metadata
///     images/<id>.jpg         — saved image attachments
///
class GlyphStore: ObservableObject {
    static let shared = GlyphStore()
    
    @Published var items: [SavedGlyph] = []
    
    private let fileManager = FileManager.default
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    /// Root directory for all saved glyphs
    private var libraryDir: URL {
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("GlyphLibrary", isDirectory: true)
    }
    
    /// Subdirectory for image files
    private var imagesDir: URL {
        libraryDir.appendingPathComponent("images", isDirectory: true)
    }
    
    /// Subdirectory for audio files
    private var audioDir: URL {
        libraryDir.appendingPathComponent("audio", isDirectory: true)
    }
    
    /// The index file containing all metadata
    private var indexURL: URL {
        libraryDir.appendingPathComponent("index.json")
    }
    
    init() {
        ensureDirectories()
        load()
    }
    
    // MARK: - Public API
    
    /// Save a received message (with optional image) to the library.
    @discardableResult
    func save(message: GlyphMessage) -> SavedGlyph {
        let id = UUID().uuidString
        var imagePath: String?
        var audioPath: String?
        
        // Save image to disk if present
        if let img = message.decodedImage,
           let jpegData = img.jpegData(compressionQuality: 0.9) {
            let filename = "\(id).jpg"
            let fileURL = imagesDir.appendingPathComponent(filename)
            try? jpegData.write(to: fileURL)
            imagePath = filename
            #if DEBUG
            print("💾 Saved image: \(filename) (\(jpegData.count) bytes)")
            #endif
        }
        
        // Save audio to disk if present
        if let audioData = message.decodedAudioData {
            let filename = "\(id).m4a"
            let fileURL = audioDir.appendingPathComponent(filename)
            try? audioData.write(to: fileURL)
            audioPath = filename
            #if DEBUG
            print("💾 Saved audio: \(filename) (\(audioData.count) bytes)")
            #endif
        }
        
        let saved = SavedGlyph(
            id: id,
            text: message.text,
            imagePath: imagePath,
            hasAudio: message.audioData != nil,
            audioPath: audioPath,
            savedAt: Date(),
            sourceType: .message
        )
        
        items.insert(saved, at: 0) // Newest first
        persist()
        
        #if DEBUG
        print("💾 Saved glyph to library: \"\(message.text.prefix(30))…\" (id: \(id))")
        #endif
        
        return saved
    }
    
    /// Save a received web experience to the library.
    @discardableResult
    func save(webBundle: GlyphWebBundle) -> SavedGlyph {
        let id = UUID().uuidString
        
        let saved = SavedGlyph(
            id: id,
            text: webBundle.title,
            imagePath: nil,
            hasAudio: false,
            savedAt: Date(),
            sourceType: .webExperience,
            webBundleTitle: webBundle.title,
            webBundleType: webBundle.templateType
        )
        
        items.insert(saved, at: 0)
        persist()
        
        #if DEBUG
        print("💾 Saved web experience to library: \"\(webBundle.title)\" (id: \(id))")
        #endif
        
        return saved
    }
    
    /// Load the image for a saved glyph.
    func loadImage(for glyph: SavedGlyph) -> UIImage? {
        guard let filename = glyph.imagePath else { return nil }
        let fileURL = imagesDir.appendingPathComponent(filename)
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return UIImage(data: data)
    }
    
    /// Load the audio data for a saved glyph.
    func loadAudio(for glyph: SavedGlyph) -> Data? {
        guard let filename = glyph.audioPath else { return nil }
        let fileURL = audioDir.appendingPathComponent(filename)
        return try? Data(contentsOf: fileURL)
    }
    
    /// Delete a saved glyph and its associated files.
    func delete(_ glyph: SavedGlyph) {
        // Remove image file if present
        if let filename = glyph.imagePath {
            let fileURL = imagesDir.appendingPathComponent(filename)
            try? fileManager.removeItem(at: fileURL)
        }
        
        // Remove audio file if present
        if let filename = glyph.audioPath {
            let fileURL = audioDir.appendingPathComponent(filename)
            try? fileManager.removeItem(at: fileURL)
        }
        
        items.removeAll { $0.id == glyph.id }
        persist()
        
        #if DEBUG
        print("🗑️ Deleted glyph: \(glyph.id)")
        #endif
    }
    
    /// Delete all saved glyphs.
    func deleteAll() {
        // Remove all image files
        if let files = try? fileManager.contentsOfDirectory(at: imagesDir, includingPropertiesForKeys: nil) {
            for file in files {
                try? fileManager.removeItem(at: file)
            }
        }
        
        // Remove all audio files
        if let files = try? fileManager.contentsOfDirectory(at: audioDir, includingPropertiesForKeys: nil) {
            for file in files {
                try? fileManager.removeItem(at: file)
            }
        }
        
        items.removeAll()
        persist()
        
        #if DEBUG
        print("🗑️ Cleared entire library")
        #endif
    }
    
    /// Total number of saved items.
    var count: Int { items.count }
    
    /// Items that have images.
    var imageItems: [SavedGlyph] {
        items.filter { $0.imagePath != nil }
    }
    
    /// Items that are web experiences.
    var webItems: [SavedGlyph] {
        items.filter { $0.sourceType == .webExperience }
    }
    
    /// Items that are text-only messages.
    var textItems: [SavedGlyph] {
        items.filter { $0.sourceType == .message && $0.imagePath == nil }
    }
    
    // MARK: - Persistence
    
    private func ensureDirectories() {
        try? fileManager.createDirectory(at: libraryDir, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: imagesDir, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: audioDir, withIntermediateDirectories: true)
    }
    
    private func load() {
        guard fileManager.fileExists(atPath: indexURL.path),
              let data = try? Data(contentsOf: indexURL) else {
            items = []
            return
        }
        
        decoder.dateDecodingStrategy = .secondsSince1970
        items = (try? decoder.decode([SavedGlyph].self, from: data)) ?? []
        
        #if DEBUG
        print("📂 Loaded \(items.count) glyphs from library")
        #endif
    }
    
    private func persist() {
        encoder.dateEncodingStrategy = .secondsSince1970
        encoder.outputFormatting = .prettyPrinted
        guard let data = try? encoder.encode(items) else { return }
        try? data.write(to: indexURL, options: .atomic)
    }
}

// MARK: - Saved Glyph Model

/// Metadata for a saved glyph in the local library.
struct SavedGlyph: Codable, Identifiable {
    let id: String
    let text: String
    let imagePath: String?       // Filename within images/ directory
    let hasAudio: Bool
    let audioPath: String?       // Filename within audio/ directory
    let savedAt: Date
    let sourceType: SourceType
    
    // Web experience metadata (optional)
    let webBundleTitle: String?
    let webBundleType: String?
    
    init(
        id: String,
        text: String,
        imagePath: String?,
        hasAudio: Bool,
        audioPath: String? = nil,
        savedAt: Date,
        sourceType: SourceType,
        webBundleTitle: String? = nil,
        webBundleType: String? = nil
    ) {
        self.id = id
        self.text = text
        self.imagePath = imagePath
        self.hasAudio = hasAudio
        self.audioPath = audioPath
        self.savedAt = savedAt
        self.sourceType = sourceType
        self.webBundleTitle = webBundleTitle
        self.webBundleType = webBundleType
    }
    
    enum SourceType: String, Codable {
        case message
        case webExperience
    }
    
    /// Relative time string (e.g., "2 hours ago")
    var relativeTime: String {
        let interval = Date().timeIntervalSince(savedAt)
        if interval < 60 { return "Just now" }
        if interval < 3600 { return "\(Int(interval / 60))m ago" }
        if interval < 86400 { return "\(Int(interval / 3600))h ago" }
        if interval < 604800 { return "\(Int(interval / 86400))d ago" }
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: savedAt)
    }
    
    /// Icon for the source type.
    var icon: String {
        switch sourceType {
        case .message:
            if imagePath != nil { return "photo.fill" }
            if hasAudio { return "speaker.wave.2.fill" }
            return "bubble.left.fill"
        case .webExperience:
            return "sparkles.rectangle.stack.fill"
        }
    }
}
