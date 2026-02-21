import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

// MARK: - Share Card View

/// A branded, colorful QR code card for in-person app sharing.
///
/// The QR encodes the TestFlight URL, so:
/// - **Any camera app** → opens TestFlight → installs Glyph
/// - **Glyph scanner** → detects the invite URL → triggers a special welcome experience
///
/// The QR is rendered with Glyph's gradient colors and the logo overlaid in the
/// center. QR error correction (level H, 30%) handles the logo obscuring some modules.
struct ShareCardView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var profile = SocialProfile.shared
    
    @State private var appeared = false
    @State private var pulseScale: CGFloat = 1.0
    @State private var showShareSheet = false
    @State private var renderedImage: UIImage?
    
    /// The TestFlight invite URL encoded into the QR.
    static let testFlightURL = "https://testflight.apple.com/join/pJ72EpPS"
    
    /// Check if a scanned string is the Glyph invite QR.
    static func isInviteQR(_ string: String) -> Bool {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return trimmed.contains("testflight.apple.com/join/pj72epps")
    }
    
    var body: some View {
        ZStack {
            // Background
            GlyphTheme.backgroundGradient
                .ignoresSafeArea()
            
            // Ambient glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            GlyphTheme.accent.opacity(0.15),
                            GlyphTheme.violet.opacity(0.08),
                            .clear
                        ],
                        center: .center,
                        startRadius: 40,
                        endRadius: 250
                    )
                )
                .frame(width: 500, height: 500)
                .scaleEffect(pulseScale)
                .blur(radius: 40)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // QR Card
                    qrCardSection
                    
                    // Info
                    infoSection
                    
                    // Action buttons
                    actionButtons
                    
                    Spacer().frame(height: 20)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.1)) {
                appeared = true
            }
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                pulseScale = 1.1
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let image = renderedImage {
                ShareSheet(items: [
                    image,
                    URL(string: Self.testFlightURL)!,
                    "Try Glyph — encrypted vanishing messages 🔮\n\(Self.testFlightURL)" as String
                ])
            }
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.white.opacity(0.5))
            }
            Spacer()
            Text("Share Glyph")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundColor(GlyphTheme.primaryText)
            Spacer()
            // Balance spacer
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 28))
                .foregroundColor(.clear)
        }
    }
    
    // MARK: - QR Card
    
    private var qrCardSection: some View {
        VStack(spacing: 0) {
            // The QR code with Glyph branding
            ZStack {
                // White background for QR readability
                RoundedRectangle(cornerRadius: 20)
                    .fill(.white)
                
                VStack(spacing: 16) {
                    // Branded QR code
                    ZStack {
                        if let qrImage = generateBrandedQR() {
                            Image(uiImage: qrImage)
                                .interpolation(.none)
                                .resizable()
                                .aspectRatio(1, contentMode: .fit)
                                // No corner clip — preserve all QR finder patterns
                        }
                        
                        // Glyph logo overlay in center — kept small so
                        // Level-H error correction (30%) can compensate
                        GlyphLogoView(size: 32, glowRadius: 0, glowOpacity: 0)
                            .background(
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(.white)
                                    .frame(width: 40, height: 40)
                            )
                    }
                    .padding(20)
                }
            }
            .frame(height: 320)
            .shadow(color: GlyphTheme.accent.opacity(0.2), radius: 20)
            .scaleEffect(appeared ? 1.0 : 0.85)
            .opacity(appeared ? 1.0 : 0)
            
            // Card footer — identity badge
            VStack(spacing: 8) {
                GlyphLogoView(size: 28, glowRadius: 0, glowOpacity: 0)
                
                Text("Glyph")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(GlyphTheme.accentGradient)
                
                if profile.isLinked {
                    HStack(spacing: 4) {
                        Image(systemName: profile.platform.icon)
                            .font(.system(size: 12))
                        Text("@\(profile.handle)")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                    }
                    .foregroundColor(GlyphTheme.secondaryText)
                }
                
                Text("Scan to join the beta")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(GlyphTheme.secondaryText)
            }
            .padding(.top, 16)
            .opacity(appeared ? 1.0 : 0)
        }
    }
    
    // MARK: - Info
    
    private var infoSection: some View {
        VStack(spacing: 12) {
            InfoRow(icon: "camera.viewfinder", text: "Any camera app → installs Glyph via TestFlight", color: GlyphTheme.accent)
            InfoRow(icon: "sparkles", text: "Scanned in Glyph → special in-app welcome", color: GlyphTheme.violet)
            InfoRow(icon: "person.2", text: "In-person sharing — no links, no texting", color: Color(red: 0.27, green: 0.87, blue: 0.53))
        }
        .padding(.horizontal, 8)
        .opacity(appeared ? 1.0 : 0)
    }
    
    // MARK: - Actions
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Save / Share
            HStack(spacing: 12) {
                Button {
                    saveQRImage()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Save")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: GlyphTheme.buttonHeight)
                    .background(GlyphTheme.surface)
                    .foregroundColor(GlyphTheme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: GlyphTheme.cornerRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: GlyphTheme.cornerRadius)
                            .stroke(GlyphTheme.accent.opacity(0.3), lineWidth: 1)
                    )
                }
                
                Button {
                    shareQRImage()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Share")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: GlyphTheme.buttonHeight)
                    .background(GlyphTheme.accentGradient)
                    .foregroundColor(.black)
                    .clipShape(RoundedRectangle(cornerRadius: GlyphTheme.cornerRadius))
                }
            }
            
            // Print
            Button {
                printQRCard()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "printer.fill")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Print")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                }
                .frame(maxWidth: .infinity)
                .frame(height: GlyphTheme.buttonHeight)
                .background(GlyphTheme.surface)
                .foregroundColor(GlyphTheme.secondaryText)
                .clipShape(RoundedRectangle(cornerRadius: GlyphTheme.cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: GlyphTheme.cornerRadius)
                        .stroke(GlyphTheme.secondaryText.opacity(0.2), lineWidth: 1)
                )
            }
        }
        .opacity(appeared ? 1.0 : 0)
    }
    
    // MARK: - QR Generation
    
    /// Generates a high-contrast, scannable QR code image.
    ///
    /// Uses pure black modules on a white background for maximum
    /// compatibility with every camera / QR reader app. The QR
    /// includes a white quiet zone (margin) as required by the spec.
    private func generateBrandedQR() -> UIImage? {
        let data = Data(Self.testFlightURL.utf8)
        
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        // Level H (30% error correction) — tolerates the small logo overlay
        filter.setValue("H", forKey: "inputCorrectionLevel")
        
        guard let ciImage = filter.outputImage else { return nil }
        
        let extent = ciImage.extent
        guard extent.width > 0, extent.height > 0 else { return nil }
        
        // Scale up using nearest-neighbor (no interpolation) so every
        // QR module stays a crisp pixel-perfect square.
        let targetSize: CGFloat = 1024.0
        let moduleScale = targetSize / extent.size.width
        guard moduleScale.isFinite, moduleScale > 0 else { return nil }
        
        // Centre the QR at the origin before scaling
        let translated = ciImage.transformed(by: CGAffineTransform(translationX: -extent.origin.x, y: -extent.origin.y))
        let scaled = translated.transformed(by: CGAffineTransform(scaleX: moduleScale, y: moduleScale))
        let outputRect = scaled.extent.integral
        
        let ciContext = CIContext(options: [.useSoftwareRenderer: false])
        guard let cgImage = ciContext.createCGImage(scaled, from: outputRect) else { return nil }
        
        // Add a white quiet zone (4-module margin) around the QR
        let quietZone: CGFloat = 4 * moduleScale
        let totalSize = CGSize(
            width: outputRect.width + quietZone * 2,
            height: outputRect.height + quietZone * 2
        )
        
        let renderer = UIGraphicsImageRenderer(size: totalSize)
        let finalImage = renderer.image { ctx in
            let fullRect = CGRect(origin: .zero, size: totalSize)
            
            // White background (quiet zone)
            UIColor.white.setFill()
            ctx.fill(fullRect)
            
            // Draw the QR code centred within the quiet zone.
            // Flip Y because CGImage draws bottom-up.
            ctx.cgContext.saveGState()
            ctx.cgContext.translateBy(x: quietZone, y: totalSize.height - quietZone)
            ctx.cgContext.scaleBy(x: 1, y: -1)
            ctx.cgContext.draw(cgImage, in: CGRect(origin: .zero,
                                                    size: CGSize(width: outputRect.width,
                                                                 height: outputRect.height)))
            ctx.cgContext.restoreGState()
        }
        
        return finalImage
    }
    
    // MARK: - Actions
    
    private func saveQRImage() {
        guard let image = generateBrandedQR() else { return }
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }
    
    private func shareQRImage() {
        guard let image = generateBrandedQR() else { return }
        renderedImage = image
        showShareSheet = true
    }
    
    private func printQRCard() {
        guard let image = generateBrandedQR() else { return }
        let printController = UIPrintInteractionController.shared
        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.outputType = .photo
        printInfo.jobName = "Glyph Invite QR"
        printController.printInfo = printInfo
        printController.printingItem = image
        printController.present(animated: true)
    }
}

// MARK: - Info Row

private struct InfoRow: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 28)
            
            Text(text)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(GlyphTheme.secondaryText)
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(GlyphTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.15), lineWidth: 1)
        )
    }
}

// MARK: - Invite Welcome View

/// Shown when a Glyph user scans another user's Share Card QR code.
/// Recognizes the TestFlight URL and provides a special in-app celebration.
struct InviteWelcomeView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var iconScale: CGFloat = 0.3
    @State private var iconOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var detailsOpacity: Double = 0
    @State private var glowRadius: CGFloat = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var confetti: [ConfettiParticle] = []
    
    var body: some View {
        ZStack {
            GlyphTheme.backgroundGradient
                .ignoresSafeArea()
            
            // Ambient glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            GlyphTheme.accent.opacity(0.25),
                            GlyphTheme.violet.opacity(0.12),
                            .clear
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 200
                    )
                )
                .frame(width: 400, height: 400)
                .scaleEffect(pulseScale)
                .blur(radius: 35)
            
            // Confetti particles
            ForEach(confetti) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .position(particle.position)
                    .opacity(particle.opacity)
            }
            
            VStack(spacing: 28) {
                Spacer()
                
                // Logo with glow
                GlyphLogoView(size: 120, glowRadius: glowRadius, glowOpacity: 0.5)
                    .scaleEffect(iconScale)
                    .opacity(iconOpacity)
                
                // Title
                VStack(spacing: 8) {
                    Text("You're In The Circle")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(GlyphTheme.accentGradient)
                        .shadow(color: GlyphTheme.accent.opacity(0.3), radius: 12)
                    
                    Text("Invited in person · The way it should be")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(GlyphTheme.secondaryText)
                }
                .opacity(textOpacity)
                
                Spacer()
                
                // Details
                VStack(spacing: 16) {
                    DetailBadge(
                        icon: "person.2.fill",
                        title: "Real Connection",
                        subtitle: "Someone showed you this QR in person",
                        color: GlyphTheme.accent
                    )
                    
                    DetailBadge(
                        icon: "eye.slash.fill",
                        title: "Vanishing Messages",
                        subtitle: "Send encrypted messages that self-destruct",
                        color: GlyphTheme.violet
                    )
                    
                    DetailBadge(
                        icon: "wifi.slash",
                        title: "Zero Servers",
                        subtitle: "No cloud, no accounts, no traces",
                        color: Color(red: 0.27, green: 0.87, blue: 0.53)
                    )
                }
                .padding(.horizontal, 32)
                .opacity(detailsOpacity)
                
                Spacer()
                
                // Dismiss
                Button {
                    dismiss()
                } label: {
                    Text("✨ Nice")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .frame(height: GlyphTheme.buttonHeight)
                        .background(GlyphTheme.accentGradient)
                        .foregroundColor(.black)
                        .clipShape(RoundedRectangle(cornerRadius: GlyphTheme.cornerRadius))
                }
                .padding(.horizontal, 32)
                .opacity(detailsOpacity)
                
                Spacer().frame(height: 40)
            }
        }
        .onAppear {
            // Staggered entrance
            withAnimation(.spring(response: 0.7, dampingFraction: 0.65)) {
                iconScale = 1.0
                iconOpacity = 1.0
            }
            
            withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                textOpacity = 1.0
            }
            
            withAnimation(.easeOut(duration: 0.5).delay(0.6)) {
                detailsOpacity = 1.0
            }
            
            withAnimation(.easeInOut(duration: 0.8).delay(0.2)) {
                glowRadius = 30
            }
            
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                pulseScale = 1.15
            }
            
            // Spawn confetti
            spawnConfetti()
        }
    }
    
    private func spawnConfetti() {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        let colors: [Color] = [GlyphTheme.accent, GlyphTheme.violet, Color(red: 0.27, green: 0.87, blue: 0.53), .white, GlyphTheme.warning]
        
        for i in 0..<30 {
            let particle = ConfettiParticle(
                id: i,
                position: CGPoint(
                    x: CGFloat.random(in: 0...screenWidth),
                    y: CGFloat.random(in: -50...(-10))
                ),
                color: colors.randomElement()!,
                size: CGFloat.random(in: 4...10),
                opacity: 1.0
            )
            confetti.append(particle)
            
            // Animate each particle falling
            let delay = Double(i) * 0.05
            withAnimation(.easeIn(duration: Double.random(in: 1.5...3.0)).delay(delay + 0.5)) {
                confetti[i].position.y = screenHeight + 50
                confetti[i].position.x += CGFloat.random(in: -60...60)
                confetti[i].opacity = 0
            }
        }
    }
}

// MARK: - Confetti Particle

private struct ConfettiParticle: Identifiable {
    let id: Int
    var position: CGPoint
    let color: Color
    let size: CGFloat
    var opacity: Double
}

// MARK: - Detail Badge

private struct DetailBadge: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 36)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(GlyphTheme.primaryText)
                Text(subtitle)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundColor(GlyphTheme.secondaryText)
            }
            
            Spacer()
        }
        .padding(14)
        .background(GlyphTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(color.opacity(0.15), lineWidth: 1)
        )
    }
}

#Preview("Share Card") {
    ShareCardView()
        .preferredColorScheme(.dark)
}

#Preview("Invite Welcome") {
    InviteWelcomeView()
        .preferredColorScheme(.dark)
}
