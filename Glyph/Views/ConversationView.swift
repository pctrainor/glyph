import SwiftUI
import AVFoundation

// MARK: - Conversation View

/// Chat thread with a friend. Shows message bubbles (from me vs from them),
/// locked messages with a tap-to-unlock flow, and a compose bar for sending
/// new messages via in-app text or QR code.
struct ConversationView: View {
    let friend: GlyphFriend
    
    @ObservedObject private var convoStore = ConversationStore.shared
    @ObservedObject private var socialProfile = SocialProfile.shared
    @State private var showUnlockFlow = false
    @State private var showComposeQR = false
    @State private var composeText = ""
    @State private var messageQRImages: [UIImage] = []
    @State private var messageQRExpiration: ExpirationOption = .forever
    @State private var showMessageQR = false
    @State private var pendingQRAfterDismiss = false
    @State private var scrollToBottom = false
    
    private var conversation: Conversation {
        convoStore.conversation(for: friend.id)
    }
    
    var body: some View {
        ZStack {
            GlyphTheme.backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Chat header
                chatHeader
                
                Divider()
                    .background(GlyphTheme.accent.opacity(0.1))
                
                if conversation.messages.isEmpty {
                    emptyState
                } else {
                    // Messages list
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(conversation.messages) { msg in
                                    ChatBubble(message: msg, friend: friend) {
                                        showQRForMessage(msg)
                                    }
                                    .id(msg.id)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                        .onAppear {
                            if let last = conversation.messages.last {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                        .onChange(of: conversation.messages.count) { _, _ in
                            if let last = conversation.messages.last {
                                withAnimation {
                                    proxy.scrollTo(last.id, anchor: .bottom)
                                }
                            }
                        }
                        .onChange(of: scrollToBottom) { _, shouldScroll in
                            if shouldScroll, let last = conversation.messages.last {
                                withAnimation {
                                    proxy.scrollTo(last.id, anchor: .bottom)
                                }
                                scrollToBottom = false
                            }
                        }
                    }
                }
                
                // Bottom bar
                bottomBar
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .fullScreenCover(isPresented: $showUnlockFlow) {
            UnlockFlowView(friend: friend)
        }
        .fullScreenCover(isPresented: $showComposeQR, onDismiss: {
            // After compose sheet dismisses, auto-show QR if we have pending images
            if pendingQRAfterDismiss && !messageQRImages.isEmpty {
                pendingQRAfterDismiss = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showMessageQR = true
                }
            }
            scrollToBottom = true
        }) {
            ConversationComposeSheet(
                friend: friend,
                initialText: composeText,
                onGenerate: { images, expiration in
                    messageQRImages = images
                    messageQRExpiration = expiration
                    pendingQRAfterDismiss = true
                }
            )
            .onAppear { composeText = "" }
        }
        .fullScreenCover(isPresented: $showMessageQR, onDismiss: {
            scrollToBottom = true
        }) {
            QRDisplayView(
                qrImages: messageQRImages,
                expiration: messageQRExpiration,
                messagePreview: "Message",
                timeWindow: .none,
                showActions: false
            )
        }
    }
    
    // MARK: - Actions
    
    private func showQRForMessage(_ msg: ConversationMessage) {
        guard !msg.isLocked else { return }
        let glyphMsg = GlyphMessage(
            text: msg.text ?? "",
            expirationSeconds: ExpirationOption.forever.rawValue,
            createdAt: msg.timestamp,
            imageData: msg.imageData,
            audioData: msg.audioData,
            signature: msg.signature
        )
        let images = GlyphChunkSplitter.split(message: glyphMsg)
        guard !images.isEmpty else { return }
        messageQRImages = images
        messageQRExpiration = .forever
        // Delay slightly so state is committed before presenting
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            showMessageQR = true
        }
    }
    
    // MARK: - Chat Header
    
    private var chatHeader: some View {
        HStack(spacing: 12) {
            // Platform icon
            ZStack {
                Circle()
                    .fill(GlyphTheme.accentGradient)
                    .frame(width: 40, height: 40)
                
                Image(systemName: friend.platform.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.black)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(friend.nickname ?? friend.displayHandle)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(GlyphTheme.primaryText)
                
                Text(friend.platform.displayName)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(GlyphTheme.accent)
            }
            
            Spacer()
            
            // Social profile link
            if let url = friend.profileURL {
                Button {
                    UIApplication.shared.open(url)
                } label: {
                    Image(systemName: "arrow.up.right.square")
                        .font(.system(size: 16))
                        .foregroundColor(GlyphTheme.accent.opacity(0.6))
                }
            }
            
            // Unlock all button (if there are locked messages)
            if conversation.lockedCount > 0 {
                Button {
                    showUnlockFlow = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "lock.open")
                            .font(.system(size: 13, weight: .semibold))
                        Text("\(conversation.lockedCount)")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(GlyphTheme.accentGradient)
                    .clipShape(Capsule())
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(GlyphTheme.surface.opacity(0.5))
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 48, weight: .thin))
                .foregroundStyle(GlyphTheme.accentGradient)
            
            Text("No messages yet")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(GlyphTheme.primaryText)
            
            Text("Scan their Glyph codes or\nsend one via QR")
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(GlyphTheme.secondaryText)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
    }
    
    // MARK: - Bottom Bar
    
    private var bottomBar: some View {
        HStack(spacing: 12) {
            // Message input
            TextField("Message...", text: $composeText)
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundColor(GlyphTheme.primaryText)
                .autocorrectionDisabled()
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(GlyphTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 22))
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(GlyphTheme.accent.opacity(0.15), lineWidth: 1)
                )
            
            // Send via QR button
            Button {
                showComposeQR = true
            } label: {
                Image(systemName: "qrcode")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(GlyphTheme.violet)
                    .frame(width: 44, height: 44)
                    .background(GlyphTheme.surface)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(GlyphTheme.violet.opacity(0.3), lineWidth: 1)
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(GlyphTheme.background.opacity(0.9))
    }
    
}

// MARK: - Chat Bubble

struct ChatBubble: View {
    let message: ConversationMessage
    let friend: GlyphFriend
    var onTap: (() -> Void)? = nil
    
    var body: some View {
        HStack {
            if message.isFromMe { Spacer(minLength: 60) }
            
            VStack(alignment: message.isFromMe ? .trailing : .leading, spacing: 4) {
                // Locked state
                if message.isLocked {
                    lockedBubble
                } else {
                    // Tappable bubble content for unlocked messages
                    Button {
                        onTap?()
                    } label: {
                        bubbleContent
                    }
                    .buttonStyle(.plain)
                }
                
                // Metadata row: signature + time
                HStack(spacing: 6) {
                    if let sig = message.signature {
                        Image(systemName: sig.platform.icon)
                            .font(.system(size: 10))
                        Text("@\(sig.handle)")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                    }
                    
                    if message.isPinProtected {
                        Image(systemName: message.isLocked ? "lock.fill" : "lock.open")
                            .font(.system(size: 9))
                    }
                    
                    Text(timeString(message.timestamp))
                        .font(.system(size: 10, weight: .regular, design: .rounded))
                }
                .foregroundColor(GlyphTheme.secondaryText.opacity(0.6))
            }
            
            if !message.isFromMe { Spacer(minLength: 60) }
        }
    }
    
    // MARK: - Bubble Content
    
    @ViewBuilder
    private var bubbleContent: some View {
        VStack(alignment: message.isFromMe ? .trailing : .leading, spacing: 6) {
            // Image attachment
            if let base64 = message.imageData,
               let data = Data(base64Encoded: base64),
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 220, maxHeight: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            
            // Audio indicator
            if message.audioData != nil {
                HStack(spacing: 6) {
                    Image(systemName: "waveform")
                        .font(.system(size: 14))
                    Text("Audio message")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                }
                .foregroundColor(message.isFromMe ? .black.opacity(0.7) : GlyphTheme.accent)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(message.isFromMe ? GlyphTheme.accentGradient : LinearGradient(colors: [GlyphTheme.surface], startPoint: .leading, endPoint: .trailing))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            
            // Text bubble
            if let text = message.text, !text.isEmpty {
                Text(text)
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundColor(message.isFromMe ? .black : GlyphTheme.primaryText)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        message.isFromMe
                            ? AnyShapeStyle(GlyphTheme.accentGradient)
                            : AnyShapeStyle(GlyphTheme.surface)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }
    
    // MARK: - Locked Bubble
    
    private var lockedBubble: some View {
        HStack(spacing: 8) {
            Image(systemName: "lock.fill")
                .font(.system(size: 16, weight: .semibold))
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Encrypted Message")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                Text("Enter PIN to unlock")
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundColor(GlyphTheme.secondaryText)
            }
        }
        .foregroundColor(GlyphTheme.violet)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(GlyphTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(GlyphTheme.violet.opacity(0.3), lineWidth: 1)
        )
    }
    
    private func timeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            formatter.dateFormat = "h:mm a"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            formatter.dateFormat = "MMM d"
        }
        return formatter.string(from: date)
    }
}

// MARK: - Conversation Compose Sheet

/// Fullscreen compose sheet for creating a QR message from within a conversation.
/// Reuses core GlyphMessage + QR generation, auto-signs with social, saves to thread.
struct ConversationComposeSheet: View {
    @Environment(\.dismiss) private var dismiss
    let friend: GlyphFriend
    var initialText: String = ""
    var onGenerate: (([UIImage], ExpirationOption) -> Void)? = nil
    
    @ObservedObject private var socialProfile = SocialProfile.shared
    
    @State private var messageText = ""
    @State private var pinEnabled = false
    @State private var pinCode = ""
    @State private var selectedExpiration: ExpirationOption = .seconds30
    @State private var isGenerating = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                GlyphTheme.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Recipient header
                        HStack(spacing: 10) {
                            Image(systemName: friend.platform.icon)
                                .font(.system(size: 16))
                                .foregroundStyle(GlyphTheme.accentGradient)
                            Text("To: \(friend.displayHandle)")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(GlyphTheme.primaryText)
                            Spacer()
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        
                        // Message input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Message")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(GlyphTheme.secondaryText)
                            
                            TextEditor(text: $messageText)
                                .font(.system(size: 16, weight: .regular, design: .rounded))
                                .foregroundColor(GlyphTheme.primaryText)
                                .scrollContentBackground(.hidden)
                                .frame(minHeight: 120)
                                .padding(12)
                                .background(GlyphTheme.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(GlyphTheme.accent.opacity(0.2), lineWidth: 1)
                                )
                        }
                        .padding(.horizontal, 24)
                        
                        // Expiration picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Viewer Timer")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(GlyphTheme.secondaryText)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(ExpirationOption.allCases) { option in
                                        Button {
                                            selectedExpiration = option
                                        } label: {
                                            HStack(spacing: 4) {
                                                Image(systemName: option.icon)
                                                    .font(.system(size: 12))
                                                Text(option.displayName)
                                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                            }
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(selectedExpiration == option ? AnyShapeStyle(GlyphTheme.accentGradient) : AnyShapeStyle(GlyphTheme.surface))
                                            .foregroundColor(selectedExpiration == option ? .black : GlyphTheme.secondaryText)
                                            .clipShape(Capsule())
                                        }
                                    }
                                }
                                .padding(.horizontal, 4)
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        // PIN toggle
                        VStack(spacing: 12) {
                            Toggle(isOn: $pinEnabled) {
                                HStack(spacing: 8) {
                                    Image(systemName: "lock.shield")
                                        .font(.system(size: 16))
                                        .foregroundColor(GlyphTheme.violet)
                                    Text("Encrypt with PIN")
                                        .font(.system(size: 15, weight: .medium, design: .rounded))
                                        .foregroundColor(GlyphTheme.primaryText)
                                }
                            }
                            .tint(GlyphTheme.violet)
                            
                            if pinEnabled {
                                TextField("PIN", text: $pinCode)
                                    .font(.system(size: 18, weight: .semibold, design: .monospaced))
                                    .foregroundColor(GlyphTheme.primaryText)
                                    .multilineTextAlignment(.center)
                                    .keyboardType(.numberPad)
                                    .padding(12)
                                    .background(GlyphTheme.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(GlyphTheme.violet.opacity(0.3), lineWidth: 1)
                                    )
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        // Generate QR button
                        Button {
                            generateQR()
                        } label: {
                            HStack(spacing: 10) {
                                if isGenerating {
                                    ProgressView()
                                        .tint(.black)
                                } else {
                                    Image(systemName: "qrcode")
                                        .font(.system(size: 18, weight: .semibold))
                                }
                                Text("Generate QR")
                                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: GlyphTheme.buttonHeight)
                            .background(canGenerate ? AnyShapeStyle(GlyphTheme.accentGradient) : AnyShapeStyle(GlyphTheme.surface))
                            .foregroundColor(canGenerate ? .black : GlyphTheme.secondaryText)
                            .clipShape(RoundedRectangle(cornerRadius: GlyphTheme.cornerRadius))
                        }
                        .disabled(!canGenerate || isGenerating)
                        .padding(.horizontal, 24)
                        
                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationTitle("Send via QR")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
            }
            .onAppear {
                if messageText.isEmpty && !initialText.isEmpty {
                    messageText = initialText
                }
            }
        }
    }
    
    private var canGenerate: Bool {
        !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        (!pinEnabled || !pinCode.trimmingCharacters(in: .whitespaces).isEmpty)
    }
    
    private func generateQR() {
        isGenerating = true
        
        Task {
            let trimmed = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
            
            let message = GlyphMessage(
                text: trimmed,
                expirationSeconds: selectedExpiration.rawValue,
                createdAt: Date(),
                signature: socialProfile.signature
            )
            
            // Save to conversation as "from me"
            if pinEnabled && !pinCode.isEmpty {
                if let encoded = message.encode(pin: pinCode) {
                    ConversationStore.shared.addLockedMessage(
                        payload: encoded,
                        signature: socialProfile.signature,
                        to: friend.id,
                        isFromMe: true
                    )
                }
            } else {
                ConversationStore.shared.addMessage(message, to: friend.id, isFromMe: true)
            }
            
            let images = GlyphChunkSplitter.split(message: message, pin: pinEnabled ? pinCode : nil)
            let expiration = selectedExpiration
            
            await MainActor.run {
                isGenerating = false
                if !images.isEmpty {
                    onGenerate?(images, expiration)
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ConversationView(friend: GlyphFriend(from: SocialSignature(platform: .instagram, handle: "testuser")))
            .preferredColorScheme(.dark)
    }
}
