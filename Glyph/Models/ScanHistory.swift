import Foundation
import CryptoKit

// MARK: - Scan History

/// Tracks previously scanned Glyph payloads to enforce expiration rules.
///
/// - Read Once messages: blocked after first scan
/// - Timed messages: blocked after expiration window
/// - Forever messages: always allowed
/// - Web experiences: always allowed (they're content, not ephemeral)
///
/// Uses SHA-256 hash of the raw QR payload as the key, so we never
/// store the actual message content on disk.
///
/// Storage: Documents/GlyphScanHistory/history.json
///
class ScanHistory: ObservableObject {
    static let shared = ScanHistory()
    
    @Published private(set) var entries: [String: ScanEntry] = [:]
    
    private let fileManager = FileManager.default
    
    private var storeDir: URL {
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("GlyphScanHistory", isDirectory: true)
    }
    
    private var historyURL: URL {
        storeDir.appendingPathComponent("history.json")
    }
    
    init() {
        try? fileManager.createDirectory(at: storeDir, withIntermediateDirectories: true)
        load()
        cleanupExpired()
    }
    
    // MARK: - Public API
    
    /// Check if a raw QR payload should be allowed to display.
    /// Returns nil if allowed, or a user-facing reason string if blocked.
    func shouldBlock(payload: String, message: GlyphMessage) -> String? {
        let hash = payloadHash(payload)
        
        // Forever messages — always allow
        if message.expirationSeconds == ExpirationOption.forever.rawValue {
            return nil
        }
        
        guard let entry = entries[hash] else {
            // Never scanned before — allow
            return nil
        }
        
        // Read Once — block after first view
        if message.expirationSeconds == ExpirationOption.readOnce.rawValue {
            return "This message was set to Read Once and has already been viewed."
        }
        
        // Timed message — block if the original viewing window has expired
        let elapsed = Date().timeIntervalSince(entry.firstScannedAt)
        if elapsed >= TimeInterval(message.expirationSeconds) {
            return "This message expired \(formatElapsed(elapsed - TimeInterval(message.expirationSeconds))) ago."
        }
        
        // Still within the timer window — allow re-scan
        return nil
    }
    
    /// Record that a payload was scanned and viewed.
    /// Call this when the message is actually displayed to the user.
    func recordScan(payload: String, expirationSeconds: Int) {
        let hash = payloadHash(payload)
        
        if entries[hash] == nil {
            entries[hash] = ScanEntry(
                firstScannedAt: Date(),
                expirationSeconds: expirationSeconds,
                scanCount: 1
            )
        } else {
            entries[hash]?.scanCount += 1
            entries[hash]?.lastScannedAt = Date()
        }
        
        persist()
        
        #if DEBUG
        print("📝 Recorded scan: hash=\(hash.prefix(12))… count=\(entries[hash]?.scanCount ?? 0)")
        #endif
    }
    
    /// Check if a payload has been seen before (for any reason).
    func hasBeenScanned(payload: String) -> Bool {
        entries[payloadHash(payload)] != nil
    }
    
    /// Get scan count for a payload.
    func scanCount(for payload: String) -> Int {
        entries[payloadHash(payload)]?.scanCount ?? 0
    }
    
    // MARK: - Hashing
    
    /// SHA-256 hash of the raw payload string.
    /// We store hashes, not content, so the history file never contains message text.
    private func payloadHash(_ payload: String) -> String {
        let data = Data(payload.utf8)
        let digest = SHA256.hash(data: data)
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    // MARK: - Cleanup
    
    /// Remove entries for messages that expired more than 24 hours ago.
    /// Keeps the history file from growing indefinitely.
    private func cleanupExpired() {
        let now = Date()
        let cutoff: TimeInterval = 86400 // 24 hours grace period
        
        let beforeCount = entries.count
        entries = entries.filter { _, entry in
            // Keep forever entries (they don't expire)
            if entry.expirationSeconds == ExpirationOption.forever.rawValue {
                return true
            }
            // Keep read-once entries (they should block forever)
            if entry.expirationSeconds == ExpirationOption.readOnce.rawValue {
                return true
            }
            // Keep timed entries until 24h after their expiration
            let expiresAt = entry.firstScannedAt.addingTimeInterval(
                TimeInterval(entry.expirationSeconds) + cutoff
            )
            return now < expiresAt
        }
        
        if entries.count != beforeCount {
            persist()
            #if DEBUG
            print("🧹 Cleaned up \(beforeCount - entries.count) expired scan history entries")
            #endif
        }
    }
    
    // MARK: - Formatting
    
    private func formatElapsed(_ seconds: TimeInterval) -> String {
        if seconds < 60 { return "\(Int(seconds))s" }
        if seconds < 3600 { return "\(Int(seconds / 60))m" }
        if seconds < 86400 { return "\(Int(seconds / 3600))h" }
        return "\(Int(seconds / 86400))d"
    }
    
    // MARK: - Persistence
    
    private func load() {
        guard let data = try? Data(contentsOf: historyURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        entries = (try? decoder.decode([String: ScanEntry].self, from: data)) ?? [:]
        #if DEBUG
        print("📂 Loaded \(entries.count) scan history entries")
        #endif
    }
    
    private func persist() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        guard let data = try? encoder.encode(entries) else { return }
        try? data.write(to: historyURL, options: .atomic)
    }
}

// MARK: - Scan Entry

struct ScanEntry: Codable {
    let firstScannedAt: Date
    let expirationSeconds: Int
    var scanCount: Int
    var lastScannedAt: Date?
}
