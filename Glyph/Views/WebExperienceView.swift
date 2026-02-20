import SwiftUI
import WebKit

// MARK: - Web Experience View

/// Displays a self-contained web experience received via QR codes.
/// Uses WKWebView in a fully sandboxed, offline-only mode.
/// Styled to feel like a clean native browsing experience (no ugly browser chrome).
struct WebExperienceView: View {
    @Environment(\.dismiss) private var dismiss
    
    let bundle: GlyphWebBundle
    
    @State private var appeared = false
    @State private var loadProgress: Double = 0
    @State private var isLoaded = false
    @State private var pageTitle: String?
    
    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // MARK: - Top Chrome
                topBar
                
                // Check if the time window has expired
                if bundle.isWindowExpired {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "clock.badge.exclamationmark")
                            .font(.system(size: 56))
                            .foregroundStyle(GlyphTheme.accentGradient)
                        Text("Experience Expired")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("This web experience's time window has closed.\nIt can no longer be viewed.")
                            .font(.system(size: 15, design: .rounded))
                            .foregroundColor(GlyphTheme.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .padding(32)
                    Spacer()
                } else {
                    // Loading bar
                    if !isLoaded {
                        GeometryReader { geo in
                            Rectangle()
                                .fill(GlyphTheme.accentGradient)
                                .frame(width: geo.size.width * loadProgress, height: 2)
                                .animation(.easeOut(duration: 0.3), value: loadProgress)
                        }
                        .frame(height: 2)
                    }
                    
                    // MARK: - Web Content
                    SandboxedWebView(
                        html: bundle.html,
                        onProgress: { progress in
                            loadProgress = progress
                        },
                        onLoaded: {
                            withAnimation(.easeOut(duration: 0.3)) {
                                isLoaded = true
                            }
                        },
                        onTitleChange: { title in
                            pageTitle = title
                        }
                    )
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.4), value: appeared)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                appeared = true
            }
        }
        .statusBarHidden(true)
    }
    
    // MARK: - Top Bar
    
    private var topBar: some View {
        HStack(spacing: 12) {
            // Close button
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 26))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            // Title area
            VStack(alignment: .leading, spacing: 2) {
                Text(pageTitle ?? bundle.title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(GlyphTheme.primaryText)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 9, weight: .bold))
                    Text("Offline · Glyph Experience")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                }
                .foregroundColor(GlyphTheme.accent.opacity(0.7))
            }
            
            Spacer()
            
            // Template badge
            if let templateType = bundle.templateType {
                Image(systemName: templateIcon(templateType))
                    .font(.system(size: 20))
                    .foregroundStyle(GlyphTheme.accent)
                    .padding(8)
                    .background(GlyphTheme.surface)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            GlyphTheme.surface
                .overlay(
                    Rectangle()
                        .fill(GlyphTheme.accent.opacity(0.05))
                )
        )
    }
    
    private func templateIcon(_ type: String) -> String {
        switch type {
        case "trivia": return "brain.head.profile"
        case "soundboard": return "music.note.list"
        case "article": return "doc.richtext"
        case "art": return "paintpalette"
        case "adventure": return "map"
        default: return "sparkles"
        }
    }
}

// MARK: - Sandboxed WKWebView

/// A fully sandboxed WKWebView that:
/// - Loads HTML from a string (no network)
/// - Blocks all external navigation
/// - Blocks all network requests
/// - Reports progress and title changes
struct SandboxedWebView: UIViewRepresentable {
    let html: String
    var onProgress: ((Double) -> Void)?
    var onLoaded: (() -> Void)?
    var onTitleChange: ((String?) -> Void)?
    
    func makeCoordinator() -> Coordinator {
        Coordinator(
            onProgress: onProgress,
            onLoaded: onLoaded,
            onTitleChange: onTitleChange
        )
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        
        // Sandboxing: disable everything network-related
        config.websiteDataStore = .nonPersistent() // No cookies, no cache persistence
        config.suppressesIncrementalRendering = false
        
        // Allow inline media playback (for audio/video in templates)
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = [] // Allow autoplay
        
        // Content rules to block ALL network requests
        let blockRule = """
        [{
            "trigger": { "url-filter": ".*" },
            "action": { "type": "block" }
        }]
        """
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        
        // Style: no bounce, smooth scrolling
        webView.scrollView.bounces = true
        webView.scrollView.showsHorizontalScrollIndicator = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        
        // Observe progress
        context.coordinator.webView = webView
        context.coordinator.progressObservation = webView.observe(\.estimatedProgress) { view, _ in
            DispatchQueue.main.async {
                context.coordinator.onProgress?(view.estimatedProgress)
            }
        }
        context.coordinator.titleObservation = webView.observe(\.title) { view, _ in
            DispatchQueue.main.async {
                context.coordinator.onTitleChange?(view.title)
            }
        }
        
        // Add content rules then load
        WKContentRuleListStore.default().compileContentRuleList(
            forIdentifier: "GlyphSandbox",
            encodedContentRuleList: blockRule
        ) { ruleList, error in
            if let ruleList = ruleList {
                config.userContentController.add(ruleList)
            }
            // Load HTML — about:blank as base URL prevents any relative URL resolution
            DispatchQueue.main.async {
                webView.loadHTMLString(html, baseURL: nil)
            }
        }
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // No updates needed — content is static
    }
    
    // MARK: - Coordinator
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var onProgress: ((Double) -> Void)?
        var onLoaded: (() -> Void)?
        var onTitleChange: ((String?) -> Void)?
        
        weak var webView: WKWebView?
        var progressObservation: NSKeyValueObservation?
        var titleObservation: NSKeyValueObservation?
        
        init(onProgress: ((Double) -> Void)?,
             onLoaded: (() -> Void)?,
             onTitleChange: ((String?) -> Void)?) {
            self.onProgress = onProgress
            self.onLoaded = onLoaded
            self.onTitleChange = onTitleChange
        }
        
        // Block ALL navigation except the initial load
        func webView(_ webView: WKWebView,
                     decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if navigationAction.navigationType == .other {
                // Allow initial HTML string load
                decisionHandler(.allow)
            } else {
                // Block link clicks, form submissions, etc.
                decisionHandler(.cancel)
            }
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async { [weak self] in
                self?.onLoaded?()
            }
        }
    }
}

#Preview {
    WebExperienceView(
        bundle: GlyphWebBundle(
            title: "Test Experience",
            html: """
            <!DOCTYPE html>
            <html>
            <head>
                <meta name="viewport" content="width=device-width, initial-scale=1">
                <style>
                    body {
                        background: #0a0a14;
                        color: #e0e0e0;
                        font-family: -apple-system, system-ui, sans-serif;
                        display: flex;
                        flex-direction: column;
                        align-items: center;
                        justify-content: center;
                        min-height: 100vh;
                        margin: 0;
                        padding: 24px;
                    }
                    h1 { font-size: 3em; }
                    p { color: #888; font-size: 1.2em; }
                </style>
            </head>
            <body>
                <h1>✦</h1>
                <h2>It Works!</h2>
                <p>This entire page came from a QR code.</p>
            </body>
            </html>
            """,
            templateType: nil,
            createdAt: Date()
        )
    )
}
