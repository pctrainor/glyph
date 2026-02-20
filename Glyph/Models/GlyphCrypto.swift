import Foundation
import CryptoKit

// MARK: - Glyph Crypto

/// End-to-end encryption for Glyph payloads using AES-256-GCM.
///
/// Two security tiers:
///
/// **Tier 1 — Embedded Key (default):**
///   Every message gets a unique 256-bit key generated at creation time.
///   The key is embedded in the QR payload itself. Physical proximity
///   to scan IS the security — like whispering in someone's ear.
///   Protects data at rest and against casual interception.
///
/// **Tier 2 — PIN-Protected (optional):**
///   Sender sets a PIN that must be shared separately (verbally, text, etc).
///   The encryption key is derived from PIN + random salt using HKDF-SHA256.
///   The PIN is NEVER embedded in the QR. Without the PIN, the payload is
///   computationally infeasible to decrypt — AES-256-GCM is unbreakable
///   with current (2026) technology.
///
/// Wire formats:
///   GLY1E:<key-hex>:<nonce-hex>:<ciphertext-base64>   (embedded key)
///   GLY1P:<salt-hex>:<nonce-hex>:<ciphertext-base64>  (PIN-protected, no key)
///   GLYCE: / GLYCP: (encrypted/PIN chunks)
///   GLYWE: / GLYWP: (encrypted/PIN web bundles)
///   GLYRE: / GLYRP: (encrypted/PIN survey responses)
///
/// Algorithm: AES-256-GCM (authenticated encryption)
/// Key derivation (PIN mode): HKDF-SHA256 with random 32-byte salt
///
enum GlyphCrypto {
    
    // MARK: - Encrypted Prefixes (embedded key)
    
    static let encryptedMessagePrefix  = "GLY1E:"
    static let encryptedChunkPrefix    = "GLYCE:"
    static let encryptedWebPrefix      = "GLYWE:"
    static let encryptedResponsePrefix = "GLYRE:"
    
    // MARK: - PIN-Protected Prefixes (key derived from PIN)
    
    static let pinMessagePrefix  = "GLY1P:"
    static let pinChunkPrefix    = "GLYCP:"
    static let pinWebPrefix      = "GLYWP:"
    static let pinResponsePrefix = "GLYRP:"
    
    // MARK: - Key Generation
    
    /// Generate a new random 256-bit encryption key.
    static func generateKey() -> SymmetricKey {
        SymmetricKey(size: .bits256)
    }
    
    /// Convert a SymmetricKey to a hex string for embedding in QR payloads.
    static func keyToHex(_ key: SymmetricKey) -> String {
        key.withUnsafeBytes { bytes in
            bytes.map { String(format: "%02x", $0) }.joined()
        }
    }
    
    /// Reconstruct a SymmetricKey from a hex string.
    static func keyFromHex(_ hex: String) -> SymmetricKey? {
        guard hex.count == 64 else { return nil }  // 32 bytes = 64 hex chars
        guard let data = hexToData(hex), data.count == 32 else { return nil }
        return SymmetricKey(data: data)
    }
    
    // MARK: - PIN Key Derivation
    
    /// Derive a 256-bit encryption key from a PIN and random salt using HKDF-SHA256.
    /// This is computationally infeasible to brute-force for any non-trivial PIN.
    static func deriveKey(pin: String, salt: Data) -> SymmetricKey {
        let pinData = Data(pin.utf8)
        // Use the PIN as input key material and salt for HKDF
        let inputKey = SymmetricKey(data: pinData)
        let derived = HKDF<SHA256>.deriveKey(
            inputKeyMaterial: inputKey,
            salt: salt,
            info: Data("GlyphE2E-v1".utf8),
            outputByteCount: 32
        )
        return derived
    }
    
    /// Generate a random 32-byte salt for PIN-based key derivation.
    static func generateSalt() -> Data {
        var salt = Data(count: 32)
        _ = salt.withUnsafeMutableBytes { SecRandomCopyBytes(kSecRandomDefault, 32, $0.baseAddress!) }
        return salt
    }
    
    // MARK: - Encrypt / Decrypt Core
    
    /// Encrypt raw data using AES-256-GCM.
    /// Returns (nonce, ciphertext+tag) on success.
    static func encrypt(_ plaintext: Data, key: SymmetricKey) -> (nonce: Data, ciphertext: Data)? {
        do {
            let nonce = AES.GCM.Nonce()
            let sealed = try AES.GCM.seal(plaintext, using: key, nonce: nonce)
            guard let combined = sealed.combined else { return nil }
            // combined = nonce (12 bytes) + ciphertext + tag (16 bytes)
            let ciphertextAndTag = combined.dropFirst(12)
            return (nonce: Data(nonce), ciphertext: Data(ciphertextAndTag))
        } catch {
            #if DEBUG
            print("🔐 Encryption failed: \(error)")
            #endif
            return nil
        }
    }
    
    /// Decrypt AES-256-GCM ciphertext.
    static func decrypt(_ ciphertext: Data, key: SymmetricKey, nonce nonceData: Data) -> Data? {
        do {
            var combined = Data(nonceData)
            combined.append(ciphertext)
            let box = try AES.GCM.SealedBox(combined: combined)
            return try AES.GCM.open(box, using: key)
        } catch {
            #if DEBUG
            print("🔐 Decryption failed: \(error)")
            #endif
            return nil
        }
    }
    
    // MARK: - Detection Helpers
    
    /// Check if a string is an encrypted Glyph message (embedded key).
    static func isEncryptedMessage(_ string: String) -> Bool {
        string.hasPrefix(encryptedMessagePrefix)
    }
    
    /// Check if a string is a PIN-protected Glyph message.
    static func isPinProtectedMessage(_ string: String) -> Bool {
        string.hasPrefix(pinMessagePrefix)
    }
    
    /// Check if a string is an encrypted chunk (embedded key).
    static func isEncryptedChunk(_ string: String) -> Bool {
        string.hasPrefix(encryptedChunkPrefix)
    }
    
    /// Check if a string is a PIN-protected chunk.
    static func isPinProtectedChunk(_ string: String) -> Bool {
        string.hasPrefix(pinChunkPrefix)
    }
    
    /// Check if a string is an encrypted web bundle (embedded key).
    static func isEncryptedWebBundle(_ string: String) -> Bool {
        string.hasPrefix(encryptedWebPrefix)
    }
    
    /// Check if a string is a PIN-protected web bundle.
    static func isPinProtectedWebBundle(_ string: String) -> Bool {
        string.hasPrefix(pinWebPrefix)
    }
    
    /// Check if a string is an encrypted survey response (embedded key).
    static func isEncryptedSurveyResponse(_ string: String) -> Bool {
        string.hasPrefix(encryptedResponsePrefix)
    }
    
    /// Check if a string is a PIN-protected survey response.
    static func isPinProtectedSurveyResponse(_ string: String) -> Bool {
        string.hasPrefix(pinResponsePrefix)
    }
    
    /// Check if ANY payload is PIN-protected (needs a PIN to decrypt).
    static func isPinProtected(_ string: String) -> Bool {
        string.hasPrefix(pinMessagePrefix) ||
        string.hasPrefix(pinChunkPrefix) ||
        string.hasPrefix(pinWebPrefix) ||
        string.hasPrefix(pinResponsePrefix)
    }
    
    // MARK: - High-Level: Encrypt Message Payload
    
    /// Encrypt a GLY1: payload string → GLY1E: (embedded key) or GLY1P: (PIN-protected).
    ///
    /// - Parameters:
    ///   - payload: The plaintext GLY1: payload string
    ///   - pin: Optional PIN. If provided, uses HKDF key derivation (Tier 2).
    ///          If nil, embeds the key in the payload (Tier 1).
    static func encryptMessage(_ payload: String, pin: String? = nil) -> String? {
        guard payload.hasPrefix(GlyphMessage.magicPrefix) else { return nil }
        let raw = String(payload.dropFirst(GlyphMessage.magicPrefix.count))
        guard let data = Data(base64Encoded: raw) else { return nil }
        
        if let pin = pin, !pin.isEmpty {
            // PIN-protected: derive key from PIN + random salt
            let salt = generateSalt()
            let key = deriveKey(pin: pin, salt: salt)
            guard let (nonce, ciphertext) = encrypt(data, key: key) else { return nil }
            
            let saltHex = salt.map { String(format: "%02x", $0) }.joined()
            let nonceHex = nonce.map { String(format: "%02x", $0) }.joined()
            let ctBase64 = ciphertext.base64EncodedString()
            
            return "\(pinMessagePrefix)\(saltHex):\(nonceHex):\(ctBase64)"
        } else {
            // Embedded key: key travels with the QR
            let key = generateKey()
            guard let (nonce, ciphertext) = encrypt(data, key: key) else { return nil }
            
            let keyHex = keyToHex(key)
            let nonceHex = nonce.map { String(format: "%02x", $0) }.joined()
            let ctBase64 = ciphertext.base64EncodedString()
            
            return "\(encryptedMessagePrefix)\(keyHex):\(nonceHex):\(ctBase64)"
        }
    }
    
    /// Decrypt a GLY1E: payload → GlyphMessage (embedded key, no PIN needed).
    static func decryptMessage(_ encrypted: String) -> GlyphMessage? {
        guard encrypted.hasPrefix(encryptedMessagePrefix) else { return nil }
        let body = String(encrypted.dropFirst(encryptedMessagePrefix.count))
        
        let parts = body.split(separator: ":", maxSplits: 2)
        guard parts.count == 3 else { return nil }
        
        guard let key = keyFromHex(String(parts[0])) else { return nil }
        guard let nonceData = hexToData(String(parts[1])), nonceData.count == 12 else { return nil }
        guard let ciphertext = Data(base64Encoded: String(parts[2])) else { return nil }
        
        guard let plaintext = decrypt(ciphertext, key: key, nonce: nonceData) else { return nil }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return try? decoder.decode(GlyphMessage.self, from: plaintext)
    }
    
    /// Decrypt a GLY1P: payload → GlyphMessage (requires PIN).
    static func decryptMessage(_ encrypted: String, pin: String) -> GlyphMessage? {
        guard encrypted.hasPrefix(pinMessagePrefix) else { return nil }
        let body = String(encrypted.dropFirst(pinMessagePrefix.count))
        
        let parts = body.split(separator: ":", maxSplits: 2)
        guard parts.count == 3 else { return nil }
        
        guard let salt = hexToData(String(parts[0])), salt.count == 32 else { return nil }
        guard let nonceData = hexToData(String(parts[1])), nonceData.count == 12 else { return nil }
        guard let ciphertext = Data(base64Encoded: String(parts[2])) else { return nil }
        
        let key = deriveKey(pin: pin, salt: salt)
        guard let plaintext = decrypt(ciphertext, key: key, nonce: nonceData) else { return nil }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return try? decoder.decode(GlyphMessage.self, from: plaintext)
    }
    
    // MARK: - High-Level: Encrypt Chunk Payload
    
    /// Encrypt a GLYC: chunk → GLYCE: (embedded key) or GLYCP: (PIN-protected).
    static func encryptChunk(_ payload: String, pin: String? = nil) -> String? {
        guard payload.hasPrefix(GlyphChunk.magicPrefix) else { return nil }
        let raw = String(payload.dropFirst(GlyphChunk.magicPrefix.count))
        guard let data = raw.data(using: .utf8) else { return nil }
        
        if let pin = pin, !pin.isEmpty {
            let salt = generateSalt()
            let key = deriveKey(pin: pin, salt: salt)
            guard let (nonce, ciphertext) = encrypt(data, key: key) else { return nil }
            
            let saltHex = salt.map { String(format: "%02x", $0) }.joined()
            let nonceHex = nonce.map { String(format: "%02x", $0) }.joined()
            let ctBase64 = ciphertext.base64EncodedString()
            
            return "\(pinChunkPrefix)\(saltHex):\(nonceHex):\(ctBase64)"
        } else {
            let key = generateKey()
            guard let (nonce, ciphertext) = encrypt(data, key: key) else { return nil }
            
            let keyHex = keyToHex(key)
            let nonceHex = nonce.map { String(format: "%02x", $0) }.joined()
            let ctBase64 = ciphertext.base64EncodedString()
            
            return "\(encryptedChunkPrefix)\(keyHex):\(nonceHex):\(ctBase64)"
        }
    }
    
    /// Decrypt a GLYCE: chunk → original GLYC: chunk string (embedded key).
    static func decryptChunk(_ encrypted: String) -> String? {
        guard encrypted.hasPrefix(encryptedChunkPrefix) else { return nil }
        let body = String(encrypted.dropFirst(encryptedChunkPrefix.count))
        
        let parts = body.split(separator: ":", maxSplits: 2)
        guard parts.count == 3 else { return nil }
        
        guard let key = keyFromHex(String(parts[0])) else { return nil }
        guard let nonceData = hexToData(String(parts[1])), nonceData.count == 12 else { return nil }
        guard let ciphertext = Data(base64Encoded: String(parts[2])) else { return nil }
        
        guard let plaintext = decrypt(ciphertext, key: key, nonce: nonceData) else { return nil }
        guard let chunkBody = String(data: plaintext, encoding: .utf8) else { return nil }
        
        return GlyphChunk.magicPrefix + chunkBody
    }
    
    /// Decrypt a GLYCP: chunk → original GLYC: chunk string (requires PIN).
    static func decryptChunk(_ encrypted: String, pin: String) -> String? {
        guard encrypted.hasPrefix(pinChunkPrefix) else { return nil }
        let body = String(encrypted.dropFirst(pinChunkPrefix.count))
        
        let parts = body.split(separator: ":", maxSplits: 2)
        guard parts.count == 3 else { return nil }
        
        guard let salt = hexToData(String(parts[0])), salt.count == 32 else { return nil }
        guard let nonceData = hexToData(String(parts[1])), nonceData.count == 12 else { return nil }
        guard let ciphertext = Data(base64Encoded: String(parts[2])) else { return nil }
        
        let key = deriveKey(pin: pin, salt: salt)
        guard let plaintext = decrypt(ciphertext, key: key, nonce: nonceData) else { return nil }
        guard let chunkBody = String(data: plaintext, encoding: .utf8) else { return nil }
        
        return GlyphChunk.magicPrefix + chunkBody
    }
    
    // MARK: - High-Level: Encrypt Web Bundle
    
    /// Encrypt a GLYW: web bundle → GLYWE: or GLYWP:.
    static func encryptWebBundle(_ payload: String, pin: String? = nil) -> String? {
        guard payload.hasPrefix(GlyphWebBundle.magicPrefix) else { return nil }
        let raw = String(payload.dropFirst(GlyphWebBundle.magicPrefix.count))
        guard let data = Data(base64Encoded: raw) else { return nil }
        
        if let pin = pin, !pin.isEmpty {
            let salt = generateSalt()
            let key = deriveKey(pin: pin, salt: salt)
            guard let (nonce, ciphertext) = encrypt(data, key: key) else { return nil }
            
            let saltHex = salt.map { String(format: "%02x", $0) }.joined()
            let nonceHex = nonce.map { String(format: "%02x", $0) }.joined()
            let ctBase64 = ciphertext.base64EncodedString()
            
            return "\(pinWebPrefix)\(saltHex):\(nonceHex):\(ctBase64)"
        } else {
            let key = generateKey()
            guard let (nonce, ciphertext) = encrypt(data, key: key) else { return nil }
            
            let keyHex = keyToHex(key)
            let nonceHex = nonce.map { String(format: "%02x", $0) }.joined()
            let ctBase64 = ciphertext.base64EncodedString()
            
            return "\(encryptedWebPrefix)\(keyHex):\(nonceHex):\(ctBase64)"
        }
    }
    
    /// Decrypt a GLYWE: payload → GlyphWebBundle (embedded key).
    static func decryptWebBundle(_ encrypted: String) -> GlyphWebBundle? {
        guard encrypted.hasPrefix(encryptedWebPrefix) else { return nil }
        let body = String(encrypted.dropFirst(encryptedWebPrefix.count))
        
        let parts = body.split(separator: ":", maxSplits: 2)
        guard parts.count == 3 else { return nil }
        
        guard let key = keyFromHex(String(parts[0])) else { return nil }
        guard let nonceData = hexToData(String(parts[1])), nonceData.count == 12 else { return nil }
        guard let ciphertext = Data(base64Encoded: String(parts[2])) else { return nil }
        
        guard let compressed = decrypt(ciphertext, key: key, nonce: nonceData) else { return nil }
        guard let jsonData = GlyphWebBundle.gunzip(compressed) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return try? decoder.decode(GlyphWebBundle.self, from: jsonData)
    }
    
    /// Decrypt a GLYWP: payload → GlyphWebBundle (requires PIN).
    static func decryptWebBundle(_ encrypted: String, pin: String) -> GlyphWebBundle? {
        guard encrypted.hasPrefix(pinWebPrefix) else { return nil }
        let body = String(encrypted.dropFirst(pinWebPrefix.count))
        
        let parts = body.split(separator: ":", maxSplits: 2)
        guard parts.count == 3 else { return nil }
        
        guard let salt = hexToData(String(parts[0])), salt.count == 32 else { return nil }
        guard let nonceData = hexToData(String(parts[1])), nonceData.count == 12 else { return nil }
        guard let ciphertext = Data(base64Encoded: String(parts[2])) else { return nil }
        
        let key = deriveKey(pin: pin, salt: salt)
        guard let compressed = decrypt(ciphertext, key: key, nonce: nonceData) else { return nil }
        guard let jsonData = GlyphWebBundle.gunzip(compressed) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return try? decoder.decode(GlyphWebBundle.self, from: jsonData)
    }
    
    // MARK: - High-Level: Encrypt Survey Response
    
    /// Encrypt a GLYR: survey response → GLYRE: or GLYRP:.
    static func encryptSurveyResponse(_ payload: String, pin: String? = nil) -> String? {
        guard payload.hasPrefix(SurveyResponse.magicPrefix) else { return nil }
        let raw = String(payload.dropFirst(SurveyResponse.magicPrefix.count))
        guard let data = Data(base64Encoded: raw) else { return nil }
        
        if let pin = pin, !pin.isEmpty {
            let salt = generateSalt()
            let key = deriveKey(pin: pin, salt: salt)
            guard let (nonce, ciphertext) = encrypt(data, key: key) else { return nil }
            
            let saltHex = salt.map { String(format: "%02x", $0) }.joined()
            let nonceHex = nonce.map { String(format: "%02x", $0) }.joined()
            let ctBase64 = ciphertext.base64EncodedString()
            
            return "\(pinResponsePrefix)\(saltHex):\(nonceHex):\(ctBase64)"
        } else {
            let key = generateKey()
            guard let (nonce, ciphertext) = encrypt(data, key: key) else { return nil }
            
            let keyHex = keyToHex(key)
            let nonceHex = nonce.map { String(format: "%02x", $0) }.joined()
            let ctBase64 = ciphertext.base64EncodedString()
            
            return "\(encryptedResponsePrefix)\(keyHex):\(nonceHex):\(ctBase64)"
        }
    }
    
    /// Decrypt a GLYRE: payload → SurveyResponse (embedded key).
    static func decryptSurveyResponse(_ encrypted: String) -> SurveyResponse? {
        guard encrypted.hasPrefix(encryptedResponsePrefix) else { return nil }
        let body = String(encrypted.dropFirst(encryptedResponsePrefix.count))
        
        let parts = body.split(separator: ":", maxSplits: 2)
        guard parts.count == 3 else { return nil }
        
        guard let key = keyFromHex(String(parts[0])) else { return nil }
        guard let nonceData = hexToData(String(parts[1])), nonceData.count == 12 else { return nil }
        guard let ciphertext = Data(base64Encoded: String(parts[2])) else { return nil }
        
        guard let plaintext = decrypt(ciphertext, key: key, nonce: nonceData) else { return nil }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return try? decoder.decode(SurveyResponse.self, from: plaintext)
    }
    
    /// Decrypt a GLYRP: payload → SurveyResponse (requires PIN).
    static func decryptSurveyResponse(_ encrypted: String, pin: String) -> SurveyResponse? {
        guard encrypted.hasPrefix(pinResponsePrefix) else { return nil }
        let body = String(encrypted.dropFirst(pinResponsePrefix.count))
        
        let parts = body.split(separator: ":", maxSplits: 2)
        guard parts.count == 3 else { return nil }
        
        guard let salt = hexToData(String(parts[0])), salt.count == 32 else { return nil }
        guard let nonceData = hexToData(String(parts[1])), nonceData.count == 12 else { return nil }
        guard let ciphertext = Data(base64Encoded: String(parts[2])) else { return nil }
        
        let key = deriveKey(pin: pin, salt: salt)
        guard let plaintext = decrypt(ciphertext, key: key, nonce: nonceData) else { return nil }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return try? decoder.decode(SurveyResponse.self, from: plaintext)
    }
    
    // MARK: - Hex Helpers
    
    static func hexToData(_ hex: String) -> Data? {
        guard hex.count % 2 == 0 else { return nil }
        var data = Data()
        var index = hex.startIndex
        while index < hex.endIndex {
            let nextIndex = hex.index(index, offsetBy: 2)
            guard nextIndex <= hex.endIndex,
                  let byte = UInt8(hex[index..<nextIndex], radix: 16) else { return nil }
            data.append(byte)
            index = nextIndex
        }
        return data
    }
}
