import SwiftUI
@preconcurrency import AVFoundation
import Vision

// MARK: - Scanner View

/// Full-screen camera view for scanning a Glyph QR code.
struct ScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var scanner = QRScannerModel()
    @StateObject private var assembler = GlyphChunkAssembler()
    
    @State private var scannedMessage: GlyphMessage?
    @State private var scannedWebBundle: GlyphWebBundle?
    @State private var scanLineOffset: CGFloat = -120
    @State private var scanError: String?
    @State private var showPhotoScanner = false
    @State private var showProgressiveImage = false
    @State private var showWebExperience = false
    @State private var lastReceivedCount = 0
    @State private var lastScannedPayload = ""  // Debounce duplicate reads
    @State private var surveyResponseRecorded = false
    @State private var surveyResponseError: String?
    @State private var blockedReason: String?
    @State private var pinPromptPayload: String?     // Holds payload awaiting PIN entry
    @State private var pinInput = ""                  // PIN text field value
    @State private var windowExpiredReason: String?   // QR time window expired
    @State private var showLogoEasterEgg = false      // Glyph logo QR scanned
    @State private var dragOffset: CGFloat = 0         // Swipe-down to dismiss
    @AppStorage("flashOnScanEnabled") private var flashOnScanEnabled = true
    
    /// Haptic feedback when a new chunk lands
    private let chunkHaptic = UIImpactFeedbackGenerator(style: .medium)
    
    var body: some View {
        ZStack {
            // Camera preview
            CameraPreviewView(session: scanner.session)
                .ignoresSafeArea()
                .onTapGesture {
                    // Tap outside scan area to dismiss
                    if assembler.totalCount == 0 {
                        scanner.stop()
                        dismiss()
                    }
                }
            
            // Overlay — hidden when progressive image view is active
            if !showProgressiveImage {
            VStack {
                // Top bar
                HStack {
                    Button {
                        scanner.stop()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    Spacer()
                    Button {
                        scanner.stop()
                        showPhotoScanner = true
                    } label: {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(8)
                            .background(.ultraThinMaterial.opacity(0.6))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)
                
                Spacer()
                
                // Chunk progress — positioned directly above the scan frame
                if assembler.totalCount > 0 && !showProgressiveImage {
                    VStack(spacing: 6) {
                        Text("Receiving \(assembler.receivedCount)/\(assembler.totalCount)")
                            .font(.system(size: 14, weight: .semibold, design: .monospaced))
                            .foregroundColor(GlyphTheme.accent)
                        
                        ProgressView(value: assembler.progress)
                            .progressViewStyle(.linear)
                            .tint(GlyphTheme.accent)
                            .frame(width: 200)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial.opacity(0.7))
                    .clipShape(Capsule())
                    .padding(.bottom, 12)
                }
                
                // Scan frame
                ZStack {
                    // Cutout frame
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            assembler.totalCount > 0
                                ? GlyphTheme.accent
                                : GlyphTheme.accent.opacity(0.6),
                            lineWidth: assembler.totalCount > 0 ? 2.5 : 2
                        )
                        .frame(width: 260, height: 260)
                    
                    // Animated scan line
                    RoundedRectangle(cornerRadius: 1)
                        .fill(GlyphTheme.accent.opacity(0.5))
                        .frame(width: 220, height: 2)
                        .offset(y: scanLineOffset)
                        .onAppear {
                            withAnimation(
                                .easeInOut(duration: 2.0)
                                .repeatForever(autoreverses: true)
                            ) {
                                scanLineOffset = 120
                            }
                        }
                    
                    // Corner accents
                    ScanCorners()
                        .stroke(GlyphTheme.accent, lineWidth: 3)
                        .frame(width: 260, height: 260)
                }
                
                Spacer()
                
                // Bottom instruction
                VStack(spacing: 8) {
                    if assembler.totalCount > 0 && !showProgressiveImage {
                        // Keep camera aimed — progress is shown above the frame
                        Text("Hold steady — keep QR in frame")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                    } else {
                        Text("Point at a Glyph code")
                            .font(.system(size: 17, weight: .medium, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("The message will appear automatically")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(.white.opacity(0.5))
                        
                        Button {
                            scanner.stop()
                            showPhotoScanner = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Scan from Photos")
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                            }
                            .foregroundColor(GlyphTheme.accent)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(GlyphTheme.surface.opacity(0.8))
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(GlyphTheme.accent.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .padding(.top, 8)
                    }
                }
                .padding(.bottom, 80)
            }
            } // end if !showProgressiveImage
            
            // Permission denied overlay
            if scanner.permissionDenied {
                VStack(spacing: 16) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 48))
                        .foregroundColor(GlyphTheme.secondaryText)
                    
                    Text("Camera Access Required")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Glyph needs camera access to scan QR codes.\nEnable it in Settings.")
                        .font(.system(size: 15, design: .rounded))
                        .foregroundColor(GlyphTheme.secondaryText)
                        .multilineTextAlignment(.center)
                    
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(GlyphTheme.accent)
                    .padding(.top, 8)
                }
                .padding(40)
                .background(.ultraThinMaterial.opacity(0.9))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .padding(32)
            }
            
            // Progressive image overlay — rendered inline so camera stays visible behind
            if showProgressiveImage {
                ProgressiveImageView(
                    assembler: assembler,
                    scanner: scanner,
                    onComplete: { message in
                        showProgressiveImage = false
                        scanner.stop()
                        chunkHaptic.impactOccurred(intensity: 1.0)
                        
                        // Check time window
                        if message.isWindowExpired {
                            assembler.reset()
                            windowExpiredReason = Self.windowExpiredMessage(message)
                            return
                        }
                        
                        // Check scan history for batched messages
                        let assembledPayload = message.encode() ?? ""
                        if let reason = ScanHistory.shared.shouldBlock(payload: assembledPayload, message: message) {
                            assembler.reset()
                            blockedReason = reason
                            return
                        }
                        ScanHistory.shared.recordScan(payload: assembledPayload, expirationSeconds: message.expirationSeconds)
                        
                        triggerScanFlash(for: message)
                        scannedMessage = message
                        assembler.reset()
                    },
                    onCancel: {
                        showProgressiveImage = false
                        assembler.reset()
                        lastReceivedCount = 0
                        lastScannedPayload = ""
                        scanner.stop()
                        dismiss()
                    }
                )
                .transition(.opacity)
            }
        }
        .onAppear {
            chunkHaptic.prepare()
            scanner.onCodeScanned = { code in
                guard scannedMessage == nil else { return } // Prevent double-scan
                guard scannedWebBundle == nil && !showWebExperience else { return } // Web bundle already assembled
                let cleaned = code.trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Debounce — camera fires many times for the same QR while it's on screen
                guard cleaned != lastScannedPayload else { return }
                lastScannedPayload = cleaned
                
                // Logo easter egg — the Glyph app-icon QR
                if GlyphMessage.isLogoQR(cleaned) {
                    scanner.stop()
                    showLogoEasterEgg = true
                    return
                }
                
                // Try survey response (GLYR: or GLYRE:) — single static QR from respondent
                if SurveyResponse.isSurveyResponse(cleaned) {
                    if let response = SurveyResponse.decode(from: cleaned) {
                        let recorded = SurveyStore.shared.record(response: response)
                        scanner.stop()
                        if recorded {
                            surveyResponseRecorded = true
                        } else {
                            surveyResponseError = "Response already recorded or survey not found."
                        }
                        return
                    }
                }
                
                // Try single-QR web bundle (GLYW: or GLYWE:) — small experiences
                if GlyphWebBundle.isWebBundle(cleaned) {
                    if let bundle = GlyphWebBundle.decode(from: cleaned) {
                        #if DEBUG
                        print("✅ Decoded single web bundle: \(bundle.title)")
                        #endif
                        scanner.stop()
                        scannedWebBundle = bundle
                        showWebExperience = true
                        scanError = nil
                        return
                    }
                }
                
                // Try classic single-QR format (GLY1: or GLY1E:)
                if GlyphMessage.isMessage(cleaned) {
                    // PIN-protected — prompt for PIN
                    if GlyphMessage.isPinProtected(cleaned) {
                        scanner.stop()
                        pinPromptPayload = cleaned
                        pinInput = ""
                        return
                    }
                    
                    if let message = GlyphMessage.decode(from: cleaned) {
                        // Check time window FIRST — reject dead QR codes
                        if message.isWindowExpired {
                            scanner.stop()
                            windowExpiredReason = Self.windowExpiredMessage(message)
                            return
                        }
                        
                        // Check scan history — enforce read-once and expiration
                        if let reason = ScanHistory.shared.shouldBlock(payload: cleaned, message: message) {
                            #if DEBUG
                            print("🚫 Blocked re-scan: \(reason)")
                            #endif
                            scanner.stop()
                            blockedReason = reason
                            return
                        }
                        
                        // Record this scan
                        ScanHistory.shared.recordScan(payload: cleaned, expirationSeconds: message.expirationSeconds)
                        
                        #if DEBUG
                        print("✅ Decoded single Glyph: chars=\(message.text.count) expires=\(message.expirationSeconds)")
                        #endif
                        scanner.stop()
                        triggerScanFlash(for: message)
                        scannedMessage = message
                        scanError = nil
                        return
                    }
                }
                
                // Try chunked format (GLYC: or encrypted GLYCE:)
                if assembler.feed(cleaned) {
                    scanError = nil
                    
                    // Check if assembler completed a web bundle
                    if let webBundle = assembler.assembledWebBundle {
                        #if DEBUG
                        print("✅ Assembled web bundle: \(webBundle.title)")
                        #endif
                        scanner.stop()
                        chunkHaptic.impactOccurred(intensity: 1.0)
                        scannedWebBundle = webBundle
                        showWebExperience = true
                        // Dismiss progressive view if it was showing (don't reset yet — onDismiss handles it)
                        if showProgressiveImage {
                            showProgressiveImage = false
                        }
                        return
                    }
                    
                    // Show progressive image view as soon as we know total count
                    // BUT not if a web bundle just completed or web experience is pending
                    if assembler.totalCount > 0 && !showProgressiveImage && !showWebExperience
                        && assembler.assembledWebBundle == nil {
                        showProgressiveImage = true
                    }
                    
                    // Check if assembler has completed (handled by ProgressiveImageView now,
                    // but keep as fallback in case progressive view isn't shown yet)
                    if let message = assembler.assembledMessage, !showProgressiveImage {
                        // Check time window first
                        if message.isWindowExpired {
                            scanner.stop()
                            chunkHaptic.impactOccurred(intensity: 1.0)
                            windowExpiredReason = Self.windowExpiredMessage(message)
                            assembler.reset()
                            return
                        }
                        
                        // For batched messages, hash the encoded payload to check history
                        let assembledPayload = message.encode() ?? ""
                        if let reason = ScanHistory.shared.shouldBlock(payload: assembledPayload, message: message) {
                            #if DEBUG
                            print("🚫 Blocked re-scan (batched): \(reason)")
                            #endif
                            scanner.stop()
                            chunkHaptic.impactOccurred(intensity: 1.0)
                            blockedReason = reason
                            assembler.reset()
                            return
                        }
                        ScanHistory.shared.recordScan(payload: assembledPayload, expirationSeconds: message.expirationSeconds)
                        
                        #if DEBUG
                        print("✅ Assembled batched Glyph: chars=\(message.text.count) hasImage=\(message.imageData != nil)")
                        #endif
                        scanner.stop()
                        chunkHaptic.impactOccurred(intensity: 1.0)
                        triggerScanFlash(for: message)
                        scannedMessage = message
                        assembler.reset()
                    }
                    return
                }
                
                // Neither format matched — only show error if we're NOT mid-batch
                // (during batch, transient misreads from frame transitions are normal)
                if assembler.totalCount == 0 {
                    #if DEBUG
                    print("⚠️ Scanned non-Glyph payload: \(cleaned.prefix(80))")
                    #endif
                    scanError = "Not a valid Glyph code"
                }
            }
            scanner.start()
        }
        .onDisappear {
            scanner.stop()
        }
        .offset(y: dragOffset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    // Only allow downward drag when not mid-scan
                    if value.translation.height > 0 && assembler.totalCount == 0 {
                        dragOffset = value.translation.height
                    }
                }
                .onEnded { value in
                    if value.translation.height > 120 && assembler.totalCount == 0 {
                        scanner.stop()
                        dismiss()
                    } else {
                        withAnimation(.spring(response: 0.3)) {
                            dragOffset = 0
                        }
                    }
                }
        )
        .alert("Scan Error", isPresented: Binding(
            get: { scanError != nil },
            set: { newValue in if !newValue { scanError = nil } }
        )) {
            Button("OK", role: .cancel) { scanError = nil }
        } message: {
            Text(scanError ?? "Unknown error")
        }
        .alert("Message Unavailable", isPresented: Binding(
            get: { blockedReason != nil },
            set: { if !$0 { blockedReason = nil } }
        )) {
            Button("OK") {
                blockedReason = nil
                lastScannedPayload = ""
                scanner.start()
            }
        } message: {
            Text(blockedReason ?? "This message can no longer be viewed.")
        }
        .fullScreenCover(item: $scannedMessage, onDismiss: {
            assembler.reset()
            lastReceivedCount = 0
            lastScannedPayload = ""
            scanner.start() // Resume scanning
        }) { message in
            MessageView(message: message)
        }
        .onChange(of: scannedMessage) { _, newMessage in
            // Auto-add signed messages to the friend's conversation
            guard let message = newMessage, let sig = message.signature else { return }
            let friendId = "\(sig.platform.rawValue):\(sig.handle)"
            ConversationStore.shared.addMessage(message, to: friendId, isFromMe: false)
        }
        .sheet(isPresented: $showPhotoScanner, onDismiss: {
            scanner.start() // Resume camera when photo scanner is dismissed
        }) {
            PhotoScannerView()
        }
        .fullScreenCover(isPresented: $showWebExperience, onDismiss: {
            scannedWebBundle = nil
            assembler.reset()
            lastReceivedCount = 0
            lastScannedPayload = ""
            scanner.start()
        }) {
            if let bundle = scannedWebBundle {
                WebExperienceView(bundle: bundle)
            }
        }
        .fullScreenCover(isPresented: $showLogoEasterEgg, onDismiss: {
            lastScannedPayload = ""
            scanner.start()
        }) {
            LogoEasterEggView()
        }
        .onChange(of: assembler.assembledWebBundle) { _, newBundle in
            // Safety net: catches web bundle completion even when ProgressiveImageView is showing
            guard let bundle = newBundle, !showWebExperience else { return }
            #if DEBUG
            print("✅ onChange caught assembled web bundle: \(bundle.title)")
            #endif
            scanner.stop()
            chunkHaptic.impactOccurred(intensity: 1.0)
            // Dismiss progressive image view if it's showing
            if showProgressiveImage {
                showProgressiveImage = false
            }
            scannedWebBundle = bundle
            showWebExperience = true
        }
        .alert("Response Recorded", isPresented: $surveyResponseRecorded) {
            Button("OK") {
                lastScannedPayload = ""
                scanner.start()
            }
        } message: {
            Text("Survey response has been saved. View results in your Surveys list.")
        }
        .alert("Response Error", isPresented: Binding(
            get: { surveyResponseError != nil },
            set: { if !$0 { surveyResponseError = nil } }
        )) {
            Button("OK") {
                surveyResponseError = nil
                lastScannedPayload = ""
                scanner.start()
            }
        } message: {
            Text(surveyResponseError ?? "Could not record this response.")
        }
        .alert("PIN Required", isPresented: Binding(
            get: { pinPromptPayload != nil },
            set: { if !$0 { pinPromptPayload = nil } }
        )) {
            SecureField("Enter PIN", text: $pinInput)
                .keyboardType(.numberPad)
            Button("Unlock") {
                guard let payload = pinPromptPayload else { return }
                if let message = GlyphMessage.decode(from: payload, pin: pinInput) {
                    // Check time window
                    if message.isWindowExpired {
                        pinPromptPayload = nil
                        pinInput = ""
                        windowExpiredReason = Self.windowExpiredMessage(message)
                        return
                    }
                    
                    // Check scan history
                    if let reason = ScanHistory.shared.shouldBlock(payload: payload, message: message) {
                        pinPromptPayload = nil
                        pinInput = ""
                        blockedReason = reason
                        return
                    }
                    ScanHistory.shared.recordScan(payload: payload, expirationSeconds: message.expirationSeconds)
                    pinPromptPayload = nil
                    pinInput = ""
                    triggerScanFlash(for: message)
                    scannedMessage = message
                } else {
                    // Wrong PIN — keep payload, clear input, re-show
                    pinInput = ""
                    scanError = "Incorrect PIN. Try again."
                    // Keep pinPromptPayload nil so user can re-scan
                    pinPromptPayload = nil
                    lastScannedPayload = ""
                    scanner.start()
                }
            }
            Button("Cancel", role: .cancel) {
                pinPromptPayload = nil
                pinInput = ""
                lastScannedPayload = ""
                scanner.start()
            }
        } message: {
            Text("This message is PIN-protected.\nEnter the PIN shared by the sender.")
        }
        .alert("QR Expired", isPresented: Binding(
            get: { windowExpiredReason != nil },
            set: { if !$0 { windowExpiredReason = nil } }
        )) {
            Button("OK") {
                windowExpiredReason = nil
                lastScannedPayload = ""
                scanner.start()
            }
        } message: {
            Text(windowExpiredReason ?? "This QR code has expired.")
        }
    }
    
    // MARK: - Torch Flash Helper
    
    /// Briefly pulses the device's torch to signal a successful scan.
    /// Respects both the global setting and the per-message `flashOnScan` flag.
    private func triggerScanFlash(for message: GlyphMessage) {
        // Global override — user disabled flash in settings
        guard flashOnScanEnabled else { return }
        // Per-message flag — sender disabled flash (nil defaults to true)
        guard message.flashOnScan ?? true else { return }
        
        guard let device = AVCaptureDevice.default(for: .video),
              device.hasTorch else { return }
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try device.lockForConfiguration()
                device.torchMode = .on
                device.unlockForConfiguration()
                
                // Keep torch on briefly, then turn off
                DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.35) {
                    do {
                        try device.lockForConfiguration()
                        device.torchMode = .off
                        device.unlockForConfiguration()
                    } catch {
                        #if DEBUG
                        print("⚠️ Torch off failed: \(error)")
                        #endif
                    }
                }
            } catch {
                #if DEBUG
                print("⚠️ Torch flash failed: \(error)")
                #endif
            }
        }
    }
    
    // MARK: - Window Expired Helper
    
    /// Generates a user-friendly message about when the QR expired.
    private static func windowExpiredMessage(_ message: GlyphMessage) -> String {
        guard let expiresAt = message.expiresAt else {
            return "This QR code has expired."
        }
        let elapsed = Date().timeIntervalSince(expiresAt)
        let formatted = formatElapsedWindow(elapsed)
        return "This QR code expired \(formatted) ago.\nThe sender set a time window that has closed."
    }
    
    /// Format elapsed seconds into a readable string.
    private static func formatElapsedWindow(_ seconds: TimeInterval) -> String {
        let s = Int(seconds)
        if s < 60 { return "\(s) sec" }
        if s < 3600 { return "\(s / 60) min" }
        if s < 86400 { return "\(s / 3600) hour\(s / 3600 == 1 ? "" : "s")" }
        return "\(s / 86400) day\(s / 86400 == 1 ? "" : "s")"
    }
}

// MARK: - Scan Corner Shape

/// Draws corner brackets for the scan frame.
struct ScanCorners: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let length: CGFloat = 30
        let r: CGFloat = 8
        
        // Top-left
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + length))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + r))
        path.addQuadCurve(to: CGPoint(x: rect.minX + r, y: rect.minY),
                          control: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + length, y: rect.minY))
        
        // Top-right
        path.move(to: CGPoint(x: rect.maxX - length, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - r, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + r),
                          control: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + length))
        
        // Bottom-right
        path.move(to: CGPoint(x: rect.maxX, y: rect.maxY - length))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - r))
        path.addQuadCurve(to: CGPoint(x: rect.maxX - r, y: rect.maxY),
                          control: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX - length, y: rect.maxY))
        
        // Bottom-left
        path.move(to: CGPoint(x: rect.minX + length, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + r, y: rect.maxY))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY - r),
                          control: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - length))
        
        return path
    }
}

// MARK: - Camera Preview (UIViewRepresentable)

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = UIScreen.main.bounds
        view.layer.addSublayer(previewLayer)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let layer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            layer.frame = UIScreen.main.bounds
        }
    }
}

// MARK: - QR Scanner Model (Vision-based)

/// Uses AVCaptureVideoDataOutput + VNDetectBarcodesRequest for reliable
/// scanning of dense QR codes (like GLYC: chunks). AVCaptureMetadataOutput
/// often fails to decode high-density QR codes; Vision is significantly
/// more capable.
class QRScannerModel: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    let session = AVCaptureSession()
    
    @MainActor @Published var permissionDenied = false
    @MainActor var onCodeScanned: ((String) -> Void)?
    
    private var isRunning = false
    
    /// Throttle: skip frames while one is being processed
    private var isProcessingFrame = false
    
    /// Reusable Vision request
    private lazy var barcodeRequest: VNDetectBarcodesRequest = {
        let request = VNDetectBarcodesRequest()
        request.symbologies = [.qr]
        return request
    }()
    
    @MainActor
    func start() {
        guard !isRunning else { return }
        
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.setupSession()
                    } else {
                        self?.permissionDenied = true
                    }
                }
            }
        default:
            permissionDenied = true
        }
    }
    
    @MainActor
    func stop() {
        guard isRunning else { return }
        isRunning = false
        DispatchQueue.global(qos: .userInitiated).async { [session] in
            session.stopRunning()
        }
    }
    
    @MainActor
    private func setupSession() {
        guard !isRunning else { return }
        
        let captureSession = session
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self, captureSession] in
            guard let self else { return }
            
            captureSession.beginConfiguration()
            
            // Use high resolution for dense QR codes
            if captureSession.canSetSessionPreset(.hd1920x1080) {
                captureSession.sessionPreset = .hd1920x1080
            }
            
            // Remove existing inputs/outputs
            captureSession.inputs.forEach { captureSession.removeInput($0) }
            captureSession.outputs.forEach { captureSession.removeOutput($0) }
            
            guard let device = AVCaptureDevice.default(for: .video),
                  let input = try? AVCaptureDeviceInput(device: device),
                  captureSession.canAddInput(input) else {
                captureSession.commitConfiguration()
                return
            }
            
            captureSession.addInput(input)
            
            // Lock autofocus to near range for scanning screens
            try? device.lockForConfiguration()
            if device.isAutoFocusRangeRestrictionSupported {
                device.autoFocusRangeRestriction = .near
            }
            if device.isFocusModeSupported(.continuousAutoFocus) {
                device.focusMode = .continuousAutoFocus
            }
            device.unlockForConfiguration()
            
            // Video data output — we'll run Vision on each frame
            let videoOutput = AVCaptureVideoDataOutput()
            videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "glyph.qr.scan", qos: .userInitiated))
            videoOutput.alwaysDiscardsLateVideoFrames = true
            
            if captureSession.canAddOutput(videoOutput) {
                captureSession.addOutput(videoOutput)
            }
            
            captureSession.commitConfiguration()
            captureSession.startRunning()
            
            DispatchQueue.main.async {
                self.isRunning = true
            }
        }
    }
    
    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
    
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        // Throttle — don't queue up Vision requests
        guard !isProcessingFrame else { return }
        isProcessingFrame = true
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            isProcessingFrame = false
            return
        }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        
        do {
            try handler.perform([barcodeRequest])
        } catch {
            #if DEBUG
            print("⚠️ Vision request failed: \(error)")
            #endif
            isProcessingFrame = false
            return
        }
        
        guard let results = barcodeRequest.results, !results.isEmpty else {
            isProcessingFrame = false
            return
        }
        
        // Gather all QR payloads from this frame
        let payloads = results.compactMap { $0.payloadStringValue }
        
        if !payloads.isEmpty {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                for payload in payloads {
                    self.onCodeScanned?(payload)
                }
            }
        }
        
        isProcessingFrame = false
    }
}

#Preview {
    ScannerView()
}
