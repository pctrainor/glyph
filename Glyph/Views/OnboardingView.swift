import SwiftUI

// MARK: - Onboarding View

/// First-launch onboarding wizard. Walks the user through what Glyph does,
/// how the encryption works, and the terms of service. Can be replayed
/// from the home screen settings.
struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentPage = 0
    @State private var accepted = false
    
    private let totalPages = 5
    
    var body: some View {
        ZStack {
            GlyphTheme.backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Skip / page indicator
                HStack {
                    if currentPage < totalPages - 1 {
                        Button {
                            withAnimation { currentPage = totalPages - 1 }
                        } label: {
                            Text("Skip")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(GlyphTheme.secondaryText)
                        }
                    } else {
                        Spacer().frame(width: 40)
                    }
                    
                    Spacer()
                    
                    // Page dots
                    HStack(spacing: 6) {
                        ForEach(0..<totalPages, id: \.self) { i in
                            Circle()
                                .fill(i == currentPage ? GlyphTheme.accent : GlyphTheme.secondaryText.opacity(0.3))
                                .frame(width: i == currentPage ? 10 : 6, height: i == currentPage ? 10 : 6)
                                .animation(.spring(response: 0.3), value: currentPage)
                        }
                    }
                    
                    Spacer()
                    
                    Spacer().frame(width: 40)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                // Page content
                TabView(selection: $currentPage) {
                    welcomePage.tag(0)
                    howItWorksPage.tag(1)
                    privacyPage.tag(2)
                    termsPage.tag(3)
                    getStartedPage.tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentPage)
                
                // Bottom button
                bottomButton
                    .padding(.horizontal, 32)
                    .padding(.bottom, 40)
            }
        }
    }
    
    // MARK: - Page 1: Welcome
    
    private var welcomePage: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "qrcode")
                .font(.system(size: 80, weight: .thin))
                .foregroundStyle(GlyphTheme.accentGradient)
                .shadow(color: GlyphTheme.accent.opacity(0.4), radius: 30)
            
            Text("Welcome to Glyph")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(GlyphTheme.primaryText)
            
            Text("Vanishing messages encoded\ninto QR codes.\n\nSay it. Show it. Gone.")
                .font(.system(size: 17, weight: .regular, design: .rounded))
                .foregroundColor(GlyphTheme.secondaryText)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
            
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
    }
    
    // MARK: - Page 2: How It Works
    
    private var howItWorksPage: some View {
        VStack(spacing: 32) {
            Spacer()
            
            Text("How It Works")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(GlyphTheme.primaryText)
            
            VStack(alignment: .leading, spacing: 24) {
                onboardingStep(
                    icon: "square.and.pencil",
                    color: GlyphTheme.accent,
                    title: "Compose",
                    description: "Type your message, add a photo or voice note, set a viewer timer."
                )
                
                onboardingStep(
                    icon: "qrcode",
                    color: GlyphTheme.violet,
                    title: "Generate QR",
                    description: "Your message becomes a QR code. Hold it up or share it."
                )
                
                onboardingStep(
                    icon: "camera.viewfinder",
                    color: GlyphTheme.accent,
                    title: "Scan",
                    description: "The receiver scans it with Glyph. The message appears — then disappears."
                )
                
                onboardingStep(
                    icon: "flame",
                    color: GlyphTheme.danger,
                    title: "Gone",
                    description: "Once the viewer timer expires, the message is gone forever. No screenshots warning."
                )
            }
            .padding(.horizontal, 8)
            
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
    }
    
    // MARK: - Page 3: Privacy & Encryption
    
    private var privacyPage: some View {
        VStack(spacing: 32) {
            Spacer()
            
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 56, weight: .thin))
                .foregroundStyle(GlyphTheme.accentGradient)
            
            Text("Private by Design")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(GlyphTheme.primaryText)
            
            VStack(alignment: .leading, spacing: 20) {
                privacyPoint(
                    icon: "server.rack",
                    text: "No servers. Messages live only in the QR code — never uploaded anywhere."
                )
                
                privacyPoint(
                    icon: "key.fill",
                    text: "AES-256-GCM encryption. Add a PIN for an extra layer only the receiver knows."
                )
                
                privacyPoint(
                    icon: "person.2.slash",
                    text: "No accounts required. Link a social handle optionally to verify your identity."
                )
                
                privacyPoint(
                    icon: "clock.arrow.circlepath",
                    text: "Messages self-destruct after the viewer timer expires. No copies, no cloud."
                )
            }
            .padding(.horizontal, 8)
            
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
    }
    
    // MARK: - Page 4: Terms of Service
    
    private var termsPage: some View {
        VStack(spacing: 16) {
            Text("Terms of Service")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(GlyphTheme.primaryText)
                .padding(.top, 24)
            
            ScrollView {
                Text(termsOfServiceText)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundColor(GlyphTheme.secondaryText)
                    .lineSpacing(4)
                    .padding(.horizontal, 8)
                    .padding(.bottom, 16)
            }
            .background(GlyphTheme.surface.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, 8)
            
            // Accept toggle
            Toggle(isOn: $accepted) {
                Text("I accept the Terms of Service")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(GlyphTheme.primaryText)
            }
            .tint(GlyphTheme.accent)
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - Page 5: Get Started
    
    private var getStartedPage: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(GlyphTheme.accentGradient)
                    .frame(width: 120, height: 120)
                    .shadow(color: GlyphTheme.accent.opacity(0.4), radius: 30)
                
                Image(systemName: "checkmark")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.black)
            }
            
            Text("You're Ready")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(GlyphTheme.primaryText)
            
            Text("Compose your first vanishing message\nand share it with someone nearby.")
                .font(.system(size: 17, weight: .regular, design: .rounded))
                .foregroundColor(GlyphTheme.secondaryText)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
            
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
    }
    
    // MARK: - Bottom Button
    
    private var bottomButton: some View {
        Group {
            if currentPage == totalPages - 1 {
                // Final page — Get Started
                Button {
                    UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
                    dismiss()
                } label: {
                    Text("Get Started")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .frame(height: GlyphTheme.buttonHeight)
                        .background(accepted ? AnyShapeStyle(GlyphTheme.accentGradient) : AnyShapeStyle(GlyphTheme.surface))
                        .foregroundColor(accepted ? .black : GlyphTheme.secondaryText)
                        .clipShape(RoundedRectangle(cornerRadius: GlyphTheme.cornerRadius))
                }
                .disabled(!accepted)
            } else if currentPage == 3 {
                // Terms page — must accept before continuing
                Button {
                    withAnimation { currentPage += 1 }
                } label: {
                    Text("Continue")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .frame(height: GlyphTheme.buttonHeight)
                        .background(accepted ? AnyShapeStyle(GlyphTheme.accentGradient) : AnyShapeStyle(GlyphTheme.surface))
                        .foregroundColor(accepted ? .black : GlyphTheme.secondaryText)
                        .clipShape(RoundedRectangle(cornerRadius: GlyphTheme.cornerRadius))
                }
                .disabled(!accepted)
            } else {
                // Other pages — Next
                Button {
                    withAnimation { currentPage += 1 }
                } label: {
                    Text("Next")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .frame(height: GlyphTheme.buttonHeight)
                        .background(GlyphTheme.accentGradient)
                        .foregroundColor(.black)
                        .clipShape(RoundedRectangle(cornerRadius: GlyphTheme.cornerRadius))
                }
            }
        }
    }
    
    // MARK: - Helper Views
    
    private func onboardingStep(icon: String, color: Color, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 36)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(GlyphTheme.primaryText)
                
                Text(description)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(GlyphTheme.secondaryText)
                    .lineSpacing(2)
            }
        }
    }
    
    private func privacyPoint(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(GlyphTheme.accentGradient)
                .frame(width: 28)
            
            Text(text)
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundColor(GlyphTheme.secondaryText)
                .lineSpacing(2)
        }
    }
    
    // MARK: - Terms of Service
    
    private var termsOfServiceText: String {
        """
        GLYPH TERMS OF SERVICE
        Last Updated: February 19, 2026
        
        These Terms of Service ("Terms") govern your use of the Glyph mobile application ("App") developed and operated by Glyph ("we," "us," or "our"). By downloading, installing, or using the App, you agree to be bound by these Terms.
        
        1. ACCEPTANCE OF TERMS
        
        By using Glyph, you confirm that you are at least 13 years of age and have the legal capacity to enter into these Terms. If you are under 18, you must have parental or guardian consent.
        
        2. DESCRIPTION OF SERVICE
        
        Glyph is a vanishing-message application that encodes messages into QR codes. Messages are designed to be temporary and self-destructing after a user-defined viewer timer expires. The App operates entirely on-device and does not transmit message content to any server.
        
        3. USER RESPONSIBILITIES
        
        You agree to:
        • Use Glyph only for lawful purposes and in compliance with all applicable laws
        • Not use the App to create, distribute, or facilitate the distribution of content that is illegal, harmful, threatening, abusive, harassing, defamatory, obscene, or otherwise objectionable
        • Not attempt to reverse-engineer, decompile, or disassemble the App
        • Not use the App to infringe upon the rights of others
        • Take responsibility for all content you create and share through the App
        
        4. PRIVACY & DATA
        
        Glyph is designed with privacy as a core principle:
        • No accounts are required to use the App
        • Messages are encoded directly into QR codes and are never uploaded to or stored on any external server
        • Encryption uses AES-256-GCM, an industry-standard algorithm
        • Optional social identity linking is stored locally on your device only
        • Friends lists and conversation history are stored locally on your device
        • We do not collect, store, or have access to your messages, contacts, or personal information
        • Crash analytics and basic usage telemetry may be collected through Apple's standard frameworks
        
        5. INTELLECTUAL PROPERTY
        
        The App, including its design, code, graphics, and all associated intellectual property, is owned by Glyph and protected by copyright and other intellectual property laws. You are granted a limited, non-exclusive, non-transferable license to use the App for personal, non-commercial purposes.
        
        6. VANISHING NATURE OF MESSAGES
        
        Glyph messages are designed to vanish. However:
        • We cannot guarantee that a recipient will not capture, record, or otherwise preserve your message through external means (e.g., screenshots, photos of the screen, screen recording)
        • Once a QR code is generated, anyone who scans it before the time window expires can read the message
        • The viewer timer controls how long the message is displayed after scanning — it does not prevent the QR code itself from being scanned multiple times
        • PIN-protected messages add an additional encryption layer but are subject to the same limitations regarding external capture
        
        7. DISCLAIMER OF WARRANTIES
        
        THE APP IS PROVIDED "AS IS" AND "AS AVAILABLE" WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED. WE DO NOT WARRANT THAT THE APP WILL BE UNINTERRUPTED, ERROR-FREE, OR COMPLETELY SECURE. WE MAKE NO GUARANTEES REGARDING THE ABSOLUTE SECURITY OR PRIVACY OF MESSAGES CREATED USING THE APP.
        
        8. LIMITATION OF LIABILITY
        
        TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW, GLYPH AND ITS DEVELOPERS SHALL NOT BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES ARISING OUT OF OR RELATING TO YOUR USE OF THE APP, INCLUDING BUT NOT LIMITED TO LOSS OF DATA, UNAUTHORIZED ACCESS TO YOUR MESSAGES, OR ANY CONDUCT BY THIRD PARTIES.
        
        9. INDEMNIFICATION
        
        You agree to indemnify and hold harmless Glyph and its developers from any claims, damages, losses, or expenses arising from your use of the App, your violation of these Terms, or your violation of any rights of a third party.
        
        10. MODIFICATIONS TO TERMS
        
        We reserve the right to modify these Terms at any time. Changes will be reflected within the App. Your continued use of the App after changes are posted constitutes acceptance of the revised Terms.
        
        11. TERMINATION
        
        We reserve the right to terminate or restrict your access to the App at any time, without notice, for conduct that we believe violates these Terms or is harmful to other users or the App.
        
        12. GOVERNING LAW
        
        These Terms shall be governed by and construed in accordance with the laws of the United States, without regard to conflict of law principles.
        
        13. CONTACT
        
        For questions about these Terms, please contact us at:
        support@glyphmsg.io
        
        By using Glyph, you acknowledge that you have read, understood, and agree to be bound by these Terms of Service.
        """
    }
}

#Preview {
    OnboardingView()
}
