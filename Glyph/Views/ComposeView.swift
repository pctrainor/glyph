import SwiftUI
import PhotosUI
import AVFoundation

// MARK: - Compose View

/// Where the sender types a message, picks expiration, and generates a QR code.
struct ComposeView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var messageText = ""
    @State private var selectedExpiration: ExpirationOption = .seconds30
    @State private var qrImages: [UIImage] = []
    @State private var showQR = false
    
    // Photo attachment
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var attachedImage: UIImage?
    @State private var isCompressing = false
    @State private var selectedQuality: ImageQuality = .standard
    
    // Audio attachment
    @State private var selectedSound: SampleSound?
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isPlayingPreview = false
    @StateObject private var voiceRecorder = VoiceRecorder()
    @State private var audioMode: AudioAttachmentMode = .samples
    
    // PIN encryption (optional Tier 2)
    @State private var pinEnabled = false
    @State private var pinCode = ""
    
    // Social signature
    @State private var signWithSocial = false
    @ObservedObject private var socialProfile = SocialProfile.shared
    
    // Flash on scan
    @State private var flashOnScan = true
    
    // Time window — how long the QR stays valid
    @State private var selectedWindow: TimeWindow = .none
    
    /// Max characters to fit comfortably in a single QR code
    private let maxCharacters = 600
    
    // Settings panel
    @State private var showSettings = false
    
    var body: some View {
        ZStack {
            GlyphTheme.backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                ScrollView {
                    VStack(spacing: 16) {
                        
                        // ═══════════════════════════════════════════
                        // MARK: - Message Input (Hero)
                        // ═══════════════════════════════════════════
                        
                        VStack(alignment: .leading, spacing: 8) {
                            ZStack(alignment: .topLeading) {
                                if messageText.isEmpty {
                                    Text("Type something that vanishes...")
                                        .foregroundColor(GlyphTheme.secondaryText.opacity(0.5))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 14)
                                }
                                
                                TextEditor(text: $messageText)
                                    .scrollContentBackground(.hidden)
                                    .font(.system(size: 17, design: .rounded))
                                    .foregroundColor(GlyphTheme.primaryText)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 8)
                                    .frame(minHeight: 160, maxHeight: 240)
                            }
                            .background(GlyphTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(
                                        messageText.count > maxCharacters && attachedImage == nil
                                            ? GlyphTheme.danger.opacity(0.6)
                                            : GlyphTheme.accent.opacity(0.15),
                                        lineWidth: 1
                                    )
                            )
                            
                            // Character count (only for text-only messages)
                            if attachedImage == nil && selectedSound == nil && voiceRecorder.recordedData == nil {
                                HStack {
                                    Spacer()
                                    Text("\(messageText.count)/\(maxCharacters)")
                                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                                        .foregroundColor(
                                            messageText.count > maxCharacters
                                                ? GlyphTheme.danger
                                                : GlyphTheme.secondaryText.opacity(0.6)
                                        )
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        
                        // ═══════════════════════════════════════════
                        // MARK: - Attachment Previews (if any)
                        // ═══════════════════════════════════════════
                        
                        if let img = attachedImage {
                            HStack(spacing: 10) {
                                Image(uiImage: img)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 48, height: 48)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Photo attached")
                                        .font(.system(size: 13, weight: .medium, design: .rounded))
                                        .foregroundColor(GlyphTheme.primaryText)
                                    Text(selectedQuality.displayName + " · " + selectedQuality.subtitle)
                                        .font(.system(size: 11, design: .rounded))
                                        .foregroundColor(GlyphTheme.secondaryText)
                                }
                                
                                Spacer()
                                
                                // Quality cycle
                                Button {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        let all = ImageQuality.allCases
                                        let idx = all.firstIndex(of: selectedQuality) ?? 0
                                        selectedQuality = all[(idx + 1) % all.count]
                                    }
                                } label: {
                                    Image(systemName: selectedQuality.icon)
                                        .font(.system(size: 14))
                                        .foregroundColor(GlyphTheme.accent)
                                        .frame(width: 30, height: 30)
                                        .background(GlyphTheme.accent.opacity(0.1))
                                        .clipShape(Circle())
                                }
                                
                                Button {
                                    withAnimation { attachedImage = nil; selectedPhoto = nil }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(.white.opacity(0.3))
                                }
                            }
                            .padding(10)
                            .background(GlyphTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .padding(.horizontal, 20)
                        }
                        
                        if let sound = selectedSound {
                            HStack(spacing: 10) {
                                Button { togglePreview(sound) } label: {
                                    ZStack {
                                        Circle()
                                            .fill(GlyphTheme.accent.opacity(0.12))
                                            .frame(width: 36, height: 36)
                                        Image(systemName: isPlayingPreview ? "stop.fill" : "play.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(GlyphTheme.accent)
                                    }
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(sound.displayName)
                                        .font(.system(size: 13, weight: .medium, design: .rounded))
                                        .foregroundColor(GlyphTheme.primaryText)
                                    Text(sound.subtitle + " · batched QR")
                                        .font(.system(size: 11, design: .rounded))
                                        .foregroundColor(GlyphTheme.secondaryText)
                                }
                                Spacer()
                                Button {
                                    withAnimation { stopPreview(); selectedSound = nil }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(.white.opacity(0.3))
                                }
                            }
                            .padding(10)
                            .background(GlyphTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .padding(.horizontal, 20)
                        } else if voiceRecorder.recordedData != nil {
                            HStack(spacing: 10) {
                                Button { voiceRecorder.togglePlayback() } label: {
                                    ZStack {
                                        Circle()
                                            .fill(GlyphTheme.violet.opacity(0.12))
                                            .frame(width: 36, height: 36)
                                        Image(systemName: voiceRecorder.isPlaying ? "stop.fill" : "play.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(GlyphTheme.violet)
                                    }
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Voice Memo")
                                        .font(.system(size: 13, weight: .medium, design: .rounded))
                                        .foregroundColor(GlyphTheme.primaryText)
                                    Text("\(voiceRecorder.durationString) · ~\(voiceRecorder.estimatedFrames) frames")
                                        .font(.system(size: 11, design: .rounded))
                                        .foregroundColor(GlyphTheme.secondaryText)
                                }
                                Spacer()
                                Button {
                                    withAnimation { voiceRecorder.clear() }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(.white.opacity(0.3))
                                }
                            }
                            .padding(10)
                            .background(GlyphTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .padding(.horizontal, 20)
                        }
                        
                        // Recording in-progress UI
                        if voiceRecorder.isRecording {
                            VStack(spacing: 10) {
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 8, height: 8)
                                        .opacity(voiceRecorder.recordingProgress.truncatingRemainder(dividingBy: 0.1) < 0.05 ? 0.4 : 1.0)
                                    Text("Recording…")
                                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text(voiceRecorder.durationString)
                                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                                        .foregroundColor(GlyphTheme.accent)
                                }
                                
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(GlyphTheme.surface)
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(
                                                LinearGradient(
                                                    colors: [GlyphTheme.violet, Color.red.opacity(0.8)],
                                                    startPoint: .leading, endPoint: .trailing
                                                )
                                            )
                                            .frame(width: geo.size.width * voiceRecorder.recordingProgress)
                                            .animation(.linear(duration: 0.05), value: voiceRecorder.recordingProgress)
                                    }
                                }
                                .frame(height: 3)
                                
                                Button {
                                    voiceRecorder.stopRecording()
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "stop.circle.fill")
                                            .font(.system(size: 16))
                                        Text("Stop")
                                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 38)
                                    .background(Color.red.opacity(0.12))
                                    .foregroundColor(Color.red)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                            }
                            .padding(12)
                            .background(GlyphTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal, 20)
                        }
                        
                        // ═══════════════════════════════════════════
                        // MARK: - Attachment Toolbar
                        // ═══════════════════════════════════════════
                        
                        if !voiceRecorder.isRecording {
                            HStack(spacing: 10) {
                                // Photo button
                                PhotosPicker(
                                    selection: $selectedPhoto,
                                    matching: .images,
                                    photoLibrary: .shared()
                                ) {
                                    composeToolbarButton(
                                        icon: "photo.on.rectangle",
                                        label: "Photo",
                                        active: attachedImage != nil,
                                        color: GlyphTheme.accent
                                    )
                                }
                                
                                // Sample sounds
                                Menu {
                                    ForEach(SampleSound.allCases) { sound in
                                        Button {
                                            withAnimation {
                                                voiceRecorder.clear()
                                                selectedSound = sound
                                            }
                                        } label: {
                                            Label(sound.displayName + " (" + sound.subtitle + ")", systemImage: sound.icon)
                                        }
                                    }
                                } label: {
                                    composeToolbarButton(
                                        icon: "music.note",
                                        label: "Sound",
                                        active: selectedSound != nil,
                                        color: GlyphTheme.accent
                                    )
                                }
                                
                                // Voice record
                                Button {
                                    if voiceRecorder.recordedData == nil {
                                        voiceRecorder.requestPermission()
                                        stopPreview()
                                        selectedSound = nil
                                        voiceRecorder.startRecording()
                                    }
                                } label: {
                                    composeToolbarButton(
                                        icon: "mic.fill",
                                        label: "Voice",
                                        active: voiceRecorder.recordedData != nil,
                                        color: GlyphTheme.violet
                                    )
                                }
                                .disabled(voiceRecorder.permissionDenied)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // ═══════════════════════════════════════════
                        // MARK: - Settings (Collapsible)
                        // ═══════════════════════════════════════════
                        
                        VStack(spacing: 0) {
                            // Toggle header
                            Button {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    showSettings.toggle()
                                }
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "slider.horizontal.3")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(GlyphTheme.secondaryText)
                                    Text("Settings")
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                        .foregroundColor(GlyphTheme.secondaryText)
                                    
                                    // Active indicators
                                    settingsBadges
                                    
                                    Spacer()
                                    Image(systemName: showSettings ? "chevron.up" : "chevron.down")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(GlyphTheme.secondaryText.opacity(0.6))
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(GlyphTheme.surface.opacity(0.5))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            .padding(.horizontal, 20)
                            
                            if showSettings {
                                VStack(spacing: 14) {
                                    
                                    // Expiration
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("Self-destructs after")
                                            .font(.system(size: 12, weight: .medium, design: .rounded))
                                            .foregroundColor(GlyphTheme.secondaryText)
                                            .padding(.horizontal, 20)
                                        
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack(spacing: 8) {
                                                ForEach(ExpirationOption.allCases) { option in
                                                    ExpirationChip(option: option, isSelected: selectedExpiration == option)
                                                        .onTapGesture {
                                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                                selectedExpiration = option
                                                            }
                                                        }
                                                }
                                            }
                                            .padding(.horizontal, 20)
                                        }
                                    }
                                    
                                    // Time window
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("QR valid for")
                                            .font(.system(size: 12, weight: .medium, design: .rounded))
                                            .foregroundColor(GlyphTheme.secondaryText)
                                            .padding(.horizontal, 20)
                                        
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack(spacing: 8) {
                                                ForEach(TimeWindow.allCases) { window in
                                                    TimeWindowChip(window: window, isSelected: selectedWindow == window)
                                                        .onTapGesture {
                                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                                selectedWindow = window
                                                            }
                                                        }
                                                }
                                            }
                                            .padding(.horizontal, 20)
                                        }
                                        
                                        if selectedWindow != .none {
                                            Text(selectedWindow.subtitle)
                                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                                .foregroundColor(GlyphTheme.accent.opacity(0.6))
                                                .padding(.horizontal, 20)
                                        }
                                    }
                                    
                                    // PIN lock
                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack {
                                            Image(systemName: "lock.fill")
                                                .font(.system(size: 12))
                                                .foregroundColor(GlyphTheme.secondaryText)
                                            Text("PIN lock")
                                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                                .foregroundColor(GlyphTheme.secondaryText)
                                            Spacer()
                                            Toggle("", isOn: $pinEnabled)
                                                .labelsHidden()
                                                .tint(GlyphTheme.accent)
                                                .scaleEffect(0.85)
                                        }
                                        
                                        if pinEnabled {
                                            HStack(spacing: 8) {
                                                Image(systemName: "lock.shield.fill")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(GlyphTheme.accent)
                                                
                                                SecureField("Enter PIN", text: $pinCode)
                                                    .font(.system(size: 15, weight: .medium, design: .monospaced))
                                                    .foregroundColor(GlyphTheme.primaryText)
                                                    .textContentType(.oneTimeCode)
                                                    .keyboardType(.numberPad)
                                            }
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 10)
                                            .background(GlyphTheme.surface)
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(GlyphTheme.accent.opacity(0.25), lineWidth: 1)
                                            )
                                            
                                            Text("Share PIN separately — without it, nobody can decrypt this message")
                                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                                .foregroundColor(GlyphTheme.accent.opacity(0.5))
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                    .animation(.easeInOut(duration: 0.2), value: pinEnabled)
                                    
                                    // Social signature
                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack {
                                            Image(systemName: "person.crop.circle")
                                                .font(.system(size: 12))
                                                .foregroundColor(GlyphTheme.secondaryText)
                                            Text("Sign with social")
                                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                                .foregroundColor(GlyphTheme.secondaryText)
                                            Spacer()
                                            Toggle("", isOn: $signWithSocial)
                                                .labelsHidden()
                                                .tint(GlyphTheme.violet)
                                                .scaleEffect(0.85)
                                        }
                                        
                                        if signWithSocial {
                                            if socialProfile.isLinked {
                                                HStack(spacing: 8) {
                                                    Image(systemName: socialProfile.platform.icon)
                                                        .font(.system(size: 14))
                                                        .foregroundStyle(GlyphTheme.accentGradient)
                                                    Text("@\(socialProfile.handle)")
                                                        .font(.system(size: 13, weight: .medium, design: .rounded))
                                                        .foregroundColor(GlyphTheme.primaryText)
                                                    Spacer()
                                                    Image(systemName: "checkmark.circle.fill")
                                                        .font(.system(size: 14))
                                                        .foregroundColor(GlyphTheme.accent)
                                                }
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 10)
                                                .background(GlyphTheme.surface)
                                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 10)
                                                        .stroke(GlyphTheme.violet.opacity(0.2), lineWidth: 1)
                                                )
                                            } else {
                                                HStack(spacing: 8) {
                                                    Image(systemName: "person.crop.circle.badge.questionmark")
                                                        .font(.system(size: 16))
                                                        .foregroundColor(GlyphTheme.secondaryText)
                                                    Text("No social linked — set up from home")
                                                        .font(.system(size: 12, design: .rounded))
                                                        .foregroundColor(GlyphTheme.secondaryText)
                                                }
                                                .padding(10)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .background(GlyphTheme.surface)
                                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                    .animation(.easeInOut(duration: 0.2), value: signWithSocial)
                                    
                                    // Flash on scan
                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack {
                                            Image(systemName: "bolt.fill")
                                                .font(.system(size: 12))
                                                .foregroundColor(GlyphTheme.secondaryText)
                                            Text("Flash on scan")
                                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                                .foregroundColor(GlyphTheme.secondaryText)
                                            Spacer()
                                            Toggle("", isOn: $flashOnScan)
                                                .labelsHidden()
                                                .tint(GlyphTheme.accent)
                                                .scaleEffect(0.85)
                                        }
                                        
                                        Text("Receiver's phone will flash when scan completes")
                                            .font(.system(size: 10, weight: .medium, design: .rounded))
                                            .foregroundColor(GlyphTheme.accent.opacity(0.5))
                                    }
                                    .padding(.horizontal, 20)
                                    
                                }
                                .padding(.top, 10)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                        
                    }
                }
                .scrollDismissesKeyboard(.interactively)
                
                // ═══════════════════════════════════════════
                // MARK: - Generate Button (Pinned)
                // ═══════════════════════════════════════════
                
                Button {
                    generateQR()
                } label: {
                    HStack(spacing: 10) {
                        if isCompressing {
                            ProgressView()
                                .tint(.black)
                        } else {
                            Image(systemName: pinEnabled ? "lock.fill" : (hasMedia ? "qrcode.viewfinder" : "qrcode"))
                                .font(.system(size: 18, weight: .semibold))
                        }
                        Text(pinEnabled ? "Generate Locked Glyph" : (hasMedia ? "Generate Batch" : "Generate Glyph"))
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: GlyphTheme.buttonHeight)
                    .background(
                        canGenerate
                            ? AnyShapeStyle(GlyphTheme.accentGradient)
                            : AnyShapeStyle(GlyphTheme.surface)
                    )
                    .foregroundColor(canGenerate ? .black : GlyphTheme.secondaryText)
                    .clipShape(RoundedRectangle(cornerRadius: GlyphTheme.cornerRadius))
                }
                .disabled(!canGenerate || isCompressing)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
        }
        .navigationTitle("Compose")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onChange(of: selectedPhoto) { _, newItem in
            if newItem == nil {
                withAnimation { attachedImage = nil }
            } else {
                loadPhoto(newItem)
            }
        }
        .fullScreenCover(isPresented: $showQR) {
            QRDisplayView(
                qrImages: qrImages,
                expiration: selectedExpiration,
                messagePreview: String(messageText.prefix(50)),
                timeWindow: selectedWindow
            )
        }
    }
    
    // MARK: - Settings Badges
    
    @ViewBuilder
    private var settingsBadges: some View {
        HStack(spacing: 4) {
            // Show active settings as small pills
            if selectedExpiration != .seconds30 {
                settingsPill(selectedExpiration.displayName, color: GlyphTheme.accent)
            }
            if selectedWindow != .none {
                settingsPill(selectedWindow.displayName, color: GlyphTheme.violet)
            }
            if pinEnabled {
                settingsPill("PIN", color: GlyphTheme.accent)
            }
            if signWithSocial && socialProfile.isLinked {
                settingsPill("Signed", color: GlyphTheme.violet)
            }
            if !flashOnScan {
                settingsPill("No Flash", color: GlyphTheme.secondaryText)
            }
        }
    }
    
    private func settingsPill(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 9, weight: .bold, design: .rounded))
            .foregroundColor(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }
    
    private func composeToolbarButton(icon: String, label: String, active: Bool, color: Color) -> some View {
        VStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
            Text(label)
                .font(.system(size: 10, weight: .medium, design: .rounded))
        }
        .frame(width: 60, height: 48)
        .background(active ? color.opacity(0.12) : GlyphTheme.surface.opacity(0.6))
        .foregroundColor(active ? color : GlyphTheme.secondaryText)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(active ? color.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
    
    // MARK: - Helpers
    
    private var canGenerate: Bool {
        let hasText = !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasImage = attachedImage != nil
        let hasAudio = selectedSound != nil || voiceRecorder.recordedData != nil
        // PIN must be non-empty if enabled
        if pinEnabled && pinCode.trimmingCharacters(in: .whitespaces).isEmpty { return false }
        // Text-only: enforce character limit. With media: text is optional caption.
        if hasImage || hasAudio {
            return true
        }
        return hasText && messageText.count <= maxCharacters
    }
    
    private var hasMedia: Bool {
        attachedImage != nil || selectedSound != nil || voiceRecorder.recordedData != nil
    }
    
    private var hasAudioAttached: Bool {
        selectedSound != nil || voiceRecorder.recordedData != nil
    }
    
    // MARK: - Audio Helpers
    
    private func togglePreview(_ sound: SampleSound) {
        if isPlayingPreview {
            stopPreview()
        } else {
            playPreview(sound)
        }
    }
    
    private func playPreview(_ sound: SampleSound) {
        guard let url = sound.url else { return }
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
            isPlayingPreview = true
            // Auto-stop when done
            DispatchQueue.main.asyncAfter(deadline: .now() + (audioPlayer?.duration ?? 2.0) + 0.1) {
                isPlayingPreview = false
            }
        } catch {
            #if DEBUG
            print("⚠️ Audio preview failed: \(error)")
            #endif
        }
    }
    
    private func stopPreview() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlayingPreview = false
    }
    
    private func loadPhoto(_ item: PhotosPickerItem?) {
        guard let item else {
            // Cancelled — ensure no stale image
            withAnimation { attachedImage = nil }
            return
        }
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                await MainActor.run { attachedImage = uiImage }
            } else {
                // Load failed — clear selection
                await MainActor.run {
                    withAnimation { attachedImage = nil; selectedPhoto = nil }
                }
            }
        }
    }
    
    private func generateQR() {
        isCompressing = true
        stopPreview()  // Stop any audio preview
        voiceRecorder.stopPlaying()
        
        Task {
            let trimmedText = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Compress image if present
            var base64Image: String?
            if let img = attachedImage {
                base64Image = compressImage(img, quality: selectedQuality)
            }
            
            // Load audio — sample sound OR recorded voice memo
            var base64Audio: String?
            if let sound = selectedSound, let url = sound.url {
                if let data = try? Data(contentsOf: url) {
                    base64Audio = data.base64EncodedString()
                    #if DEBUG
                    print("Audio (sample): \(data.count) bytes → ~\(data.count / 800 + 1) QR frames")
                    #endif
                }
            } else if let voiceBase64 = voiceRecorder.base64Audio {
                base64Audio = voiceBase64
                #if DEBUG
                print("Audio (voice): \(voiceRecorder.recordedData?.count ?? 0) bytes → ~\(voiceRecorder.estimatedFrames) QR frames")
                #endif
            }
            
            // Default caption based on attachment type
            let defaultCaption: String
            if base64Image != nil && base64Audio != nil {
                defaultCaption = "Photo & Audio"
            } else if base64Audio != nil {
                defaultCaption = "Audio"
            } else {
                defaultCaption = "Photo"
            }
            
            let message = GlyphMessage(
                text: trimmedText.isEmpty ? defaultCaption : trimmedText,
                expirationSeconds: selectedExpiration.rawValue,
                createdAt: Date(),
                imageData: base64Image,
                audioData: base64Audio,
                expiresAt: selectedWindow.expiresAt(),
                signature: signWithSocial ? socialProfile.signature : nil,
                flashOnScan: flashOnScan
            )
            
            let images = GlyphChunkSplitter.split(message: message, pin: pinEnabled ? pinCode : nil)
            
            await MainActor.run {
                isCompressing = false
                if !images.isEmpty {
                    qrImages = images
                    showQR = true
                } else {
                    #if DEBUG
                    print("⚠️ QR generation failed")
                    #endif
                }
            }
        }
    }
    
    /// Progressively compress a UIImage to JPEG using the selected quality profile.
    private func compressImage(_ image: UIImage, quality: ImageQuality) -> String? {
        let maxDimension = quality.maxDimension
        let maxBytes = quality.maxBytes
        
        // Downscale large images first
        let scaled: UIImage
        if max(image.size.width, image.size.height) > maxDimension {
            let ratio = maxDimension / max(image.size.width, image.size.height)
            let newSize = CGSize(width: image.size.width * ratio, height: image.size.height * ratio)
            UIGraphicsBeginImageContextWithOptions(newSize, true, 1.0)
            image.draw(in: CGRect(origin: .zero, size: newSize))
            scaled = UIGraphicsGetImageFromCurrentImageContext() ?? image
            UIGraphicsEndImageContext()
        } else {
            scaled = image
        }
        
        // Binary search for the best JPEG quality that fits
        var lo: CGFloat = 0.05
        var hi: CGFloat = quality.maxJPEGQuality
        var bestData: Data?
        
        for _ in 0..<10 {
            let mid = (lo + hi) / 2
            if let data = scaled.jpegData(compressionQuality: mid) {
                if data.count <= maxBytes {
                    bestData = data
                    lo = mid
                } else {
                    hi = mid
                }
            }
        }
        
        // Final fallback at lowest quality
        if bestData == nil {
            bestData = scaled.jpegData(compressionQuality: 0.05)
        }
        
        guard let data = bestData else { return nil }
        
        #if DEBUG
        print("🖼️ Compressed image [\(quality.displayName)]: \(data.count) bytes (\(data.count * 4 / 3) base64 chars) → ~\(data.count / 800 + 1) QR frames")
        #endif
        
        return data.base64EncodedString()
    }
}

// MARK: - Expiration Chip

struct ExpirationChip: View {
    let option: ExpirationOption
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: option.icon)
                .font(.system(size: 13, weight: .semibold))
            Text(option.displayName)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            isSelected
                ? GlyphTheme.accent.opacity(0.15)
                : GlyphTheme.surface
        )
        .foregroundColor(
            isSelected
                ? GlyphTheme.accent
                : GlyphTheme.secondaryText
        )
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(
                    isSelected
                        ? GlyphTheme.accent.opacity(0.5)
                        : Color.clear,
                    lineWidth: 1
                )
        )
    }
}

// MARK: - Time Window Chip

struct TimeWindowChip: View {
    let window: TimeWindow
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: window.icon)
                .font(.system(size: 13, weight: .semibold))
            Text(window.displayName)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            isSelected
                ? (window == .none ? GlyphTheme.surface : GlyphTheme.violet.opacity(0.15))
                : GlyphTheme.surface
        )
        .foregroundColor(
            isSelected
                ? (window == .none ? GlyphTheme.secondaryText : GlyphTheme.violet)
                : GlyphTheme.secondaryText
        )
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(
                    isSelected && window != .none
                        ? GlyphTheme.violet.opacity(0.5)
                        : Color.clear,
                    lineWidth: 1
                )
        )
    }
}

// MARK: - Image Quality

/// Quality profiles for photo attachments.
/// Higher quality = more QR frames to scan but sharper image.
enum ImageQuality: Int, CaseIterable, Identifiable {
    case standard = 0
    case high = 1
    case highest = 2
    
    var id: Int { rawValue }
    
    var displayName: String {
        switch self {
        case .standard: return "Standard"
        case .high:     return "High"
        case .highest:  return "Highest"
        }
    }
    
    var icon: String {
        switch self {
        case .standard: return "circle.bottomhalf.filled"
        case .high:     return "circle.inset.filled"
        case .highest:  return "circle.fill"
        }
    }
    
    var subtitle: String {
        switch self {
        case .standard: return "~35 frames"
        case .high:     return "~75 frames"
        case .highest:  return "~150 frames"
        }
    }
    
    /// Max JPEG bytes before base64 encoding
    var maxBytes: Int {
        switch self {
        case .standard: return 50_000    // ~50 KB
        case .high:     return 100_000   // ~100 KB
        case .highest:  return 200_000   // ~200 KB
        }
    }
    
    /// Max pixel dimension (width or height)
    var maxDimension: CGFloat {
        switch self {
        case .standard: return 256
        case .high:     return 512
        case .highest:  return 768
        }
    }
    
    /// Top end of JPEG quality search range
    var maxJPEGQuality: CGFloat {
        switch self {
        case .standard: return 0.8
        case .high:     return 0.85
        case .highest:  return 0.92
        }
    }
}

// MARK: - Quality Chip

struct QualityChip: View {
    let quality: ImageQuality
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 5) {
                Image(systemName: quality.icon)
                    .font(.system(size: 12, weight: .semibold))
                Text(quality.displayName)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
            }
            Text(quality.subtitle)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .opacity(0.7)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            isSelected
                ? GlyphTheme.accent.opacity(0.15)
                : GlyphTheme.surface
        )
        .foregroundColor(
            isSelected
                ? GlyphTheme.accent
                : GlyphTheme.secondaryText
        )
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(
                    isSelected
                        ? GlyphTheme.accent.opacity(0.5)
                        : Color.clear,
                    lineWidth: 1
                )
        )
    }
}

// MARK: - Sample Sound

/// Bundled sample sounds the sender can attach.
enum SampleSound: String, CaseIterable, Identifiable {
    case chime = "chime"
    case mystery = "mystery"
    case ping = "ping"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .chime:   return "Chime"
        case .mystery: return "Mystery"
        case .ping:    return "Ping"
        }
    }
    
    var icon: String {
        switch self {
        case .chime:   return "bell.fill"
        case .mystery: return "wand.and.stars"
        case .ping:    return "bolt.fill"
        }
    }
    
    var subtitle: String {
        switch self {
        case .chime:   return "1.3s"
        case .mystery: return "1.5s"
        case .ping:    return "0.5s"
        }
    }
    
    var url: URL? {
        Bundle.main.url(forResource: rawValue, withExtension: "m4a")
    }
}

// MARK: - Sound Chip

struct SoundChip: View {
    let sound: SampleSound
    let isPlaying: Bool
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: isPlaying ? "speaker.wave.2.fill" : sound.icon)
                .font(.system(size: 13, weight: .semibold))
            VStack(alignment: .leading, spacing: 1) {
                Text(sound.displayName)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                Text(sound.subtitle)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .opacity(0.7)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(GlyphTheme.surface)
        .foregroundColor(isPlaying ? GlyphTheme.accent : GlyphTheme.secondaryText)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(
                    isPlaying ? GlyphTheme.accent.opacity(0.5) : GlyphTheme.accent.opacity(0.2),
                    lineWidth: 1
                )
        )
    }
}

// MARK: - Audio Attachment Mode

enum AudioAttachmentMode {
    case samples
    case record
}

// MARK: - Audio Mode Tab

struct AudioModeTab: View {
    let title: String
    let icon: String
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
            Text(title)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(isSelected ? GlyphTheme.accent.opacity(0.15) : Color.clear)
        .foregroundColor(isSelected ? GlyphTheme.accent : GlyphTheme.secondaryText)
        .overlay(
            Rectangle()
                .fill(isSelected ? GlyphTheme.accent : Color.clear)
                .frame(height: 2),
            alignment: .bottom
        )
        .contentShape(Rectangle())
    }
}

#Preview {
    NavigationStack {
        ComposeView()
    }
    .preferredColorScheme(.dark)
}
