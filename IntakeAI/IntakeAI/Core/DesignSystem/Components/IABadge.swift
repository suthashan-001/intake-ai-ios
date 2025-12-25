import SwiftUI

// MARK: - Badge Styles
enum IABadgeStyle {
    case primary
    case secondary
    case success
    case warning
    case error
    case info
    case neutral
    case severity(RedFlagSeverity)

    var backgroundColor: Color {
        switch self {
        case .primary: return DesignSystem.Colors.primary.opacity(0.12)
        case .secondary: return DesignSystem.Colors.surfaceSecondary
        case .success: return DesignSystem.Colors.success.opacity(0.12)
        case .warning: return DesignSystem.Colors.warning.opacity(0.12)
        case .error: return DesignSystem.Colors.error.opacity(0.12)
        case .info: return DesignSystem.Colors.info.opacity(0.12)
        case .neutral: return DesignSystem.Colors.surfaceSecondary
        case .severity(let severity): return severity.color.opacity(0.12)
        }
    }

    var foregroundColor: Color {
        switch self {
        case .primary: return DesignSystem.Colors.primary
        case .secondary: return DesignSystem.Colors.textSecondary
        case .success: return DesignSystem.Colors.success
        case .warning: return DesignSystem.Colors.warning
        case .error: return DesignSystem.Colors.error
        case .info: return DesignSystem.Colors.info
        case .neutral: return DesignSystem.Colors.textSecondary
        case .severity(let severity): return severity.color
        }
    }
}

enum IABadgeSize {
    case small
    case medium
    case large

    var font: Font {
        switch self {
        case .small: return DesignSystem.Typography.labelSmall
        case .medium: return DesignSystem.Typography.labelMedium
        case .large: return DesignSystem.Typography.labelLarge
        }
    }

    var horizontalPadding: CGFloat {
        switch self {
        case .small: return DesignSystem.Spacing.xs
        case .medium: return DesignSystem.Spacing.sm
        case .large: return DesignSystem.Spacing.md
        }
    }

    var verticalPadding: CGFloat {
        switch self {
        case .small: return DesignSystem.Spacing.xxxs
        case .medium: return DesignSystem.Spacing.xxs
        case .large: return DesignSystem.Spacing.xs
        }
    }

    var iconSize: CGFloat {
        switch self {
        case .small: return DesignSystem.IconSize.xs
        case .medium: return DesignSystem.IconSize.sm
        case .large: return DesignSystem.IconSize.md
        }
    }
}

// MARK: - Badge Component
struct IABadge: View {
    let text: String
    let style: IABadgeStyle
    let size: IABadgeSize
    let icon: String?
    let isPill: Bool

    init(
        _ text: String,
        style: IABadgeStyle = .primary,
        size: IABadgeSize = .medium,
        icon: String? = nil,
        isPill: Bool = true
    ) {
        self.text = text
        self.style = style
        self.size = size
        self.icon = icon
        self.isPill = isPill
    }

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xxxs) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: size.iconSize, weight: .semibold))
            }

            Text(text)
                .font(size.font)
                .fontWeight(.medium)
        }
        .foregroundColor(style.foregroundColor)
        .padding(.horizontal, size.horizontalPadding)
        .padding(.vertical, size.verticalPadding)
        .background(
            Group {
                if isPill {
                    Capsule()
                        .fill(style.backgroundColor)
                } else {
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xs, style: .continuous)
                        .fill(style.backgroundColor)
                }
            }
        )
    }
}

// MARK: - Count Badge (Notification style)
struct IACountBadge: View {
    let count: Int
    let maxCount: Int
    let style: IABadgeStyle

    init(count: Int, maxCount: Int = 99, style: IABadgeStyle = .error) {
        self.count = count
        self.maxCount = maxCount
        self.style = style
    }

    private var displayText: String {
        count > maxCount ? "\(maxCount)+" : "\(count)"
    }

    var body: some View {
        if count > 0 {
            Text(displayText)
                .font(DesignSystem.Typography.labelSmall)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, count > 9 ? DesignSystem.Spacing.xs : DesignSystem.Spacing.xxs)
                .padding(.vertical, DesignSystem.Spacing.xxxs)
                .frame(minWidth: 18, minHeight: 18)
                .background(
                    Capsule()
                        .fill(DesignSystem.Colors.error)
                )
        }
    }
}

// MARK: - Status Badge
struct IAStatusBadge: View {
    let status: IntakeStatus

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xxxs) {
            Circle()
                .fill(status.color)
                .frame(width: 8, height: 8)

            Text(status.label)
                .font(DesignSystem.Typography.labelMedium)
                .foregroundColor(status.color)
        }
        .padding(.horizontal, DesignSystem.Spacing.sm)
        .padding(.vertical, DesignSystem.Spacing.xxs)
        .background(
            Capsule()
                .fill(status.color.opacity(0.12))
        )
    }
}

// MARK: - Intake Status
enum IntakeStatus: String, Codable, CaseIterable {
    case pending = "PENDING"
    case inProgress = "IN_PROGRESS"
    case completed = "COMPLETED"
    case reviewed = "REVIEWED"

    var label: String {
        switch self {
        case .pending: return "Pending"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        case .reviewed: return "Reviewed"
        }
    }

    var color: Color {
        switch self {
        case .pending: return DesignSystem.Colors.warning
        case .inProgress: return DesignSystem.Colors.info
        case .completed: return DesignSystem.Colors.success
        case .reviewed: return DesignSystem.Colors.primary
        }
    }

    var icon: String {
        switch self {
        case .pending: return "clock"
        case .inProgress: return "pencil.circle"
        case .completed: return "checkmark.circle"
        case .reviewed: return "checkmark.seal"
        }
    }
}

// MARK: - Red Flag Badge
struct IARedFlagBadge: View {
    let count: Int
    let hasHighSeverity: Bool

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xxxs) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: DesignSystem.IconSize.sm, weight: .semibold))

            Text("\(count)")
                .font(DesignSystem.Typography.labelMedium)
                .fontWeight(.bold)
        }
        .foregroundColor(.white)
        .padding(.horizontal, DesignSystem.Spacing.sm)
        .padding(.vertical, DesignSystem.Spacing.xxs)
        .background(
            Capsule()
                .fill(hasHighSeverity ? DesignSystem.Colors.redFlagGradient : LinearGradient(
                    colors: [DesignSystem.Colors.warning, DesignSystem.Colors.warning.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                ))
        )
        .shadow(color: hasHighSeverity ? DesignSystem.Colors.error.opacity(0.3) : DesignSystem.Colors.warning.opacity(0.3),
                radius: 4, x: 0, y: 2)
    }
}

// MARK: - Preview
#Preview {
    ScrollView {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // Basic Badges
            HStack(spacing: DesignSystem.Spacing.sm) {
                IABadge("Primary", style: .primary)
                IABadge("Secondary", style: .secondary)
                IABadge("Success", style: .success, icon: "checkmark")
            }

            HStack(spacing: DesignSystem.Spacing.sm) {
                IABadge("Warning", style: .warning, icon: "exclamationmark.triangle")
                IABadge("Error", style: .error, icon: "xmark.circle")
                IABadge("Info", style: .info, icon: "info.circle")
            }

            // Severity Badges
            HStack(spacing: DesignSystem.Spacing.sm) {
                IABadge("High", style: .severity(.high), icon: "exclamationmark.triangle.fill")
                IABadge("Medium", style: .severity(.medium), icon: "exclamationmark.circle.fill")
                IABadge("Low", style: .severity(.low), icon: "info.circle.fill")
            }

            // Sizes
            HStack(spacing: DesignSystem.Spacing.sm) {
                IABadge("Small", style: .primary, size: .small)
                IABadge("Medium", style: .primary, size: .medium)
                IABadge("Large", style: .primary, size: .large)
            }

            // Count Badges
            HStack(spacing: DesignSystem.Spacing.md) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell")
                        .font(.system(size: 24))
                    IACountBadge(count: 5)
                        .offset(x: 8, y: -8)
                }

                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell")
                        .font(.system(size: 24))
                    IACountBadge(count: 100)
                        .offset(x: 12, y: -8)
                }
            }

            // Status Badges
            VStack(spacing: DesignSystem.Spacing.sm) {
                IAStatusBadge(status: .pending)
                IAStatusBadge(status: .inProgress)
                IAStatusBadge(status: .completed)
                IAStatusBadge(status: .reviewed)
            }

            // Red Flag Badges
            HStack(spacing: DesignSystem.Spacing.md) {
                IARedFlagBadge(count: 3, hasHighSeverity: true)
                IARedFlagBadge(count: 2, hasHighSeverity: false)
            }
        }
        .padding()
    }
}
