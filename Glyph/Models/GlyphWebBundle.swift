import Foundation
import CoreImage
import UIKit
import Compression

// MARK: - Glyph Web Bundle

/// A self-contained web experience (HTML/CSS/JS) that can be transmitted
/// via cycling QR codes and rendered offline in a WKWebView.
///
/// Wire format:  `GLYW:<base64(gzipped HTML)>`
///
/// The HTML is a single self-contained file with all CSS/JS inline,
/// images as data URIs, and audio as base64 `<audio>` sources.
/// Gzip compression typically achieves 4:1 on HTML, meaning a 25KB
/// page compresses to ~6KB = ~8 QR frames at 800 bytes/chunk.
struct GlyphWebBundle: Codable, Equatable {
    let title: String           // Display title (shown in viewer chrome)
    let html: String            // Complete self-contained HTML
    let templateType: String?   // "trivia", "soundboard", "article", "art", or nil for custom
    let createdAt: Date
    let expiresAt: Date?        // Absolute deadline — after this, experience is expired (nil = no window)
    
    init(title: String, html: String, templateType: String?, createdAt: Date, expiresAt: Date? = nil) {
        self.title = title
        self.html = html
        self.templateType = templateType
        self.createdAt = createdAt
        self.expiresAt = expiresAt
    }
    
    /// Whether this web bundle's time window has passed.
    var isWindowExpired: Bool {
        guard let expiresAt else { return false }
        return Date() > expiresAt
    }
    
    static let magicPrefix = "GLYW:"
    
    // MARK: - Encode → QR String (gzipped + encrypted)
    
    /// Encodes this bundle into an encrypted string for QR embedding.
    /// Format: GLYWE:<key-hex>:<nonce-hex>:<ciphertext-base64>
    func encode() -> String? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        guard let jsonData = try? encoder.encode(self) else { return nil }
        guard let compressed = Self.gzip(jsonData) else { return nil }
        
        #if DEBUG
        let ratio = Double(jsonData.count) / Double(compressed.count)
        print("🗜️ Web bundle: \(jsonData.count) bytes → \(compressed.count) bytes (gzip \(String(format: "%.1f", ratio)):1)")
        #endif
        
        let plainPayload = Self.magicPrefix + compressed.base64EncodedString()
        // Encrypt the payload
        return GlyphCrypto.encryptWebBundle(plainPayload) ?? plainPayload
    }
    
    // MARK: - Decode ← QR String
    
    /// Decodes a QR string back into a GlyphWebBundle.
    /// Handles encrypted (GLYWE:), PIN-protected (GLYWP:), and legacy (GLYW:) formats.
    /// PIN-protected bundles return nil without the correct PIN.
    static func decode(from string: String) -> GlyphWebBundle? {
        // PIN-protected needs a PIN
        if GlyphCrypto.isPinProtectedWebBundle(string) {
            return nil
        }
        
        // Try encrypted format (embedded key)
        if GlyphCrypto.isEncryptedWebBundle(string) {
            return GlyphCrypto.decryptWebBundle(string)
        }
        
        // Legacy plaintext fallback
        guard string.hasPrefix(magicPrefix) else { return nil }
        let payload = String(string.dropFirst(magicPrefix.count))
        guard let compressedData = Data(base64Encoded: payload) else { return nil }
        guard let jsonData = gunzip(compressedData) else { return nil }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return try? decoder.decode(GlyphWebBundle.self, from: jsonData)
    }
    
    /// Decode a PIN-protected web bundle.
    static func decode(from string: String, pin: String) -> GlyphWebBundle? {
        guard GlyphCrypto.isPinProtectedWebBundle(string) else {
            return decode(from: string)
        }
        return GlyphCrypto.decryptWebBundle(string, pin: pin)
    }
    
    /// Quick check — is this raw string a web bundle (encrypted, PIN, or legacy)?
    static func isWebBundle(_ string: String) -> Bool {
        string.hasPrefix(magicPrefix) ||
        GlyphCrypto.isEncryptedWebBundle(string) ||
        GlyphCrypto.isPinProtectedWebBundle(string)
    }
    
    // MARK: - QR Code Generation (single frame, for small bundles)
    
    func generateQRCode() -> UIImage? {
        guard let qrString = encode() else { return nil }
        let data = Data(qrString.utf8)
        
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("L", forKey: "inputCorrectionLevel")
        
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
    
    // MARK: - Gzip Compression
    
    /// Compress data using zlib.
    static func gzip(_ data: Data) -> Data? {
        guard !data.isEmpty else { return nil }
        
        return data.withUnsafeBytes { (rawPointer: UnsafeRawBufferPointer) -> Data? in
            guard let sourcePtr = rawPointer.baseAddress else { return nil }
            
            let destCapacity = data.count + 1024 // generous buffer
            let destBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: destCapacity)
            defer { destBuffer.deallocate() }
            
            let compressedSize = compression_encode_buffer(
                destBuffer, destCapacity,
                sourcePtr.assumingMemoryBound(to: UInt8.self), data.count,
                nil,
                COMPRESSION_ZLIB
            )
            
            guard compressedSize > 0 else { return nil }
            return Data(bytes: destBuffer, count: compressedSize)
        }
    }
    
    /// Decompress gzipped data. Handles both raw deflate (COMPRESSION_ZLIB)
    /// and zlib-wrapped format (0x78 header).
    static func gunzip(_ data: Data) -> Data? {
        guard !data.isEmpty else { return nil }
        
        // Try raw deflate first (Apple's COMPRESSION_ZLIB)
        if let result = gunzipRaw(data) {
            return result
        }
        
        // If the data has a zlib header (0x78), strip it and try raw deflate
        if data.count > 6, data[0] == 0x78 {
            let stripped = data.dropFirst(2).dropLast(4) // Remove 2-byte header + 4-byte Adler-32
            if let result = gunzipRaw(Data(stripped)) {
                return result
            }
        }
        
        return nil
    }
    
    /// Raw deflate decompression using Apple's compression framework.
    private static func gunzipRaw(_ data: Data) -> Data? {
        guard !data.isEmpty else { return nil }
        
        return data.withUnsafeBytes { (rawPointer: UnsafeRawBufferPointer) -> Data? in
            guard let sourcePtr = rawPointer.baseAddress else { return nil }
            
            // Allocate generous destination buffer (assume up to 10x expansion)
            let destCapacity = data.count * 10 + 65536
            let destBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: destCapacity)
            defer { destBuffer.deallocate() }
            
            let decompressedSize = compression_decode_buffer(
                destBuffer, destCapacity,
                sourcePtr.assumingMemoryBound(to: UInt8.self), data.count,
                nil,
                COMPRESSION_ZLIB
            )
            
            guard decompressedSize > 0 else { return nil }
            return Data(bytes: destBuffer, count: decompressedSize)
        }
    }
}

// MARK: - Web Bundle Chunk Splitter

/// Splits a GlyphWebBundle into cycling QR code images, reusing
/// the same chunk infrastructure as image/audio transfers.
enum GlyphWebChunkSplitter {
    
    /// Splits a web bundle into QR code images for cycling display.
    /// The entire bundle is encrypted before chunking, so each reassembled
    /// payload requires decryption to access the content.
    static func split(bundle: GlyphWebBundle) -> [UIImage] {
        // Encode the bundle (gzip + encrypt via bundle.encode())
        guard let encryptedPayload = bundle.encode() else { return [] }
        
        #if DEBUG
        print("🌐 Encrypted web bundle payload: \(encryptedPayload.count) chars")
        print("🌐 Estimated frames: \(encryptedPayload.count / GlyphChunk.maxChunkBytes + 1)")
        #endif
        
        // Convert the encrypted payload string to base64 for chunking
        let payloadData = Data(encryptedPayload.utf8)
        let payloadBase64ForChunking = payloadData.base64EncodedString()
        
        let sessionId = String(UUID().uuidString.prefix(8))
        let chunkSize = GlyphChunk.maxChunkBytes
        
        // Split the base64 string into slices
        var slices: [String] = []
        var start = payloadBase64ForChunking.startIndex
        while start < payloadBase64ForChunking.endIndex {
            let end = payloadBase64ForChunking.index(
                start,
                offsetBy: chunkSize,
                limitedBy: payloadBase64ForChunking.endIndex
            ) ?? payloadBase64ForChunking.endIndex
            slices.append(String(payloadBase64ForChunking[start..<end]))
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
            if let img = chunk.generateQRCode() {
                qrImages.append(img)
            }
        }
        
        #if DEBUG
        print("📦 Web bundle split into \(total) chunks, generated \(qrImages.count) QR images")
        #endif
        
        return qrImages.count == total ? qrImages : []
    }
}

// MARK: - Web Payload Detection

/// Detects what type of payload was assembled from chunks.
enum GlyphPayloadType {
    case message(GlyphMessage)
    case webBundle(GlyphWebBundle)
    case unknown
    
    /// Detect and decode an assembled payload (after chunk reassembly).
    /// Handles both encrypted and legacy formats.
    static func detect(from assembledBase64: String) -> GlyphPayloadType {
        guard let rawData = Data(base64Encoded: assembledBase64) else { return .unknown }
        guard let rawString = String(data: rawData, encoding: .utf8) else {
            // Not a string — try decoding as message JSON directly
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .secondsSince1970
            if let msg = try? decoder.decode(GlyphMessage.self, from: rawData) {
                return .message(msg)
            }
            return .unknown
        }
        
        // Check for web bundle prefix (encrypted or legacy)
        if GlyphWebBundle.isWebBundle(rawString) {
            if let bundle = GlyphWebBundle.decode(from: rawString) {
                return .webBundle(bundle)
            }
        }
        
        // Check for message prefix (encrypted or legacy)
        if GlyphMessage.isMessage(rawString) {
            if let msg = GlyphMessage.decode(from: rawString) {
                return .message(msg)
            }
        }
        
        // Try raw JSON decode as message
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        if let msg = try? decoder.decode(GlyphMessage.self, from: rawData) {
            return .message(msg)
        }
        
        return .unknown
    }
}
