//
//  Theme.swift
//  Vinted Notifications
//
//  Modern theme with dark/light mode support
//  Elegant champagne gold theme
//

import SwiftUI

// MARK: - Theme Colors

struct AppColors {
    // Primary - Champagne gold accent
    let primary: Color
    let primaryDark: Color
    let primaryLight: Color

    // Backgrounds
    let background: Color
    let secondaryBackground: Color
    let groupedBackground: Color
    let secondaryGroupedBackground: Color
    let cardBackground: Color
    let tertiaryBackground: Color

    // Text
    let text: Color
    let textSecondary: Color
    let textTertiary: Color
    let placeholder: Color

    // Status
    let success: Color
    let error: Color
    let warning: Color
    let info: Color

    // UI Elements
    let separator: Color
    let border: Color
    let link: Color

    // Buttons & Controls
    let buttonFill: Color
    let secondaryButtonFill: Color
}

// Dark theme colors (default)
let darkColors = AppColors(
    // Primary - Champagne gold accent
    primary: Color(hex: "C8B588"),
    primaryDark: Color(hex: "B09D6F"),
    primaryLight: Color(hex: "D8C38F"),

    // Backgrounds - Soft black & charcoal
    background: Color(hex: "0C0C0C"),
    secondaryBackground: Color(hex: "1A1A1A"),
    groupedBackground: Color(hex: "0C0C0C"),
    secondaryGroupedBackground: Color(hex: "1A1A1A"),
    cardBackground: Color(hex: "1A1A1A"),
    tertiaryBackground: Color(hex: "242424"),

    // Text - High contrast, elegant
    text: Color(hex: "FAFAFA"),
    textSecondary: Color(hex: "CCCCCC"),
    textTertiary: Color(hex: "888888"),
    placeholder: Color(hex: "666666"),

    // Status
    success: Color(hex: "D8C38F"),
    error: Color(hex: "EF4444"),
    warning: Color(hex: "F59E0B"),
    info: Color(hex: "6A7A8C"),

    // UI Elements
    separator: Color.white.opacity(0.06),
    border: Color.white.opacity(0.08),
    link: Color(hex: "6A7A8C"),

    // Buttons & Controls
    buttonFill: Color.white.opacity(0.06),
    secondaryButtonFill: Color(hex: "1A1A1A")
)

// Light theme colors
let lightColors = AppColors(
    // Primary - Champagne gold accent
    primary: Color(hex: "B09D6F"),
    primaryDark: Color(hex: "8F7D52"),
    primaryLight: Color(hex: "C8B588"),

    // Backgrounds - Soft whites and creams
    background: Color(hex: "FAFAFA"),
    secondaryBackground: Color(hex: "FFFFFF"),
    groupedBackground: Color(hex: "FAFAFA"),
    secondaryGroupedBackground: Color(hex: "FFFFFF"),
    cardBackground: Color(hex: "FFFFFF"),
    tertiaryBackground: Color(hex: "F5F5F5"),

    // Text - Dark, elegant
    text: Color(hex: "0C0C0C"),
    textSecondary: Color(hex: "333333"),
    textTertiary: Color(hex: "666666"),
    placeholder: Color(hex: "999999"),

    // Status
    success: Color(hex: "B09D6F"),
    error: Color(hex: "EF4444"),
    warning: Color(hex: "F59E0B"),
    info: Color(hex: "6A7A8C"),

    // UI Elements
    separator: Color.black.opacity(0.08),
    border: Color.black.opacity(0.12),
    link: Color(hex: "6A7A8C"),

    // Buttons & Controls
    buttonFill: Color.black.opacity(0.04),
    secondaryButtonFill: Color(hex: "F5F5F5")
)

// MARK: - Font Sizes (iOS Typography Scale)

struct FontSizes {
    static let largeTitle: CGFloat = 34    // iOS Large Title
    static let title1: CGFloat = 28        // iOS Title 1
    static let title2: CGFloat = 22        // iOS Title 2
    static let title3: CGFloat = 20        // iOS Title 3
    static let headline: CGFloat = 17      // iOS Headline (semibold)
    static let body: CGFloat = 17          // iOS Body (regular)
    static let callout: CGFloat = 16       // iOS Callout
    static let subheadline: CGFloat = 15   // iOS Subheadline
    static let footnote: CGFloat = 13      // iOS Footnote
    static let caption1: CGFloat = 12      // iOS Caption 1
    static let caption2: CGFloat = 11      // iOS Caption 2
}

// MARK: - Spacing (8pt grid)

struct Spacing {
    static let xxs: CGFloat = 2
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16    // Standard margin
    static let lg: CGFloat = 20
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    static let xxxl: CGFloat = 48
}

// MARK: - Border Radius

struct BorderRadius {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 6
    static let md: CGFloat = 8
    static let lg: CGFloat = 10
    static let xl: CGFloat = 12
    static let xxl: CGFloat = 16
    static let round: CGFloat = 999
}

// MARK: - Shadows

struct Shadows {
    static let small = (color: Color.black.opacity(0.18), radius: CGFloat(1.0), x: CGFloat(0), y: CGFloat(1))
    static let medium = (color: Color.black.opacity(0.20), radius: CGFloat(3.0), x: CGFloat(0), y: CGFloat(2))
    static let large = (color: Color.black.opacity(0.22), radius: CGFloat(5.0), x: CGFloat(0), y: CGFloat(4))
}

// MARK: - Heights

struct Heights {
    static let navBar: CGFloat = 44
    static let tabBar: CGFloat = 49
    static let listRow: CGFloat = 44
    static let listRowLarge: CGFloat = 60
    static let button: CGFloat = 44
    static let input: CGFloat = 44
}

// MARK: - Layout

struct Layout {
    static let screenPadding: CGFloat = Spacing.md       // 16pt margin from edges
    static let listInset: CGFloat = Spacing.md          // 16pt list inset
    static let sectionSpacing: CGFloat = Spacing.lg     // 20pt between sections
    static let cardPadding: CGFloat = Spacing.md        // 16pt inside cards
    static let listSeparatorInset: CGFloat = Spacing.md // 16pt separator inset
}

// MARK: - Animation

struct Animation {
    static let quick: Double = 0.2
    static let standard: Double = 0.3
    static let slow: Double = 0.5
}

// MARK: - Color Extension for Hex Support

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Theme Environment Key

struct ThemeKey: EnvironmentKey {
    static let defaultValue: AppColors = darkColors
}

extension EnvironmentValues {
    var theme: AppColors {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

// MARK: - Theme Manager

class ThemeManager: ObservableObject {
    @Published var isDarkMode: Bool = true

    var currentTheme: AppColors {
        isDarkMode ? darkColors : lightColors
    }

    func toggleTheme() {
        isDarkMode.toggle()
    }
}
