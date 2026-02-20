import Foundation
import CoreImage
import UIKit

// MARK: - Glyph Message

/// The payload encoded into and decoded from a QR code.
/// Contains the message text, the sender's chosen expiration, and a creation timestamp.
struct GlyphMessage: Codable, Identifiable, Equatable {
    let id: UUID
    let text: String
    let expirationSeconds: Int   // How long the receiver has to read it (viewer timer)
    let createdAt: Date          // When the QR was generated
    let imageData: String?       // Base64-encoded JPEG (nil = text-only)
    let audioData: String?       // Base64-encoded M4A audio (nil = no audio)
    let expiresAt: Date?         // Absolute deadline — after this, QR is dead (nil = no window)
    let signature: SocialSignature?  // Optional sender social identity
    let flashOnScan: Bool?       // Sender requests flash on receiver's phone (nil = default true)
    
    static func == (lhs: GlyphMessage, rhs: GlyphMessage) -> Bool {
        lhs.id == rhs.id
    }
    
    /// Convenience initializer — id is local-only and not encoded into the QR.
    init(text: String, expirationSeconds: Int, createdAt: Date, imageData: String? = nil, audioData: String? = nil, expiresAt: Date? = nil, signature: SocialSignature? = nil, flashOnScan: Bool? = nil) {
        self.id = UUID()
        self.text = text
        self.expirationSeconds = expirationSeconds
        self.createdAt = createdAt
        self.imageData = imageData
        self.audioData = audioData
        self.expiresAt = expiresAt
        self.signature = signature
        self.flashOnScan = flashOnScan
    }
    
    /// Exclude `id` from the QR payload — it's only used locally for SwiftUI identity.
    private enum CodingKeys: String, CodingKey {
        case text, expirationSeconds, createdAt, imageData, audioData, expiresAt, signature, flashOnScan
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.text = try container.decode(String.self, forKey: .text)
        self.expirationSeconds = try container.decode(Int.self, forKey: .expirationSeconds)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.imageData = try container.decodeIfPresent(String.self, forKey: .imageData)
        self.audioData = try container.decodeIfPresent(String.self, forKey: .audioData)
        self.expiresAt = try container.decodeIfPresent(Date.self, forKey: .expiresAt)
        self.signature = try container.decodeIfPresent(SocialSignature.self, forKey: .signature)
        self.flashOnScan = try container.decodeIfPresent(Bool.self, forKey: .flashOnScan)
    }
    
    // MARK: - Image Helpers
    
    /// Decodes the attached image, if any.
    var decodedImage: UIImage? {
        guard let base64 = imageData,
              let data = Data(base64Encoded: base64) else { return nil }
        return UIImage(data: data)
    }
    
    /// Decodes the attached audio data, if any.
    var decodedAudioData: Data? {
        guard let base64 = audioData,
              let data = Data(base64Encoded: base64) else { return nil }
        return data
    }
    
    /// Whether this message needs multi-QR batching.
    var needsBatching: Bool {
        imageData != nil || audioData != nil
    }
    
    /// A compact identifier prefix so we know it's a Glyph QR, not some random one.
    static let magicPrefix = "GLY1:"
    
    /// The exact string encoded in the Glyph logo QR code.
    /// This is a URL so the system camera can open the app / App Store page.
    /// The Glyph scanner recognises it as the logo easter egg.
    static let logoPayload = "https://glyphmsg.io/app"
    
    /// Check if a scanned string is the Glyph logo QR.
    /// Matches the canonical URL with or without trailing slash, http/https, etc.
    static func isLogoQR(_ string: String) -> Bool {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        // Match the exact URL (with or without trailing slash / scheme variations)
        let normalized = trimmed
            .replacingOccurrences(of: "http://", with: "https://")
        let stripped = normalized
            .replacingOccurrences(of: "https://", with: "")
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return stripped == "glyphmsg.io/app"
    }
    
    // MARK: - Encode → QR String (Encrypted)
    
    /// Encodes this message into an encrypted string suitable for QR embedding.
    ///
    /// - Parameter pin: Optional PIN for Tier 2 encryption. If provided, the key
    ///   is derived from the PIN via HKDF — the PIN is NOT in the QR.
    ///   Without the PIN, the message is computationally impossible to decrypt.
    ///   If nil, uses Tier 1 (embedded key) encryption.
    func encode(pin: String? = nil) -> String? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        guard let jsonData = try? encoder.encode(self) else { return nil }
        let base64 = jsonData.base64EncodedString()
        let plainPayload = Self.magicPrefix + base64
        // Encrypt the payload (with or without PIN)
        return GlyphCrypto.encryptMessage(plainPayload, pin: pin) ?? plainPayload
    }
    
    // MARK: - Decode ← QR String
    
    /// Decodes a QR string back into a GlyphMessage.
    /// Handles encrypted (GLY1E:), PIN-protected (GLY1P:), and legacy (GLY1:) formats.
    /// PIN-protected messages return nil without the correct PIN — use `decode(from:pin:)`.
    static func decode(from string: String) -> GlyphMessage? {
        // PIN-protected messages can't be decoded without a PIN
        if GlyphCrypto.isPinProtectedMessage(string) {
            return nil
        }
        
        // Try encrypted format (embedded key)
        if GlyphCrypto.isEncryptedMessage(string) {
            return GlyphCrypto.decryptMessage(string)
        }
        
        // Legacy plaintext fallback (GLY1:)
        guard string.hasPrefix(magicPrefix) else { return nil }
        
        let payload = String(string.dropFirst(magicPrefix.count))
        guard let data = Data(base64Encoded: payload) else { return nil }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return try? decoder.decode(GlyphMessage.self, from: data)
    }
    
    /// Decodes a PIN-protected message. Returns nil if PIN is wrong.
    static func decode(from string: String, pin: String) -> GlyphMessage? {
        guard GlyphCrypto.isPinProtectedMessage(string) else {
            // Not PIN-protected — decode normally
            return decode(from: string)
        }
        return GlyphCrypto.decryptMessage(string, pin: pin)
    }
    
    /// Check if a string is any kind of Glyph message (encrypted, PIN, or legacy).
    static func isMessage(_ string: String) -> Bool {
        string.hasPrefix(magicPrefix) ||
        GlyphCrypto.isEncryptedMessage(string) ||
        GlyphCrypto.isPinProtectedMessage(string)
    }
    
    /// Check if a string is a PIN-protected message (requires PIN to read).
    static func isPinProtected(_ string: String) -> Bool {
        GlyphCrypto.isPinProtectedMessage(string)
    }
    
    // MARK: - Expiration Check
    
    /// Whether this QR code's time window has passed (absolute deadline).
    /// This is checked BEFORE showing the message — the QR itself is dead.
    var isWindowExpired: Bool {
        guard let expiresAt else { return false }
        return Date() > expiresAt
    }
    
    /// How long until the time window closes. Nil if no window set.
    var windowTimeRemaining: TimeInterval? {
        guard let expiresAt else { return nil }
        return expiresAt.timeIntervalSinceNow
    }
    
    /// How many seconds remain before this message expires. Negative = already expired.
    /// This is the VIEWER timer (starts when receiver opens the message).
    var secondsRemaining: TimeInterval {
        let elapsed = Date().timeIntervalSince(createdAt)
        return TimeInterval(expirationSeconds) - elapsed
    }
    
    var isExpired: Bool {
        secondsRemaining <= 0
    }
    
    // MARK: - QR Code Generation
    
    /// Generates a UIImage of the QR code for this message.
    func generateQRCode(pin: String? = nil) -> UIImage? {
        guard let qrString = encode(pin: pin) else { return nil }
        
        #if DEBUG
        print("📦 QR payload length: \(qrString.count) chars")
        #endif
        
        let data = Data(qrString.utf8)
        
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")
        
        guard let ciImage = filter.outputImage else { return nil }
        
        let extent = ciImage.extent
        #if DEBUG
        print("📐 CIImage extent: \(extent)")
        #endif
        guard extent.width > 0, extent.height > 0 else { return nil }
        
        // Scale up — raw QR is tiny (e.g. 43x43)
        let targetSize: CGFloat = 600.0
        let scale = targetSize / extent.size.width
        guard scale.isFinite, scale > 0 else { return nil }
        
        // Translate to origin (0,0) first, then scale — CIQRCodeGenerator
        // can produce images with non-zero origins that cause blank renders.
        let translated = ciImage.transformed(by: CGAffineTransform(translationX: -extent.origin.x, y: -extent.origin.y))
        let scaled = translated.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        let outputRect = scaled.extent.integral
        
        // MUST rasterize to CGImage — UIImage(ciImage:) does NOT render in SwiftUI
        let ciContext = CIContext(options: [.useSoftwareRenderer: false])
        guard let cgImage = ciContext.createCGImage(scaled, from: outputRect) else { return nil }
        
        return UIImage(cgImage: cgImage)
    }
    
    // MARK: - Compression Helpers (reserved for future use)
}

// MARK: - Expiration Options

/// The expiration choices shown to the sender.
enum ExpirationOption: Int, CaseIterable, Identifiable {
    case readOnce = -1     // Special: vanishes after first read
    case seconds10 = 10
    case seconds30 = 30
    case minute1 = 60
    case minutes5 = 300
    case forever = -2      // Special: image saved to receiver's library, message persists
    
    var id: Int { rawValue }
    
    var displayName: String {
        switch self {
        case .readOnce:  return "Read Once"
        case .seconds10: return "10 sec"
        case .seconds30: return "30 sec"
        case .minute1:   return "1 min"
        case .minutes5:  return "5 min"
        case .forever:   return "Forever"
        }
    }
    
    var icon: String {
        switch self {
        case .readOnce:  return "eye.slash"
        case .seconds10: return "10.circle"
        case .seconds30: return "30.circle"
        case .minute1:   return "clock"
        case .minutes5:  return "clock.badge.checkmark"
        case .forever:   return "infinity"
        }
    }
}

// MARK: - Time Window

/// Optional time window — how long the QR code itself stays valid.
/// After the window closes, the QR is dead and cannot be scanned at all.
/// This is independent of ExpirationOption (which controls the viewer timer).
enum TimeWindow: Int, CaseIterable, Identifiable {
    case none      = 0       // No window — QR stays valid forever
    case minutes15 = 900     // 15 minutes
    case hour1     = 3600    // 1 hour
    case hours24   = 86400   // 24 hours
    case days7     = 604800  // 7 days
    case days30    = 2592000 // 30 days
    
    var id: Int { rawValue }
    
    /// The absolute deadline date from now.
    /// Returns nil for `.none`.
    func expiresAt(from date: Date = Date()) -> Date? {
        guard self != .none else { return nil }
        return date.addingTimeInterval(TimeInterval(rawValue))
    }
    
    var displayName: String {
        switch self {
        case .none:      return "No Window"
        case .minutes15: return "15 min"
        case .hour1:     return "1 hour"
        case .hours24:   return "24 hours"
        case .days7:     return "7 days"
        case .days30:    return "30 days"
        }
    }
    
    var icon: String {
        switch self {
        case .none:      return "infinity.circle"
        case .minutes15: return "15.circle"
        case .hour1:     return "clock"
        case .hours24:   return "clock.badge.checkmark"
        case .days7:     return "calendar"
        case .days30:    return "calendar.badge.clock"
        }
    }
    
    var subtitle: String {
        switch self {
        case .none:      return "QR stays valid indefinitely"
        case .minutes15: return "Dead after 15 minutes"
        case .hours24:   return "Dead after 24 hours"
        case .hour1:     return "Dead after 1 hour"
        case .days7:     return "Dead after 1 week"
        case .days30:    return "Dead after 30 days"
        }
    }
}
