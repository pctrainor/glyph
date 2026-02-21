# Swift iOS App — Production Blueprint

> **Purpose**: Hand this file to any AI coding agent so it can scaffold a polished, production-ready SwiftUI iOS app in minutes. Every pattern below is battle-tested. Replace `{AppName}` with your actual product name throughout.

---

## 1. Project Skeleton (What to Tell Xcode)

### Create via Xcode
1. **File → New → Project → App**
2. Interface: **SwiftUI**, Language: **Swift**, Storage: **None**
3. ✅ Include Tests
4. Product Name: `{AppName}`
5. Organization Identifier: `com.yourcompany` (produces bundle `com.yourcompany.{AppName}`)

### Resulting Xcode Config (project.pbxproj key values)
```
IPHONEOS_DEPLOYMENT_TARGET = 17.0
SWIFT_VERSION = 5.0
TARGETED_DEVICE_FAMILY = 1          // iPhone only
SUPPORTED_PLATFORMS = "iphoneos iphonesimulator"
SUPPORTS_MACCATALYST = NO
INFOPLIST_KEY_UIRequiresFullScreen = YES
INFOPLIST_KEY_UISupportedInterfaceOrientations = UIInterfaceOrientationPortrait
CODE_SIGN_STYLE = Automatic
GENERATE_INFOPLIST_FILE = YES
```

### No SPM / No CocoaPods
Zero external dependencies. Apple's first-party frameworks cover everything:
- `SwiftUI` — all UI
- `CryptoKit` — AES-256-GCM, SHA-256, HKDF
- `AVFoundation` — camera, audio recording
- `CoreImage` — QR code generation (`CIQRCodeGenerator`)
- `Vision` / `VNDetectBarcodesRequest` — QR code reading from photos
- `NaturalLanguage` — on-device NLP
- `WebKit` — sandboxed WKWebView for HTML content
- `Compression` — zlib/gzip for payload compression
- `Photos` — save to photo library
- `UIKit` — haptics (`UIImpactFeedbackGenerator`), `UIImage`, share sheets

---

## 2. Folder Structure

```
{AppName}/
├── {AppName}App.swift              // @main entry point (< 30 lines)
├── Info.plist                      // Permissions, orientation, encryption flag
├── PrivacyInfo.xcprivacy           // App Store privacy manifest
├── Assets.xcassets/
│   ├── Contents.json
│   ├── AccentColor.colorset/
│   │   └── Contents.json           // Your accent color
│   └── AppIcon.appiconset/
│       ├── Contents.json           // Single 1024×1024 universal icon
│       └── AppIcon.png
├── Audio/                          // Bundle audio assets (.m4a)
│   ├── chime.m4a
│   └── ...
├── Theme/
│   └── {AppName}Theme.swift        // ALL design tokens — single source of truth
├── Models/
│   ├── {Feature}Model.swift        // Data structs (Codable, Identifiable, Equatable)
│   ├── {Feature}Store.swift        // ObservableObject persistence singletons
│   └── ...
└── Views/
    ├── HomeView.swift              // Main landing / navigation hub
    ├── OnboardingView.swift        // First-launch wizard
    ├── {Feature}View.swift         // One file per screen
    └── ...
{AppName}Tests/
    └── {AppName}Tests.swift
```

**Rules**:
- One file per struct/class. Name matches the type: `MessageView.swift` → `struct MessageView: View`.
- Models hold data + encode/decode. Stores hold persistence + business logic. Views hold UI only.
- No `ViewModel` suffix pattern needed — `@State` and `@ObservedObject` on stores is sufficient for most apps.

---

## 3. App Entry Point

```swift
// {AppName}App.swift
import SwiftUI

@main
struct {AppName}App: App {
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "hasSeenOnboarding")

    var body: some Scene {
        WindowGroup {
            HomeView()
                .preferredColorScheme(.dark)      // Force dark mode globally
                .fullScreenCover(isPresented: $showOnboarding) {
                    OnboardingView()
                }
        }
    }
}
```

**Key decisions**:
- `.preferredColorScheme(.dark)` — one color scheme = one set of design tokens = no ambiguity.
- `fullScreenCover` for onboarding, not `sheet` — prevents swipe dismiss.
- URL handling: add `.onOpenURL { url in ... }` here for deep links / universal links.

---

## 4. Theme System (Single Source of Truth)

```swift
// Theme/{AppName}Theme.swift
import SwiftUI

enum {AppName}Theme {

    // MARK: - Colors
    static let background    = Color(red: 0.04, green: 0.04, blue: 0.08)   // #0a0a14
    static let surface       = Color(red: 0.08, green: 0.08, blue: 0.14)   // Cards/sheets
    static let accent        = Color(red: 0.4,  green: 0.85, blue: 1.0)    // Primary action
    static let violet        = Color(red: 0.6,  green: 0.4,  blue: 1.0)    // Secondary accent
    static let warning       = Color(red: 1.0,  green: 0.7,  blue: 0.2)    // Caution states
    static let danger        = Color(red: 1.0,  green: 0.3,  blue: 0.3)    // Destructive
    static let primaryText   = Color.white
    static let secondaryText = Color(white: 0.5)

    // MARK: - Gradients
    static let backgroundGradient = LinearGradient(
        colors: [background, Color(red: 0.06, green: 0.04, blue: 0.12)],
        startPoint: .top, endPoint: .bottom
    )
    static let accentGradient = LinearGradient(
        colors: [accent, violet],
        startPoint: .leading, endPoint: .trailing
    )

    // MARK: - Sizes
    static let cornerRadius: CGFloat = 16
    static let buttonHeight: CGFloat = 56
}
```

**Usage everywhere**:
```swift
GlyphTheme.backgroundGradient.ignoresSafeArea()   // Screen background
.foregroundStyle(GlyphTheme.accentGradient)         // Gradient text/icons
.fill(GlyphTheme.accent)                            // Solid accent
```

**Why an `enum`**: Can't be instantiated. Pure namespace for static constants. Cleaner than a struct.

---

## 5. Model Pattern

Every data model follows the same template:

```swift
import Foundation

struct {Item}: Codable, Identifiable, Equatable {
    let id: String
    let title: String
    let createdAt: Date
    // ... domain fields

    init(title: String) {
        self.id = String(UUID().uuidString.prefix(8))   // Short readable IDs
        self.title = title
        self.createdAt = Date()
    }

    // MARK: - Computed helpers
    var isExpired: Bool { /* ... */ }

    // MARK: - Equatable (by ID only for performance)
    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
}
```

**Conventions**:
- Always `Codable` — ready for JSON persistence or wire transfer.
- Always `Identifiable` — required for `ForEach`, `List`.
- Always `Equatable` — enables SwiftUI diff optimization.
- Short IDs via `UUID().uuidString.prefix(8)` — human-readable, low collision for local use.
- No optionals unless truly nullable. Use sensible defaults.

---

## 6. Store Pattern (Singleton + ObservableObject)

```swift
import Foundation

final class {Feature}Store: ObservableObject {
    static let shared = {Feature}Store()

    @Published var items: [Item] = []

    private let fileURL: URL

    private init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("{AppName}Data", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.fileURL = dir.appendingPathComponent("items.json")
        load()
    }

    // MARK: - CRUD

    func add(_ item: Item) {
        items.insert(item, at: 0)       // Newest first
        save()
    }

    func delete(_ item: Item) {
        items.removeAll { $0.id == item.id }
        save()
    }

    // MARK: - Persistence (JSON file)

    private func save() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([Item].self, from: data)
        else { return }
        items = decoded
    }
}
```

**Why this pattern**:
- `static let shared` — singleton, accessible from any view via `@ObservedObject var store = {Feature}Store.shared`.
- Documents directory — persists across app launches, included in device backups.
- `.atomic` writes — no partial file corruption on crash.
- No CoreData, no Realm, no SQLite. Plain JSON files are sufficient for most apps and trivially debuggable.

### For small/simple data, use UserDefaults:
```swift
@Published var setting: Bool {
    didSet { UserDefaults.standard.set(setting, forKey: "settingKey") }
}
// In init: setting = UserDefaults.standard.bool(forKey: "settingKey")
```

---

## 7. View Patterns

### Screen Template
```swift
import SwiftUI

struct {Feature}View: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: {Feature}Store = .shared
    @State private var appeared = false

    var body: some View {
        ZStack {
            {AppName}Theme.backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Content here
            }
        }
        .navigationTitle("{Title}")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                appeared = true
            }
        }
    }
}
```

### Navigation Pattern (Hub-and-Spoke)
HomeView uses `NavigationStack` with `NavigationLink` or `.sheet`/`.fullScreenCover`:

```swift
struct HomeView: View {
    @State private var showFeatureA = false
    @State private var showFeatureB = false

    var body: some View {
        NavigationStack {
            ZStack {
                {AppName}Theme.backgroundGradient.ignoresSafeArea()

                VStack(spacing: 16) {
                    // Action buttons
                    actionButton("Feature A", icon: "star.fill") { showFeatureA = true }
                    actionButton("Feature B", icon: "bolt.fill") { showFeatureB = true }
                }
            }
            .navigationDestination(isPresented: $showFeatureA) { FeatureAView() }
            .sheet(isPresented: $showFeatureB) { FeatureBView() }
        }
    }

    private func actionButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle({AppName}Theme.accentGradient)
                Text(title)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor({AppName}Theme.primaryText)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor({AppName}Theme.secondaryText)
            }
            .padding(.horizontal, 20)
            .frame(height: {AppName}Theme.buttonHeight)
            .background({AppName}Theme.surface)
            .cornerRadius({AppName}Theme.cornerRadius)
        }
        .padding(.horizontal, 20)
    }
}
```

### Animation Conventions
- Appear: `.spring(response: 0.5, dampingFraction: 0.8)`
- State transitions: `.easeInOut(duration: 0.3)`
- Micro-interactions: `.easeOut(duration: 0.2)`
- Always use `withAnimation { }` blocks, not implicit `.animation()` modifiers (avoids unintended animations).

### Haptics
```swift
private let haptic = UIImpactFeedbackGenerator(style: .medium)
// In action: haptic.impactOccurred()

private let notifHaptic = UINotificationFeedbackGenerator()
// Success: notifHaptic.notificationOccurred(.success)
// Error:   notifHaptic.notificationOccurred(.error)
```

---

## 8. Info.plist — Permissions & Config

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>{AppName}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSRequiresIPhoneOS</key>
    <true/>

    <!-- PERMISSIONS — add only what you need -->
    <key>NSCameraUsageDescription</key>
    <string>{AppName} needs camera access to [your reason].</string>
    <key>NSPhotoLibraryUsageDescription</key>
    <string>{AppName} needs photo library access to [your reason].</string>
    <key>NSPhotoLibraryAddUsageDescription</key>
    <string>{AppName} needs permission to save images to your photo library.</string>
    <key>NSMicrophoneUsageDescription</key>
    <string>{AppName} needs microphone access to [your reason].</string>

    <!-- App Store encryption compliance -->
    <key>ITSAppUsesNonExemptEncryption</key>
    <false/>

    <!-- UI Config -->
    <key>UIApplicationSceneManifest</key>
    <dict>
        <key>UIApplicationSupportsMultipleScenes</key>
        <false/>
    </dict>
    <key>UILaunchScreen</key>
    <dict/>
    <key>UIRequiredDeviceCapabilities</key>
    <array>
        <string>arm64</string>
    </array>
    <key>UISupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
    </array>
    <key>UIStatusBarStyle</key>
    <string>UIStatusBarStyleLightContent</string>
    <key>UIRequiresFullScreen</key>
    <true/>
</dict>
</plist>
```

---

## 9. PrivacyInfo.xcprivacy (Required for App Store)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>NSPrivacyTracking</key>
    <false/>
    <key>NSPrivacyTrackingDomains</key>
    <array/>
    <key>NSPrivacyCollectedDataTypes</key>
    <array/>
    <key>NSPrivacyAccessedAPITypes</key>
    <array>
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategoryFileTimestamp</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array>
                <string>C617.1</string>
            </array>
        </dict>
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategoryDiskSpace</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array>
                <string>E174.1</string>
            </array>
        </dict>
    </array>
</dict>
</plist>
```

---

## 10. Assets.xcassets Structure

```
Assets.xcassets/
├── Contents.json                    ← { "info": { "author": "xcode", "version": 1 } }
├── AccentColor.colorset/
│   └── Contents.json                ← sRGB color matching your theme accent
└── AppIcon.appiconset/
    ├── Contents.json                ← Single 1024×1024 universal entry
    └── AppIcon.png                  ← 1024×1024 PNG, no transparency
```

**AppIcon.appiconset/Contents.json**:
```json
{
  "images": [
    {
      "filename": "AppIcon.png",
      "idiom": "universal",
      "platform": "ios",
      "size": "1024x1024"
    }
  ],
  "info": { "author": "xcode", "version": 1 }
}
```

**AccentColor.colorset/Contents.json** (match your theme):
```json
{
  "colors": [
    {
      "color": {
        "color-space": "srgb",
        "components": {
          "alpha": "1.000",
          "blue": "1.000",
          "green": "0.800",
          "red": "0.400"
        }
      },
      "idiom": "universal"
    }
  ],
  "info": { "author": "xcode", "version": 1 }
}
```

---

## 11. Onboarding Pattern

```swift
struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0
    private let totalPages = 4

    var body: some View {
        ZStack {
            {AppName}Theme.backgroundGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                // Skip button + page dots
                HStack {
                    if currentPage < totalPages - 1 {
                        Button("Skip") {
                            withAnimation { currentPage = totalPages - 1 }
                        }
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor({AppName}Theme.secondaryText)
                    }
                    Spacer()
                    HStack(spacing: 6) {
                        ForEach(0..<totalPages, id: \.self) { i in
                            Circle()
                                .fill(i == currentPage ? {AppName}Theme.accent : {AppName}Theme.secondaryText.opacity(0.3))
                                .frame(width: i == currentPage ? 10 : 6, height: i == currentPage ? 10 : 6)
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 24).padding(.top, 16)

                TabView(selection: $currentPage) {
                    page1.tag(0)
                    page2.tag(1)
                    page3.tag(2)
                    getStartedPage.tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Bottom CTA
                Button {
                    if currentPage < totalPages - 1 {
                        withAnimation { currentPage += 1 }
                    } else {
                        UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
                        dismiss()
                    }
                } label: {
                    Text(currentPage < totalPages - 1 ? "Next" : "Get Started")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: {AppName}Theme.buttonHeight)
                        .background({AppName}Theme.accentGradient)
                        .cornerRadius({AppName}Theme.cornerRadius)
                }
                .padding(.horizontal, 32).padding(.bottom, 40)
            }
        }
    }
}
```

---

## 12. Common Capabilities — Copy-Paste Recipes

### 12a. Camera (AVFoundation)
```swift
import AVFoundation

class CameraModel: NSObject, ObservableObject, AVCaptureMetadataOutputObjectsDelegate {
    let session = AVCaptureSession()
    @Published var isRunning = false

    func start() {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device)
        else { return }

        session.beginConfiguration()
        if session.canAddInput(input) { session.addInput(input) }

        let output = AVCaptureMetadataOutput()
        if session.canAddOutput(output) {
            session.addOutput(output)
            output.setMetadataObjectsDelegate(self, queue: .main)
            output.metadataObjectTypes = [.qr]      // or other types
        }
        session.commitConfiguration()

        DispatchQueue.global(qos: .userInitiated).async {
            self.session.startRunning()
            DispatchQueue.main.async { self.isRunning = true }
        }
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput results: [AVMetadataObject],
                        from connection: AVCaptureConnection) {
        guard let obj = results.first as? AVMetadataMachineReadableCodeObject,
              let value = obj.stringValue
        else { return }
        // Handle scanned value
    }

    // IMPORTANT: Disable torch/flash
    func disableTorch() {
        guard let device = AVCaptureDevice.default(for: .video),
              device.hasTorch else { return }
        try? device.lockForConfiguration()
        device.torchMode = .off
        device.unlockForConfiguration()
    }
}
```

### 12b. Audio Recording
```swift
import AVFoundation

class VoiceRecorder: NSObject, ObservableObject, AVAudioRecorderDelegate {
    @Published var isRecording = false
    private var recorder: AVAudioRecorder?
    private var fileURL: URL?

    func startRecording() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playAndRecord, mode: .default)
        try? session.setActive(true)

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".m4a")
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 22050,
            AVNumberOfChannelsKey: 1,
            AVEncoderBitRateKey: 24000,
            AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue
        ]
        recorder = try? AVAudioRecorder(url: url, settings: settings)
        recorder?.delegate = self
        recorder?.record()
        fileURL = url
        isRecording = true
    }

    func stopRecording() -> Data? {
        recorder?.stop()
        isRecording = false
        guard let url = fileURL else { return nil }
        return try? Data(contentsOf: url)
    }
}
```

### 12c. QR Code Generation
```swift
import CoreImage
import UIKit

func generateQRCode(from string: String) -> UIImage? {
    guard let data = string.data(using: .utf8),
          let filter = CIFilter(name: "CIQRCodeGenerator")
    else { return nil }

    filter.setValue(data, forKey: "inputMessage")
    filter.setValue("M", forKey: "inputCorrectionLevel")   // L, M, Q, H

    guard let ciImage = filter.outputImage else { return nil }
    let scale = CGAffineTransform(scaleX: 10, y: 10)       // Scale up from tiny
    let scaledImage = ciImage.transformed(by: scale)

    let context = CIContext()
    guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent)
    else { return nil }

    return UIImage(cgImage: cgImage)
}
```

### 12d. Encryption (AES-256-GCM)
```swift
import CryptoKit
import Foundation

enum Crypto {
    static func encrypt(_ data: Data, key: SymmetricKey) -> Data? {
        guard let sealed = try? AES.GCM.seal(data, using: key) else { return nil }
        return sealed.combined      // nonce + ciphertext + tag
    }

    static func decrypt(_ combined: Data, key: SymmetricKey) -> Data? {
        guard let box = try? AES.GCM.SealedBox(combined: combined),
              let data = try? AES.GCM.open(box, using: key)
        else { return nil }
        return data
    }

    /// Derive a key from a user-entered PIN
    static func keyFromPIN(_ pin: String, salt: Data) -> SymmetricKey {
        let pinData = Data(pin.utf8)
        let derived = HKDF<SHA256>.deriveKey(
            inputKeyMaterial: SymmetricKey(data: pinData),
            salt: salt,
            info: Data("YourApp-PIN".utf8),
            outputByteCount: 32
        )
        return derived
    }
}
```

### 12e. Sandboxed WKWebView
```swift
import WebKit
import SwiftUI

struct SandboxedWebView: UIViewRepresentable {
    let html: String

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true

        // Sandbox: no network, no navigation
        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = true
        config.defaultWebpagePreferences = prefs

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        webView.loadHTMLString(html, baseURL: nil)
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    class Coordinator: NSObject, WKNavigationDelegate {
        // Block all external navigation
        func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if action.navigationType == .other { decisionHandler(.allow) }
            else { decisionHandler(.cancel) }
        }
    }
}
```

### 12f. Data Compression (zlib)
```swift
import Foundation
import Compression

extension Data {
    func deflated() -> Data? {
        let bufferSize = count + 512
        var buffer = [UInt8](repeating: 0, count: bufferSize)
        let compressedSize = compression_encode_buffer(
            &buffer, bufferSize,
            [UInt8](self), count,
            nil, COMPRESSION_ZLIB
        )
        guard compressedSize > 0 else { return nil }
        return Data(buffer.prefix(compressedSize))
    }

    func inflated() -> Data? {
        let bufferSize = count * 8
        var buffer = [UInt8](repeating: 0, count: bufferSize)
        let decompressedSize = compression_decode_buffer(
            &buffer, bufferSize,
            [UInt8](self), count,
            nil, COMPRESSION_ZLIB
        )
        guard decompressedSize > 0 else { return nil }
        return Data(buffer.prefix(decompressedSize))
    }
}
```

### 12g. Protocol-Based Pluggable Architecture
For features that might have multiple implementations (e.g., AI, auth, networking):

```swift
protocol {Feature}Provider {
    var name: String { get }
    func process(_ input: String) async throws -> String
}

enum {Feature}Tier: String, CaseIterable {
    case basic, enhanced, advanced
}

class {Feature}Manager: ObservableObject {
    @Published var currentTier: {Feature}Tier = .basic

    private var providers: [{Feature}Tier: {Feature}Provider] = [:]

    func register(_ provider: {Feature}Provider, for tier: {Feature}Tier) {
        providers[tier] = provider
    }

    func process(_ input: String) async throws -> String {
        guard let provider = providers[currentTier] else {
            throw {Feature}Error.noProvider
        }
        return try await provider.process(input)
    }
}
```

---

## 13. Wire Format / Serialization Pattern

For encoding structured data into compact strings (e.g., QR codes, deep links):

```
PREFIX: + base64(json)              // Simple
PREFIX: + base64(gzip(json))        // Compressed
PREFIX: + base64(encrypt(json))     // Encrypted
PREFIX: + base64(encrypt(gzip(json)))  // Both
```

**Magic prefix convention**:
- Use 3-5 char uppercase prefix + colon → `MSG:`, `DATA:`, `RESP:`
- Lets the receiver detect type by prefix before decoding.
- For encrypted variants, append `E` → `MSGE:` (embedded key), `MSGP:` (PIN-protected).

**Chunking for large payloads**:
```swift
struct Chunk: Codable {
    let sessionId: String   // Groups chunks together
    let index: Int          // 0-based position
    let total: Int          // Total chunk count
    let data: String        // Base64 slice
}
// Prefix: CHUNK: + base64(json(Chunk))
```

---

## 14. project.pbxproj — Understanding the Structure

The Xcode project file has a deterministic structure. When an agent needs to add a new `.swift` file:

### Sections to modify (in order):
1. **PBXBuildFile** — add: `A2XXXXXX /* NewFile.swift in Sources */ = {isa = PBXBuildFile; fileRef = B2XXXXXX;};`
2. **PBXFileReference** — add: `B2XXXXXX /* NewFile.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = NewFile.swift; sourceTree = "<group>";};`
3. **PBXGroup** — add `B2XXXXXX /* NewFile.swift */` to the appropriate group's `children` array (Models, Views, or Theme).
4. **PBXSourcesBuildPhase** — add `A2XXXXXX /* NewFile.swift in Sources */` to the `files` array.

### ID Convention (keeps diffs clean):
- Use sequential hex IDs: `B2000055`, `A2000055`, etc.
- Build file IDs start with `A2`, file refs with `B2`, groups with `D2`.
- For resource files (audio, images): add to `PBXResourcesBuildPhase` instead of `PBXSourcesBuildPhase`.

### For resource files (.m4a, .json, etc.):
- `lastKnownFileType`: `audio.m4a`, `text.json`, `image.png`
- Add to **PBXResourcesBuildPhase** `files` array (not Sources).

---

## 15. Xcode Scheme (xcscheme)

The shared scheme lives at:
```
{AppName}.xcodeproj/xcshareddata/xcschemes/{AppName}.xcscheme
```

Standard scheme XML — usually untouched after Xcode generates it:
- BuildAction: parallelized, all build-for flags enabled
- TestAction: Debug config, LLDB debugger, auto-create test plan
- LaunchAction: Debug config, LLDB
- ProfileAction: Release config
- ArchiveAction: Release config

---

## 16. Testing Setup

```swift
// {AppName}Tests/{AppName}Tests.swift
import XCTest
@testable import {AppName}

final class {AppName}Tests: XCTestCase {
    func testModelEncoding() throws {
        let item = Item(title: "Test")
        let data = try JSONEncoder().encode(item)
        let decoded = try JSONDecoder().decode(Item.self, from: data)
        XCTAssertEqual(item.id, decoded.id)
    }

    func testStoreAddDelete() {
        let store = {Feature}Store.shared
        let count = store.items.count
        let item = Item(title: "Test")
        store.add(item)
        XCTAssertEqual(store.items.count, count + 1)
        store.delete(item)
        XCTAssertEqual(store.items.count, count)
    }
}
```

Test target config in pbxproj:
```
BUNDLE_LOADER = "$(TEST_HOST)"
TEST_HOST = "$(BUILT_PRODUCTS_DIR)/{AppName}.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/{AppName}"
PRODUCT_BUNDLE_IDENTIFIER = com.yourcompany.{AppName}.tests
```

---

## 17. Build & Run Checklist

Before first build:
- [ ] `DEVELOPMENT_TEAM` set in pbxproj (or Xcode → Signing & Capabilities → Team)
- [ ] `PRODUCT_BUNDLE_IDENTIFIER` is unique
- [ ] `Info.plist` permissions match your actual framework usage
- [ ] `PrivacyInfo.xcprivacy` present (App Store requirement)
- [ ] `AppIcon.png` is exactly 1024×1024, no transparency, no rounded corners (iOS rounds them)
- [ ] Scheme is shared (xcshareddata/xcschemes/)

---

## 18. File Naming & Code Style Cheat Sheet

| Convention | Example |
|---|---|
| Views end in `View` | `HomeView.swift`, `ScannerView.swift` |
| Stores end in `Store` | `FriendStore.swift`, `LibraryStore.swift` |
| Models are nouns | `Message.swift`, `Profile.swift` |
| Theme is an enum | `{AppName}Theme.swift` |
| One type per file | `MessageView.swift` → `struct MessageView: View` |
| MARK comments | `// MARK: - Section Name` |
| Doc comments on structs | `/// Brief description of what this does.` |
| Private by default | Use `private` unless something needs external access |
| Font system | `.system(size: N, weight: .W, design: .rounded)` |
| Spacing | `.padding(.horizontal, 20)` for screen edges, `spacing: 12-16` for stacks |

---

## 19. Agent Scaffolding Prompt Template

When starting a new app, tell the agent:

> Create a SwiftUI iOS app called `{AppName}` following the blueprint in `SWIFT_APP_BLUEPRINT.md`.
> The app should: [describe what it does in 2-3 sentences].
> Core features: [list 3-5 features].
> The entry point is `{AppName}App.swift`, theme lives in `Theme/{AppName}Theme.swift`,
> models in `Models/`, views in `Views/`. Use the singleton store pattern for persistence.
> Dark mode only. No external dependencies. iPhone only, portrait only.
> Generate complete, production-ready code — not stubs.

---

## 20. Summary of Architectural Decisions

| Decision | Choice | Why |
|---|---|---|
| UI Framework | SwiftUI | Declarative, fast iteration, no storyboards |
| Color Scheme | Dark only | One set of tokens, modern aesthetic |
| Navigation | NavigationStack + sheets/covers | Simple hub-and-spoke, no deep nesting |
| Persistence | JSON files in Documents + UserDefaults | Simple, debuggable, no CoreData overhead |
| State Management | @State + ObservableObject singletons | No Combine pipelines, no third-party state libs |
| Dependencies | Zero external | No SPM/CocoaPods — ships tomorrow, never breaks |
| Encryption | CryptoKit AES-256-GCM | Apple-native, FIPS-validated, 3 lines of code |
| IDs | UUID prefix(8) | Human-readable, sufficient for local uniqueness |
| Testing | XCTest on models/stores | Test data layer, visually verify UI |
| Privacy | PrivacyInfo.xcprivacy | Required for App Store since Spring 2024 |
| Orientation | Portrait locked | Simpler layouts, consistent UX |
| Device | iPhone only | Focused experience, no iPad adaptation needed |
