import SwiftUI

// MARK: - Premium Skeleton Loading Components
/// Apple Health/Fitness-quality skeleton loading states with shimmer animations

// MARK: - Patient Row Skeleton
struct PatientRowSkeleton: View {
    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            // Avatar skeleton
            Circle()
                .fill(Color(uiColor: .systemGray5))
                .frame(width: 52, height: 52)
                .shimmerOverlay(isAnimating: isAnimating)

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                // Name skeleton
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(uiColor: .systemGray5))
                    .frame(width: 140, height: 16)
                    .shimmerOverlay(isAnimating: isAnimating)

                // Details skeleton
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(uiColor: .systemGray6))
                    .frame(width: 100, height: 12)
                    .shimmerOverlay(isAnimating: isAnimating)
            }

            Spacer()

            // Badge skeleton
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(uiColor: .systemGray5))
                .frame(width: 70, height: 24)
                .shimmerOverlay(isAnimating: isAnimating)
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg, style: .continuous))
        .onAppear { isAnimating = true }
    }
}

// MARK: - Dashboard Card Skeleton
struct DashboardCardSkeleton: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack {
                // Icon skeleton
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(uiColor: .systemGray5))
                    .frame(width: 40, height: 40)
                    .shimmerOverlay(isAnimating: isAnimating)

                Spacer()

                // Value skeleton
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(uiColor: .systemGray5))
                    .frame(width: 50, height: 28)
                    .shimmerOverlay(isAnimating: isAnimating)
            }

            // Title skeleton
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(uiColor: .systemGray6))
                .frame(width: 80, height: 14)
                .shimmerOverlay(isAnimating: isAnimating)
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg, style: .continuous))
        .onAppear { isAnimating = true }
    }
}

// MARK: - Summary Card Skeleton
struct SummaryCardSkeleton: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            // Header
            HStack {
                Circle()
                    .fill(Color(uiColor: .systemGray5))
                    .frame(width: 44, height: 44)
                    .shimmerOverlay(isAnimating: isAnimating)

                VStack(alignment: .leading, spacing: 4) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(uiColor: .systemGray5))
                        .frame(width: 120, height: 16)
                        .shimmerOverlay(isAnimating: isAnimating)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(uiColor: .systemGray6))
                        .frame(width: 80, height: 12)
                        .shimmerOverlay(isAnimating: isAnimating)
                }

                Spacer()
            }

            // Content lines
            ForEach(0..<3, id: \.self) { index in
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(uiColor: .systemGray6))
                    .frame(height: 14)
                    .frame(maxWidth: index == 2 ? 200 : .infinity)
                    .shimmerOverlay(isAnimating: isAnimating)
            }

            // Red flag skeleton
            HStack(spacing: DesignSystem.Spacing.xs) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(uiColor: .systemGray5))
                    .frame(width: 20, height: 20)

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(uiColor: .systemGray6))
                    .frame(width: 100, height: 12)
            }
            .shimmerOverlay(isAnimating: isAnimating)
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg, style: .continuous))
        .onAppear { isAnimating = true }
    }
}

// MARK: - List Skeleton
struct PatientListSkeleton: View {
    let count: Int

    init(count: Int = 5) {
        self.count = count
    }

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            ForEach(0..<count, id: \.self) { _ in
                PatientRowSkeleton()
            }
        }
    }
}

// MARK: - Kanban Column Skeleton
struct KanbanColumnSkeleton: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            ForEach(0..<3, id: \.self) { _ in
                HStack(spacing: DesignSystem.Spacing.md) {
                    Circle()
                        .fill(Color(uiColor: .systemGray5))
                        .frame(width: 48, height: 48)
                        .shimmerOverlay(isAnimating: isAnimating)

                    VStack(alignment: .leading, spacing: 6) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(uiColor: .systemGray5))
                            .frame(width: 120, height: 14)
                            .shimmerOverlay(isAnimating: isAnimating)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(uiColor: .systemGray6))
                            .frame(width: 160, height: 12)
                            .shimmerOverlay(isAnimating: isAnimating)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(uiColor: .systemGray6))
                            .frame(width: 80, height: 10)
                            .shimmerOverlay(isAnimating: isAnimating)
                    }

                    Spacer()

                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(uiColor: .systemGray5))
                        .frame(width: 60, height: 22)
                        .shimmerOverlay(isAnimating: isAnimating)
                }
                .padding(DesignSystem.Spacing.md)
                .background(DesignSystem.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg, style: .continuous))
            }
        }
        .onAppear { isAnimating = true }
    }
}

// MARK: - Detail View Skeleton
struct PatientDetailSkeleton: View {
    @State private var isAnimating = false

    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.lg) {
                // Header
                VStack(spacing: DesignSystem.Spacing.md) {
                    Circle()
                        .fill(Color(uiColor: .systemGray5))
                        .frame(width: 80, height: 80)
                        .shimmerOverlay(isAnimating: isAnimating)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(uiColor: .systemGray5))
                        .frame(width: 160, height: 24)
                        .shimmerOverlay(isAnimating: isAnimating)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(uiColor: .systemGray6))
                        .frame(width: 100, height: 14)
                        .shimmerOverlay(isAnimating: isAnimating)
                }
                .padding(.top, DesignSystem.Spacing.lg)

                // Info cards
                ForEach(0..<3, id: \.self) { _ in
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(uiColor: .systemGray5))
                            .frame(width: 100, height: 14)
                            .shimmerOverlay(isAnimating: isAnimating)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(uiColor: .systemGray6))
                            .frame(height: 44)
                            .shimmerOverlay(isAnimating: isAnimating)
                    }
                    .padding(DesignSystem.Spacing.md)
                    .background(DesignSystem.Colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg, style: .continuous))
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
        }
        .onAppear { isAnimating = true }
    }
}

// MARK: - Shimmer Overlay Modifier
struct ShimmerOverlay: ViewModifier {
    let isAnimating: Bool
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { geometry in
                    let width = geometry.size.width
                    LinearGradient(
                        colors: [
                            .clear,
                            .white.opacity(0.6),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: width * 0.5)
                    .offset(x: phase * width * 1.5 - width * 0.25)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            .onChange(of: isAnimating) { _, newValue in
                if newValue {
                    withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                        phase = 1
                    }
                }
            }
            .onAppear {
                if isAnimating {
                    withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                        phase = 1
                    }
                }
            }
    }
}

extension View {
    func shimmerOverlay(isAnimating: Bool) -> some View {
        modifier(ShimmerOverlay(isAnimating: isAnimating))
    }
}

// MARK: - Activity Ring Skeleton (Apple Health Style)
struct ActivityRingSkeleton: View {
    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color(uiColor: .systemGray5), lineWidth: 12)
                .frame(width: 100, height: 100)

            // Animated partial ring
            Circle()
                .trim(from: 0, to: 0.3)
                .stroke(
                    LinearGradient(
                        colors: [Color(uiColor: .systemGray4), Color(uiColor: .systemGray5)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .frame(width: 100, height: 100)
                .rotationEffect(.degrees(rotation))
        }
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}

// MARK: - Previews
#Preview("Patient Row Skeleton") {
    VStack(spacing: 12) {
        PatientRowSkeleton()
        PatientRowSkeleton()
        PatientRowSkeleton()
    }
    .padding()
    .background(Color(uiColor: .systemGroupedBackground))
}

#Preview("Dashboard Skeleton") {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
        DashboardCardSkeleton()
        DashboardCardSkeleton()
        DashboardCardSkeleton()
        DashboardCardSkeleton()
    }
    .padding()
    .background(Color(uiColor: .systemGroupedBackground))
}

#Preview("Activity Ring") {
    ActivityRingSkeleton()
        .padding()
}
