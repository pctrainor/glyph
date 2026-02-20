import SwiftUI

@main
struct GlyphApp: App {
    @State private var showLogoEasterEgg = false
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
    
    var body: some Scene {
        WindowGroup {
            HomeView()
                .preferredColorScheme(.dark)
                .onOpenURL { url in
                    // Logo QR scanned by system camera → opened via Universal Link
                    if GlyphMessage.isLogoQR(url.absoluteString) {
                        showLogoEasterEgg = true
                    }
                }
                .fullScreenCover(isPresented: $showLogoEasterEgg) {
                    LogoEasterEggView()
                }
                .fullScreenCover(isPresented: $showOnboarding) {
                    OnboardingView()
                }
        }
    }
}
