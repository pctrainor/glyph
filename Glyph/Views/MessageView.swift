import SwiftUI
import Photos
import AVFoundation

// MARK: - Message View

/// Displays the decoded message to the receiver with a countdown timer.
/// When time expires (or on dismiss for "Read Once"), the message is gone forever.
struct MessageView: View {
    @Environment(\.dismiss) private var dismiss
    
    let message: GlyphMessage
    
    @State private var secondsLeft: TimeInterval = 0
    @State private var totalSeconds: TimeInterval = 0
    @State private var isExpired = false
    @State private var appeared = false
    @State private var vanishProgress: CGFloat = 0  // 0 = fully visible, 1 = gone
    @State private var timer: Timer?
    @State private var openedAt: Date?  // When the receiver actually sees the message
    @State private var messageSaved = false         // Whether the message has been saved to library
    @State private var messageSaveError: String?    // Error message if save fails
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isPlayingAudio = false
    @State private var audioProgress: Double = 0
    @State private var audioTimer: Timer?
    @State private var friendAdded = false        // Whether we just added them as a friend
    @ObservedObject private var friendStore = FriendStore.shared
    
    /// Whether this is a "read once" message
    private var isReadOnce: Bool {
        message.expirationSeconds == ExpirationOption.readOnce.rawValue
    }
    
    /// Whether this is a "forever" message — image saved to library, no self-destruct
    private var isForever: Bool {
        message.expirationSeconds == ExpirationOption.forever.rawValue
    }
    
    var body: some View {
        ZStack {
            GlyphTheme.backgroundGradient
                .ignoresSafeArea()
            
            if message.isWindowExpired {
                // MARK: - Window Expired State (QR time window passed)
                windowExpiredView
            } else if isExpired {
                // MARK: - Expired State
                expiredView
            } else {
                // MARK: - Active Message
                VStack(spacing: 24) {
                    
                    // Top bar
                    HStack {
                        Spacer()
                        Button {
                            if isForever {
                                dismiss()  // Just close — nothing to destroy
                            } else {
                                expireMessage()
                            }
                        } label: {
                            Image(systemName: isForever ? "xmark.circle.fill" : "xmark.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.white.opacity(0.4))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    
                    Spacer()
                    
                    // Timer ring
                    if isForever {
                        // Forever badge
                        VStack(spacing: 8) {
                            Image(systemName: "infinity")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(GlyphTheme.accent)
                            Text("Forever")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(GlyphTheme.accent)
                            
                            // Save status
                            if messageSaved {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 13))
                                    Text("Saved to Library")
                                        .font(.system(size: 12, weight: .medium, design: .rounded))
                                }
                                .foregroundColor(GlyphTheme.accent.opacity(0.8))
                                .transition(.opacity)
                            } else if let error = messageSaveError {
                                HStack(spacing: 4) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.system(size: 13))
                                    Text(error)
                                        .font(.system(size: 12, weight: .medium, design: .rounded))
                                }
                                .foregroundColor(GlyphTheme.warning)
                                .transition(.opacity)
                            }
                        }
                        .opacity(appeared ? 1 : 0)
                    } else if !isReadOnce {
                        timerRing
                            .opacity(appeared ? 1 : 0)
                    } else {
                        // Read once badge
                        VStack(spacing: 8) {
                            Image(systemName: "eye.slash.circle.fill")
                                .font(.system(size: 48))
                                .foregroundColor(GlyphTheme.violet)
                            Text("Read Once")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(GlyphTheme.violet)
                        }
                        .opacity(appeared ? 1 : 0)
                    }
                    
                    // Image attachment (if present)
                    if let img = message.decodedImage {
                        Image(uiImage: img)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: 280, maxHeight: 280)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(timerColor.opacity(0.2), lineWidth: 1)
                            )
                            .shadow(color: GlyphTheme.accent.opacity(0.2), radius: 20)
                            .padding(.horizontal, 24)
                            .opacity(appeared ? 1 : 0)
                            .opacity(1.0 - Double(vanishProgress))
                            .scaleEffect(appeared ? 1 : 0.9)
                    }
                    
                    // Audio attachment (if present)
                    if message.audioData != nil {
                        audioPlayerView
                            .padding(.horizontal, 24)
                            .opacity(appeared ? 1 : 0)
                            .opacity(1.0 - Double(vanishProgress))
                            .scaleEffect(appeared ? 1 : 0.9)
                    }
                    
                    // Message bubble
                    Text(message.text)
                        .font(.system(size: 20, weight: .regular, design: .rounded))
                        .foregroundColor(GlyphTheme.primaryText)
                        .multilineTextAlignment(.center)
                        .padding(24)
                        .frame(maxWidth: .infinity)
                        .background(GlyphTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(timerColor.opacity(0.2), lineWidth: 1)
                        )
                        .padding(.horizontal, 24)
                        .opacity(appeared ? 1 : 0)
                        .opacity(1.0 - Double(vanishProgress))
                        .scaleEffect(appeared ? 1 : 0.9)
                    
                    // Social signature (if signed)
                    if let sig = message.signature {
                        Button {
                            if let url = sig.profileURL {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: sig.platform.icon)
                                    .font(.system(size: 16))
                                
                                Text(sig.displayText)
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                
                                if sig.profileURL != nil {
                                    Image(systemName: "arrow.up.right.square")
                                        .font(.system(size: 12))
                                }
                            }
                            .foregroundStyle(GlyphTheme.accentGradient)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(GlyphTheme.surface)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(GlyphTheme.violet.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .opacity(appeared ? 1 : 0)
                        .opacity(1.0 - Double(vanishProgress))
                        
                        // Friend add / status row
                        if friendStore.isFriend(sig) {
                            HStack(spacing: 6) {
                                Image(systemName: "person.crop.circle.badge.checkmark")
                                    .font(.system(size: 13))
                                Text("Friend")
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                            }
                            .foregroundColor(GlyphTheme.accent.opacity(0.6))
                            .opacity(appeared ? 1 : 0)
                            .opacity(1.0 - Double(vanishProgress))
                        } else {
                            Button {
                                friendStore.addOrUpdate(from: sig)
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    friendAdded = true
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: friendAdded ? "checkmark.circle.fill" : "person.badge.plus")
                                        .font(.system(size: 14))
                                    Text(friendAdded ? "Added!" : "Add Friend")
                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                                }
                                .foregroundColor(friendAdded ? GlyphTheme.accent : GlyphTheme.violet)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(GlyphTheme.surface)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke((friendAdded ? GlyphTheme.accent : GlyphTheme.violet).opacity(0.3), lineWidth: 1)
                                )
                            }
                            .disabled(friendAdded)
                            .opacity(appeared ? 1 : 0)
                            .opacity(1.0 - Double(vanishProgress))
                        }
                    }
                    
                    Spacer()
                    
                    // Dismiss instruction
                    if isForever {
                        Text("This glyph is yours to keep ∞")
                            .font(.system(size: 13, design: .rounded))
                            .foregroundColor(GlyphTheme.secondaryText)
                            .padding(.bottom, 40)
                    } else if isReadOnce {
                        VStack(spacing: 12) {
                            if !messageSaved {
                                Button {
                                    saveToLibrary()
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "square.and.arrow.down")
                                            .font(.system(size: 14, weight: .semibold))
                                        Text("Save to Library")
                                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    }
                                    .foregroundColor(GlyphTheme.accent)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(GlyphTheme.surface)
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule().stroke(GlyphTheme.accent.opacity(0.3), lineWidth: 1)
                                    )
                                }
                            } else {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 13))
                                    Text("Saved to Library")
                                        .font(.system(size: 13, weight: .medium, design: .rounded))
                                }
                                .foregroundColor(GlyphTheme.accent.opacity(0.7))
                            }
                            
                            Text("Tap ✕ when done — message vanishes forever")
                                .font(.system(size: 13, design: .rounded))
                                .foregroundColor(GlyphTheme.secondaryText)
                        }
                        .padding(.bottom, 40)
                    } else {
                        VStack(spacing: 12) {
                            if !messageSaved {
                                Button {
                                    saveToLibrary()
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "square.and.arrow.down")
                                            .font(.system(size: 14, weight: .semibold))
                                        Text("Save to Library")
                                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    }
                                    .foregroundColor(GlyphTheme.accent)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(GlyphTheme.surface)
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule().stroke(GlyphTheme.accent.opacity(0.3), lineWidth: 1)
                                    )
                                }
                            } else {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 13))
                                    Text("Saved to Library")
                                        .font(.system(size: 13, weight: .medium, design: .rounded))
                                }
                                .foregroundColor(GlyphTheme.accent.opacity(0.7))
                            }
                            
                            Text("Message will self-destruct when timer expires")
                                .font(.system(size: 13, design: .rounded))
                                .foregroundColor(GlyphTheme.secondaryText)
                        }
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .onAppear {
            startTimer()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                appeared = true
            }
            // Auto-play audio after a brief delay so it feels intentional
            if message.audioData != nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    playAudio()
                }
            }
            // Auto-update friend if already added (bumps message count + last seen)
            if let sig = message.signature, friendStore.isFriend(sig) {
                friendStore.addOrUpdate(from: sig)
            }
        }
        .onDisappear {
            timer?.invalidate()
            audioTimer?.invalidate()
            audioPlayer?.stop()
        }
    }
    
    // MARK: - Audio Player View
    
    private var audioPlayerView: some View {
        HStack(spacing: 16) {
            // Play/Stop button
            Button {
                toggleAudio()
            } label: {
                ZStack {
                    Circle()
                        .fill(timerColor.opacity(0.15))
                        .frame(width: 52, height: 52)
                    Image(systemName: isPlayingAudio ? "stop.fill" : "play.fill")
                        .font(.system(size: 22))
                        .foregroundColor(timerColor)
                }
            }
            
            // Waveform / progress
            VStack(alignment: .leading, spacing: 6) {
                // Animated waveform bars
                HStack(spacing: 3) {
                    ForEach(0..<20, id: \.self) { i in
                        let filled = Double(i) / 20.0 < audioProgress
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(filled ? timerColor : GlyphTheme.surface)
                            .frame(width: 3, height: waveformHeight(for: i, playing: isPlayingAudio))
                            .animation(.easeOut(duration: 0.15), value: isPlayingAudio)
                            .animation(.easeOut(duration: 0.1), value: audioProgress)
                    }
                }
                .frame(height: 28)
                
                Text(isPlayingAudio ? "Playing…" : "Tap to play sound")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(GlyphTheme.secondaryText)
            }
            
            Spacer()
            
            // Sound icon
            Image(systemName: isPlayingAudio ? "speaker.wave.3.fill" : "speaker.fill")
                .font(.system(size: 18))
                .foregroundColor(timerColor.opacity(0.6))
                .symbolEffect(.variableColor, isActive: isPlayingAudio)
        }
        .padding(16)
        .background(GlyphTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(timerColor.opacity(0.2), lineWidth: 1)
        )
    }
    
    /// Generate pseudo-random waveform bar heights for visual effect
    private func waveformHeight(for index: Int, playing: Bool) -> CGFloat {
        let base: [CGFloat] = [8, 14, 20, 12, 24, 16, 22, 10, 18, 26, 14, 20, 8, 22, 16, 24, 12, 18, 10, 20]
        let h = base[index % base.count]
        return playing ? h : h * 0.4
    }
    
    private func toggleAudio() {
        if isPlayingAudio {
            stopAudio()
        } else {
            playAudio()
        }
    }
    
    private func playAudio() {
        guard let data = message.decodedAudioData else { return }
        do {
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.play()
            isPlayingAudio = true
            audioProgress = 0
            
            // Track progress
            audioTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
                guard let player = audioPlayer else { return }
                if player.isPlaying {
                    audioProgress = player.currentTime / max(player.duration, 0.01)
                } else {
                    // Playback ended
                    stopAudio()
                }
            }
        } catch {
            #if DEBUG
            print("⚠️ Audio playback failed: \(error)")
            #endif
        }
    }
    
    private func stopAudio() {
        audioPlayer?.stop()
        audioPlayer = nil
        audioTimer?.invalidate()
        audioTimer = nil
        isPlayingAudio = false
        audioProgress = 0
    }
    
    // MARK: - Timer Ring
    
    private var timerRing: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(GlyphTheme.surface, lineWidth: 6)
                .frame(width: 100, height: 100)
            
            // Progress ring
            Circle()
                .trim(from: 0, to: totalSeconds > 0 ? secondsLeft / totalSeconds : 0)
                .stroke(timerColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .frame(width: 100, height: 100)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.3), value: secondsLeft)
            
            // Time label
            VStack(spacing: 2) {
                Text(timeString)
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundColor(timerColor)
                Text("sec")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(GlyphTheme.secondaryText)
            }
        }
    }
    
    // MARK: - Expired View
    
    private var expiredView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "flame.fill")
                .font(.system(size: 56))
                .foregroundStyle(
                    LinearGradient(
                        colors: [GlyphTheme.warning, GlyphTheme.danger],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .scaleEffect(appeared ? 1.2 : 0.5)
            
            Text("Message Destroyed")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(GlyphTheme.primaryText)
            
            Text("This glyph has vanished forever.")
                .font(.system(size: 15, design: .rounded))
                .foregroundColor(GlyphTheme.secondaryText)
            
            Spacer()
            
            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .frame(height: GlyphTheme.buttonHeight)
                    .background(GlyphTheme.surface)
                    .foregroundColor(GlyphTheme.primaryText)
                    .clipShape(RoundedRectangle(cornerRadius: GlyphTheme.cornerRadius))
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Window Expired View
    
    private var windowExpiredView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "clock.badge.exclamationmark")
                .font(.system(size: 56))
                .foregroundStyle(GlyphTheme.accentGradient)
                .scaleEffect(appeared ? 1.1 : 0.5)
            
            Text("QR Code Expired")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(GlyphTheme.primaryText)
            
            Text("This QR code's time window has closed.\nIt can no longer be viewed.")
                .font(.system(size: 15, design: .rounded))
                .foregroundColor(GlyphTheme.secondaryText)
                .multilineTextAlignment(.center)
            
            if let expiresAt = message.expiresAt {
                let elapsed = Date().timeIntervalSince(expiresAt)
                Text("Expired \(Self.formatElapsedWindow(elapsed)) ago")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(GlyphTheme.warning.opacity(0.8))
            }
            
            Spacer()
            
            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .frame(height: GlyphTheme.buttonHeight)
                    .background(GlyphTheme.surface)
                    .foregroundColor(GlyphTheme.primaryText)
                    .clipShape(RoundedRectangle(cornerRadius: GlyphTheme.cornerRadius))
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
    }
    
    /// Format elapsed seconds into a readable string.
    private static func formatElapsedWindow(_ seconds: TimeInterval) -> String {
        let s = Int(seconds)
        if s < 60 { return "\(s) sec" }
        if s < 3600 { return "\(s / 60) min" }
        if s < 86400 { return "\(s / 3600) hour\(s / 3600 == 1 ? "" : "s")" }
        return "\(s / 86400) day\(s / 86400 == 1 ? "" : "s")"
    }
    
    // MARK: - Helpers
    
    private var timerColor: Color {
        if isForever || isReadOnce {
            return GlyphTheme.accent
        } else if secondsLeft > 10 {
            return GlyphTheme.accent
        } else if secondsLeft > 5 {
            return GlyphTheme.warning
        } else {
            return GlyphTheme.danger
        }
    }
    
    private var timeString: String {
        let secs = max(0, Int(ceil(secondsLeft)))
        if secs >= 60 {
            return String(format: "%d:%02d", secs / 60, secs % 60)
        }
        return "\(secs)"
    }
    
    private func startTimer() {
        if isReadOnce {
            // No countdown for read-once — it vanishes when dismissed
            return
        }
        
        if isForever {
            // No countdown for forever — auto-save to the app's local library
            saveToLibrary()
            return
        }
        
        // The countdown starts NOW — when the receiver actually opens the message.
        // Not from `createdAt` (which is when the sender generated the QR code).
        let now = Date()
        openedAt = now
        totalSeconds = TimeInterval(message.expirationSeconds)
        secondsLeft = totalSeconds
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            guard let openedAt else { return }
            let elapsed = Date().timeIntervalSince(openedAt)
            secondsLeft = max(0, totalSeconds - elapsed)
            
            // Start vanish effect in last 3 seconds
            if secondsLeft < 3 && secondsLeft > 0 {
                withAnimation(.easeIn(duration: 0.2)) {
                    vanishProgress = CGFloat(1.0 - (secondsLeft / 3.0))
                }
            }
            
            if secondsLeft <= 0 {
                expireMessage()
            }
        }
    }
    
    private func expireMessage() {
        timer?.invalidate()
        withAnimation(.easeOut(duration: 0.5)) {
            vanishProgress = 1.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.spring(response: 0.4)) {
                isExpired = true
            }
        }
    }
    
    /// Saves the message (with optional image/audio) to the app's local library.
    private func saveToLibrary() {
        GlyphStore.shared.save(message: message)
        withAnimation { messageSaved = true }
    }
}

#Preview("Timed Message") {
    MessageView(
        message: GlyphMessage(
            text: "This is a secret message that will self-destruct!",
            expirationSeconds: 30,
            createdAt: Date()
        )
    )
    .preferredColorScheme(.dark)
}

#Preview("Read Once") {
    MessageView(
        message: GlyphMessage(
            text: "You can only read this once",
            expirationSeconds: -1,
            createdAt: Date()
        )
    )
    .preferredColorScheme(.dark)
}

#Preview("Forever") {
    MessageView(
        message: GlyphMessage(
            text: "This one is yours to keep",
            expirationSeconds: -2,
            createdAt: Date()
        )
    )
    .preferredColorScheme(.dark)
}
