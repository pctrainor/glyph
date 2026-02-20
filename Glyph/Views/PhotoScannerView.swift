import SwiftUI
import PhotosUI
import Vision

// MARK: - Photo Scanner View

/// Scans Glyph QR codes from saved photos / screenshots.
///
/// Each GLYC: chunk self-describes its position (`index` / `total`),
/// so the UI auto-builds a chunk grid the moment the first frame is recognised.
/// The user just keeps picking photos and watches the slots fill in — exactly
/// like holding a camera at a cycling QR display.
struct PhotoScannerView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPhotos: [PhotosPickerItem] = []
    @StateObject private var assembler = GlyphChunkAssembler()
    @State private var scannedMessage: GlyphMessage?
    @State private var scannedWebBundle: GlyphWebBundle?
    @State private var showWebExperience = false
    @State private var scanError: String?
    @State private var isProcessing = false
    @State private var photosScannedCount = 0
    @State private var surveyResponseRecorded = false
    @State private var surveyResponseError: String?
    @State private var pinPromptPayload: String?
    @State private var pinInput = ""
    @State private var windowExpiredReason: String?
    @State private var blockedReason: String?
    @State private var showLogoEasterEgg = false
    
    /// Haptic generator for chunk-landed feedback
    private let haptic = UIImpactFeedbackGenerator(style: .medium)

    var body: some View {
        ZStack {
            GlyphTheme.backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 28) {

                // MARK: - Top bar
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    Spacer()
                    Text("Scan from Photos")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(GlyphTheme.primaryText)
                    Spacer()
                    Color.clear.frame(width: 28, height: 28) // balance
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                // MARK: - Content
                if assembler.totalCount > 0 && scannedMessage == nil {
                    // Batch in progress — show chunk grid
                    chunkGridSection
                    Spacer()
                } else if scannedMessage == nil {
                    // Idle — show instructions
                    Spacer()
                    instructionSection
                    Spacer()
                }

                // MARK: - Photo picker
                if scannedMessage == nil {
                    photoPickerButton
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                }
            }

            // Processing spinner
            if isProcessing {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                VStack(spacing: 14) {
                    ProgressView()
                        .scaleEffect(1.4)
                        .tint(GlyphTheme.accent)
                    Text("Scanning QR codes…")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(.white)
                }
            }
        }
        .alert("Scan Error", isPresented: Binding(
            get: { scanError != nil },
            set: { if !$0 { scanError = nil } }
        )) {
            Button("OK", role: .cancel) { scanError = nil }
        } message: {
            Text(scanError ?? "Unknown error")
        }
        .alert("Response Recorded", isPresented: $surveyResponseRecorded) {
            Button("OK") { }
        } message: {
            Text("Survey response has been saved. View results in your Surveys list.")
        }
        .alert("Response Error", isPresented: Binding(
            get: { surveyResponseError != nil },
            set: { if !$0 { surveyResponseError = nil } }
        )) {
            Button("OK") { surveyResponseError = nil }
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
                    if message.isWindowExpired {
                        pinPromptPayload = nil
                        pinInput = ""
                        windowExpiredReason = Self.windowExpiredMessage(message)
                        return
                    }
                    if let reason = ScanHistory.shared.shouldBlock(payload: payload, message: message) {
                        pinPromptPayload = nil
                        pinInput = ""
                        blockedReason = reason
                        return
                    }
                    ScanHistory.shared.recordScan(payload: payload, expirationSeconds: message.expirationSeconds)
                    pinPromptPayload = nil
                    pinInput = ""
                    scannedMessage = message
                } else {
                    pinInput = ""
                    scanError = "Incorrect PIN. Try again."
                    pinPromptPayload = nil
                }
            }
            Button("Cancel", role: .cancel) {
                pinPromptPayload = nil
                pinInput = ""
            }
        } message: {
            Text("This message is PIN-protected.\nEnter the PIN shared by the sender.")
        }
        .alert("QR Expired", isPresented: Binding(
            get: { windowExpiredReason != nil },
            set: { if !$0 { windowExpiredReason = nil } }
        )) {
            Button("OK") { windowExpiredReason = nil }
        } message: {
            Text(windowExpiredReason ?? "This QR code has expired.")
        }
        .alert("Message Unavailable", isPresented: Binding(
            get: { blockedReason != nil },
            set: { if !$0 { blockedReason = nil } }
        )) {
            Button("OK") { blockedReason = nil }
        } message: {
            Text(blockedReason ?? "This message can no longer be viewed.")
        }
        .fullScreenCover(item: $scannedMessage, onDismiss: {
            resetState()
        }) { message in
            MessageView(message: message)
        }
        .onChange(of: scannedMessage) { _, newMessage in
            // Auto-add signed messages to the friend's conversation
            guard let message = newMessage, let sig = message.signature else { return }
            let friendId = "\(sig.platform.rawValue):\(sig.handle)"
            ConversationStore.shared.addMessage(message, to: friendId, isFromMe: false)
        }
        .fullScreenCover(isPresented: $showWebExperience, onDismiss: {
            scannedWebBundle = nil
            resetState()
        }) {
            if let bundle = scannedWebBundle {
                WebExperienceView(bundle: bundle)
            }
        }
        .fullScreenCover(isPresented: $showLogoEasterEgg, onDismiss: {
            resetState()
        }) {
            LogoEasterEggView()
        }
    }

    // MARK: - Instruction (idle state)

    private var instructionSection: some View {
        VStack(spacing: 14) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 52, weight: .thin))
                .foregroundStyle(GlyphTheme.accentGradient)

            Text("Select photos with Glyph QR codes")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundColor(GlyphTheme.primaryText)
                .multilineTextAlignment(.center)

            Text("For batched messages, select multiple screenshots.\nChunk positions are encoded in each QR —\nprogress fills in automatically.")
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(GlyphTheme.secondaryText)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
        }
    }

    // MARK: - Chunk Grid (batch in progress)

    private var chunkGridSection: some View {
        VStack(spacing: 16) {
            // Summary
            Text("Receiving \(assembler.receivedCount) of \(assembler.totalCount) frames")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundColor(.white)

            // Progress bar
            ProgressView(value: assembler.progress)
                .progressViewStyle(.linear)
                .tint(GlyphTheme.accent)
                .frame(width: 220)

            // Chunk slot grid — each square represents one frame
            let columns = Array(repeating: GridItem(.fixed(28), spacing: 6), count: min(assembler.totalCount, 10))
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(0..<assembler.totalCount, id: \.self) { idx in
                    let received = assembler.receivedIndices.contains(idx)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(received ? GlyphTheme.accent : GlyphTheme.surface)
                        .frame(width: 28, height: 28)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(received ? GlyphTheme.accent.opacity(0.6) : GlyphTheme.secondaryText.opacity(0.3), lineWidth: 1)
                        )
                        .overlay(
                            Text("\(idx + 1)")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(received ? .black : GlyphTheme.secondaryText.opacity(0.5))
                        )
                        .animation(.easeOut(duration: 0.25), value: received)
                }
            }
            .padding(.horizontal, 24)

            // Missing-chunk hint
            let missing = assembler.totalCount - assembler.receivedCount
            if missing > 0 {
                Text("\(missing) frame\(missing == 1 ? "" : "s") remaining — pick more photos")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(GlyphTheme.secondaryText)
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Photo Picker

    private var photoPickerButton: some View {
        PhotosPicker(
            selection: $selectedPhotos,
            maxSelectionCount: 60,
            matching: .images,
            photoLibrary: .shared()
        ) {
            HStack(spacing: 10) {
                Image(systemName: assembler.totalCount > 0 ? "plus.rectangle.on.rectangle" : "photo.badge.plus")
                    .font(.system(size: 20, weight: .semibold))
                Text(assembler.totalCount > 0 ? "Add More Photos" : "Choose Photos")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
            }
            .frame(maxWidth: .infinity)
            .frame(height: GlyphTheme.buttonHeight)
            .background(GlyphTheme.accentGradient)
            .foregroundColor(.black)
            .clipShape(RoundedRectangle(cornerRadius: GlyphTheme.cornerRadius))
        }
        .onChange(of: selectedPhotos) { _, newItems in
            guard !newItems.isEmpty else { return }
            processSelectedPhotos(newItems)
        }
    }

    // MARK: - Processing Logic

    private func processSelectedPhotos(_ items: [PhotosPickerItem]) {
        isProcessing = true
        haptic.prepare()

        Task {
            var newChunksTotal = 0

            for item in items {
                guard let data = try? await item.loadTransferable(type: Data.self),
                      let uiImage = UIImage(data: data) else { continue }

                let payloads = detectQRCodes(in: uiImage)

                for payload in payloads {
                    let cleaned = payload.trimmingCharacters(in: .whitespacesAndNewlines)

                    // Logo easter egg — the Glyph app-icon QR
                    if GlyphMessage.isLogoQR(cleaned) {
                        await MainActor.run {
                            isProcessing = false
                            showLogoEasterEgg = true
                        }
                        return
                    }

                    // Survey response (GLYR: or GLYRE: or GLYRP:)
                    if SurveyResponse.isSurveyResponse(cleaned) {
                        if let response = SurveyResponse.decode(from: cleaned) {
                            let recorded = SurveyStore.shared.record(response: response)
                            await MainActor.run {
                                isProcessing = false
                                if recorded {
                                    surveyResponseRecorded = true
                                } else {
                                    surveyResponseError = "Response already recorded or survey not found."
                                }
                            }
                            return
                        }
                    }

                    // Single-QR web bundle (GLYW: or GLYWE: or GLYWP:)
                    if GlyphWebBundle.isWebBundle(cleaned) {
                        if let bundle = GlyphWebBundle.decode(from: cleaned) {
                            #if DEBUG
                            print("✅ [PhotoScan] Single web bundle decoded: \(bundle.title)")
                            #endif
                            await MainActor.run {
                                isProcessing = false
                                haptic.impactOccurred(intensity: 1.0)
                                scannedWebBundle = bundle
                                showWebExperience = true
                            }
                            return
                        }
                    }

                    // Single-QR message (GLY1: or GLY1E: or GLY1P:)
                    if GlyphMessage.isMessage(cleaned) {
                        // PIN-protected — prompt for PIN
                        if GlyphMessage.isPinProtected(cleaned) {
                            await MainActor.run {
                                isProcessing = false
                                pinPromptPayload = cleaned
                                pinInput = ""
                            }
                            return
                        }

                        if let message = GlyphMessage.decode(from: cleaned) {
                            // Check time window
                            if message.isWindowExpired {
                                await MainActor.run {
                                    isProcessing = false
                                    windowExpiredReason = Self.windowExpiredMessage(message)
                                }
                                return
                            }
                            // Check scan history
                            if let reason = ScanHistory.shared.shouldBlock(payload: cleaned, message: message) {
                                await MainActor.run {
                                    isProcessing = false
                                    blockedReason = reason
                                }
                                return
                            }
                            ScanHistory.shared.recordScan(payload: cleaned, expirationSeconds: message.expirationSeconds)

                            #if DEBUG
                            print("✅ [PhotoScan] Single Glyph decoded")
                            #endif
                            await MainActor.run {
                                isProcessing = false
                                haptic.impactOccurred(intensity: 1.0)
                                scannedMessage = message
                            }
                            return
                        }
                    }

                    // Chunked frame (GLYC: or GLYCE: or GLYCP:)
                    if assembler.feed(cleaned) {
                        newChunksTotal += 1
                        await MainActor.run {
                            haptic.impactOccurred(intensity: 0.6)
                        }

                        // Check if assembler completed a web bundle
                        if let webBundle = assembler.assembledWebBundle {
                            #if DEBUG
                            print("✅ [PhotoScan] Batch web bundle assembled: \(webBundle.title)")
                            #endif
                            await MainActor.run {
                                isProcessing = false
                                haptic.impactOccurred(intensity: 1.0)
                                scannedWebBundle = webBundle
                                showWebExperience = true
                                assembler.reset()
                            }
                            return
                        }

                        if let message = assembler.assembledMessage {
                            // Check time window
                            if message.isWindowExpired {
                                await MainActor.run {
                                    isProcessing = false
                                    haptic.impactOccurred(intensity: 1.0)
                                    windowExpiredReason = Self.windowExpiredMessage(message)
                                    assembler.reset()
                                }
                                return
                            }
                            // Check scan history for batched messages
                            let assembledPayload = message.encode() ?? ""
                            if let reason = ScanHistory.shared.shouldBlock(payload: assembledPayload, message: message) {
                                await MainActor.run {
                                    isProcessing = false
                                    haptic.impactOccurred(intensity: 1.0)
                                    blockedReason = reason
                                    assembler.reset()
                                }
                                return
                            }
                            ScanHistory.shared.recordScan(payload: assembledPayload, expirationSeconds: message.expirationSeconds)

                            #if DEBUG
                            print("✅ [PhotoScan] Batch assembled: \(message.text.prefix(40))…")
                            #endif
                            await MainActor.run {
                                isProcessing = false
                                haptic.impactOccurred(intensity: 1.0)
                                scannedMessage = message
                                assembler.reset()
                            }
                            return
                        }
                    }
                }

                await MainActor.run { photosScannedCount += 1 }
            }

            await MainActor.run {
                isProcessing = false
                selectedPhotos = []

                if assembler.totalCount > 0 && assembler.assembledMessage == nil {
                    // Partial batch — grid shows what's missing; no error needed
                } else if newChunksTotal == 0 && scannedMessage == nil && !showWebExperience && !surveyResponseRecorded {
                    scanError = photosScannedCount == 0
                        ? "Could not load any of the selected photos"
                        : "No valid Glyph QR codes found in the selected photos"
                }
            }
        }
    }

    // MARK: - QR Detection (Vision Framework)

    /// Detects every QR code in an image using the Vision framework.
    /// Vision is significantly more reliable than CIDetector for dense QR codes.
    private func detectQRCodes(in image: UIImage) -> [String] {
        guard let cgImage = image.cgImage else { return [] }

        var payloads: [String] = []
        let request = VNDetectBarcodesRequest { request, _ in
            guard let results = request.results as? [VNBarcodeObservation] else { return }
            for result in results {
                if result.symbology == .qr, let value = result.payloadStringValue {
                    payloads.append(value)
                }
            }
        }
        request.symbologies = [.qr]

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try? handler.perform([request])
        return payloads
    }

    // MARK: - Window Expired Helper

    private static func windowExpiredMessage(_ message: GlyphMessage) -> String {
        guard let expiresAt = message.expiresAt else {
            return "This QR code has expired."
        }
        let elapsed = Date().timeIntervalSince(expiresAt)
        let formatted = formatElapsedWindow(elapsed)
        return "This QR code expired \(formatted) ago.\nThe sender set a time window that has closed."
    }

    private static func formatElapsedWindow(_ seconds: TimeInterval) -> String {
        let s = Int(seconds)
        if s < 60 { return "\(s) sec" }
        if s < 3600 { return "\(s / 60) min" }
        if s < 86400 { return "\(s / 3600) hour\(s / 3600 == 1 ? "" : "s")" }
        return "\(s / 86400) day\(s / 86400 == 1 ? "" : "s")"
    }

    // MARK: - Reset

    private func resetState() {
        assembler.reset()
        selectedPhotos = []
        photosScannedCount = 0
        scannedMessage = nil
        scannedWebBundle = nil
        showWebExperience = false
        scanError = nil
        pinPromptPayload = nil
        pinInput = ""
        windowExpiredReason = nil
        blockedReason = nil
        surveyResponseRecorded = false
        surveyResponseError = nil
    }
}

#Preview {
    PhotoScannerView()
        .preferredColorScheme(.dark)
}
