import Foundation

// MARK: - Social Platform

/// Supported social platforms for identity verification.
enum SocialPlatform: String, Codable, CaseIterable, Identifiable {
    case instagram
    case x          // Twitter / X
    case tiktok
    case snapchat
    case youtube
    case threads
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .instagram: return "Instagram"
        case .x:         return "X"
        case .tiktok:    return "TikTok"
        case .snapchat:  return "Snapchat"
        case .youtube:   return "YouTube"
        case .threads:   return "Threads"
        }
    }
    
    var icon: String {
        switch self {
        case .instagram: return "camera.circle"
        case .x:         return "at.circle"
        case .tiktok:    return "play.circle"
        case .snapchat:  return "message.circle"
        case .youtube:   return "play.rectangle"
        case .threads:   return "at"
        }
    }
    
    /// Build a profile URL from a handle so the receiver can tap to verify.
    func profileURL(handle: String) -> URL? {
        let clean = handle
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "@", with: "")
        guard !clean.isEmpty else { return nil }
        
        switch self {
        case .instagram: return URL(string: "https://instagram.com/\(clean)")
        case .x:         return URL(string: "https://x.com/\(clean)")
        case .tiktok:    return URL(string: "https://tiktok.com/@\(clean)")
        case .snapchat:  return URL(string: "https://snapchat.com/add/\(clean)")
        case .youtube:   return URL(string: "https://youtube.com/@\(clean)")
        case .threads:   return URL(string: "https://threads.net/@\(clean)")
        }
    }
}

// MARK: - Social Signature

/// A lightweight signature embedded in a Glyph QR payload.
/// Just the platform + handle — the receiver can verify by tapping the profile link.
struct SocialSignature: Codable, Equatable {
    let platform: SocialPlatform
    let handle: String     // e.g. "@username" (stored without @)
    
    init(platform: SocialPlatform, handle: String) {
        self.platform = platform
        self.handle = handle
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "@", with: "")
    }
    
    /// Display string — e.g. "@username on Instagram"
    var displayText: String {
        "@\(handle) on \(platform.displayName)"
    }
    
    /// Tappable URL to verify the sender's identity.
    var profileURL: URL? {
        platform.profileURL(handle: handle)
    }
}

// MARK: - Social Profile (Local Storage)

/// Manages the user's linked social account.
/// Stored in UserDefaults — no server, no sign-in, just a handle.
final class SocialProfile: ObservableObject {
    
    static let shared = SocialProfile()
    
    private enum Keys {
        static let platform = "glyphSocialPlatform"
        static let handle   = "glyphSocialHandle"
    }
    
    @Published var platform: SocialPlatform {
        didSet { save() }
    }
    
    @Published var handle: String {
        didSet { save() }
    }
    
    /// Whether the user has linked a social account.
    var isLinked: Bool {
        !handle.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "@", with: "")
            .isEmpty
    }
    
    /// Build a signature for embedding in a QR.
    var signature: SocialSignature? {
        guard isLinked else { return nil }
        return SocialSignature(platform: platform, handle: handle)
    }
    
    // MARK: - Init
    
    private init() {
        let defaults = UserDefaults.standard
        if let raw = defaults.string(forKey: Keys.platform),
           let p = SocialPlatform(rawValue: raw) {
            self.platform = p
        } else {
            self.platform = .instagram
        }
        self.handle = defaults.string(forKey: Keys.handle) ?? ""
    }
    
    // MARK: - Persistence
    
    private func save() {
        let defaults = UserDefaults.standard
        defaults.set(platform.rawValue, forKey: Keys.platform)
        defaults.set(handle, forKey: Keys.handle)
    }
    
    /// Unlink the social account.
    func unlink() {
        handle = ""
        platform = .instagram
    }
}
