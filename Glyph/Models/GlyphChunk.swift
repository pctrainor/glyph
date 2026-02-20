import Foundation
import CoreImage
import UIKit

// MARK: - Glyph Chunk

/// A single frame in a multi-QR transfer.
/// Each chunk carries a slice of the full payload plus metadata so the receiver
/// can reassemble them in order.
///
/// Wire format:  `GLYC:<base64(json)>`
struct GlyphChunk: Codable {
    let sessionId: String   // Short unique ID tying chunks together
    let index: Int          // 0-based
    let total: Int          // Total number of chunks
    let data: String        // Base64 slice of the full payload
    
    static let magicPrefix = "GLYC:"
    
    /// Max raw bytes per chunk payload.
    /// Lower density QR codes (version ~15–20) are far more reliably decoded
    /// by phone cameras scanning a cycling display. More frames, but each
    /// one scans successfully on the first pass.
    static let maxChunkBytes = 800
    
    // MARK: - Encode → QR String (Encrypted)
    
    /// Encode this chunk. Pass a PIN for Tier 2 (PIN-protected) encryption.
    func encode(pin: String? = nil) -> String? {
        guard let jsonData = try? JSONEncoder().encode(self) else { return nil }
        let plainPayload = Self.magicPrefix + jsonData.base64EncodedString()
        // Encrypt each chunk individually
        return GlyphCrypto.encryptChunk(plainPayload, pin: pin) ?? plainPayload
    }
    
    // MARK: - Decode ← QR String
    
    /// Decode a chunk string. Handles encrypted (GLYCE:), PIN-protected (GLYCP:),
    /// and legacy (GLYC:) formats. PIN-protected chunks return nil without PIN.
    static func decode(from string: String) -> GlyphChunk? {
        return decode(from: string, pin: nil)
    }
    
    /// Decode a chunk string with an optional PIN for GLYCP: chunks.
    static func decode(from string: String, pin: String?) -> GlyphChunk? {
        var payloadString = string
        
        // PIN-protected chunk
        if GlyphCrypto.isPinProtectedChunk(string) {
            guard let pin = pin, !pin.isEmpty,
                  let decrypted = GlyphCrypto.decryptChunk(string, pin: pin) else { return nil }
            payloadString = decrypted
        }
        // Encrypted chunk (embedded key)
        else if GlyphCrypto.isEncryptedChunk(string) {
            guard let decrypted = GlyphCrypto.decryptChunk(string) else { return nil }
            payloadString = decrypted
        }
        
        // Now parse the plaintext GLYC: format
        guard payloadString.hasPrefix(magicPrefix) else { return nil }
        let payload = String(payloadString.dropFirst(magicPrefix.count))
        guard let raw = Data(base64Encoded: payload) else { return nil }
        return try? JSONDecoder().decode(GlyphChunk.self, from: raw)
    }
    
    /// Check if a string is a Glyph chunk (encrypted, PIN, or legacy).
    static func isChunk(_ string: String) -> Bool {
        string.hasPrefix(magicPrefix) ||
        GlyphCrypto.isEncryptedChunk(string) ||
        GlyphCrypto.isPinProtectedChunk(string)
    }
    
    /// Check if a string is a PIN-protected chunk.
    static func isPinProtected(_ string: String) -> Bool {
        GlyphCrypto.isPinProtectedChunk(string)
    }
    
    // MARK: - QR Image
    
    func generateQRCode(pin: String? = nil) -> UIImage? {
        guard let qrString = encode(pin: pin) else { return nil }
        let data = Data(qrString.utf8)
        
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("L", forKey: "inputCorrectionLevel") // L = more capacity
        
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

// MARK: - Chunk Splitter

/// Splits a full GlyphMessage (including optional image) into an array of chunk QR images.
enum GlyphChunkSplitter {
    
    /// Splits a message into QR code images.
    /// Returns a single-element array for small text-only messages (uses the classic GLY1 format),
    /// or a multi-element array for anything that needs batching.
    ///
    /// - Parameter pin: Optional PIN for Tier 2 encryption. Pass through to chunk encoding.
    static func split(message: GlyphMessage, pin: String? = nil) -> [UIImage] {
        // If it's a simple text message that fits in one QR, use the classic format
        if message.imageData == nil && message.audioData == nil, let single = message.generateQRCode(pin: pin) {
            return [single]
        }
        
        // Otherwise, encode the full message (with image) and chunk it
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        guard let fullPayload = try? encoder.encode(message) else { return [] }
        let payloadBase64 = fullPayload.base64EncodedString()
        
        let sessionId = String(UUID().uuidString.prefix(8))
        let chunkSize = GlyphChunk.maxChunkBytes
        
        // Split the base64 string into slices
        var slices: [String] = []
        var start = payloadBase64.startIndex
        while start < payloadBase64.endIndex {
            let end = payloadBase64.index(start, offsetBy: chunkSize, limitedBy: payloadBase64.endIndex) ?? payloadBase64.endIndex
            slices.append(String(payloadBase64[start..<end]))
            start = end
        }
        
        let total = slices.count
        var qrImages: [UIImage] = []
        
        for (i, slice) in slices.enumerated() {
            let chunk = GlyphChunk(
                sessionId: sessionId,
                index: i,
                total: total,
                data: slice
            )
            if let img = chunk.generateQRCode(pin: pin) {
                qrImages.append(img)
            }
        }
        
        #if DEBUG
        print("📦 Split into \(total) chunks, generated \(qrImages.count) QR images (session: \(sessionId))")
        #endif
        
        return qrImages.count == total ? qrImages : []
    }
}

// MARK: - Chunk Assembler

/// Collects scanned chunks and reassembles them into a GlyphMessage.
class GlyphChunkAssembler: ObservableObject {
    @Published var progress: Double = 0       // 0…1
    @Published var receivedCount: Int = 0
    @Published var totalCount: Int = 0
    @Published var receivedIndices: Set<Int> = []  // Which chunk slots are filled
    @Published var assembledMessage: GlyphMessage?
    @Published var assembledWebBundle: GlyphWebBundle?
    
    private var sessionId: String?
    private var chunks: [Int: String] = [:]   // index → data
    
    /// Feed a raw QR string. Returns true if a new chunk was accepted.
    /// Handles both encrypted (GLYCE:) and legacy (GLYC:) chunk formats.
    @discardableResult
    func feed(_ raw: String) -> Bool {
        let cleaned = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let chunk = GlyphChunk.decode(from: cleaned) else { return false }
        
        // Lock to the first session we see
        if sessionId == nil {
            sessionId = chunk.sessionId
            totalCount = chunk.total
        }
        guard chunk.sessionId == sessionId else { return false }
        guard chunks[chunk.index] == nil else { return false } // Already have this one
        
        chunks[chunk.index] = chunk.data
        receivedCount = chunks.count
        receivedIndices = Set(chunks.keys)
        progress = totalCount > 0 ? Double(receivedCount) / Double(totalCount) : 0
        
        #if DEBUG
        print("📥 Chunk \(chunk.index + 1)/\(chunk.total) (session: \(chunk.sessionId))")
        #endif
        
        if chunks.count == totalCount {
            assemble()
        }
        return true
    }
    
    /// Reset for a new transfer.
    func reset() {
        sessionId = nil
        chunks.removeAll()
        receivedCount = 0
        totalCount = 0
        receivedIndices = []
        progress = 0
        assembledMessage = nil
        assembledWebBundle = nil
    }
    
    /// Attempt to decode a partial image from whatever chunks we have so far.
    /// Missing chunks are filled with zero bytes, which produces a partially-rendered
    /// JPEG — the image decodes up to the point of corruption, showing whatever was
    /// loaded so far (often the top portion of the image).
    func partialAssemble() -> GlyphMessage? {
        guard totalCount > 0, receivedCount > 0 else { return nil }
        
        // Build the full base64 string, filling gaps with 'A' (base64 zero bytes)
        var slices: [String] = []
        for i in 0..<totalCount {
            if let data = chunks[i] {
                slices.append(data)
            } else {
                // Fill missing chunk with base64-encoded zeros (same length as a real chunk)
                let fillLength = GlyphChunk.maxChunkBytes
                slices.append(String(repeating: "A", count: fillLength))
            }
        }
        
        let fullBase64 = slices.joined()
        guard let jsonData = Data(base64Encoded: fullBase64) else { return nil }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return try? decoder.decode(GlyphMessage.self, from: jsonData)
    }
    
    /// Tries to extract a partial image even when the JSON can't fully decode.
    /// Since the message JSON has imageData as a base64 string field near the end,
    /// we can try to grab whatever image data is available from received chunks.
    func partialImage() -> UIImage? {
        // First try full assembly if we have everything
        if let msg = assembledMessage, let img = msg.decodedImage { return img }
        
        // Try partial assembly
        if let msg = partialAssemble(), let img = msg.decodedImage { return img }
        
        // Last resort: concatenate received chunks in order and try to find
        // the base64 image data embedded in the JSON payload
        guard totalCount > 0 else { return nil }
        
        let ordered = (0..<totalCount).compactMap { chunks[$0] }
        guard !ordered.isEmpty else { return nil }
        let partialBase64 = ordered.joined()
        
        // The full payload is base64-encoded JSON. Try to decode it.
        guard let jsonData = Data(base64Encoded: partialBase64) else { return nil }
        
        // Try to find the imageData field within partial JSON
        // The JSON looks like: {"text":"...","expirationSeconds":...,"imageData":"<base64JPEG>","createdAt":...}
        if let jsonString = String(data: jsonData, encoding: .utf8),
           let range = jsonString.range(of: "\"imageData\":\"") {
            let afterKey = jsonString[range.upperBound...]
            // Grab everything up to the next quote (or end of string for partial data)
            let base64Part: String
            if let endQuote = afterKey.firstIndex(of: "\"") {
                base64Part = String(afterKey[..<endQuote])
            } else {
                // Partial — take what we have and pad to valid base64 length
                var raw = String(afterKey)
                // Remove any trailing non-base64 chars
                let validChars = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=")
                while let last = raw.last, !last.unicodeScalars.allSatisfy({ validChars.contains($0) }) {
                    raw.removeLast()
                }
                // Pad to multiple of 4
                let remainder = raw.count % 4
                if remainder > 0 { raw += String(repeating: "=", count: 4 - remainder) }
                base64Part = raw
            }
            
            if let imageBytes = Data(base64Encoded: base64Part),
               let img = UIImage(data: imageBytes) {
                return img
            }
            
            // Even if we can't decode a full image, try with truncated data
            // JPEG is resilient — decoders will render whatever is valid
            if base64Part.count > 100 {
                var truncated = base64Part
                // Try progressively shorter slices
                for _ in 0..<5 {
                    let len = truncated.count
                    let padded = truncated.padding(toLength: ((len + 3) / 4) * 4, withPad: "=", startingAt: 0)
                    if let data = Data(base64Encoded: padded), let img = UIImage(data: data) {
                        return img
                    }
                    // Remove last ~10% and try again
                    truncated = String(truncated.prefix(len - len / 10))
                }
            }
        }
        
        return nil
    }
    
    private func assemble() {
        // Recombine slices in order
        let ordered = (0..<totalCount).compactMap { chunks[$0] }
        guard ordered.count == totalCount else { return }
        
        let fullBase64 = ordered.joined()
        
        #if DEBUG
        print("🔧 Assemble: fullBase64 length = \(fullBase64.count)")
        #endif
        
        guard let rawData = Data(base64Encoded: fullBase64) else {
            #if DEBUG
            print("❌ Assemble: base64 decode failed")
            #endif
            return
        }
        
        #if DEBUG
        print("🔧 Assemble: rawData = \(rawData.count) bytes")
        if let preview = String(data: rawData.prefix(60), encoding: .utf8) {
            print("🔧 Assemble: rawData preview = \(preview)")
        }
        #endif
        
        // Check if the payload is a web bundle (GLYW:, encrypted GLYWE:, or PIN GLYWP:)
        if let rawString = String(data: rawData, encoding: .utf8),
           GlyphWebBundle.isWebBundle(rawString) {
            #if DEBUG
            print("🔧 Assemble: detected web bundle prefix, attempting decode...")
            #endif
            
            if let bundle = GlyphWebBundle.decode(from: rawString) {
                #if DEBUG
                print("✅ Assembled web bundle: \(bundle.title) (\(bundle.html.count) chars HTML)")
                #endif
                assembledWebBundle = bundle
                return
            } else {
                #if DEBUG
                print("❌ Assemble: GlyphWebBundle.decode returned nil")
                #endif
            }
        }
        
        // Otherwise try to decode as a GlyphMessage
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        
        if let message = try? decoder.decode(GlyphMessage.self, from: rawData) {
            #if DEBUG
            print("✅ Assembled message: text=\(message.text.prefix(30))… hasImage=\(message.imageData != nil)")
            #endif
            assembledMessage = message
        }
    }
}
