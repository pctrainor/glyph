import SwiftUI

// MARK: - QR Display View

/// Full-screen view showing the generated QR code(s) for the receiver to scan.
/// For single-QR messages, displays a static code.
/// For batched (multi-QR) messages, auto-cycles through frames so the receiver's
/// camera can capture them in sequence.
struct QRDisplayView: View {
    @Environment(\.dismiss) private var dismiss
    
    let qrImages: [UIImage]
    let expiration: ExpirationOption
    let messagePreview: String
    let timeWindow: TimeWindow
    var showActions: Bool = true
    
    @State private var appeared = false
    @State private var currentIndex = 0
    @State private var cycleTimer: Timer?
    @State private var frameDuration: TimeInterval = 0.5
    @State private var showShareSheet = false
    
    private var isBatched: Bool { qrImages.count > 1 }
    
    /// Speed presets: label, interval
    private let speedOptions: [(label: String, interval: TimeInterval)] = [
        ("Turbo", 0.2),
        ("Fast", 0.35),
        ("Normal", 0.5),
        ("Slow", 1.0),
    ]
    
    var body: some View {
        ZStack {
            // Pure black background for max QR contrast
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 32) {
                
                // Header
                HStack {
                    Button {
                        cycleTimer?.invalidate()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    Spacer()
                    
                    // Batch counter + speed control
                    if isBatched {
                        HStack(spacing: 12) {
                            Text("\(currentIndex + 1)/\(qrImages.count)")
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundColor(GlyphTheme.accent)
                            
                            // Speed picker
                            Menu {
                                ForEach(speedOptions, id: \.interval) { option in
                                    Button {
                                        frameDuration = option.interval
                                        restartCycling()
                                    } label: {
                                        HStack {
                                            Text(option.label)
                                            if abs(frameDuration - option.interval) < 0.01 {
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "gauge.with.dots.needle.67percent")
                                        .font(.system(size: 13, weight: .semibold))
                                    Text(currentSpeedLabel)
                                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                                }
                                .foregroundColor(GlyphTheme.accent)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(GlyphTheme.surface)
                                .clipShape(Capsule())
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                Spacer()
                
                // QR Code — made as large as possible so the receiver's
                // camera has maximum pixel density to decode from.
                VStack(spacing: 16) {
                    if let img = qrImages[safe: currentIndex] {
                        Image(uiImage: img)
                            .interpolation(.none)
                            .resizable()
                            .aspectRatio(1, contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .padding(16)
                            .background(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: GlyphTheme.accent.opacity(0.3), radius: 30)
                            .padding(.horizontal, 24)
                            .scaleEffect(appeared ? 1.0 : 0.8)
                            .opacity(appeared ? 1.0 : 0)
                            // Instant swap — no cross-fade animation that would blur
                            // the QR code and make it unreadable to the scanner camera.
                            .transaction { t in t.animation = nil }
                    }
                    
                    // Batch progress bar
                    if isBatched {
                        VStack(spacing: 10) {
                            // Progress dots
                            ProgressView(value: Double(currentIndex + 1), total: Double(qrImages.count))
                                .progressViewStyle(.linear)
                                .tint(GlyphTheme.accent)
                                .frame(width: 200)
                            
                            Text("Hold steady — scanning \(qrImages.count) frames")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(GlyphTheme.secondaryText)
                        }
                        .opacity(appeared ? 1.0 : 0)
                    }
                    
                    // Info below QR
                    VStack(spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: expiration.icon)
                                .font(.system(size: 14))
                            Text("Expires: \(expiration.displayName)")
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                        }
                        .foregroundColor(GlyphTheme.accent)
                        
                        if timeWindow != .none {
                            HStack(spacing: 6) {
                                Image(systemName: timeWindow.icon)
                                    .font(.system(size: 13))
                                Text("QR valid: \(timeWindow.displayName)")
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                            }
                            .foregroundColor(GlyphTheme.violet)
                        }
                        
                        Text(isBatched ? "Hold up to receiver's camera — codes cycle automatically" : "Hold up to receiver's camera")
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundColor(GlyphTheme.secondaryText)
                    }
                    .opacity(appeared ? 1.0 : 0)
                    
                    // MARK: - Print & Share Actions (single QR only)
                    
                    if !isBatched && showActions {
                        HStack(spacing: 12) {
                            // AirPrint
                            Button {
                                printQRCode()
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "printer.fill")
                                        .font(.system(size: 14, weight: .semibold))
                                    Text("Print")
                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                                }
                                .foregroundColor(GlyphTheme.accent)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(GlyphTheme.surface)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(GlyphTheme.accent.opacity(0.3), lineWidth: 1)
                                )
                            }
                            
                            // Share
                            Button {
                                showShareSheet = true
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 14, weight: .semibold))
                                    Text("Share")
                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                                }
                                .foregroundColor(GlyphTheme.accent)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(GlyphTheme.surface)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(GlyphTheme.accent.opacity(0.3), lineWidth: 1)
                                )
                            }
                            
                            // Order Prints (Shopify)
                            Button {
                                openOrderPrints()
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "shippingbox.fill")
                                        .font(.system(size: 14, weight: .semibold))
                                    Text("Order")
                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                                }
                                .foregroundColor(.black)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(GlyphTheme.accentGradient)
                                .clipShape(Capsule())
                            }
                        }
                        .opacity(appeared ? 1.0 : 0)
                        .padding(.top, 8)
                    }
                }
                
                Spacer()
                Spacer()
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                appeared = true
            }
            startCycling()
        }
        .onDisappear {
            cycleTimer?.invalidate()
        }
        .sheet(isPresented: $showShareSheet) {
            if let image = qrImages.first {
                ShareSheet(items: [image])
            }
        }
    }
    
    private func startCycling() {
        guard isBatched else { return }
        cycleTimer = Timer.scheduledTimer(withTimeInterval: frameDuration, repeats: true) { _ in
            // Loop continuously so the receiver can catch any missed frames
            currentIndex = (currentIndex + 1) % qrImages.count
        }
    }
    
    private func restartCycling() {
        cycleTimer?.invalidate()
        startCycling()
    }
    
    private var currentSpeedLabel: String {
        speedOptions.first(where: { abs($0.interval - frameDuration) < 0.01 })?.label ?? "Custom"
    }
    
    // MARK: - Print via AirPrint
    
    private func printQRCode() {
        guard let image = qrImages.first else { return }
        let printController = UIPrintInteractionController.shared
        
        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.jobName = "Glyph QR Code"
        printInfo.outputType = .photo
        printController.printInfo = printInfo
        printController.printingItem = image
        
        printController.present(animated: true)
    }
    
    // MARK: - Order Prints (Shopify)
    
    /// Opens the Glyph Shopify store for ordering physical QR prints.
    /// This is a placeholder URL — replace with your actual Shopify store URL.
    private func openOrderPrints() {
        // TODO: Replace with actual Shopify store URL
        // Could pass QR image data as a query parameter or upload to a staging endpoint
        let shopifyURL = "https://glyphprints.myshopify.com"
        if let url = URL(string: shopifyURL) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Share Sheet (UIActivityViewController)

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Safe Array Subscript

extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

#Preview("Single") {
    QRDisplayView(
        qrImages: [UIImage(systemName: "qrcode")!],
        expiration: .seconds30,
        messagePreview: "Hello world",
        timeWindow: .hour1
    )
}

#Preview("Batched") {
    QRDisplayView(
        qrImages: [
            UIImage(systemName: "qrcode")!,
            UIImage(systemName: "qrcode.viewfinder")!,
            UIImage(systemName: "qrcode")!,
        ],
        expiration: .minute1,
        messagePreview: "Photo message",
        timeWindow: .none
    )
}
