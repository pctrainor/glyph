import Foundation

// MARK: - Conversation Message

/// A single message in a conversation thread.
/// Can be from you (sent via QR) or from a friend (received by scanning their QR).
/// PIN-protected messages stay encrypted until the user unlocks them.
struct ConversationMessage: Codable, Identifiable, Equatable {
    let id: UUID
    let text: String?                // Plaintext (nil if still locked)
    let imageData: String?           // Base64 JPEG (nil if still locked or no image)
    let audioData: String?           // Base64 M4A (nil if still locked or no audio)
    let signature: SocialSignature?  // QR signature attached to this message
    let rawPayload: String?          // Original encrypted QR payload (kept for PIN-locked msgs)
    let isPinProtected: Bool         // Whether this message requires a PIN to read
    let isFromMe: Bool               // true = I composed this, false = I scanned it
    let timestamp: Date              // When the message was added to the conversation
    
    /// Whether the plaintext has been revealed yet.
    var isLocked: Bool {
        isPinProtected && text == nil
    }
    
    /// Create from a decoded (plaintext) GlyphMessage.
    init(from message: GlyphMessage, isFromMe: Bool, rawPayload: String? = nil) {
        self.id = UUID()
        self.text = message.text
        self.imageData = message.imageData
        self.audioData = message.audioData
        self.signature = message.signature
        self.rawPayload = rawPayload
        self.isPinProtected = false
        self.isFromMe = isFromMe
        self.timestamp = Date()
    }
    
    /// Create a locked (PIN-protected) message — payload stored, content hidden until unlocked.
    init(lockedPayload: String, signature: SocialSignature?, isFromMe: Bool) {
        self.id = UUID()
        self.text = nil
        self.imageData = nil
        self.audioData = nil
        self.signature = signature
        self.rawPayload = lockedPayload
        self.isPinProtected = true
        self.isFromMe = isFromMe
        self.timestamp = Date()
    }
    
    /// Produce an unlocked copy with decoded content.
    func unlocked(with message: GlyphMessage) -> ConversationMessage {
        ConversationMessage(
            id: self.id,
            text: message.text,
            imageData: message.imageData,
            audioData: message.audioData,
            signature: message.signature ?? self.signature,
            rawPayload: self.rawPayload,
            isPinProtected: true,       // Still flagged as PIN-protected (was locked)
            isFromMe: self.isFromMe,
            timestamp: self.timestamp,
            isUnlocked: true
        )
    }
    
    // Private memberwise for unlocked copy
    private init(id: UUID, text: String?, imageData: String?, audioData: String?,
                 signature: SocialSignature?, rawPayload: String?,
                 isPinProtected: Bool, isFromMe: Bool, timestamp: Date, isUnlocked: Bool) {
        self.id = id
        self.text = text
        self.imageData = imageData
        self.audioData = audioData
        self.signature = signature
        self.rawPayload = rawPayload
        self.isPinProtected = isPinProtected
        self.isFromMe = isFromMe
        self.timestamp = timestamp
    }
}

// MARK: - Conversation

/// A thread between you and a friend. Identified by the friend's social id.
struct Conversation: Codable, Identifiable, Equatable {
    var id: String { friendId }           // e.g. "instagram:username"
    let friendId: String                  // Same as GlyphFriend.id
    var messages: [ConversationMessage]
    
    /// The most recent message, if any.
    var lastMessage: ConversationMessage? { messages.last }
    
    /// How many locked messages remain.
    var lockedCount: Int { messages.filter(\.isLocked).count }
    
    /// Preview text for the friends list.
    var previewText: String {
        guard let last = lastMessage else { return "No messages" }
        if last.isLocked { return "Locked message" }
        let prefix = last.isFromMe ? "You: " : ""
        return prefix + (last.text ?? "Media")
    }
}

// MARK: - Conversation Store

/// Manages all conversation threads. Fully offline — stored in UserDefaults.
final class ConversationStore: ObservableObject {
    
    static let shared = ConversationStore()
    
    private let key = "glyphConversations"
    
    @Published private(set) var conversations: [Conversation] = []
    
    private init() {
        load()
    }
    
    // MARK: - Public API
    
    /// Get or create a conversation for a friend.
    func conversation(for friendId: String) -> Conversation {
        if let existing = conversations.first(where: { $0.friendId == friendId }) {
            return existing
        }
        let new = Conversation(friendId: friendId, messages: [])
        conversations.append(new)
        save()
        return new
    }
    
    /// Add a decoded (plaintext) message to a friend's conversation.
    @discardableResult
    func addMessage(_ message: GlyphMessage, to friendId: String, isFromMe: Bool, rawPayload: String? = nil) -> ConversationMessage {
        let convoMsg = ConversationMessage(from: message, isFromMe: isFromMe, rawPayload: rawPayload)
        appendMessage(convoMsg, to: friendId)
        return convoMsg
    }
    
    /// Add a locked (PIN-protected) message to a friend's conversation.
    @discardableResult
    func addLockedMessage(payload: String, signature: SocialSignature?, to friendId: String, isFromMe: Bool) -> ConversationMessage {
        let convoMsg = ConversationMessage(lockedPayload: payload, signature: signature, isFromMe: isFromMe)
        appendMessage(convoMsg, to: friendId)
        return convoMsg
    }
    
    /// Unlock a specific message by replacing it with its decoded content.
    func unlock(messageId: UUID, in friendId: String, with decoded: GlyphMessage) {
        guard let ci = conversations.firstIndex(where: { $0.friendId == friendId }),
              let mi = conversations[ci].messages.firstIndex(where: { $0.id == messageId }) else { return }
        conversations[ci].messages[mi] = conversations[ci].messages[mi].unlocked(with: decoded)
        save()
    }
    
    /// All locked messages in a conversation (for the unlock flow).
    func lockedMessages(for friendId: String) -> [ConversationMessage] {
        conversation(for: friendId).messages.filter(\.isLocked)
    }
    
    /// Delete a conversation.
    func deleteConversation(for friendId: String) {
        conversations.removeAll { $0.friendId == friendId }
        save()
    }
    
    /// Message count for a friend.
    func messageCount(for friendId: String) -> Int {
        conversation(for: friendId).messages.count
    }
    
    // MARK: - Internal
    
    private func appendMessage(_ msg: ConversationMessage, to friendId: String) {
        if let index = conversations.firstIndex(where: { $0.friendId == friendId }) {
            conversations[index].messages.append(msg)
        } else {
            var convo = Conversation(friendId: friendId, messages: [])
            convo.messages.append(msg)
            conversations.append(convo)
        }
        save()
    }
    
    // MARK: - Persistence
    
    private func save() {
        guard let data = try? JSONEncoder().encode(conversations) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
    
    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([Conversation].self, from: data) else { return }
        conversations = decoded
    }
}
