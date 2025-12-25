import SwiftUI

// MARK: - Avatar Sizes
enum IAAvatarSize {
    case xs
    case small
    case medium
    case large
    case xl
    case xxl

    var dimension: CGFloat {
        switch self {
        case .xs: return 24
        case .small: return 32
        case .medium: return 40
        case .large: return 48
        case .xl: return 64
        case .xxl: return 80
        }
    }

    var font: Font {
        switch self {
        case .xs: return .system(size: 10, weight: .semibold)
        case .small: return .system(size: 12, weight: .semibold)
        case .medium: return .system(size: 14, weight: .semibold)
        case .large: return .system(size: 18, weight: .semibold)
        case .xl: return .system(size: 24, weight: .semibold)
        case .xxl: return .system(size: 32, weight: .semibold)
        }
    }

    var badgeSize: CGFloat {
        switch self {
        case .xs, .small: return 8
        case .medium: return 10
        case .large: return 12
        case .xl: return 14
        case .xxl: return 16
        }
    }
}

// MARK: - Avatar Component
struct IAAvatar: View {
    let name: String
    let imageURL: URL?
    let size: IAAvatarSize
    let showBadge: Bool
    let badgeColor: Color

    init(
        name: String,
        imageURL: URL? = nil,
        size: IAAvatarSize = .medium,
        showBadge: Bool = false,
        badgeColor: Color = DesignSystem.Colors.success
    ) {
        self.name = name
        self.imageURL = imageURL
        self.size = size
        self.showBadge = showBadge
        self.badgeColor = badgeColor
    }

    private var initials: String {
        let components = name.split(separator: " ")
        if components.count >= 2 {
            return String(components[0].prefix(1) + components[1].prefix(1)).uppercased()
        } else if let first = components.first {
            return String(first.prefix(2)).uppercased()
        }
        return "?"
    }

    private var backgroundColor: Color {
        // Generate a consistent color based on the name
        let hash = abs(name.hashValue)
        let colors: [Color] = [
            Color(hex: "4A7C59"), // Sage green
            Color(hex: "6B8E7A"), // Light sage
            Color(hex: "3D6B4F"), // Dark sage
            Color(hex: "5B9279"), // Teal green
            Color(hex: "7CA982"), // Mint
            Color(hex: "4F7942"), // Fern
        ]
        return colors[hash % colors.count]
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                if let imageURL = imageURL {
                    AsyncImage(url: imageURL) { phase in
                        switch phase {
                        case .empty:
                            initialsView
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure:
                            initialsView
                        @unknown default:
                            initialsView
                        }
                    }
                } else {
                    initialsView
                }
            }
            .frame(width: size.dimension, height: size.dimension)
            .clipShape(Circle())

            if showBadge {
                Circle()
                    .fill(badgeColor)
                    .frame(width: size.badgeSize, height: size.badgeSize)
                    .overlay(
                        Circle()
                            .stroke(DesignSystem.Colors.surface, lineWidth: 2)
                    )
                    .offset(x: 2, y: 2)
            }
        }
        .accessibilityLabel(name)
    }

    private var initialsView: some View {
        ZStack {
            Circle()
                .fill(backgroundColor)

            Text(initials)
                .font(size.font)
                .foregroundColor(.white)
        }
    }
}

// MARK: - Avatar Group (Stacked)
struct IAAvatarGroup: View {
    let names: [String]
    let size: IAAvatarSize
    let maxVisible: Int
    let overlap: CGFloat

    init(
        names: [String],
        size: IAAvatarSize = .small,
        maxVisible: Int = 4,
        overlap: CGFloat = 0.3
    ) {
        self.names = names
        self.size = size
        self.maxVisible = maxVisible
        self.overlap = overlap
    }

    private var visibleNames: [String] {
        Array(names.prefix(maxVisible))
    }

    private var remainingCount: Int {
        max(0, names.count - maxVisible)
    }

    var body: some View {
        HStack(spacing: -size.dimension * overlap) {
            ForEach(Array(visibleNames.enumerated()), id: \.offset) { index, name in
                IAAvatar(name: name, size: size)
                    .overlay(
                        Circle()
                            .stroke(DesignSystem.Colors.surface, lineWidth: 2)
                    )
                    .zIndex(Double(visibleNames.count - index))
            }

            if remainingCount > 0 {
                ZStack {
                    Circle()
                        .fill(DesignSystem.Colors.surfaceSecondary)

                    Text("+\(remainingCount)")
                        .font(size.font)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                .frame(width: size.dimension, height: size.dimension)
                .overlay(
                    Circle()
                        .stroke(DesignSystem.Colors.surface, lineWidth: 2)
                )
                .zIndex(0)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(names.count) people")
    }
}

// MARK: - User Avatar with Status
struct IAUserAvatar: View {
    let user: UserProfile
    let size: IAAvatarSize
    let showTitle: Bool

    struct UserProfile {
        let firstName: String
        let lastName: String
        let title: String?
        let imageURL: URL?

        var fullName: String {
            "\(firstName) \(lastName)"
        }

        var displayTitle: String {
            if let title = title {
                return "\(title) \(lastName)"
            }
            return fullName
        }
    }

    init(
        user: UserProfile,
        size: IAAvatarSize = .medium,
        showTitle: Bool = true
    ) {
        self.user = user
        self.size = size
        self.showTitle = showTitle
    }

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            IAAvatar(
                name: user.fullName,
                imageURL: user.imageURL,
                size: size
            )

            if showTitle {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxxs) {
                    Text(user.fullName)
                        .font(DesignSystem.Typography.titleSmall)
                        .foregroundColor(DesignSystem.Colors.textPrimary)

                    if let title = user.title {
                        Text(title)
                            .font(DesignSystem.Typography.bodySmall)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                }
            }
        }
    }
}

// MARK: - Patient Avatar Cell
struct IAPatientAvatarCell: View {
    let name: String
    let dateOfBirth: Date
    let status: IntakeStatus?
    let hasRedFlags: Bool
    let action: () -> Void

    @State private var isPressed = false

    private var age: Int {
        Calendar.current.dateComponents([.year], from: dateOfBirth, to: Date()).year ?? 0
    }

    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            action()
        }) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                ZStack(alignment: .topTrailing) {
                    IAAvatar(name: name, size: .large)

                    if hasRedFlags {
                        Circle()
                            .fill(DesignSystem.Colors.error)
                            .frame(width: 12, height: 12)
                            .overlay(
                                Circle()
                                    .stroke(DesignSystem.Colors.surface, lineWidth: 2)
                            )
                            .offset(x: 2, y: -2)
                    }
                }

                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxxs) {
                    Text(name)
                        .font(DesignSystem.Typography.titleMedium)
                        .foregroundColor(DesignSystem.Colors.textPrimary)

                    Text("\(age) years old")
                        .font(DesignSystem.Typography.bodySmall)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }

                Spacer()

                if let status = status {
                    IAStatusBadge(status: status)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: DesignSystem.IconSize.sm, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textTertiary)
            }
            .padding(DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg, style: .continuous))
            .shadow(
                color: DesignSystem.Shadows.small.color,
                radius: DesignSystem.Shadows.small.radius,
                x: DesignSystem.Shadows.small.x,
                y: DesignSystem.Shadows.small.y
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

// MARK: - Preview
#Preview {
    ScrollView {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // Different sizes
            HStack(spacing: DesignSystem.Spacing.md) {
                IAAvatar(name: "John Doe", size: .xs)
                IAAvatar(name: "Jane Smith", size: .small)
                IAAvatar(name: "Bob Wilson", size: .medium)
                IAAvatar(name: "Alice Brown", size: .large)
                IAAvatar(name: "Charlie Davis", size: .xl)
            }

            // With badge
            HStack(spacing: DesignSystem.Spacing.md) {
                IAAvatar(name: "Online User", size: .large, showBadge: true)
                IAAvatar(name: "Away User", size: .large, showBadge: true, badgeColor: DesignSystem.Colors.warning)
                IAAvatar(name: "Busy User", size: .large, showBadge: true, badgeColor: DesignSystem.Colors.error)
            }

            // Avatar Group
            IAAvatarGroup(names: ["John Doe", "Jane Smith", "Bob Wilson", "Alice Brown", "Charlie Davis", "Eve Miller"])

            // User Avatar with details
            IAUserAvatar(
                user: .init(
                    firstName: "Dr. Sarah",
                    lastName: "Johnson",
                    title: "MD",
                    imageURL: nil
                ),
                size: .large
            )

            // Patient cells
            IAPatientAvatarCell(
                name: "John Doe",
                dateOfBirth: Calendar.current.date(byAdding: .year, value: -35, to: Date())!,
                status: .completed,
                hasRedFlags: true
            ) {}

            IAPatientAvatarCell(
                name: "Jane Smith",
                dateOfBirth: Calendar.current.date(byAdding: .year, value: -28, to: Date())!,
                status: .pending,
                hasRedFlags: false
            ) {}
        }
        .padding()
    }
    .background(DesignSystem.Colors.background)
}
