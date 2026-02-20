import SwiftUI

// MARK: - Unlock Flow View

/// Beautifully cycles through all messages in a conversation:
/// 1. First displays all unlocked / non-PIN messages in sequence
/// 2. Then prompts for PIN on each locked message, one at a time
/// 3. User can exit early — unlocked messages persist
struct UnlockFlowView: View {
    @Environment(\.dismiss) private var dismiss
    let friend: GlyphFriend
    
    @ObservedObject private var convoStore = ConversationStore.shared
    
    @State private var currentIndex = 0
    @State private var pinInput = ""
    @State private var pinError = false
    @State private var unlockSuccess = false
    @State private var phase: FlowPhase = .loading
    @State private var appeared = false
    
    private enum FlowPhase {
        case loading
        case showingUnlocked   // Cycling through non-locked messages
        case promptingPIN      // Asking for PIN on a locked message
        case complete          // All done
    }
    
    /// Messages sorted: unlocked first, then locked
    private var allMessages: [ConversationMessage] {
        let convo = convoStore.conversation(for: friend.id)
        let unlocked = convo.messages.filter { !$0.isLocked }
        let locked = convo.messages.filter { $0.isLocked }
        return unlocked + locked
    }
    
    private var unlockedMessages: [ConversationMessage] {
        convoStore.conversation(for: friend.id).messages.filter { !$0.isLocked }
    }
    
    private var lockedMessages: [ConversationMessage] {
        convoStore.conversation(for: friend.id).messages.filter { $0.isLocked }
    }
    
    /// The current message being displayed (during unlocked phase) or prompted (during PIN phase)
    private var currentMessage: ConversationMessage? {
        guard currentIndex < allMessages.count else { return nil }
        return allMessages[currentIndex]
    }
    
    var body: some View {
        ZStack {
            GlyphTheme.backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top bar
                HStack {
                    // Friend info
                    HStack(spacing: 8) {
                        Image(systemName: friend.platform.icon)
                            .font(.system(size: 14))
                            .foregroundStyle(GlyphTheme.accentGradient)
                        Text(friend.displayHandle)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(GlyphTheme.primaryText)
                    }
                    
                    Spacer()
                    
                    // Progress
                    if !allMessages.isEmpty {
                        Text("\(currentIndex + 1) / \(allMessages.count)")
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .foregroundColor(GlyphTheme.secondaryText)
                    }
                    
                    // Close
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                
                // Progress bar
                GeometryReader { geo in
                    let progress = allMessages.isEmpty ? 0 : CGFloat(currentIndex + 1) / CGFloat(allMessages.count)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(GlyphTheme.accentGradient)
                        .frame(width: geo.size.width * progress, height: 3)
                        .animation(.easeInOut(duration: 0.3), value: currentIndex)
                }
                .frame(height: 3)
                
                Spacer()
                
                // Main content
                switch phase {
                case .loading:
                    ProgressView()
                        .tint(GlyphTheme.accent)
                        .onAppear { startFlow() }
                    
                case .showingUnlocked:
                    if let msg = currentMessage {
                        unlockedMessageCard(msg)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                            .id(msg.id)
                    }
                    
                case .promptingPIN:
                    if let msg = currentMessage {
                        pinPromptCard(msg)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                            .id(msg.id)
                    }
                    
                case .complete:
                    completeCard
                }
                
                Spacer()
                
                // Navigation buttons
                if phase == .showingUnlocked {
                    HStack(spacing: 16) {
                        if currentIndex > 0 {
                            Button {
                                withAnimation { currentIndex -= 1 }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "chevron.left")
                                    Text("Back")
                                }
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundColor(GlyphTheme.secondaryText)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(GlyphTheme.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                        }
                        
                        Button {
                            advanceToNext()
                        } label: {
                            HStack(spacing: 6) {
                                Text(isLastUnlocked ? "Unlock Messages" : "Next")
                                Image(systemName: isLastUnlocked ? "lock.open" : "chevron.right")
                            }
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(GlyphTheme.accentGradient)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 30)
                }
                
                if phase == .complete {
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: GlyphTheme.buttonHeight)
                            .background(GlyphTheme.accentGradient)
                            .clipShape(RoundedRectangle(cornerRadius: GlyphTheme.cornerRadius))
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 30)
                }
            }
        }
    }
    
    // MARK: - Unlocked Message Card
    
    private func unlockedMessageCard(_ msg: ConversationMessage) -> some View {
        VStack(spacing: 16) {
            // Sender indicator
            HStack(spacing: 6) {
                Image(systemName: msg.isFromMe ? "arrow.up.right" : "arrow.down.left")
                    .font(.system(size: 12, weight: .semibold))
                Text(msg.isFromMe ? "You sent" : "From \(friend.displayHandle)")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
            }
            .foregroundColor(GlyphTheme.secondaryText)
            
            // Image
            if let base64 = msg.imageData,
               let data = Data(base64Encoded: base64),
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 280, maxHeight: 240)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            
            // Audio
            if msg.audioData != nil {
                HStack(spacing: 8) {
                    Image(systemName: "waveform")
                        .font(.system(size: 18))
                    Text("Audio message")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                }
                .foregroundColor(GlyphTheme.accent)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(GlyphTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            
            // Text
            if let text = msg.text, !text.isEmpty {
                Text(text)
                    .font(.system(size: 20, weight: .regular, design: .rounded))
                    .foregroundColor(GlyphTheme.primaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            // Signature
            if let sig = msg.signature {
                HStack(spacing: 6) {
                    Image(systemName: sig.platform.icon)
                        .font(.system(size: 12))
                    Text("@\(sig.handle)")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                }
                .foregroundColor(GlyphTheme.accent.opacity(0.6))
            }
            
            // Time
            Text(fullTimeString(msg.timestamp))
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundColor(GlyphTheme.secondaryText.opacity(0.5))
        }
        .padding(24)
        .background(GlyphTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(GlyphTheme.accent.opacity(0.1), lineWidth: 1)
        )
        .padding(.horizontal, 24)
        .opacity(appeared ? 1 : 0)
        .scaleEffect(appeared ? 1 : 0.95)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                appeared = true
            }
        }
    }
    
    // MARK: - PIN Prompt Card
    
    private func pinPromptCard(_ msg: ConversationMessage) -> some View {
        VStack(spacing: 20) {
            // Lock icon
            Image(systemName: unlockSuccess ? "lock.open.fill" : "lock.fill")
                .font(.system(size: 44, weight: .thin))
                .foregroundStyle(unlockSuccess ? GlyphTheme.accentGradient : LinearGradient(colors: [GlyphTheme.violet], startPoint: .top, endPoint: .bottom))
                .scaleEffect(unlockSuccess ? 1.2 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: unlockSuccess)
            
            Text("Encrypted Message")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(GlyphTheme.primaryText)
            
            // Sender
            HStack(spacing: 6) {
                Image(systemName: msg.isFromMe ? "arrow.up.right" : "arrow.down.left")
                    .font(.system(size: 12))
                Text(msg.isFromMe ? "You sent this" : "From \(friend.displayHandle)")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
            }
            .foregroundColor(GlyphTheme.secondaryText)
            
            // PIN input
            VStack(spacing: 8) {
                TextField("Enter PIN", text: $pinInput)
                    .font(.system(size: 24, weight: .semibold, design: .monospaced))
                    .foregroundColor(GlyphTheme.primaryText)
                    .multilineTextAlignment(.center)
                    .keyboardType(.numberPad)
                    .padding(14)
                    .background(GlyphTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke((pinError ? GlyphTheme.danger : GlyphTheme.violet).opacity(0.4), lineWidth: 1)
                    )
                    .shakeEffect(pinError)
                
                if pinError {
                    Text("Wrong PIN — try again")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(GlyphTheme.danger)
                        .transition(.opacity)
                }
            }
            .padding(.horizontal, 8)
            
            // Unlock button
            Button {
                attemptUnlock(msg)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "lock.open")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Unlock")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: GlyphTheme.buttonHeight)
                .background(pinInput.isEmpty ? AnyShapeStyle(GlyphTheme.surface) : AnyShapeStyle(GlyphTheme.accentGradient))
                .clipShape(RoundedRectangle(cornerRadius: GlyphTheme.cornerRadius))
            }
            .disabled(pinInput.isEmpty)
            
            // Skip button
            Button {
                skipAndAdvance()
            } label: {
                Text("Skip this message")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(GlyphTheme.secondaryText)
            }
        }
        .padding(24)
        .background(GlyphTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(GlyphTheme.violet.opacity(0.15), lineWidth: 1)
        )
        .padding(.horizontal, 24)
    }
    
    // MARK: - Complete Card
    
    private var completeCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 52, weight: .thin))
                .foregroundStyle(GlyphTheme.accentGradient)
            
            Text("All Caught Up")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(GlyphTheme.primaryText)
            
            let remaining = lockedMessages.count
            if remaining > 0 {
                Text("\(remaining) message\(remaining == 1 ? "" : "s") still locked")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(GlyphTheme.secondaryText)
            } else {
                Text("All messages unlocked")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(GlyphTheme.accent)
            }
        }
    }
    
    // MARK: - Flow Logic
    
    private var isLastUnlocked: Bool {
        // Check if next message would be a locked one
        let nextIdx = currentIndex + 1
        guard nextIdx < allMessages.count else { return false }
        return allMessages[nextIdx].isLocked
    }
    
    private func startFlow() {
        if allMessages.isEmpty {
            phase = .complete
        } else {
            currentIndex = 0
            let first = allMessages[0]
            phase = first.isLocked ? .promptingPIN : .showingUnlocked
        }
    }
    
    private func advanceToNext() {
        let nextIdx = currentIndex + 1
        guard nextIdx < allMessages.count else {
            withAnimation { phase = .complete }
            return
        }
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            appeared = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            currentIndex = nextIdx
            let msg = allMessages[nextIdx]
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                phase = msg.isLocked ? .promptingPIN : .showingUnlocked
                appeared = true
                pinInput = ""
                pinError = false
                unlockSuccess = false
            }
        }
    }
    
    private func attemptUnlock(_ msg: ConversationMessage) {
        guard let payload = msg.rawPayload else { return }
        
        if let decoded = GlyphMessage.decode(from: payload, pin: pinInput) {
            // Success!
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                unlockSuccess = true
            }
            convoStore.unlock(messageId: msg.id, in: friend.id, with: decoded)
            
            // Brief celebration, then advance
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                advanceToNext()
            }
        } else {
            // Wrong PIN
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                pinError = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation { pinError = false }
            }
        }
    }
    
    private func skipAndAdvance() {
        advanceToNext()
    }
    
    private func fullTimeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Shake Effect

extension View {
    func shakeEffect(_ trigger: Bool) -> some View {
        modifier(ShakeModifier(shaking: trigger))
    }
}

struct ShakeModifier: ViewModifier {
    let shaking: Bool
    @State private var offset: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .offset(x: offset)
            .onChange(of: shaking) { _, newValue in
                guard newValue else { return }
                withAnimation(.interpolatingSpring(stiffness: 600, damping: 10)) {
                    offset = -8
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                    withAnimation(.interpolatingSpring(stiffness: 600, damping: 10)) {
                        offset = 8
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
                    withAnimation(.interpolatingSpring(stiffness: 600, damping: 10)) {
                        offset = 0
                    }
                }
            }
    }
}

#Preview {
    UnlockFlowView(friend: GlyphFriend(from: SocialSignature(platform: .instagram, handle: "demo")))
        .preferredColorScheme(.dark)
}
