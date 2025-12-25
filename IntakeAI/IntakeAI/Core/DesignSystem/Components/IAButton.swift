import SwiftUI

// MARK: - Button Styles
enum IAButtonStyle {
    case primary
    case secondary
    case tertiary
    case destructive
    case ghost
    case outline

    var backgroundColor: Color {
        switch self {
        case .primary: return DesignSystem.Colors.primary
        case .secondary: return DesignSystem.Colors.surfaceSecondary
        case .tertiary: return .clear
        case .destructive: return DesignSystem.Colors.error
        case .ghost: return .clear
        case .outline: return .clear
        }
    }

    var foregroundColor: Color {
        switch self {
        case .primary: return DesignSystem.Colors.textInverse
        case .secondary: return DesignSystem.Colors.textPrimary
        case .tertiary: return DesignSystem.Colors.primary
        case .destructive: return DesignSystem.Colors.textInverse
        case .ghost: return DesignSystem.Colors.textSecondary
        case .outline: return DesignSystem.Colors.primary
        }
    }

    var pressedOpacity: Double {
        switch self {
        case .primary, .destructive: return 0.85
        case .secondary, .outline: return 0.7
        case .tertiary, .ghost: return 0.5
        }
    }
}

enum IAButtonSize {
    case small
    case medium
    case large

    var height: CGFloat {
        switch self {
        case .small: return 36
        case .medium: return 44
        case .large: return 52
        }
    }

    var horizontalPadding: CGFloat {
        switch self {
        case .small: return DesignSystem.Spacing.sm
        case .medium: return DesignSystem.Spacing.md
        case .large: return DesignSystem.Spacing.xl
        }
    }

    var font: Font {
        switch self {
        case .small: return DesignSystem.Typography.labelMedium
        case .medium: return DesignSystem.Typography.titleSmall
        case .large: return DesignSystem.Typography.titleMedium
        }
    }

    var iconSize: CGFloat {
        switch self {
        case .small: return DesignSystem.IconSize.sm
        case .medium: return DesignSystem.IconSize.md
        case .large: return DesignSystem.IconSize.lg
        }
    }
}

// MARK: - Primary Button Component
struct IAButton: View {
    let title: String
    let style: IAButtonStyle
    let size: IAButtonSize
    let icon: String?
    let iconPosition: IconPosition
    let isLoading: Bool
    let isFullWidth: Bool
    let action: () -> Void

    enum IconPosition {
        case leading
        case trailing
    }

    init(
        _ title: String,
        style: IAButtonStyle = .primary,
        size: IAButtonSize = .medium,
        icon: String? = nil,
        iconPosition: IconPosition = .leading,
        isLoading: Bool = false,
        isFullWidth: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.size = size
        self.icon = icon
        self.iconPosition = iconPosition
        self.isLoading = isLoading
        self.isFullWidth = isFullWidth
        self.action = action
    }

    @State private var isPressed = false
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Button(action: {
            if !isLoading {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                action()
            }
        }) {
            HStack(spacing: DesignSystem.Spacing.xs) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: style.foregroundColor))
                        .scaleEffect(0.8)
                } else {
                    if let icon = icon, iconPosition == .leading {
                        Image(systemName: icon)
                            .font(.system(size: size.iconSize, weight: .medium))
                    }

                    Text(title)
                        .font(size.font)
                        .fontWeight(.semibold)

                    if let icon = icon, iconPosition == .trailing {
                        Image(systemName: icon)
                            .font(.system(size: size.iconSize, weight: .medium))
                    }
                }
            }
            .foregroundColor(style.foregroundColor)
            .frame(height: size.height)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .padding(.horizontal, size.horizontalPadding)
            .background(
                Group {
                    if style == .outline {
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: .continuous)
                            .stroke(DesignSystem.Colors.primary, lineWidth: 1.5)
                    } else {
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: .continuous)
                            .fill(style.backgroundColor)
                    }
                }
            )
            .opacity(isEnabled ? (isPressed ? style.pressedOpacity : 1.0) : 0.5)
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(DesignSystem.Animation.quick, value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!isEnabled || isLoading)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .accessibilityLabel(title)
        .accessibilityHint(isLoading ? "Loading" : "")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Icon Button
struct IAIconButton: View {
    let icon: String
    let style: IAButtonStyle
    let size: IAButtonSize
    let action: () -> Void

    @State private var isPressed = false

    init(
        icon: String,
        style: IAButtonStyle = .ghost,
        size: IAButtonSize = .medium,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.style = style
        self.size = size
        self.action = action
    }

    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            action()
        }) {
            Image(systemName: icon)
                .font(.system(size: size.iconSize, weight: .medium))
                .foregroundColor(style.foregroundColor)
                .frame(width: size.height, height: size.height)
                .background(
                    Circle()
                        .fill(style.backgroundColor)
                )
                .opacity(isPressed ? style.pressedOpacity : 1.0)
                .scaleEffect(isPressed ? 0.95 : 1.0)
                .animation(DesignSystem.Animation.quick, value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Floating Action Button
struct IAFloatingActionButton: View {
    let icon: String
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            action()
        }) {
            Image(systemName: icon)
                .font(.system(size: DesignSystem.IconSize.lg, weight: .semibold))
                .foregroundColor(DesignSystem.Colors.textInverse)
                .frame(width: 56, height: 56)
                .background(
                    Circle()
                        .fill(DesignSystem.Colors.primaryGradient)
                )
                .shadow(color: DesignSystem.Colors.primary.opacity(0.4),
                        radius: 8, x: 0, y: 4)
                .scaleEffect(isPressed ? 0.92 : 1.0)
                .animation(DesignSystem.Animation.spring, value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: DesignSystem.Spacing.md) {
        IAButton("Primary Button", style: .primary) {}

        IAButton("Secondary Button", style: .secondary) {}

        IAButton("With Icon", style: .primary, icon: "plus") {}

        IAButton("Loading...", style: .primary, isLoading: true) {}

        IAButton("Full Width", style: .primary, isFullWidth: true) {}

        IAButton("Outline", style: .outline) {}

        IAButton("Destructive", style: .destructive, icon: "trash") {}

        HStack {
            IAIconButton(icon: "heart.fill", style: .ghost) {}
            IAIconButton(icon: "square.and.arrow.up", style: .secondary) {}
            IAFloatingActionButton(icon: "plus") {}
        }
    }
    .padding()
}
