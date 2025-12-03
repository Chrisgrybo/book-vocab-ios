//
//  Theme.swift
//  BookVocab
//
//  Centralized design system for consistent UI across the app.
//  Warm tan aesthetic with black accents.
//
//  Usage:
//  - Apply .cardStyle() to any card container
//  - Use AppColors for consistent colors
//  - Use AppSpacing for consistent padding/margins
//  - Use Typography modifiers for text styling
//

import SwiftUI

// MARK: - App Colors

/// Centralized color palette for the app.
/// Warm tan backgrounds with black accents.
enum AppColors {
    // Primary brand colors - Black accent
    static let primary = Color.black
    static let primaryGradient = LinearGradient(
        colors: [Color(hex: "#1A1A1A"), Color(hex: "#000000")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Semantic colors
    static let success = Color(hex: "#2D6A4F")  // Muted forest green
    static let warning = Color(hex: "#BC6C25")  // Warm amber
    static let error = Color(hex: "#9B2226")    // Deep red
    static let info = Color(hex: "#457B9D")     // Muted blue
    
    // Background colors - Warm tan palette
    static let tan = Color(hex: "#F5F0E8")              // Light tan
    static let tanDark = Color(hex: "#EDE4D3")          // Slightly darker tan
    static let cream = Color(hex: "#FFFCF7")            // Cream white for cards
    
    static let background = Color(hex: "#F5F0E8")       // Main tan background
    static let secondaryBackground = Color(hex: "#EDE4D3")
    static let tertiaryBackground = Color(hex: "#E5DBC9")
    static let groupedBackground = Color(hex: "#F5F0E8")
    
    // Card backgrounds
    static let cardBackground = Color(hex: "#FFFCF7")   // Cream white
    static let elevatedCardBackground = Color.white
    
    // Accent gradients - Darker/muted versions
    static let blueGradient = LinearGradient(
        colors: [Color(hex: "#264653"), Color(hex: "#2A9D8F")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let purpleGradient = LinearGradient(
        colors: [Color(hex: "#1A1A1A"), Color(hex: "#333333")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let orangeGradient = LinearGradient(
        colors: [Color(hex: "#BC6C25"), Color(hex: "#DDA15E")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let greenGradient = LinearGradient(
        colors: [Color(hex: "#2D6A4F"), Color(hex: "#40916C")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let warmGradient = LinearGradient(
        colors: [Color(hex: "#BC6C25"), Color(hex: "#DDA15E")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Header gradient (subtle tan)
    static let headerGradient = LinearGradient(
        colors: [
            Color(hex: "#EDE4D3").opacity(0.8),
            Color(hex: "#F5F0E8").opacity(0.3)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - App Spacing

/// Consistent spacing values throughout the app.
enum AppSpacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 20
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    static let xxxl: CGFloat = 48
    
    // Standard horizontal padding
    static let horizontalPadding: CGFloat = 16
    
    // Standard vertical padding
    static let verticalPadding: CGFloat = 12
    
    // Card internal padding
    static let cardPadding: CGFloat = 16
    
    // Section spacing
    static let sectionSpacing: CGFloat = 24
}

// MARK: - App Radius

/// Consistent corner radius values.
enum AppRadius {
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
    static let card: CGFloat = 20
    static let extraLarge: CGFloat = 24
    static let pill: CGFloat = 100
}

// MARK: - App Shadows

/// Consistent shadow styles.
enum AppShadow {
    static let small = ShadowStyle(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
    static let medium = ShadowStyle(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
    static let large = ShadowStyle(color: .black.opacity(0.12), radius: 20, x: 0, y: 8)
    static let card = ShadowStyle(color: .black.opacity(0.06), radius: 16, x: 0, y: 6)
}

struct ShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - App Animations

/// Consistent animation presets.
enum AppAnimation {
    static let quick = Animation.easeOut(duration: 0.2)
    static let standard = Animation.easeInOut(duration: 0.3)
    static let smooth = Animation.easeInOut(duration: 0.4)
    static let spring = Animation.spring(response: 0.4, dampingFraction: 0.75)
    static let bouncy = Animation.spring(response: 0.5, dampingFraction: 0.6)
    static let gentle = Animation.spring(response: 0.6, dampingFraction: 0.8)
}

// MARK: - Card Style Modifier

/// A view modifier that applies consistent card styling.
struct CardStyle: ViewModifier {
    var padding: CGFloat = AppSpacing.cardPadding
    var cornerRadius: CGFloat = AppRadius.card
    var shadowStyle: ShadowStyle = AppShadow.card
    var backgroundColor: Color = AppColors.cardBackground
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(
                color: shadowStyle.color,
                radius: shadowStyle.radius,
                x: shadowStyle.x,
                y: shadowStyle.y
            )
    }
}

extension View {
    /// Applies consistent card styling to any view.
    func cardStyle(
        padding: CGFloat = AppSpacing.cardPadding,
        cornerRadius: CGFloat = AppRadius.card,
        shadow: ShadowStyle = AppShadow.card,
        backgroundColor: Color = AppColors.cardBackground
    ) -> some View {
        modifier(CardStyle(
            padding: padding,
            cornerRadius: cornerRadius,
            shadowStyle: shadow,
            backgroundColor: backgroundColor
        ))
    }
    
    /// Applies a subtle card style with less shadow.
    func subtleCardStyle() -> some View {
        modifier(CardStyle(
            padding: AppSpacing.cardPadding,
            cornerRadius: AppRadius.large,
            shadowStyle: AppShadow.small,
            backgroundColor: AppColors.cardBackground
        ))
    }
    
    /// Applies an elevated card style with more shadow.
    func elevatedCardStyle() -> some View {
        modifier(CardStyle(
            padding: AppSpacing.cardPadding,
            cornerRadius: AppRadius.card,
            shadowStyle: AppShadow.large,
            backgroundColor: AppColors.cardBackground
        ))
    }
}

// MARK: - Gradient Header

/// A reusable gradient header component for screen titles.
struct GradientHeader: View {
    let title: String
    let subtitle: String?
    let icon: String?
    
    init(_ title: String, subtitle: String? = nil, icon: String? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
    }
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(AppColors.primary)
            }
            
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, AppSpacing.horizontalPadding)
        .padding(.vertical, AppSpacing.lg)
        .background(
            AppColors.headerGradient
                .ignoresSafeArea(edges: .top)
        )
    }
}

// MARK: - Section Header

/// A consistent section header for lists and groups.
struct SectionHeader: View {
    let title: String
    let action: (() -> Void)?
    let actionLabel: String?
    
    init(_ title: String, action: (() -> Void)? = nil, actionLabel: String? = nil) {
        self.title = title
        self.action = action
        self.actionLabel = actionLabel
    }
    
    var body: some View {
        HStack {
            Text(title)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
            
            Spacer()
            
            if let action = action, let label = actionLabel {
                Button(action: action) {
                    Text(label)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(AppColors.primary)
                }
            }
        }
        .padding(.horizontal, AppSpacing.horizontalPadding)
        .padding(.bottom, AppSpacing.xs)
    }
}

// MARK: - Primary Button Style

/// A prominent button style for primary actions.
struct PrimaryButtonStyle: ButtonStyle {
    var isDestructive: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.md)
            .background(
                Group {
                    if isDestructive {
                        AppColors.error
                    } else {
                        AppColors.primary
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.2), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
    static var destructive: PrimaryButtonStyle { PrimaryButtonStyle(isDestructive: true) }
}

// MARK: - Secondary Button Style

/// A subtle button style for secondary actions.
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundStyle(AppColors.primary)
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .background(AppColors.primary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.2), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    static var secondary: SecondaryButtonStyle { SecondaryButtonStyle() }
}

// MARK: - Icon Button Style

/// A circular icon button style.
struct IconButtonStyle: ButtonStyle {
    var size: CGFloat = 44
    var backgroundColor: Color = AppColors.primary.opacity(0.1)
    var foregroundColor: Color = AppColors.primary
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: size * 0.45, weight: .semibold))
            .foregroundStyle(foregroundColor)
            .frame(width: size, height: size)
            .background(backgroundColor)
            .clipShape(Circle())
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Pill Tag

/// A small pill-shaped tag for labels and badges.
struct PillTag: View {
    let text: String
    var color: Color = AppColors.primary
    var icon: String? = nil
    
    var body: some View {
        HStack(spacing: AppSpacing.xxs) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.caption2)
            }
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundStyle(color)
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.xxs)
        .background(color.opacity(0.12))
        .clipShape(Capsule())
    }
}

// MARK: - Stat Display

/// A reusable stat display component.
struct StatDisplay: View {
    let value: String
    let label: String
    let icon: String?
    let color: Color
    
    init(_ value: String, label: String, icon: String? = nil, color: Color = AppColors.primary) {
        self.value = value
        self.label = label
        self.icon = icon
        self.color = color
    }
    
    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
            }
            
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Empty State View

/// A reusable empty state component.
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let buttonTitle: String?
    let action: (() -> Void)?
    
    init(
        icon: String,
        title: String,
        message: String,
        buttonTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.buttonTitle = buttonTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundStyle(AppColors.primary)
            
            VStack(spacing: AppSpacing.xs) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.xxl)
            }
            
            if let buttonTitle = buttonTitle, let action = action {
                Button(action: action) {
                    Label(buttonTitle, systemImage: "plus.circle.fill")
                }
                .buttonStyle(.primary)
                .padding(.horizontal, AppSpacing.xxxl)
            }
        }
        .padding(AppSpacing.xl)
    }
}

// MARK: - Loading Overlay

/// A loading overlay with blur effect.
struct LoadingOverlay: View {
    let message: String?
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.2)
                .ignoresSafeArea()
            
            VStack(spacing: AppSpacing.md) {
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(.white)
                
                if let message = message {
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(.white)
                }
            }
            .padding(AppSpacing.xl)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.large))
        }
    }
}

// MARK: - Shimmer Effect

/// A shimmer loading effect for placeholders.
struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        colors: [
                            .clear,
                            .white.opacity(0.5),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 2)
                    .offset(x: -geometry.size.width + (phase * geometry.size.width * 2))
                }
                .mask(content)
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerEffect())
    }
}

// MARK: - Color Extension for Hex

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
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Appear Animation Modifier

/// Animates a view when it appears.
struct AppearAnimation: ViewModifier {
    @State private var hasAppeared = false
    let delay: Double
    
    func body(content: Content) -> some View {
        content
            .opacity(hasAppeared ? 1 : 0)
            .offset(y: hasAppeared ? 0 : 20)
            .onAppear {
                withAnimation(AppAnimation.spring.delay(delay)) {
                    hasAppeared = true
                }
            }
    }
}

extension View {
    func appearAnimation(delay: Double = 0) -> some View {
        modifier(AppearAnimation(delay: delay))
    }
}

// MARK: - Preview

#Preview("Theme Components") {
    ScrollView {
        VStack(spacing: 24) {
            GradientHeader("My Books", subtitle: "4 books • 128 words", icon: "books.vertical.fill")
            
            SectionHeader("Recent", action: {}, actionLabel: "See All")
            
            Text("Card Example")
                .frame(maxWidth: .infinity)
                .frame(height: 100)
                .cardStyle()
                .padding(.horizontal)
            
            HStack(spacing: 16) {
                StatDisplay("42", label: "Words", icon: "textformat.abc", color: .blue)
                StatDisplay("28", label: "Mastered", icon: "checkmark.circle.fill", color: AppColors.success)
                StatDisplay("14", label: "Learning", icon: "book.fill", color: AppColors.warning)
            }
            .cardStyle()
            .padding(.horizontal)
            
            HStack {
                PillTag(text: "Fiction", color: AppColors.primary, icon: "book.closed.fill")
                PillTag(text: "12 words", color: AppColors.success, icon: "textformat.abc")
                PillTag(text: "Mastered", color: AppColors.warning, icon: "star.fill")
            }
            .padding(.horizontal)
            
            Button("Primary Action") {}
                .buttonStyle(.primary)
                .padding(.horizontal)
            
            Button("Secondary Action") {}
                .buttonStyle(.secondary)
        }
    }
    .background(AppColors.groupedBackground)
}
