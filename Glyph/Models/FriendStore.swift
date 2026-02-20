import Foundation

// MARK: - Glyph Friend

/// A local contact discovered by scanning a signed Glyph message.
/// No server, no accounts — just a platform + handle stored on-device.
struct GlyphFriend: Codable, Identifiable, Equatable, Hashable {
    var id: String { "\(platform.rawValue):\(handle)" }
    
    let platform: SocialPlatform
    let handle: String           // Stored without @
    let firstSeen: Date          // When we first scanned a message from them
    var lastSeen: Date           // Most recent message scanned
    var messageCount: Int        // How many signed messages we've scanned from them
    var nickname: String?        // Optional custom label
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(platform)
        hasher.combine(handle)
    }
    
    /// Display string — e.g. "@username"
    var displayHandle: String { "@\(handle)" }
    
    /// Tappable URL to their social profile.
    var profileURL: URL? {
        platform.profileURL(handle: handle)
    }
    
    /// Build from a social signature embedded in a scanned message.
    init(from signature: SocialSignature) {
        self.platform = signature.platform
        self.handle = signature.handle
        self.firstSeen = Date()
        self.lastSeen = Date()
        self.messageCount = 1
        self.nickname = nil
    }
}

// MARK: - Friend Store

/// Manages the local friends list. Fully offline — stored in UserDefaults.
final class FriendStore: ObservableObject {
    
    static let shared = FriendStore()
    
    private let key = "glyphFriendsList"
    
    @Published private(set) var friends: [GlyphFriend] = []
    
    private init() {
        load()
    }
    
    // MARK: - Public API
    
    /// Add a friend from a social signature. Returns `true` if new friend, `false` if existing (updated).
    @discardableResult
    func addOrUpdate(from signature: SocialSignature) -> Bool {
        let handle = signature.handle
        let platform = signature.platform
        
        if let index = friends.firstIndex(where: { $0.platform == platform && $0.handle == handle }) {
            // Already a friend — bump counts
            friends[index].lastSeen = Date()
            friends[index].messageCount += 1
            save()
            return false
        } else {
            // New friend
            let friend = GlyphFriend(from: signature)
            friends.insert(friend, at: 0)
            save()
            return true
        }
    }
    
    /// Check if someone is already a friend.
    func isFriend(_ signature: SocialSignature) -> Bool {
        friends.contains { $0.platform == signature.platform && $0.handle == signature.handle }
    }
    
    /// Look up a friend by signature.
    func friend(for signature: SocialSignature) -> GlyphFriend? {
        friends.first { $0.platform == signature.platform && $0.handle == signature.handle }
    }
    
    /// Remove a friend.
    func remove(_ friend: GlyphFriend) {
        friends.removeAll { $0.id == friend.id }
        save()
    }
    
    /// Remove by index set (for SwiftUI List onDelete).
    func remove(at offsets: IndexSet) {
        friends.remove(atOffsets: offsets)
        save()
    }
    
    /// Update nickname for a friend.
    func setNickname(_ nickname: String?, for friend: GlyphFriend) {
        if let index = friends.firstIndex(where: { $0.id == friend.id }) {
            friends[index].nickname = nickname?.trimmingCharacters(in: .whitespacesAndNewlines)
            save()
        }
    }
    
    /// Total friend count.
    var count: Int { friends.count }
    
    // MARK: - Persistence
    
    private func save() {
        guard let data = try? JSONEncoder().encode(friends) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
    
    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([GlyphFriend].self, from: data) else { return }
        friends = decoded
    }
}
