import XCTest
@testable import Glyph

// ═══════════════════════════════════════════════════════════════
// MARK: - GlyphMessage Tests
// ═══════════════════════════════════════════════════════════════

final class GlyphMessageTests: XCTestCase {
    
    // MARK: - Basic Init & Properties
    
    func testInitSetsAllFields() {
        let msg = GlyphMessage(
            text: "Hello",
            expirationSeconds: 30,
            createdAt: Date(),
            imageData: "base64img",
            audioData: "base64audio",
            expiresAt: Date().addingTimeInterval(3600),
            signature: SocialSignature(platform: .instagram, handle: "user")
        )
        XCTAssertEqual(msg.text, "Hello")
        XCTAssertEqual(msg.expirationSeconds, 30)
        XCTAssertEqual(msg.imageData, "base64img")
        XCTAssertEqual(msg.audioData, "base64audio")
        XCTAssertNotNil(msg.expiresAt)
        XCTAssertNotNil(msg.signature)
        XCTAssertEqual(msg.signature?.handle, "user")
    }
    
    func testInitDefaultsOptionals() {
        let msg = GlyphMessage(text: "Hi", expirationSeconds: 10, createdAt: Date())
        XCTAssertNil(msg.imageData)
        XCTAssertNil(msg.audioData)
        XCTAssertNil(msg.expiresAt)
        XCTAssertNil(msg.signature)
    }
    
    func testEquatableById() {
        let msg1 = GlyphMessage(text: "A", expirationSeconds: 10, createdAt: Date())
        let msg2 = GlyphMessage(text: "A", expirationSeconds: 10, createdAt: Date())
        // Different UUIDs
        XCTAssertNotEqual(msg1, msg2)
        // Same reference
        XCTAssertEqual(msg1, msg1)
    }
    
    // MARK: - Encode / Decode Round-Trip (Tier 1 — Embedded Key)
    
    func testEncodeDecodeRoundTrip() {
        let original = GlyphMessage(
            text: "Secret message",
            expirationSeconds: 60,
            createdAt: Date()
        )
        guard let encoded = original.encode() else {
            XCTFail("Encoding returned nil")
            return
        }
        XCTAssertTrue(GlyphMessage.isMessage(encoded))
        
        guard let decoded = GlyphMessage.decode(from: encoded) else {
            XCTFail("Decoding returned nil")
            return
        }
        XCTAssertEqual(decoded.text, "Secret message")
        XCTAssertEqual(decoded.expirationSeconds, 60)
    }
    
    func testEncodeDecodeWithSignature() {
        let sig = SocialSignature(platform: .x, handle: "testhandle")
        let original = GlyphMessage(
            text: "Signed",
            expirationSeconds: 30,
            createdAt: Date(),
            signature: sig
        )
        guard let encoded = original.encode(),
              let decoded = GlyphMessage.decode(from: encoded) else {
            XCTFail("Round-trip failed")
            return
        }
        XCTAssertEqual(decoded.signature?.platform, .x)
        XCTAssertEqual(decoded.signature?.handle, "testhandle")
    }
    
    // MARK: - Encode / Decode (Tier 2 — PIN-Protected)
    
    func testPinEncryptionRoundTrip() {
        let original = GlyphMessage(text: "PIN secret", expirationSeconds: 10, createdAt: Date())
        guard let encoded = original.encode(pin: "1234") else {
            XCTFail("PIN encoding returned nil")
            return
        }
        XCTAssertTrue(GlyphMessage.isPinProtected(encoded))
        
        // Wrong PIN returns nil
        XCTAssertNil(GlyphMessage.decode(from: encoded, pin: "0000"))
        
        // Correct PIN decodes
        guard let decoded = GlyphMessage.decode(from: encoded, pin: "1234") else {
            XCTFail("Correct PIN decode returned nil")
            return
        }
        XCTAssertEqual(decoded.text, "PIN secret")
    }
    
    func testPinMessageCannotDecodeWithoutPin() {
        let original = GlyphMessage(text: "Locked", expirationSeconds: 10, createdAt: Date())
        guard let encoded = original.encode(pin: "5678") else {
            XCTFail("Encoding returned nil")
            return
        }
        // decode(from:) without PIN returns nil for GLY1P: messages
        XCTAssertNil(GlyphMessage.decode(from: encoded))
    }
    
    // MARK: - Logo QR Detection
    
    func testLogoQRDetection() {
        XCTAssertTrue(GlyphMessage.isLogoQR("https://glyphmsg.io/app"))
        XCTAssertTrue(GlyphMessage.isLogoQR("https://glyphmsg.io/app/"))
        XCTAssertTrue(GlyphMessage.isLogoQR("http://glyphmsg.io/app"))
        XCTAssertTrue(GlyphMessage.isLogoQR("HTTPS://GLYPHMSG.IO/APP"))
        XCTAssertFalse(GlyphMessage.isLogoQR("https://google.com"))
        XCTAssertFalse(GlyphMessage.isLogoQR("GLY1:random"))
    }
    
    // MARK: - Expiration Logic
    
    func testIsReadOnce() {
        let msg = GlyphMessage(text: "Once", expirationSeconds: ExpirationOption.readOnce.rawValue, createdAt: Date())
        XCTAssertEqual(msg.expirationSeconds, -1)
    }
    
    func testIsForever() {
        let msg = GlyphMessage(text: "Forever", expirationSeconds: ExpirationOption.forever.rawValue, createdAt: Date())
        XCTAssertEqual(msg.expirationSeconds, -2)
    }
    
    func testWindowExpired() {
        let pastDate = Date().addingTimeInterval(-100)
        let msg = GlyphMessage(text: "Expired", expirationSeconds: 30, createdAt: Date(), expiresAt: pastDate)
        XCTAssertTrue(msg.isWindowExpired)
    }
    
    func testWindowNotExpired() {
        let futureDate = Date().addingTimeInterval(3600)
        let msg = GlyphMessage(text: "Valid", expirationSeconds: 30, createdAt: Date(), expiresAt: futureDate)
        XCTAssertFalse(msg.isWindowExpired)
    }
    
    func testNoWindowNeverExpires() {
        let msg = GlyphMessage(text: "No window", expirationSeconds: 30, createdAt: Date())
        XCTAssertFalse(msg.isWindowExpired)
    }
    
    // MARK: - isMessage Detection
    
    func testIsMessageDetectsAllFormats() {
        XCTAssertTrue(GlyphMessage.isMessage("GLY1:abc"))
        XCTAssertTrue(GlyphMessage.isMessage("GLY1E:abc"))
        XCTAssertTrue(GlyphMessage.isMessage("GLY1P:abc"))
        XCTAssertFalse(GlyphMessage.isMessage("RANDOM:abc"))
        XCTAssertFalse(GlyphMessage.isMessage("https://example.com"))
    }
    
    // MARK: - Backward Compatibility (no signature)
    
    func testDecodeWithoutSignature() {
        // Simulate an old message without signature field
        let msg = GlyphMessage(text: "Old", expirationSeconds: 10, createdAt: Date())
        guard let encoded = msg.encode(),
              let decoded = GlyphMessage.decode(from: encoded) else {
            XCTFail("Round-trip failed")
            return
        }
        XCTAssertNil(decoded.signature)
        XCTAssertEqual(decoded.text, "Old")
    }
    
    // MARK: - needsBatching
    
    func testNeedsBatchingWithImage() {
        let msg = GlyphMessage(text: "Photo", expirationSeconds: 30, createdAt: Date(), imageData: "base64")
        XCTAssertTrue(msg.needsBatching)
    }
    
    func testNeedsBatchingWithAudio() {
        let msg = GlyphMessage(text: "Audio", expirationSeconds: 30, createdAt: Date(), audioData: "base64")
        XCTAssertTrue(msg.needsBatching)
    }
    
    func testNeedsBatchingTextOnly() {
        let msg = GlyphMessage(text: "Text", expirationSeconds: 30, createdAt: Date())
        XCTAssertFalse(msg.needsBatching)
    }
}

// ═══════════════════════════════════════════════════════════════
// MARK: - SocialProfile Tests
// ═══════════════════════════════════════════════════════════════

final class SocialProfileTests: XCTestCase {
    
    // MARK: - SocialPlatform
    
    func testAllPlatformsHaveDisplayName() {
        for platform in SocialPlatform.allCases {
            XCTAssertFalse(platform.displayName.isEmpty, "\(platform) has empty displayName")
        }
    }
    
    func testAllPlatformsHaveIcon() {
        for platform in SocialPlatform.allCases {
            XCTAssertFalse(platform.icon.isEmpty, "\(platform) has empty icon")
        }
    }
    
    func testProfileURLGeneration() {
        XCTAssertEqual(SocialPlatform.instagram.profileURL(handle: "user")?.absoluteString, "https://instagram.com/user")
        XCTAssertEqual(SocialPlatform.x.profileURL(handle: "user")?.absoluteString, "https://x.com/user")
        XCTAssertEqual(SocialPlatform.tiktok.profileURL(handle: "user")?.absoluteString, "https://tiktok.com/@user")
        XCTAssertEqual(SocialPlatform.snapchat.profileURL(handle: "user")?.absoluteString, "https://snapchat.com/add/user")
        XCTAssertEqual(SocialPlatform.youtube.profileURL(handle: "user")?.absoluteString, "https://youtube.com/@user")
        XCTAssertEqual(SocialPlatform.threads.profileURL(handle: "user")?.absoluteString, "https://threads.net/@user")
    }
    
    func testProfileURLStripsAt() {
        XCTAssertEqual(SocialPlatform.instagram.profileURL(handle: "@user")?.absoluteString, "https://instagram.com/user")
    }
    
    func testProfileURLEmptyHandle() {
        XCTAssertNil(SocialPlatform.instagram.profileURL(handle: ""))
        XCTAssertNil(SocialPlatform.instagram.profileURL(handle: "   "))
        XCTAssertNil(SocialPlatform.instagram.profileURL(handle: "@"))
    }
    
    func testPlatformCount() {
        XCTAssertEqual(SocialPlatform.allCases.count, 6)
    }
    
    // MARK: - SocialSignature
    
    func testSignatureStripsAt() {
        let sig = SocialSignature(platform: .instagram, handle: "@myuser")
        XCTAssertEqual(sig.handle, "myuser")
    }
    
    func testSignatureDisplayText() {
        let sig = SocialSignature(platform: .tiktok, handle: "creator")
        XCTAssertEqual(sig.displayText, "@creator on TikTok")
    }
    
    func testSignatureProfileURL() {
        let sig = SocialSignature(platform: .x, handle: "dev")
        XCTAssertNotNil(sig.profileURL)
        XCTAssertEqual(sig.profileURL?.absoluteString, "https://x.com/dev")
    }
    
    func testSignatureEquatable() {
        let a = SocialSignature(platform: .instagram, handle: "same")
        let b = SocialSignature(platform: .instagram, handle: "same")
        let c = SocialSignature(platform: .x, handle: "same")
        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, c)
    }
    
    func testSignatureCodable() throws {
        let sig = SocialSignature(platform: .snapchat, handle: "testuser")
        let data = try JSONEncoder().encode(sig)
        let decoded = try JSONDecoder().decode(SocialSignature.self, from: data)
        XCTAssertEqual(decoded.platform, .snapchat)
        XCTAssertEqual(decoded.handle, "testuser")
    }
    
    // MARK: - SocialProfile Singleton
    
    func testSocialProfileIsLinked() {
        let profile = SocialProfile.shared
        let originalHandle = profile.handle
        let originalPlatform = profile.platform
        
        profile.handle = ""
        XCTAssertFalse(profile.isLinked)
        
        profile.handle = "testuser"
        XCTAssertTrue(profile.isLinked)
        
        profile.handle = "   @   "
        XCTAssertFalse(profile.isLinked)
        
        // Restore
        profile.handle = originalHandle
        profile.platform = originalPlatform
    }
    
    func testSocialProfileSignature() {
        let profile = SocialProfile.shared
        let originalHandle = profile.handle
        let originalPlatform = profile.platform
        
        profile.handle = ""
        XCTAssertNil(profile.signature)
        
        profile.platform = .youtube
        profile.handle = "channel"
        XCTAssertNotNil(profile.signature)
        XCTAssertEqual(profile.signature?.platform, .youtube)
        XCTAssertEqual(profile.signature?.handle, "channel")
        
        // Restore
        profile.handle = originalHandle
        profile.platform = originalPlatform
    }
    
    func testSocialProfileUnlink() {
        let profile = SocialProfile.shared
        let originalHandle = profile.handle
        let originalPlatform = profile.platform
        
        profile.platform = .threads
        profile.handle = "someone"
        XCTAssertTrue(profile.isLinked)
        
        profile.unlink()
        XCTAssertFalse(profile.isLinked)
        XCTAssertEqual(profile.platform, .instagram) // Default
        XCTAssertEqual(profile.handle, "")
        
        // Restore
        profile.handle = originalHandle
        profile.platform = originalPlatform
    }
}

// ═══════════════════════════════════════════════════════════════
// MARK: - FriendStore Tests
// ═══════════════════════════════════════════════════════════════

final class FriendStoreTests: XCTestCase {
    
    // Use a fresh key for test isolation
    private func makeTestStore() -> FriendStore {
        // We test the shared instance but clean up after
        return FriendStore.shared
    }
    
    override func tearDown() {
        super.tearDown()
        // Clean up any test friends
        let store = FriendStore.shared
        let testFriends = store.friends.filter { $0.handle.hasPrefix("test_") }
        for friend in testFriends {
            store.remove(friend)
        }
    }
    
    func testAddNewFriend() {
        let store = makeTestStore()
        let sig = SocialSignature(platform: .instagram, handle: "test_newuser")
        let isNew = store.addOrUpdate(from: sig)
        XCTAssertTrue(isNew)
        XCTAssertTrue(store.isFriend(sig))
    }
    
    func testAddExistingFriendBumpsCount() {
        let store = makeTestStore()
        let sig = SocialSignature(platform: .instagram, handle: "test_repeat")
        store.addOrUpdate(from: sig)
        let isNew = store.addOrUpdate(from: sig)
        XCTAssertFalse(isNew) // Not new — updated
        
        let friend = store.friend(for: sig)
        XCTAssertNotNil(friend)
        XCTAssertEqual(friend?.messageCount, 2)
    }
    
    func testIsFriend() {
        let store = makeTestStore()
        let sig = SocialSignature(platform: .tiktok, handle: "test_check")
        XCTAssertFalse(store.isFriend(sig))
        store.addOrUpdate(from: sig)
        XCTAssertTrue(store.isFriend(sig))
    }
    
    func testRemoveFriend() {
        let store = makeTestStore()
        let sig = SocialSignature(platform: .x, handle: "test_removable")
        store.addOrUpdate(from: sig)
        XCTAssertTrue(store.isFriend(sig))
        
        if let friend = store.friend(for: sig) {
            store.remove(friend)
        }
        XCTAssertFalse(store.isFriend(sig))
    }
    
    func testSetNickname() {
        let store = makeTestStore()
        let sig = SocialSignature(platform: .snapchat, handle: "test_nick")
        store.addOrUpdate(from: sig)
        
        if let friend = store.friend(for: sig) {
            XCTAssertNil(friend.nickname)
            store.setNickname("Bestie", for: friend)
        }
        
        let updated = store.friend(for: sig)
        XCTAssertEqual(updated?.nickname, "Bestie")
    }
    
    func testFriendId() {
        let sig = SocialSignature(platform: .youtube, handle: "test_channel")
        let friend = GlyphFriend(from: sig)
        XCTAssertEqual(friend.id, "youtube:test_channel")
    }
    
    func testFriendDisplayHandle() {
        let friend = GlyphFriend(from: SocialSignature(platform: .instagram, handle: "test_display"))
        XCTAssertEqual(friend.displayHandle, "@test_display")
    }
    
    func testFriendProfileURL() {
        let friend = GlyphFriend(from: SocialSignature(platform: .threads, handle: "test_threads"))
        XCTAssertNotNil(friend.profileURL)
        XCTAssertEqual(friend.profileURL?.absoluteString, "https://threads.net/@test_threads")
    }
    
    func testFriendHashable() {
        let a = GlyphFriend(from: SocialSignature(platform: .instagram, handle: "test_hash1"))
        let b = GlyphFriend(from: SocialSignature(platform: .instagram, handle: "test_hash1"))
        // Hashable — same platform + handle = same hash
        XCTAssertEqual(a.hashValue, b.hashValue)
    }
    
    func testDifferentPlatformsSameHandleAreDifferent() {
        let store = makeTestStore()
        let sig1 = SocialSignature(platform: .instagram, handle: "test_cross")
        let sig2 = SocialSignature(platform: .x, handle: "test_cross")
        store.addOrUpdate(from: sig1)
        store.addOrUpdate(from: sig2)
        XCTAssertTrue(store.isFriend(sig1))
        XCTAssertTrue(store.isFriend(sig2))
        // They should be different friends
        XCTAssertNotEqual(store.friend(for: sig1)?.id, store.friend(for: sig2)?.id)
    }
}

// ═══════════════════════════════════════════════════════════════
// MARK: - ConversationStore Tests
// ═══════════════════════════════════════════════════════════════

final class ConversationStoreTests: XCTestCase {
    
    private let testFriendId = "instagram:test_convo_user"
    
    override func tearDown() {
        super.tearDown()
        ConversationStore.shared.deleteConversation(for: testFriendId)
        ConversationStore.shared.deleteConversation(for: "x:test_convo_other")
    }
    
    func testGetOrCreateConversation() {
        let store = ConversationStore.shared
        let convo = store.conversation(for: testFriendId)
        XCTAssertEqual(convo.friendId, testFriendId)
        XCTAssertTrue(convo.messages.isEmpty)
    }
    
    func testAddMessage() {
        let store = ConversationStore.shared
        let msg = GlyphMessage(text: "Test message", expirationSeconds: 30, createdAt: Date())
        store.addMessage(msg, to: testFriendId, isFromMe: false)
        
        let convo = store.conversation(for: testFriendId)
        XCTAssertEqual(convo.messages.count, 1)
        XCTAssertEqual(convo.messages.first?.text, "Test message")
        XCTAssertFalse(convo.messages.first!.isFromMe)
    }
    
    func testAddMessageFromMe() {
        let store = ConversationStore.shared
        let msg = GlyphMessage(text: "My reply", expirationSeconds: 30, createdAt: Date())
        store.addMessage(msg, to: testFriendId, isFromMe: true)
        
        let convo = store.conversation(for: testFriendId)
        XCTAssertTrue(convo.messages.first!.isFromMe)
    }
    
    func testAddLockedMessage() {
        let store = ConversationStore.shared
        let sig = SocialSignature(platform: .instagram, handle: "test_convo_user")
        store.addLockedMessage(payload: "GLY1P:encrypted_stuff", signature: sig, to: testFriendId, isFromMe: false)
        
        let convo = store.conversation(for: testFriendId)
        XCTAssertEqual(convo.messages.count, 1)
        XCTAssertTrue(convo.messages.first!.isLocked)
        XCTAssertTrue(convo.messages.first!.isPinProtected)
        XCTAssertNil(convo.messages.first!.text)
    }
    
    func testLockedCount() {
        let store = ConversationStore.shared
        let msg = GlyphMessage(text: "Open", expirationSeconds: 30, createdAt: Date())
        store.addMessage(msg, to: testFriendId, isFromMe: false)
        store.addLockedMessage(payload: "GLY1P:data", signature: nil, to: testFriendId, isFromMe: false)
        
        let convo = store.conversation(for: testFriendId)
        XCTAssertEqual(convo.lockedCount, 1)
    }
    
    func testUnlockMessage() {
        let store = ConversationStore.shared
        store.addLockedMessage(payload: "GLY1P:data", signature: nil, to: testFriendId, isFromMe: false)
        
        let convo = store.conversation(for: testFriendId)
        let lockedMsg = convo.messages.first!
        XCTAssertTrue(lockedMsg.isLocked)
        
        let decoded = GlyphMessage(text: "Revealed!", expirationSeconds: 30, createdAt: Date())
        store.unlock(messageId: lockedMsg.id, in: testFriendId, with: decoded)
        
        let updated = store.conversation(for: testFriendId)
        XCTAssertFalse(updated.messages.first!.isLocked)
        XCTAssertEqual(updated.messages.first!.text, "Revealed!")
    }
    
    func testDeleteConversation() {
        let store = ConversationStore.shared
        let msg = GlyphMessage(text: "Delete me", expirationSeconds: 30, createdAt: Date())
        store.addMessage(msg, to: testFriendId, isFromMe: true)
        XCTAssertFalse(store.conversation(for: testFriendId).messages.isEmpty)
        
        store.deleteConversation(for: testFriendId)
        // After delete, a fresh conversation is created (empty)
        let fresh = store.conversations.first { $0.friendId == testFriendId }
        XCTAssertNil(fresh) // Should not exist in stored conversations
    }
    
    func testPreviewText() {
        let store = ConversationStore.shared
        
        // Empty
        var convo = store.conversation(for: testFriendId)
        XCTAssertEqual(convo.previewText, "No messages")
        
        // With message from friend
        let msg = GlyphMessage(text: "Hey there", expirationSeconds: 30, createdAt: Date())
        store.addMessage(msg, to: testFriendId, isFromMe: false)
        convo = store.conversation(for: testFriendId)
        XCTAssertEqual(convo.previewText, "Hey there")
        
        // With message from me
        let reply = GlyphMessage(text: "Hi back", expirationSeconds: 30, createdAt: Date())
        store.addMessage(reply, to: testFriendId, isFromMe: true)
        convo = store.conversation(for: testFriendId)
        XCTAssertEqual(convo.previewText, "You: Hi back")
    }
    
    func testMultipleConversationsAreIsolated() {
        let store = ConversationStore.shared
        let msg1 = GlyphMessage(text: "For user1", expirationSeconds: 30, createdAt: Date())
        let msg2 = GlyphMessage(text: "For user2", expirationSeconds: 30, createdAt: Date())
        store.addMessage(msg1, to: testFriendId, isFromMe: false)
        store.addMessage(msg2, to: "x:test_convo_other", isFromMe: false)
        
        let convo1 = store.conversation(for: testFriendId)
        let convo2 = store.conversation(for: "x:test_convo_other")
        XCTAssertEqual(convo1.messages.count, 1)
        XCTAssertEqual(convo2.messages.count, 1)
        XCTAssertEqual(convo1.messages.first?.text, "For user1")
        XCTAssertEqual(convo2.messages.first?.text, "For user2")
    }
    
    func testMessageCount() {
        let store = ConversationStore.shared
        XCTAssertEqual(store.messageCount(for: testFriendId), 0)
        
        let msg = GlyphMessage(text: "Count me", expirationSeconds: 30, createdAt: Date())
        store.addMessage(msg, to: testFriendId, isFromMe: true)
        XCTAssertEqual(store.messageCount(for: testFriendId), 1)
    }
}

// ═══════════════════════════════════════════════════════════════
// MARK: - ConversationMessage Tests
// ═══════════════════════════════════════════════════════════════

final class ConversationMessageTests: XCTestCase {
    
    func testCreateFromGlyphMessage() {
        let msg = GlyphMessage(
            text: "Hello",
            expirationSeconds: 30,
            createdAt: Date(),
            signature: SocialSignature(platform: .instagram, handle: "sender")
        )
        let convoMsg = ConversationMessage(from: msg, isFromMe: false)
        XCTAssertEqual(convoMsg.text, "Hello")
        XCTAssertFalse(convoMsg.isFromMe)
        XCTAssertFalse(convoMsg.isPinProtected)
        XCTAssertFalse(convoMsg.isLocked)
        XCTAssertEqual(convoMsg.signature?.handle, "sender")
    }
    
    func testCreateLockedMessage() {
        let sig = SocialSignature(platform: .x, handle: "locked_user")
        let convoMsg = ConversationMessage(lockedPayload: "GLY1P:data", signature: sig, isFromMe: false)
        XCTAssertNil(convoMsg.text)
        XCTAssertTrue(convoMsg.isPinProtected)
        XCTAssertTrue(convoMsg.isLocked)
        XCTAssertEqual(convoMsg.rawPayload, "GLY1P:data")
    }
    
    func testUnlockedCopy() {
        let convoMsg = ConversationMessage(lockedPayload: "GLY1P:data", signature: nil, isFromMe: false)
        XCTAssertTrue(convoMsg.isLocked)
        
        let decoded = GlyphMessage(text: "Unlocked!", expirationSeconds: 30, createdAt: Date())
        let unlocked = convoMsg.unlocked(with: decoded)
        
        XCTAssertEqual(unlocked.text, "Unlocked!")
        XCTAssertFalse(unlocked.isLocked) // text is now set
        XCTAssertTrue(unlocked.isPinProtected) // flag still true
        XCTAssertEqual(unlocked.id, convoMsg.id) // Same ID
        XCTAssertEqual(unlocked.timestamp, convoMsg.timestamp) // Same timestamp
    }
    
    func testCodableRoundTrip() throws {
        let msg = GlyphMessage(text: "Codable test", expirationSeconds: 10, createdAt: Date())
        let convoMsg = ConversationMessage(from: msg, isFromMe: true)
        
        let data = try JSONEncoder().encode(convoMsg)
        let decoded = try JSONDecoder().decode(ConversationMessage.self, from: data)
        
        XCTAssertEqual(decoded.text, "Codable test")
        XCTAssertTrue(decoded.isFromMe)
        XCTAssertEqual(decoded.id, convoMsg.id)
    }
}

// ═══════════════════════════════════════════════════════════════
// MARK: - GlyphCrypto Tests
// ═══════════════════════════════════════════════════════════════

final class GlyphCryptoTests: XCTestCase {
    
    func testKeyGeneration() {
        let key = GlyphCrypto.generateKey()
        let hex = GlyphCrypto.keyToHex(key)
        XCTAssertEqual(hex.count, 64) // 32 bytes = 64 hex chars
    }
    
    func testKeyHexRoundTrip() {
        let key = GlyphCrypto.generateKey()
        let hex = GlyphCrypto.keyToHex(key)
        let restored = GlyphCrypto.keyFromHex(hex)
        XCTAssertNotNil(restored)
    }
    
    func testKeyFromHexInvalidLength() {
        XCTAssertNil(GlyphCrypto.keyFromHex("abc"))
        XCTAssertNil(GlyphCrypto.keyFromHex(""))
    }
    
    func testEncryptDecryptCore() {
        let key = GlyphCrypto.generateKey()
        let plaintext = Data("Hello World".utf8)
        
        guard let (nonce, ciphertext) = GlyphCrypto.encrypt(plaintext, key: key) else {
            XCTFail("Encryption failed")
            return
        }
        
        guard let decrypted = GlyphCrypto.decrypt(ciphertext, key: key, nonce: nonce) else {
            XCTFail("Decryption failed")
            return
        }
        
        XCTAssertEqual(decrypted, plaintext)
    }
    
    func testDecryptWithWrongKeyFails() {
        let key1 = GlyphCrypto.generateKey()
        let key2 = GlyphCrypto.generateKey()
        let plaintext = Data("Secret".utf8)
        
        guard let (nonce, ciphertext) = GlyphCrypto.encrypt(plaintext, key: key1) else {
            XCTFail("Encryption failed")
            return
        }
        
        let result = GlyphCrypto.decrypt(ciphertext, key: key2, nonce: nonce)
        XCTAssertNil(result)
    }
    
    func testSaltGeneration() {
        let salt = GlyphCrypto.generateSalt()
        XCTAssertEqual(salt.count, 32)
        
        // Two salts should differ
        let salt2 = GlyphCrypto.generateSalt()
        XCTAssertNotEqual(salt, salt2)
    }
    
    func testPinKeyDerivation() {
        let salt = GlyphCrypto.generateSalt()
        let key1 = GlyphCrypto.deriveKey(pin: "1234", salt: salt)
        let key2 = GlyphCrypto.deriveKey(pin: "1234", salt: salt)
        // Same PIN + same salt = same key
        XCTAssertEqual(GlyphCrypto.keyToHex(key1), GlyphCrypto.keyToHex(key2))
        
        // Different PIN = different key
        let key3 = GlyphCrypto.deriveKey(pin: "5678", salt: salt)
        XCTAssertNotEqual(GlyphCrypto.keyToHex(key1), GlyphCrypto.keyToHex(key3))
        
        // Different salt = different key
        let salt2 = GlyphCrypto.generateSalt()
        let key4 = GlyphCrypto.deriveKey(pin: "1234", salt: salt2)
        XCTAssertNotEqual(GlyphCrypto.keyToHex(key1), GlyphCrypto.keyToHex(key4))
    }
    
    // MARK: - Detection Helpers
    
    func testIsEncryptedMessage() {
        XCTAssertTrue(GlyphCrypto.isEncryptedMessage("GLY1E:abc"))
        XCTAssertFalse(GlyphCrypto.isEncryptedMessage("GLY1P:abc"))
        XCTAssertFalse(GlyphCrypto.isEncryptedMessage("GLY1:abc"))
    }
    
    func testIsPinProtectedMessage() {
        XCTAssertTrue(GlyphCrypto.isPinProtectedMessage("GLY1P:abc"))
        XCTAssertFalse(GlyphCrypto.isPinProtectedMessage("GLY1E:abc"))
    }
    
    func testIsPinProtectedGeneral() {
        XCTAssertTrue(GlyphCrypto.isPinProtected("GLY1P:abc"))
        XCTAssertTrue(GlyphCrypto.isPinProtected("GLYCP:abc"))
        XCTAssertTrue(GlyphCrypto.isPinProtected("GLYWP:abc"))
        XCTAssertTrue(GlyphCrypto.isPinProtected("GLYRP:abc"))
        XCTAssertFalse(GlyphCrypto.isPinProtected("GLY1E:abc"))
        XCTAssertFalse(GlyphCrypto.isPinProtected("RANDOM"))
    }
    
    // MARK: - Full Message Encrypt/Decrypt
    
    func testEncryptMessageEmbeddedKey() {
        let msg = GlyphMessage(text: "Encrypted", expirationSeconds: 30, createdAt: Date())
        guard let payload = msg.encode() else {
            XCTFail("Encode returned nil")
            return
        }
        XCTAssertTrue(payload.hasPrefix("GLY1E:"))
        
        guard let decrypted = GlyphCrypto.decryptMessage(payload) else {
            XCTFail("Decrypt returned nil")
            return
        }
        XCTAssertEqual(decrypted.text, "Encrypted")
    }
    
    func testEncryptMessagePinProtected() {
        let msg = GlyphMessage(text: "PIN msg", expirationSeconds: 30, createdAt: Date())
        guard let payload = msg.encode(pin: "9999") else {
            XCTFail("Encode with PIN returned nil")
            return
        }
        XCTAssertTrue(payload.hasPrefix("GLY1P:"))
        
        // Can't decrypt without PIN
        XCTAssertNil(GlyphCrypto.decryptMessage(payload))
        
        // Can decrypt with correct PIN
        guard let decrypted = GlyphCrypto.decryptMessage(payload, pin: "9999") else {
            XCTFail("Decrypt with PIN returned nil")
            return
        }
        XCTAssertEqual(decrypted.text, "PIN msg")
    }
}

// ═══════════════════════════════════════════════════════════════
// MARK: - ExpirationOption Tests
// ═══════════════════════════════════════════════════════════════

final class ExpirationOptionTests: XCTestCase {
    
    func testAllCasesCount() {
        XCTAssertEqual(ExpirationOption.allCases.count, 6)
    }
    
    func testRawValues() {
        XCTAssertEqual(ExpirationOption.readOnce.rawValue, -1)
        XCTAssertEqual(ExpirationOption.seconds10.rawValue, 10)
        XCTAssertEqual(ExpirationOption.seconds30.rawValue, 30)
        XCTAssertEqual(ExpirationOption.minute1.rawValue, 60)
        XCTAssertEqual(ExpirationOption.minutes5.rawValue, 300)
        XCTAssertEqual(ExpirationOption.forever.rawValue, -2)
    }
    
    func testDisplayNames() {
        for option in ExpirationOption.allCases {
            XCTAssertFalse(option.displayName.isEmpty)
        }
    }
    
    func testIcons() {
        for option in ExpirationOption.allCases {
            XCTAssertFalse(option.icon.isEmpty)
        }
    }
}

// ═══════════════════════════════════════════════════════════════
// MARK: - TimeWindow Tests
// ═══════════════════════════════════════════════════════════════

final class TimeWindowTests: XCTestCase {
    
    func testNoneReturnsNilExpiresAt() {
        XCTAssertNil(TimeWindow.none.expiresAt())
    }
    
    func testNonNoneReturnsDate() {
        let now = Date()
        for window in TimeWindow.allCases where window != .none {
            let expiresAt = window.expiresAt(from: now)
            XCTAssertNotNil(expiresAt)
            XCTAssertGreaterThan(expiresAt!, now)
        }
    }
    
    func testExpiresAtIsCorrectInterval() {
        let now = Date()
        let expiresAt = TimeWindow.hour1.expiresAt(from: now)!
        let diff = expiresAt.timeIntervalSince(now)
        XCTAssertEqual(diff, 3600, accuracy: 1.0)
    }
    
    func testAllCasesCount() {
        XCTAssertEqual(TimeWindow.allCases.count, 6)
    }
    
    func testDisplayNames() {
        for window in TimeWindow.allCases {
            XCTAssertFalse(window.displayName.isEmpty)
        }
    }
    
    func testSubtitles() {
        for window in TimeWindow.allCases {
            XCTAssertFalse(window.subtitle.isEmpty)
        }
    }
}

// ═══════════════════════════════════════════════════════════════
// MARK: - GlyphFriend Tests (Codable + Model)
// ═══════════════════════════════════════════════════════════════

final class GlyphFriendTests: XCTestCase {
    
    func testCodableRoundTrip() throws {
        let sig = SocialSignature(platform: .instagram, handle: "codable_test")
        var friend = GlyphFriend(from: sig)
        friend.nickname = "Buddy"
        
        let data = try JSONEncoder().encode(friend)
        let decoded = try JSONDecoder().decode(GlyphFriend.self, from: data)
        
        XCTAssertEqual(decoded.platform, .instagram)
        XCTAssertEqual(decoded.handle, "codable_test")
        XCTAssertEqual(decoded.nickname, "Buddy")
        XCTAssertEqual(decoded.messageCount, 1)
    }
    
    func testInitFromSignature() {
        let sig = SocialSignature(platform: .youtube, handle: "creator")
        let friend = GlyphFriend(from: sig)
        XCTAssertEqual(friend.platform, .youtube)
        XCTAssertEqual(friend.handle, "creator")
        XCTAssertEqual(friend.messageCount, 1)
        XCTAssertNil(friend.nickname)
        XCTAssertNotNil(friend.firstSeen)
        XCTAssertNotNil(friend.lastSeen)
    }
    
    func testEquatable() {
        let sig = SocialSignature(platform: .instagram, handle: "same")
        let a = GlyphFriend(from: sig)
        // Auto-synthesized Equatable compares all fields including dates
        // Two separate inits will have different timestamps, so they won't be equal
        XCTAssertEqual(a, a) // Same instance is always equal
        
        // Different platform = definitely different
        let b = GlyphFriend(from: SocialSignature(platform: .x, handle: "same"))
        XCTAssertNotEqual(a, b)
        
        // Verify id-based identity
        let c = GlyphFriend(from: SocialSignature(platform: .instagram, handle: "same"))
        XCTAssertEqual(a.id, c.id) // Same logical identity
    }
}

// ═══════════════════════════════════════════════════════════════
// MARK: - ScanHistory Tests
// ═══════════════════════════════════════════════════════════════

final class ScanHistoryTests: XCTestCase {
    
    func testNewPayloadAllowed() {
        let history = ScanHistory()
        let msg = GlyphMessage(text: "Fresh", expirationSeconds: 30, createdAt: Date())
        let unique = "GLY1E:unique_test_\(UUID().uuidString)"
        XCTAssertNil(history.shouldBlock(payload: unique, message: msg))
    }
    
    func testForeverAlwaysAllowed() {
        let history = ScanHistory()
        let msg = GlyphMessage(text: "Forever", expirationSeconds: ExpirationOption.forever.rawValue, createdAt: Date())
        let payload = "GLY1E:forever_\(UUID().uuidString)"
        
        history.recordScan(payload: payload, expirationSeconds: msg.expirationSeconds)
        XCTAssertNil(history.shouldBlock(payload: payload, message: msg))
    }
    
    func testReadOnceBlockedAfterFirstScan() {
        let history = ScanHistory()
        let msg = GlyphMessage(text: "Once", expirationSeconds: ExpirationOption.readOnce.rawValue, createdAt: Date())
        let payload = "GLY1E:once_\(UUID().uuidString)"
        
        // First scan — allowed
        XCTAssertNil(history.shouldBlock(payload: payload, message: msg))
        history.recordScan(payload: payload, expirationSeconds: msg.expirationSeconds)
        
        // Second scan — blocked
        let reason = history.shouldBlock(payload: payload, message: msg)
        XCTAssertNotNil(reason)
        XCTAssertTrue(reason!.contains("Read Once"))
    }
    
    func testHasBeenScanned() {
        let history = ScanHistory()
        let payload = "GLY1E:scanned_\(UUID().uuidString)"
        XCTAssertFalse(history.hasBeenScanned(payload: payload))
        history.recordScan(payload: payload, expirationSeconds: 30)
        XCTAssertTrue(history.hasBeenScanned(payload: payload))
    }
    
    func testScanCount() {
        let history = ScanHistory()
        let payload = "GLY1E:count_\(UUID().uuidString)"
        XCTAssertEqual(history.scanCount(for: payload), 0)
        history.recordScan(payload: payload, expirationSeconds: 30)
        XCTAssertEqual(history.scanCount(for: payload), 1)
        history.recordScan(payload: payload, expirationSeconds: 30)
        XCTAssertEqual(history.scanCount(for: payload), 2)
    }
}
