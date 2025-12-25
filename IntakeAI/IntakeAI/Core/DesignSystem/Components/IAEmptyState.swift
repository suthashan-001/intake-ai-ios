import SwiftUI

// MARK: - Empty State Component
struct IAEmptyState: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?

    init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            ZStack {
                Circle()
                    .fill(DesignSystem.Colors.primary.opacity(0.08))
                    .frame(width: 100, height: 100)

                Circle()
                    .fill(DesignSystem.Colors.primary.opacity(0.12))
                    .frame(width: 80, height: 80)

                Image(systemName: icon)
                    .font(.system(size: 36, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.primary)
            }

            VStack(spacing: DesignSystem.Spacing.xs) {
                Text(title)
                    .font(DesignSystem.Typography.headlineMedium)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
            .padding(.horizontal, DesignSystem.Spacing.xl)

            if let actionTitle = actionTitle, let action = action {
                IAButton(actionTitle, style: .primary, icon: "plus", action: action)
                    .padding(.top, DesignSystem.Spacing.sm)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(DesignSystem.Spacing.xxl)
    }
}

// MARK: - Loading State Component
struct IALoadingState: View {
    let message: String

    init(message: String = "Loading...") {
        self.message = message
    }

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: DesignSystem.Colors.primary))
                .scaleEffect(1.2)

            Text(message)
                .font(DesignSystem.Typography.bodyMedium)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(DesignSystem.Spacing.xxl)
    }
}

// MARK: - Error State Component
struct IAErrorState: View {
    let title: String
    let message: String
    let retryAction: (() -> Void)?

    init(
        title: String = "Something went wrong",
        message: String,
        retryAction: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.retryAction = retryAction
    }

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            ZStack {
                Circle()
                    .fill(DesignSystem.Colors.error.opacity(0.08))
                    .frame(width: 100, height: 100)

                Circle()
                    .fill(DesignSystem.Colors.error.opacity(0.12))
                    .frame(width: 80, height: 80)

                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.error)
            }

            VStack(spacing: DesignSystem.Spacing.xs) {
                Text(title)
                    .font(DesignSystem.Typography.headlineMedium)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
            .padding(.horizontal, DesignSystem.Spacing.xl)

            if let retryAction = retryAction {
                IAButton("Try Again", style: .primary, icon: "arrow.clockwise", action: retryAction)
                    .padding(.top, DesignSystem.Spacing.sm)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(DesignSystem.Spacing.xxl)
    }
}

// MARK: - Success State Component
struct IASuccessState: View {
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?

    @State private var isAnimated = false

    init(
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            ZStack {
                Circle()
                    .fill(DesignSystem.Colors.success.opacity(0.08))
                    .frame(width: 100, height: 100)
                    .scaleEffect(isAnimated ? 1 : 0.5)

                Circle()
                    .fill(DesignSystem.Colors.success.opacity(0.12))
                    .frame(width: 80, height: 80)
                    .scaleEffect(isAnimated ? 1 : 0.5)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.success)
                    .scaleEffect(isAnimated ? 1 : 0)
                    .rotationEffect(.degrees(isAnimated ? 0 : -90))
            }
            .animation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.1), value: isAnimated)

            VStack(spacing: DesignSystem.Spacing.xs) {
                Text(title)
                    .font(DesignSystem.Typography.headlineMedium)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
            .padding(.horizontal, DesignSystem.Spacing.xl)
            .opacity(isAnimated ? 1 : 0)
            .offset(y: isAnimated ? 0 : 20)
            .animation(.easeOut(duration: 0.4).delay(0.3), value: isAnimated)

            if let actionTitle = actionTitle, let action = action {
                IAButton(actionTitle, style: .primary, action: action)
                    .padding(.top, DesignSystem.Spacing.sm)
                    .opacity(isAnimated ? 1 : 0)
                    .offset(y: isAnimated ? 0 : 20)
                    .animation(.easeOut(duration: 0.4).delay(0.5), value: isAnimated)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(DesignSystem.Spacing.xxl)
        .onAppear {
            isAnimated = true
        }
    }
}

// MARK: - No Results State
struct IANoResultsState: View {
    let searchTerm: String
    let clearAction: () -> Void

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            ZStack {
                Circle()
                    .fill(DesignSystem.Colors.surfaceSecondary)
                    .frame(width: 80, height: 80)

                Image(systemName: "magnifyingglass")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.textTertiary)
            }

            VStack(spacing: DesignSystem.Spacing.xs) {
                Text("No results found")
                    .font(DesignSystem.Typography.headlineSmall)
                    .foregroundColor(DesignSystem.Colors.textPrimary)

                Text("We couldn't find anything matching \"\(searchTerm)\"")
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            IAButton("Clear Search", style: .secondary, icon: "xmark", action: clearAction)
        }
        .frame(maxWidth: .infinity)
        .padding(DesignSystem.Spacing.xl)
    }
}

// MARK: - Skeleton Loading Components

/// A shimmer effect for skeleton loading
struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay {
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
                    .frame(width: geometry.size.width * 2)
                    .offset(x: -geometry.size.width + (phase * geometry.size.width * 2))
                    .blendMode(.overlay)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm))
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

/// Skeleton placeholder for text
struct SkeletonText: View {
    let width: CGFloat?
    let height: CGFloat

    init(width: CGFloat? = nil, height: CGFloat = 14) {
        self.width = width
        self.height = height
    }

    var body: some View {
        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
            .fill(DesignSystem.Colors.surfaceSecondary)
            .frame(width: width, height: height)
            .shimmer()
    }
}

/// Skeleton placeholder for circles (avatars)
struct SkeletonCircle: View {
    let size: CGFloat

    var body: some View {
        Circle()
            .fill(DesignSystem.Colors.surfaceSecondary)
            .frame(width: size, height: size)
            .shimmer()
    }
}

/// Skeleton placeholder for rectangles (cards, images)
struct SkeletonRect: View {
    let width: CGFloat?
    let height: CGFloat
    let cornerRadius: CGFloat

    init(width: CGFloat? = nil, height: CGFloat, cornerRadius: CGFloat = DesignSystem.CornerRadius.md) {
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(DesignSystem.Colors.surfaceSecondary)
            .frame(width: width, height: height)
            .shimmer()
    }
}

/// Skeleton for patient list row
struct SkeletonPatientRow: View {
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            SkeletonCircle(size: 56)

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                SkeletonText(width: 150, height: 16)
                SkeletonText(width: 100, height: 12)
            }

            Spacer()

            SkeletonRect(width: 60, height: 24, cornerRadius: DesignSystem.CornerRadius.full)
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
    }
}

/// Skeleton for stats card
struct SkeletonStatsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            HStack {
                SkeletonCircle(size: 44)
                Spacer()
            }

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                SkeletonText(width: 80, height: 12)
                SkeletonText(width: 60, height: 24)
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
    }
}

/// Skeleton loading state for patient list
struct IASkeletonPatientList: View {
    let count: Int

    init(count: Int = 5) {
        self.count = count
    }

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            ForEach(0..<count, id: \.self) { _ in
                SkeletonPatientRow()
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
    }
}

/// Skeleton loading state for dashboard
struct IASkeletonDashboard: View {
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // Header skeleton
            HStack {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    SkeletonText(width: 100, height: 14)
                    SkeletonText(width: 150, height: 24)
                }
                Spacer()
            }
            .padding(.horizontal, DesignSystem.Spacing.md)

            // Stats grid skeleton
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DesignSystem.Spacing.md) {
                ForEach(0..<4, id: \.self) { _ in
                    SkeletonStatsCard()
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.md)

            // Recent activity skeleton
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                SkeletonText(width: 120, height: 18)
                    .padding(.horizontal, DesignSystem.Spacing.md)

                ForEach(0..<3, id: \.self) { _ in
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        SkeletonCircle(size: 40)
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                            SkeletonText(width: 180, height: 14)
                            SkeletonText(width: 100, height: 12)
                        }
                        Spacer()
                    }
                    .padding(DesignSystem.Spacing.md)
                    .background(DesignSystem.Colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
                    .padding(.horizontal, DesignSystem.Spacing.md)
                }
            }
        }
    }
}

/// Skeleton loading state for summary detail
struct IASkeletonSummary: View {
    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.lg) {
                // Header
                VStack(spacing: DesignSystem.Spacing.md) {
                    SkeletonCircle(size: 80)
                    SkeletonText(width: 200, height: 24)
                    SkeletonText(width: 150, height: 16)
                }
                .padding(.top, DesignSystem.Spacing.lg)

                // Summary sections
                ForEach(0..<4, id: \.self) { _ in
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        SkeletonText(width: 140, height: 18)

                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            SkeletonText(height: 14)
                            SkeletonText(height: 14)
                            SkeletonText(width: 250, height: 14)
                        }
                    }
                    .padding(DesignSystem.Spacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(DesignSystem.Colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
                    .padding(.horizontal, DesignSystem.Spacing.md)
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ScrollView {
        VStack(spacing: DesignSystem.Spacing.xxl) {
            IAEmptyState(
                icon: "person.3",
                title: "No Patients Yet",
                message: "Add your first patient to get started with intake management.",
                actionTitle: "Add Patient"
            ) {}

            Divider()

            IALoadingState(message: "Loading patients...")

            Divider()

            IAErrorState(
                message: "Unable to load patients. Please check your connection and try again."
            ) {}

            Divider()

            IASuccessState(
                title: "Intake Submitted!",
                message: "Your patient's intake form has been submitted successfully.",
                actionTitle: "View Summary"
            ) {}

            Divider()

            IANoResultsState(searchTerm: "John Smith") {}
        }
        .padding()
    }
    .background(DesignSystem.Colors.background)
}
