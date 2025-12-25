import SwiftUI

// MARK: - Card Component
struct IACard<Content: View>: View {
    let content: Content
    let padding: CGFloat
    let cornerRadius: CGFloat
    let hasShadow: Bool
    let isInteractive: Bool
    var action: (() -> Void)?

    @State private var isPressed = false

    init(
        padding: CGFloat = DesignSystem.Spacing.md,
        cornerRadius: CGFloat = DesignSystem.CornerRadius.lg,
        hasShadow: Bool = true,
        isInteractive: Bool = false,
        action: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.hasShadow = hasShadow
        self.isInteractive = isInteractive
        self.action = action
        self.content = content()
    }

    var body: some View {
        Group {
            if isInteractive, let action = action {
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    action()
                }) {
                    cardContent
                }
                .buttonStyle(PlainButtonStyle())
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in isPressed = true }
                        .onEnded { _ in isPressed = false }
                )
            } else {
                cardContent
            }
        }
    }

    private var cardContent: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DesignSystem.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(
                color: hasShadow ? DesignSystem.Shadows.medium.color : .clear,
                radius: hasShadow ? DesignSystem.Shadows.medium.radius : 0,
                x: DesignSystem.Shadows.medium.x,
                y: DesignSystem.Shadows.medium.y
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(DesignSystem.Animation.quick, value: isPressed)
    }
}

// MARK: - Stats Card
struct IAStatsCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let icon: String
    let iconColor: Color
    let trend: Trend?

    enum Trend {
        case up(String)
        case down(String)
        case neutral(String)

        var color: Color {
            switch self {
            case .up: return DesignSystem.Colors.success
            case .down: return DesignSystem.Colors.error
            case .neutral: return DesignSystem.Colors.textSecondary
            }
        }

        var icon: String {
            switch self {
            case .up: return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .neutral: return "arrow.right"
            }
        }

        var text: String {
            switch self {
            case .up(let value), .down(let value), .neutral(let value):
                return value
            }
        }
    }

    init(
        title: String,
        value: String,
        subtitle: String? = nil,
        icon: String,
        iconColor: Color = DesignSystem.Colors.primary,
        trend: Trend? = nil
    ) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.icon = icon
        self.iconColor = iconColor
        self.trend = trend
    }

    var body: some View {
        IACard {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(iconColor.opacity(0.12))
                            .frame(width: 40, height: 40)

                        Image(systemName: icon)
                            .font(.system(size: DesignSystem.IconSize.md, weight: .semibold))
                            .foregroundColor(iconColor)
                    }

                    Spacer()

                    if let trend = trend {
                        HStack(spacing: DesignSystem.Spacing.xxxs) {
                            Image(systemName: trend.icon)
                                .font(.system(size: DesignSystem.IconSize.xs, weight: .semibold))
                            Text(trend.text)
                                .font(DesignSystem.Typography.labelSmall)
                        }
                        .foregroundColor(trend.color)
                        .padding(.horizontal, DesignSystem.Spacing.xs)
                        .padding(.vertical, DesignSystem.Spacing.xxxs)
                        .background(
                            Capsule()
                                .fill(trend.color.opacity(0.1))
                        )
                    }
                }

                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxxs) {
                    Text(value)
                        .font(DesignSystem.Typography.displaySmall)
                        .foregroundColor(DesignSystem.Colors.textPrimary)

                    Text(title)
                        .font(DesignSystem.Typography.bodySmall)
                        .foregroundColor(DesignSystem.Colors.textSecondary)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(DesignSystem.Typography.labelSmall)
                            .foregroundColor(DesignSystem.Colors.textTertiary)
                    }
                }
            }
        }
    }
}

// MARK: - Alert Card (for Red Flags)
struct IAAlertCard: View {
    let title: String
    let message: String
    let severity: RedFlagSeverity
    let timestamp: Date?
    var action: (() -> Void)?

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            action?()
        }) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                // Severity indicator
                RoundedRectangle(cornerRadius: 2)
                    .fill(severity.color)
                    .frame(width: 4)

                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                    HStack {
                        Image(systemName: severity.icon)
                            .font(.system(size: DesignSystem.IconSize.sm, weight: .semibold))
                            .foregroundColor(severity.color)

                        Text(title)
                            .font(DesignSystem.Typography.titleSmall)
                            .foregroundColor(DesignSystem.Colors.textPrimary)

                        Spacer()

                        if let timestamp = timestamp {
                            Text(timestamp.relativeFormatted)
                                .font(DesignSystem.Typography.labelSmall)
                                .foregroundColor(DesignSystem.Colors.textTertiary)
                        }
                    }

                    Text(message)
                        .font(DesignSystem.Typography.bodySmall)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .lineLimit(2)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: DesignSystem.IconSize.sm, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textTertiary)
            }
            .padding(DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: .continuous)
                    .stroke(severity.color.opacity(0.3), lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
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

// MARK: - Info Card
struct IAInfoCard: View {
    let title: String
    let items: [(label: String, value: String)]
    let icon: String?

    init(
        title: String,
        items: [(label: String, value: String)],
        icon: String? = nil
    ) {
        self.title = title
        self.items = items
        self.icon = icon
    }

    var body: some View {
        IACard {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: DesignSystem.IconSize.md, weight: .semibold))
                            .foregroundColor(DesignSystem.Colors.primary)
                    }

                    Text(title)
                        .font(DesignSystem.Typography.headlineSmall)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                }

                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    HStack {
                        Text(item.label)
                            .font(DesignSystem.Typography.bodySmall)
                            .foregroundColor(DesignSystem.Colors.textSecondary)

                        Spacer()

                        Text(item.value)
                            .font(DesignSystem.Typography.bodyMedium)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                    }
                }
            }
        }
    }
}

// MARK: - Date Extension
extension Date {
    var relativeFormatted: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

// MARK: - Preview
#Preview {
    ScrollView {
        VStack(spacing: DesignSystem.Spacing.md) {
            IACard {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Text("Basic Card")
                        .font(DesignSystem.Typography.headlineSmall)
                    Text("This is a simple card component with default styling.")
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
            }

            IAStatsCard(
                title: "Total Patients",
                value: "248",
                subtitle: "This month",
                icon: "person.2.fill",
                iconColor: DesignSystem.Colors.primary,
                trend: .up("+12%")
            )

            IAStatsCard(
                title: "Red Flags",
                value: "5",
                subtitle: "Require attention",
                icon: "exclamationmark.triangle.fill",
                iconColor: DesignSystem.Colors.error,
                trend: .down("-3")
            )

            IAAlertCard(
                title: "Suicidal Ideation Detected",
                message: "Patient John Doe mentioned thoughts of self-harm in their intake form.",
                severity: .high,
                timestamp: Date().addingTimeInterval(-3600)
            )

            IAAlertCard(
                title: "Chest Pain Reported",
                message: "Patient Jane Smith reported moderate chest pain.",
                severity: .medium,
                timestamp: Date().addingTimeInterval(-7200)
            )

            IAInfoCard(
                title: "Patient Details",
                items: [
                    ("Name", "John Doe"),
                    ("Date of Birth", "Jan 15, 1985"),
                    ("Phone", "(555) 123-4567"),
                    ("Email", "john@example.com")
                ],
                icon: "person.circle"
            )
        }
        .padding()
    }
    .background(DesignSystem.Colors.background)
}
