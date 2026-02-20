import SwiftUI
import Photos

// MARK: - Progressive Image View

/// Displays an image being progressively assembled from QR code chunks in real-time.
/// The user sees the image "loading in" as chunks arrive, and can stop early
/// to save whatever has been received so far — great for large (Highest quality)
/// transfers where some frames might be missed.
struct ProgressiveImageView: View {
    @ObservedObject var assembler: GlyphChunkAssembler
    @ObservedObject var scanner: QRScannerModel
    
    /// Called when the user finishes (either complete or early stop).
    /// Passes the final GlyphMessage to present in MessageView.
    var onComplete: (GlyphMessage) -> Void
    /// Called if the user cancels entirely without saving.
    var onCancel: () -> Void
    
    @State private var currentImage: UIImage?
    @State private var lastUpdateCount = 0
    @State private var imageSaved = false
    @State private var imageSaveError: String?
    @State private var showingSaveConfirmation = false
    @State private var appeared = false
    @State private var pulseScale: CGFloat = 1.0
    @State private var placeholderOffset: CGFloat = -60
    @State private var placeholderOpacity: Double = 0
    
    /// Haptic feedback
    private let chunkHaptic = UIImpactFeedbackGenerator(style: .light)
    private let completeHaptic = UINotificationFeedbackGenerator()
    
    var body: some View {
        ZStack {
            // Semi-transparent backdrop — lets camera feed show through
            Color.black.opacity(0.75)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                // MARK: - Top Bar
                topBar
                
                // MARK: - Image Preview Area
                imagePreview
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // MARK: - Progress Section
                progressSection
                
                // MARK: - Action Buttons
                actionButtons
                    .padding(.bottom, 40)
            }
        }
        .onAppear {
            chunkHaptic.prepare()
            completeHaptic.prepare()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                appeared = true
            }
        }
        .onChange(of: assembler.receivedCount) { _, newCount in
            guard newCount > lastUpdateCount else { return }
            lastUpdateCount = newCount
            chunkHaptic.impactOccurred(intensity: 0.4)
            
            // Try to render partial image every few chunks
            // (not every single one — that would be expensive)
            if newCount % 3 == 0 || newCount == assembler.totalCount {
                refreshPartialImage()
            }
            
            // Check for completion
            if let message = assembler.assembledMessage {
                completeHaptic.notificationOccurred(.success)
                currentImage = message.decodedImage
                // Auto-navigate to message view after a brief moment
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    onComplete(message)
                }
            }
        }
    }
    
    // MARK: - Top Bar
    
    private var topBar: some View {
        HStack {
            Button {
                scanner.stop()
                onCancel()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.white.opacity(0.4))
            }
            
            Spacer()
            
            VStack(spacing: 2) {
                Text("Receiving Image")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(GlyphTheme.primaryText)
                Text("\(assembler.receivedCount) of \(assembler.totalCount) frames")
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundColor(GlyphTheme.secondaryText)
            }
            
            Spacer()
            
            // Placeholder for symmetry
            Color.clear
                .frame(width: 28, height: 28)
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }
    
    // MARK: - Image Preview
    
    private var imagePreview: some View {
        ZStack {
            // Placeholder / loading state
            if let img = currentImage {
                Image(uiImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(GlyphTheme.accent.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: GlyphTheme.accent.opacity(0.3), radius: 20)
                    .padding(.horizontal, 24)
                    .transition(.opacity)
            } else {
                // Waiting for enough data to render — camera is visible behind overlay
                VStack(spacing: 16) {
                    Image(systemName: "qrcode.viewfinder")
                        .font(.system(size: 56, weight: .light))
                        .foregroundStyle(GlyphTheme.accentGradient)
                        .scaleEffect(pulseScale)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                                pulseScale = 1.1
                            }
                        }
                    
                    Text("Keep scanning — image building…")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                }
                .offset(y: placeholderOffset)
                .opacity(placeholderOpacity)
                .onAppear {
                    withAnimation(.spring(response: 0.7, dampingFraction: 0.75)) {
                        placeholderOffset = 40
                        placeholderOpacity = 1
                    }
                }
            }
            
            // Scanning indicator overlay (top-right corner)
            VStack {
                HStack {
                    Spacer()
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                            .opacity(pulseScale > 1.05 ? 1.0 : 0.4)
                        Text("SCANNING")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial.opacity(0.6))
                    .clipShape(Capsule())
                    .padding(.trailing, 28)
                    .padding(.top, 4)
                }
                Spacer()
            }
            .opacity(assembler.assembledMessage == nil ? 1 : 0)
        }
    }
    
    // MARK: - Progress Section
    
    private var progressSection: some View {
        VStack(spacing: 12) {
            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Track
                    RoundedRectangle(cornerRadius: 4)
                        .fill(GlyphTheme.surface)
                    
                    // Fill
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [GlyphTheme.accent, GlyphTheme.violet],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * assembler.progress)
                        .animation(.easeOut(duration: 0.3), value: assembler.progress)
                }
            }
            .frame(height: 6)
            .padding(.horizontal, 24)
            
            // Percentage
            Text("\(Int(assembler.progress * 100))%")
                .font(.system(size: 28, weight: .bold, design: .monospaced))
                .foregroundColor(GlyphTheme.accent)
            
            // Chunk grid (compact)
            let gridSize = assembler.totalCount
            let columns = Array(repeating: GridItem(.fixed(gridSize > 100 ? 8 : 16), spacing: 2),
                                count: min(gridSize, gridSize > 100 ? 20 : 15))
            
            ScrollView(.vertical, showsIndicators: false) {
                LazyVGrid(columns: columns, spacing: 2) {
                    ForEach(0..<assembler.totalCount, id: \.self) { idx in
                        let received = assembler.receivedIndices.contains(idx)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(received ? GlyphTheme.accent : GlyphTheme.surface.opacity(0.5))
                            .frame(height: gridSize > 100 ? 8 : 16)
                            .animation(.easeOut(duration: 0.15), value: received)
                    }
                }
                .padding(.horizontal, 24)
            }
            .frame(maxHeight: gridSize > 100 ? 80 : 100)
            
            Text("Hold camera steady on cycling QR codes")
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(GlyphTheme.secondaryText)
        }
        .padding(.vertical, 12)
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            if assembler.assembledMessage != nil {
                // Complete — show done button
                Button {
                    if let msg = assembler.assembledMessage {
                        onComplete(msg)
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                        Text("View Message")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: GlyphTheme.buttonHeight)
                    .background(GlyphTheme.accentGradient)
                    .foregroundColor(.black)
                    .clipShape(RoundedRectangle(cornerRadius: GlyphTheme.cornerRadius))
                }
                .padding(.horizontal, 24)
            } else {
                // Still receiving — show stop & save button
                Button {
                    stopAndSave()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "stop.circle.fill")
                            .font(.system(size: 20))
                        Text("Stop & Save As-Is")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: GlyphTheme.buttonHeight)
                    .background(assembler.receivedCount > 0 ? GlyphTheme.surface : GlyphTheme.surface.opacity(0.5))
                    .foregroundColor(assembler.receivedCount > 0 ? GlyphTheme.warning : GlyphTheme.secondaryText)
                    .clipShape(RoundedRectangle(cornerRadius: GlyphTheme.cornerRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: GlyphTheme.cornerRadius)
                            .stroke(GlyphTheme.warning.opacity(assembler.receivedCount > 0 ? 0.4 : 0), lineWidth: 1)
                    )
                }
                .disabled(assembler.receivedCount == 0)
                .padding(.horizontal, 24)
                
                if assembler.receivedCount > 0 && assembler.receivedCount < assembler.totalCount {
                    Text("Missing \(assembler.totalCount - assembler.receivedCount) frames — image may have gaps")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(GlyphTheme.secondaryText)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private func refreshPartialImage() {
        // Run on background to avoid blocking UI
        DispatchQueue.global(qos: .userInitiated).async {
            let img = assembler.partialImage()
            DispatchQueue.main.async {
                if let img {
                    withAnimation(.easeOut(duration: 0.3)) {
                        currentImage = img
                    }
                }
            }
        }
    }
    
    private func stopAndSave() {
        scanner.stop()
        
        // Try to get best possible image from what we have
        refreshPartialImage()
        
        // If we can build a partial message, pass it through
        if let partialMsg = assembler.partialAssemble() {
            onComplete(partialMsg)
        } else if let img = assembler.partialImage() ?? currentImage {
            // Build a synthetic message with whatever image we recovered
            let base64 = img.jpegData(compressionQuality: 0.9)?.base64EncodedString()
            let msg = GlyphMessage(
                text: "Photo",
                expirationSeconds: ExpirationOption.forever.rawValue,
                createdAt: Date(),
                imageData: base64
            )
            onComplete(msg)
        } else {
            // Nothing usable — just cancel
            onCancel()
        }
    }
}

#Preview {
    ProgressiveImageView(
        assembler: {
            let a = GlyphChunkAssembler()
            a.totalCount = 150
            a.receivedCount = 42
            a.receivedIndices = Set(0..<42)
            return a
        }(),
        scanner: QRScannerModel(),
        onComplete: { _ in },
        onCancel: { }
    )
    .preferredColorScheme(.dark)
}
