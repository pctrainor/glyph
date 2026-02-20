import SwiftUI

// MARK: - Theme

/// Centralized color and style constants for Glyph.
enum GlyphTheme {
    
    // MARK: - Colors
    
    /// Deep dark background
    static let background = Color(red: 0.04, green: 0.04, blue: 0.08)
    
    /// Slightly lighter surface for cards
    static let surface = Color(red: 0.08, green: 0.08, blue: 0.14)
    
    /// Primary accent — electric cyan
    static let accent = Color(red: 0.4, green: 0.85, blue: 1.0)
    
    /// Secondary accent — soft violet
    static let violet = Color(red: 0.6, green: 0.4, blue: 1.0)
    
    /// Warning / expiring — amber
    static let warning = Color(red: 1.0, green: 0.7, blue: 0.2)
    
    /// Danger / expired — red
    static let danger = Color(red: 1.0, green: 0.3, blue: 0.3)
    
    /// Muted text
    static let secondaryText = Color(white: 0.5)
    
    /// Primary text
    static let primaryText = Color.white
    
    // MARK: - Gradients
    
    /// Background gradient for main screens
    static let backgroundGradient = LinearGradient(
        colors: [
            Color(red: 0.04, green: 0.04, blue: 0.08),
            Color(red: 0.06, green: 0.04, blue: 0.12)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    /// Accent gradient for buttons
    static let accentGradient = LinearGradient(
        colors: [accent, violet],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    // MARK: - Sizes
    
    static let cornerRadius: CGFloat = 16
    static let buttonHeight: CGFloat = 56
}
