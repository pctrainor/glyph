import SwiftUI

// MARK: - Home View

/// The main landing screen — two big actions: Compose or Scan.
struct HomeView: View {
    @State private var showCompose = false
    @State private var showScanner = false
    @State private var showWebCompose = false
    @State private var showLibrary = false
    @State private var showFriends = false
    @State private var showSocialLink = false
    @State private var showOnboarding = false
    @State private var glowPhase: CGFloat = 0
    @AppStorage("flashOnScanEnabled") private var flashOnScanEnabled = true
    @ObservedObject private var socialProfile = SocialProfile.shared
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                GlyphTheme.backgroundGradient
                    .ignoresSafeArea()
                
                VStack(spacing: 40) {
                    Spacer()
                    
                    // Logo area
                    VStack(spacing: 12) {
                        // Glyph icon
                        Image(systemName: "qrcode")
                            .font(.system(size: 64, weight: .thin))
                            .foregroundStyle(GlyphTheme.accentGradient)
                            .shadow(color: GlyphTheme.accent.opacity(0.4), radius: 20)
                        
                        Text("Glyph")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundColor(GlyphTheme.primaryText)
                        
                        Text("Say it. Show it. Gone.")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(GlyphTheme.secondaryText)
                        
                        // Social identity badge (if linked)
                        if socialProfile.isLinked {
                            Button {
                                showSocialLink = true
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: socialProfile.platform.icon)
                                        .font(.system(size: 13))
                                    Text("@\(socialProfile.handle)")
                                        .font(.system(size: 13, weight: .medium, design: .rounded))
                                }
                                .foregroundStyle(GlyphTheme.accentGradient)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .background(GlyphTheme.surface)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(GlyphTheme.violet.opacity(0.2), lineWidth: 1)
                                )
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Action buttons
                    VStack(spacing: 16) {
                        // Compose button
                        Button {
                            showCompose = true
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "square.and.pencil")
                                    .font(.system(size: 20, weight: .semibold))
                                Text("Compose")
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: GlyphTheme.buttonHeight)
                            .background(GlyphTheme.accentGradient)
                            .foregroundColor(.black)
                            .clipShape(RoundedRectangle(cornerRadius: GlyphTheme.cornerRadius))
                        }
                        
                        // Scan button
                        Button {
                            showScanner = true
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "camera.viewfinder")
                                    .font(.system(size: 20, weight: .semibold))
                                Text("Scan")
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
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
                        
                        // Bottom row: Create + Friends + Library
                        HStack(spacing: 12) {
                            Button {
                                showWebCompose = true
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "sparkles.rectangle.stack")
                                        .font(.system(size: 14, weight: .semibold))
                                    Text("Create")
                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: GlyphTheme.buttonHeight)
                                .background(GlyphTheme.surface)
                                .foregroundColor(GlyphTheme.violet)
                                .clipShape(RoundedRectangle(cornerRadius: GlyphTheme.cornerRadius))
                                .overlay(
                                    RoundedRectangle(cornerRadius: GlyphTheme.cornerRadius)
                                        .stroke(GlyphTheme.violet.opacity(0.3), lineWidth: 1)
                                )
                            }
                            
                            Button {
                                showFriends = true
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "person.2")
                                        .font(.system(size: 14, weight: .semibold))
                                    Text("Friends")
                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: GlyphTheme.buttonHeight)
                                .background(GlyphTheme.surface)
                                .foregroundColor(GlyphTheme.accent)
                                .clipShape(RoundedRectangle(cornerRadius: GlyphTheme.cornerRadius))
                                .overlay(
                                    RoundedRectangle(cornerRadius: GlyphTheme.cornerRadius)
                                        .stroke(GlyphTheme.accent.opacity(0.2), lineWidth: 1)
                                )
                            }
                            
                            Button {
                                showLibrary = true
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "archivebox")
                                        .font(.system(size: 14, weight: .semibold))
                                    Text("Library")
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
                    }
                    .padding(.horizontal, 32)
                    
                    // Bottom links
                    HStack(spacing: 20) {
                        if !socialProfile.isLinked {
                            Button {
                                showSocialLink = true
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "person.crop.circle.badge.plus")
                                        .font(.system(size: 14))
                                    Text("Link Social")
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                }
                                .foregroundColor(GlyphTheme.secondaryText)
                            }
                        }
                        
                        Button {
                            showOnboarding = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "info.circle")
                                    .font(.system(size: 14))
                                Text("About")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                            }
                            .foregroundColor(GlyphTheme.secondaryText)
                        }
                        
                        Button {
                            flashOnScanEnabled.toggle()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: flashOnScanEnabled ? "bolt.fill" : "bolt.slash.fill")
                                    .font(.system(size: 14))
                                Text(flashOnScanEnabled ? "Flash On" : "Flash Off")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                            }
                            .foregroundColor(GlyphTheme.secondaryText)
                        }
                    }
                    
                    Spacer()
                        .frame(height: 40)
                }
            }
            .navigationDestination(isPresented: $showCompose) {
                ComposeView()
            }
            .navigationDestination(isPresented: $showWebCompose) {
                WebComposeView()
            }
            .navigationDestination(isPresented: $showLibrary) {
                LibraryView()
            }
            .navigationDestination(isPresented: $showFriends) {
                FriendsView()
            }
            .fullScreenCover(isPresented: $showScanner) {
                ScannerView()
            }
            .sheet(isPresented: $showSocialLink) {
                SocialLinkSheet()
            }
            .fullScreenCover(isPresented: $showOnboarding) {
                OnboardingView()
            }
        }
    }
}

// MARK: - Social Link Sheet

/// Sheet for linking / editing the user's social handle.
struct SocialLinkSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var profile = SocialProfile.shared
    
    @State private var selectedPlatform: SocialPlatform = .instagram
    @State private var handleText = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                GlyphTheme.backgroundGradient
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "person.crop.circle.badge.checkmark")
                            .font(.system(size: 48, weight: .thin))
                            .foregroundStyle(GlyphTheme.accentGradient)
                        
                        Text("Link Your Social")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(GlyphTheme.primaryText)
                        
                        Text("Your handle gets embedded in your QR codes\nso receivers can verify it's really you")
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundColor(GlyphTheme.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 8)
                    
                    // Platform picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Platform")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(GlyphTheme.secondaryText)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(SocialPlatform.allCases) { platform in
                                    Button {
                                        selectedPlatform = platform
                                    } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: platform.icon)
                                                .font(.system(size: 14))
                                            Text(platform.displayName)
                                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                        }
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 10)
                                        .background(selectedPlatform == platform ? AnyShapeStyle(GlyphTheme.accentGradient) : AnyShapeStyle(GlyphTheme.surface))
                                        .foregroundColor(selectedPlatform == platform ? .black : GlyphTheme.secondaryText)
                                        .clipShape(Capsule())
                                    }
                                }
                            }
                            .padding(.horizontal, 4)
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Handle input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Handle")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(GlyphTheme.secondaryText)
                        
                        HStack(spacing: 8) {
                            Text("@")
                                .font(.system(size: 20, weight: .medium, design: .rounded))
                                .foregroundColor(GlyphTheme.accent)
                            
                            TextField("username", text: $handleText)
                                .font(.system(size: 18, weight: .medium, design: .rounded))
                                .foregroundColor(GlyphTheme.primaryText)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(GlyphTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(GlyphTheme.accent.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer()
                    
                    // Save button
                    VStack(spacing: 12) {
                        Button {
                            profile.platform = selectedPlatform
                            profile.handle = handleText
                            dismiss()
                        } label: {
                            Text(cleanHandle.isEmpty ? "Skip" : "Save")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .frame(maxWidth: .infinity)
                                .frame(height: GlyphTheme.buttonHeight)
                                .background(cleanHandle.isEmpty ? AnyShapeStyle(GlyphTheme.surface) : AnyShapeStyle(GlyphTheme.accentGradient))
                                .foregroundColor(cleanHandle.isEmpty ? GlyphTheme.secondaryText : .black)
                                .clipShape(RoundedRectangle(cornerRadius: GlyphTheme.cornerRadius))
                        }
                        
                        // Unlink button (only if already linked)
                        if profile.isLinked {
                            Button {
                                profile.unlink()
                                dismiss()
                            } label: {
                                Text("Unlink Account")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(GlyphTheme.danger)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear {
                selectedPlatform = profile.platform
                handleText = profile.handle
            }
        }
        .presentationDetents([.medium, .large])
    }
    
    private var cleanHandle: String {
        handleText.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "@", with: "")
    }
}

#Preview {
    HomeView()
        .preferredColorScheme(.dark)
}
