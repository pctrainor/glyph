import SwiftUI

// MARK: - Logo Easter Egg View

/// A delightful branded splash shown when someone scans the Glyph logo QR.
struct LogoEasterEggView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var iconScale: CGFloat = 0.3
    @State private var iconOpacity: Double = 0
    @State private var textOffset: CGFloat = 30
    @State private var textOpacity: Double = 0
    @State private var taglineOpacity: Double = 0
    @State private var glowRadius: CGFloat = 0
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            GlyphTheme.backgroundGradient
                .ignoresSafeArea()

            // Ambient glow ring behind icon
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            GlyphTheme.accent.opacity(0.25),
                            GlyphTheme.violet.opacity(0.10),
                            .clear
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 180
                    )
                )
                .frame(width: 360, height: 360)
                .scaleEffect(pulseScale)
                .blur(radius: 30)

            VStack(spacing: 28) {
                Spacer()

                // QR logo — animated entrance
                GlyphLogoView(size: 140, glowRadius: glowRadius, glowOpacity: 0.6)
                    .scaleEffect(iconScale)
                    .opacity(iconOpacity)

                // Title
                Text("Glyph")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(GlyphTheme.accentGradient)
                    .shadow(color: GlyphTheme.accent.opacity(0.3), radius: 12)
                    .offset(y: textOffset)
                    .opacity(textOpacity)

                // Tagline
                Text("Say it. Show it. Gone.")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(GlyphTheme.secondaryText)
                    .opacity(taglineOpacity)

                Spacer()

                // Fun message
                VStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 24))
                        .foregroundStyle(GlyphTheme.accentGradient)

                    Text("You found the Glyph code")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(GlyphTheme.primaryText)

                    Text("Vanishing messages, hidden in plain sight.")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(GlyphTheme.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .opacity(taglineOpacity)
                .padding(.horizontal, 40)

                Spacer()
                    .frame(height: 20)

                // Dismiss button
                Button {
                    dismiss()
                } label: {
                    Text("Nice")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .frame(height: GlyphTheme.buttonHeight)
                        .background(GlyphTheme.accentGradient)
                        .foregroundColor(.black)
                        .clipShape(RoundedRectangle(cornerRadius: GlyphTheme.cornerRadius))
                }
                .padding(.horizontal, 32)
                .opacity(taglineOpacity)

                Spacer()
                    .frame(height: 40)
            }
        }
        .onAppear {
            // Staggered entrance animations
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                iconScale = 1.0
                iconOpacity = 1.0
            }

            withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                textOffset = 0
                textOpacity = 1.0
            }

            withAnimation(.easeOut(duration: 0.5).delay(0.6)) {
                taglineOpacity = 1.0
            }

            withAnimation(.easeInOut(duration: 0.8).delay(0.2)) {
                glowRadius = 30
            }

            // Continuous gentle pulse on the glow ring
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                pulseScale = 1.15
            }
        }
    }
}

#Preview {
    LogoEasterEggView()
        .preferredColorScheme(.dark)
}
