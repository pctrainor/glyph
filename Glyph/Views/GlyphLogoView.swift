import SwiftUI

// MARK: - Glyph Logo View

/// A minimal, iconic QR-inspired brand mark drawn entirely in SwiftUI.
/// Three finder-pattern squares (top-left, top-right, bottom-left) plus a
/// four-point sparkle in the bottom-right — clean, not scannable, instantly
/// recognizable.  Use `size` to control dimensions.
struct GlyphLogoView: View {
    var size: CGFloat = 120
    var glowRadius: CGFloat = 20
    var glowOpacity: Double = 0.4

    var body: some View {
        Canvas { context, _ in
            let unit = size / 10          // 10-unit conceptual grid
            let gap  = unit * 0.6         // space between the four quadrants
            let finderSize = (size - gap) / 2  // each finder pattern square

            // ── Helper: draw a single finder pattern (outer border + inner dot) ──
            func drawFinder(at origin: CGPoint) {
                let r = finderSize * 0.18  // corner radius
                let outer = CGRect(x: origin.x, y: origin.y,
                                   width: finderSize, height: finderSize)
                // Outer ring
                let outerPath = Path(roundedRect: outer, cornerRadius: r)
                context.stroke(outerPath, with: .color(.white),
                               lineWidth: finderSize * 0.13)

                // Inner filled square
                let inset = finderSize * 0.28
                let inner = CGRect(x: origin.x + inset, y: origin.y + inset,
                                   width: finderSize - inset * 2,
                                   height: finderSize - inset * 2)
                let innerPath = Path(roundedRect: inner, cornerRadius: r * 0.5)
                context.fill(innerPath, with: .color(.white))
            }

            // ── Three finder patterns ──
            // Top-left
            drawFinder(at: CGPoint(x: 0, y: 0))
            // Top-right
            drawFinder(at: CGPoint(x: finderSize + gap, y: 0))
            // Bottom-left
            drawFinder(at: CGPoint(x: 0, y: finderSize + gap))

            // ── Bottom-right: four-point sparkle / diamond ──
            let sparkleCenter = CGPoint(x: finderSize + gap + finderSize / 2,
                                        y: finderSize + gap + finderSize / 2)
            let arm = finderSize * 0.32   // length from center to tip
            let waist = arm * 0.28        // width at the waist

            var sparkle = Path()
            // Top point
            sparkle.move(to: CGPoint(x: sparkleCenter.x, y: sparkleCenter.y - arm))
            // Right point
            sparkle.addQuadCurve(
                to: CGPoint(x: sparkleCenter.x + arm, y: sparkleCenter.y),
                control: CGPoint(x: sparkleCenter.x + waist, y: sparkleCenter.y - waist))
            // Bottom point
            sparkle.addQuadCurve(
                to: CGPoint(x: sparkleCenter.x, y: sparkleCenter.y + arm),
                control: CGPoint(x: sparkleCenter.x + waist, y: sparkleCenter.y + waist))
            // Left point
            sparkle.addQuadCurve(
                to: CGPoint(x: sparkleCenter.x - arm, y: sparkleCenter.y),
                control: CGPoint(x: sparkleCenter.x - waist, y: sparkleCenter.y + waist))
            // Close back to top
            sparkle.addQuadCurve(
                to: CGPoint(x: sparkleCenter.x, y: sparkleCenter.y - arm),
                control: CGPoint(x: sparkleCenter.x - waist, y: sparkleCenter.y - waist))

            context.fill(sparkle, with: .color(.white))
        }
        .frame(width: size, height: size)
        // Gradient overlay — fills only the drawn shapes
        .overlay(
            GlyphTheme.accentGradient
                .mask(
                    Canvas { context, canvasSize in
                        let unit = canvasSize.width / 10
                        let gap  = unit * 0.6
                        let finderSize = (canvasSize.width - gap) / 2

                        func drawFinder(at origin: CGPoint) {
                            let r = finderSize * 0.18
                            let outer = CGRect(x: origin.x, y: origin.y,
                                               width: finderSize, height: finderSize)
                            let outerPath = Path(roundedRect: outer, cornerRadius: r)
                            context.stroke(outerPath, with: .color(.white),
                                           lineWidth: finderSize * 0.13)

                            let inset = finderSize * 0.28
                            let inner = CGRect(x: origin.x + inset, y: origin.y + inset,
                                               width: finderSize - inset * 2,
                                               height: finderSize - inset * 2)
                            let innerPath = Path(roundedRect: inner, cornerRadius: r * 0.5)
                            context.fill(innerPath, with: .color(.white))
                        }

                        drawFinder(at: CGPoint(x: 0, y: 0))
                        drawFinder(at: CGPoint(x: finderSize + gap, y: 0))
                        drawFinder(at: CGPoint(x: 0, y: finderSize + gap))

                        let sparkleCenter = CGPoint(x: finderSize + gap + finderSize / 2,
                                                    y: finderSize + gap + finderSize / 2)
                        let arm = finderSize * 0.32
                        let waist = arm * 0.28

                        var sparkle = Path()
                        sparkle.move(to: CGPoint(x: sparkleCenter.x, y: sparkleCenter.y - arm))
                        sparkle.addQuadCurve(
                            to: CGPoint(x: sparkleCenter.x + arm, y: sparkleCenter.y),
                            control: CGPoint(x: sparkleCenter.x + waist, y: sparkleCenter.y - waist))
                        sparkle.addQuadCurve(
                            to: CGPoint(x: sparkleCenter.x, y: sparkleCenter.y + arm),
                            control: CGPoint(x: sparkleCenter.x + waist, y: sparkleCenter.y + waist))
                        sparkle.addQuadCurve(
                            to: CGPoint(x: sparkleCenter.x - arm, y: sparkleCenter.y),
                            control: CGPoint(x: sparkleCenter.x - waist, y: sparkleCenter.y + waist))
                        sparkle.addQuadCurve(
                            to: CGPoint(x: sparkleCenter.x, y: sparkleCenter.y - arm),
                            control: CGPoint(x: sparkleCenter.x - waist, y: sparkleCenter.y - waist))

                        context.fill(sparkle, with: .color(.white))
                    }
                )
        )
        .shadow(color: GlyphTheme.accent.opacity(glowOpacity), radius: glowRadius)
    }
}

#Preview {
    ZStack {
        GlyphTheme.backgroundGradient
            .ignoresSafeArea()
        VStack(spacing: 20) {
            GlyphLogoView(size: 160)
            Text("Glyph")
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
    }
    .preferredColorScheme(.dark)
}
