import SwiftUI

// MARK: - Design System
/// A comprehensive design system for IntakeAI following Apple Human Interface Guidelines
/// with a healthcare-focused color palette and accessible typography
/// Designed to match Apple Health/Fitness app quality standards
enum DesignSystem {

    // MARK: - Colors (Adaptive Light/Dark Mode)
    enum Colors {
        // Primary Healthcare Palette - Calming Sage Green
        static let primary = Color("Primary", bundle: nil)
        static let primaryLight = Color("PrimaryLight", bundle: nil)
        static let primaryDark = Color("PrimaryDark", bundle: nil)

        // Accent Colors
        static let accent = Color("Accent", bundle: nil)
        static let accentLight = Color("AccentLight", bundle: nil)

        // Semantic Colors
        static let success = Color("Success", bundle: nil)
        static let warning = Color("Warning", bundle: nil)
        static let error = Color("Error", bundle: nil)
        static let info = Color("Info", bundle: nil)

        // Red Flag Severity Colors
        static let severityHigh = Color("SeverityHigh", bundle: nil)
        static let severityMedium = Color("SeverityMedium", bundle: nil)
        static let severityLow = Color("SeverityLow", bundle: nil)

        // Neutral Colors - Adaptive
        static let background = Color("Background", bundle: nil)
        static let surface = Color("Surface", bundle: nil)
        static let surfaceSecondary = Color("SurfaceSecondary", bundle: nil)
        static let surfaceTertiary = Color(uiColor: .tertiarySystemBackground)
        static let border = Color("Border", bundle: nil)
        static let divider = Color("Divider", bundle: nil)

        // Text Colors - Adaptive
        static let textPrimary = Color("TextPrimary", bundle: nil)
        static let textSecondary = Color("TextSecondary", bundle: nil)
        static let textTertiary = Color("TextTertiary", bundle: nil)
        static let textInverse = Color("TextInverse", bundle: nil)

        // System Colors for native feel
        static let systemBackground = Color(uiColor: .systemBackground)
        static let secondarySystemBackground = Color(uiColor: .secondarySystemBackground)
        static let tertiarySystemBackground = Color(uiColor: .tertiarySystemBackground)
        static let systemGroupedBackground = Color(uiColor: .systemGroupedBackground)
        static let secondarySystemGroupedBackground = Color(uiColor: .secondarySystemGroupedBackground)

        // Gradients
        static let primaryGradient = LinearGradient(
            colors: [Color(hex: "4A7C59"), Color(hex: "6B9B7A")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let cardGradient = LinearGradient(
            colors: [Color(hex: "FFFFFF"), Color(hex: "F8FAF9")],
            startPoint: .top,
            endPoint: .bottom
        )

        static let redFlagGradient = LinearGradient(
            colors: [Color(hex: "DC2626"), Color(hex: "EF4444")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        // Premium shimmer gradient for skeleton loading
        static let shimmerGradient = LinearGradient(
            colors: [
                Color(uiColor: .systemGray5),
                Color(uiColor: .systemGray4),
                Color(uiColor: .systemGray5)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )

        // Apple Health-style ring gradients
        static let activityRingGradient = AngularGradient(
            colors: [Color(hex: "FA114F"), Color(hex: "FA114F").opacity(0.5)],
            center: .center,
            startAngle: .degrees(0),
            endAngle: .degrees(360)
        )
    }

    // MARK: - Typography (Dynamic Type Support)
    enum Typography {
        // Display - Using TextStyle for Dynamic Type
        static let displayLarge = Font.system(.largeTitle, design: .rounded, weight: .bold)
        static let displayMedium = Font.system(size: 28, weight: .bold, design: .rounded)
        static let displaySmall = Font.system(size: 24, weight: .semibold, design: .rounded)

        // Headlines
        static let headlineLarge = Font.system(.title2, design: .default, weight: .semibold)
        static let headlineMedium = Font.system(.title3, design: .default, weight: .semibold)
        static let headlineSmall = Font.system(.headline, design: .default, weight: .semibold)

        // Titles
        static let titleLarge = Font.system(.body, design: .default, weight: .semibold)
        static let titleMedium = Font.system(.callout, design: .default, weight: .medium)
        static let titleSmall = Font.system(.subheadline, design: .default, weight: .medium)

        // Body
        static let bodyLarge = Font.system(.body, design: .default, weight: .regular)
        static let bodyMedium = Font.system(.callout, design: .default, weight: .regular)
        static let bodySmall = Font.system(.footnote, design: .default, weight: .regular)

        // Labels
        static let labelLarge = Font.system(.subheadline, design: .default, weight: .medium)
        static let labelMedium = Font.system(.caption, design: .default, weight: .medium)
        static let labelSmall = Font.system(.caption2, design: .default, weight: .medium)

        // Mono (for codes, tokens)
        static let monoMedium = Font.system(.footnote, design: .monospaced, weight: .medium)
        static let monoSmall = Font.system(.caption, design: .monospaced, weight: .regular)
    }

    // MARK: - Spacing
    enum Spacing {
        static let xxxs: CGFloat = 2
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 20
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
        static let xxxl: CGFloat = 40
        static let huge: CGFloat = 48
        static let massive: CGFloat = 64
    }

    // MARK: - Corner Radius
    enum CornerRadius {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let full: CGFloat = 9999
    }

    // MARK: - Shadows (Adaptive for Dark Mode)
    enum Shadows {
        static let small = Shadow(color: .black.opacity(0.04), radius: 2, x: 0, y: 1)
        static let medium = Shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
        static let large = Shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 4)
        static let elevated = Shadow(color: .black.opacity(0.16), radius: 24, x: 0, y: 8)

        // Apple-style material blur shadows
        static let cardShadow = Shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
        static let floatingShadow = Shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
    }

    // MARK: - Animation (Apple-standard timing)
    enum Animation {
        static let quick = SwiftUI.Animation.easeOut(duration: 0.15)
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.25)
        static let smooth = SwiftUI.Animation.easeInOut(duration: 0.35)
        static let spring = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.75)
        static let bouncy = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.6)

        // Apple-standard interactive spring
        static let interactiveSpring = SwiftUI.Animation.interactiveSpring(response: 0.35, dampingFraction: 0.7, blendDuration: 0.1)

        // Snappy for UI feedback
        static let snappy = SwiftUI.Animation.snappy(duration: 0.25)

        // Premium easing curves
        static let gentleBounce = SwiftUI.Animation.spring(response: 0.6, dampingFraction: 0.8)
    }

    // MARK: - Icon Sizes
    enum IconSize {
        static let xs: CGFloat = 12
        static let sm: CGFloat = 16
        static let md: CGFloat = 20
        static let lg: CGFloat = 24
        static let xl: CGFloat = 28
        static let xxl: CGFloat = 32
        static let huge: CGFloat = 48
    }

    // MARK: - Haptics
    enum Haptics {
        @MainActor
        static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
            let generator = UIImpactFeedbackGenerator(style: style)
            generator.impactOccurred()
        }

        @MainActor
        static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(type)
        }

        @MainActor
        static func selection() {
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
        }
    }
}

// MARK: - Shadow Helper
struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
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
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - View Modifiers
extension View {
    func cardStyle(padding: CGFloat = DesignSystem.Spacing.md) -> some View {
        self
            .padding(padding)
            .background(DesignSystem.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg, style: .continuous))
            .shadow(color: DesignSystem.Shadows.medium.color,
                    radius: DesignSystem.Shadows.medium.radius,
                    x: DesignSystem.Shadows.medium.x,
                    y: DesignSystem.Shadows.medium.y)
    }

    func elevatedCardStyle() -> some View {
        self
            .padding(DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl, style: .continuous))
            .shadow(color: DesignSystem.Shadows.large.color,
                    radius: DesignSystem.Shadows.large.radius,
                    x: DesignSystem.Shadows.large.x,
                    y: DesignSystem.Shadows.large.y)
    }

    func inputFieldStyle() -> some View {
        self
            .padding(DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.surfaceSecondary)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: .continuous)
                    .stroke(DesignSystem.Colors.border, lineWidth: 1)
            )
    }

    func redFlagBadgeStyle(severity: RedFlagSeverity) -> some View {
        self
            .font(DesignSystem.Typography.labelMedium)
            .foregroundColor(.white)
            .padding(.horizontal, DesignSystem.Spacing.xs)
            .padding(.vertical, DesignSystem.Spacing.xxs)
            .background(severity.color)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm, style: .continuous))
    }

    // MARK: - iOS 17 Sensory Feedback
    @ViewBuilder
    func sensoryFeedback<T: Equatable>(_ feedback: SensoryFeedback, trigger: T) -> some View {
        if #available(iOS 17.0, *) {
            self.sensoryFeedback(feedback, trigger: trigger)
        } else {
            self
        }
    }

    // Apple-style glass material background
    func glassBackground() -> some View {
        self
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg, style: .continuous))
    }

    // Inset grouped list row style (Apple Settings style)
    func insetGroupedRowStyle() -> some View {
        self
            .listRowBackground(DesignSystem.Colors.secondarySystemGroupedBackground)
            .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
    }
}

// MARK: - Red Flag Severity
enum RedFlagSeverity: String, Codable, CaseIterable {
    case high
    case medium
    case low

    var color: Color {
        switch self {
        case .high: return DesignSystem.Colors.severityHigh
        case .medium: return DesignSystem.Colors.severityMedium
        case .low: return DesignSystem.Colors.severityLow
        }
    }

    var icon: String {
        switch self {
        case .high: return "exclamationmark.triangle.fill"
        case .medium: return "exclamationmark.circle.fill"
        case .low: return "info.circle.fill"
        }
    }

    var label: String {
        switch self {
        case .high: return "High Priority"
        case .medium: return "Medium Priority"
        case .low: return "Low Priority"
        }
    }
}

// MARK: - Skeleton Loading Modifier
struct SkeletonModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    let isLoading: Bool

    func body(content: Content) -> some View {
        if isLoading {
            content
                .redacted(reason: .placeholder)
                .overlay(
                    GeometryReader { geometry in
                        LinearGradient(
                            colors: [
                                .clear,
                                .white.opacity(0.4),
                                .clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: geometry.size.width * 0.6)
                        .offset(x: -geometry.size.width + (geometry.size.width * 2 * phase))
                        .animation(
                            .linear(duration: 1.5)
                            .repeatForever(autoreverses: false),
                            value: phase
                        )
                    }
                    .mask(content)
                )
                .onAppear { phase = 1 }
        } else {
            content
        }
    }
}

extension View {
    func skeleton(isLoading: Bool) -> some View {
        modifier(SkeletonModifier(isLoading: isLoading))
    }
}

// MARK: - Premium Shimmer Effect
struct ShimmerEffect: ViewModifier {
    @State private var moveTo: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { geometry in
                    let extraWidth = geometry.size.width * 0.5
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    .clear,
                                    .white.opacity(0.5),
                                    .clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: extraWidth)
                        .offset(x: moveTo * (geometry.size.width + extraWidth))
                }
            }
            .mask { content }
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    moveTo = 1
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerEffect())
    }
}

// MARK: - Bounce Press Effect (Apple Style)
struct BouncePress: ViewModifier {
    @State private var isPressed = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false }
            )
    }
}

extension View {
    func bouncePress() -> some View {
        modifier(BouncePress())
    }
}

// MARK: - Symbol Effect Wrapper for iOS 17
extension View {
    @ViewBuilder
    func pulsingSymbol(_ isActive: Bool = true) -> some View {
        if #available(iOS 17.0, *), isActive {
            self.symbolEffect(.pulse, options: .repeating)
        } else {
            self
        }
    }

    @ViewBuilder
    func bouncingSymbol(trigger: Bool) -> some View {
        if #available(iOS 17.0, *) {
            self.symbolEffect(.bounce, value: trigger)
        } else {
            self
        }
    }

    @ViewBuilder
    func variableSymbol(_ value: Double) -> some View {
        if #available(iOS 17.0, *) {
            self.symbolEffect(.variableColor.iterative.cumulative, options: .repeating, value: value)
        } else {
            self
        }
    }
}
