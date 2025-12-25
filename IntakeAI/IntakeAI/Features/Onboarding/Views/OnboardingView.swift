import SwiftUI

// MARK: - Onboarding Data
struct OnboardingPage: Identifiable {
    let id = UUID()
    let illustration: IllustrationType
    let title: String
    let subtitle: String
    let description: String
    let color: Color

    enum IllustrationType {
        case aiIntake
        case redFlag
        case summary
        case security
    }

    static let pages: [OnboardingPage] = [
        OnboardingPage(
            illustration: .aiIntake,
            title: "Smart Patient Intake",
            subtitle: "Save 25 minutes per patient",
            description: "Patients complete beautiful, mobile-friendly intake forms from home. No more clipboards in the waiting room.",
            color: DesignSystem.Colors.primary
        ),
        OnboardingPage(
            illustration: .redFlag,
            title: "Never Miss a Red Flag",
            subtitle: "Dual-layer safety detection",
            description: "AI + keyword scanning catches critical symptoms like chest pain, suicidal ideation, and breathing difficulty instantly.",
            color: DesignSystem.Colors.error
        ),
        OnboardingPage(
            illustration: .summary,
            title: "AI Clinical Summaries",
            subtitle: "One-click intelligence",
            description: "Generate structured summaries with chief complaint, medications, systems review, and lifestyle factors in seconds.",
            color: DesignSystem.Colors.accent
        ),
        OnboardingPage(
            illustration: .security,
            title: "HIPAA-Ready Security",
            subtitle: "Healthcare-grade protection",
            description: "DOB verification, 64-character encrypted links, complete audit trails, and HttpOnly cookie authentication.",
            color: DesignSystem.Colors.success
        )
    ]
}

// MARK: - Onboarding View
struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var currentPage = 0
    @State private var isAnimating = false
    @State private var particles: [FloatingParticle] = []
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack {
            // Animated background
            AnimatedGradientBackground(color: OnboardingPage.pages[currentPage].color)
                .ignoresSafeArea()

            // Floating particles
            ForEach(particles) { particle in
                Circle()
                    .fill(OnboardingPage.pages[currentPage].color.opacity(particle.opacity))
                    .frame(width: particle.size, height: particle.size)
                    .position(particle.position)
                    .blur(radius: particle.blur)
            }

            VStack(spacing: 0) {
                // Top bar
                HStack {
                    // Logo
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Image(systemName: "heart.text.square.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [DesignSystem.Colors.primary, DesignSystem.Colors.primaryLight],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        Text("IntakeAI")
                            .font(DesignSystem.Typography.titleMedium)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                    }

                    Spacer()

                    Button("Skip") {
                        completeOnboarding()
                    }
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                .padding(.horizontal, DesignSystem.Spacing.lg)
                .padding(.top, DesignSystem.Spacing.sm)

                // Page content
                TabView(selection: $currentPage) {
                    ForEach(Array(OnboardingPage.pages.enumerated()), id: \.element.id) { index, page in
                        OnboardingPageView(page: page, isAnimating: $isAnimating)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: currentPage)

                // Bottom section
                VStack(spacing: DesignSystem.Spacing.lg) {
                    // Progress indicator
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        ForEach(0..<OnboardingPage.pages.count, id: \.self) { index in
                            Capsule()
                                .fill(
                                    index == currentPage
                                        ? OnboardingPage.pages[currentPage].color
                                        : DesignSystem.Colors.textTertiary.opacity(0.2)
                                )
                                .frame(width: index == currentPage ? 32 : 8, height: 8)
                                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentPage)
                        }
                    }

                    // Action buttons
                    HStack(spacing: DesignSystem.Spacing.md) {
                        if currentPage > 0 {
                            Button {
                                withAnimation {
                                    currentPage -= 1
                                }
                                appState.triggerHaptic(.light)
                            } label: {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                                    .frame(width: 56, height: 56)
                                    .background(DesignSystem.Colors.surface)
                                    .clipShape(Circle())
                                    .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
                            }
                        }

                        Button {
                            if currentPage < OnboardingPage.pages.count - 1 {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                    currentPage += 1
                                }
                                appState.triggerHaptic(.light)
                            } else {
                                completeOnboarding()
                            }
                        } label: {
                            HStack(spacing: DesignSystem.Spacing.sm) {
                                Text(currentPage < OnboardingPage.pages.count - 1 ? "Continue" : "Get Started")
                                    .font(DesignSystem.Typography.titleSmall)

                                Image(systemName: currentPage < OnboardingPage.pages.count - 1 ? "arrow.right" : "checkmark")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    colors: [
                                        OnboardingPage.pages[currentPage].color,
                                        OnboardingPage.pages[currentPage].color.opacity(0.8)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(Capsule())
                            .shadow(
                                color: OnboardingPage.pages[currentPage].color.opacity(0.4),
                                radius: 15,
                                y: 8
                            )
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)

                    // Legal text
                    Text("By continuing, you agree to our [Terms](terms) and [Privacy Policy](privacy)")
                        .font(DesignSystem.Typography.labelSmall)
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                        .multilineTextAlignment(.center)
                        .tint(DesignSystem.Colors.primary)
                }
                .padding(.bottom, DesignSystem.Spacing.xl)
            }
        }
        .onAppear {
            isAnimating = true
            generateParticles()
        }
        .onChange(of: currentPage) { _, _ in
            isAnimating = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isAnimating = true
            }
        }
    }

    private func completeOnboarding() {
        appState.triggerNotificationHaptic(.success)
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            hasCompletedOnboarding = true
        }
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }

    private func generateParticles() {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height

        particles = (0..<15).map { _ in
            FloatingParticle(
                position: CGPoint(
                    x: CGFloat.random(in: 0...screenWidth),
                    y: CGFloat.random(in: 0...screenHeight)
                ),
                size: CGFloat.random(in: 4...20),
                opacity: Double.random(in: 0.05...0.15),
                blur: CGFloat.random(in: 0...3)
            )
        }
    }
}

// MARK: - Floating Particle
struct FloatingParticle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var size: CGFloat
    var opacity: Double
    var blur: CGFloat
}

// MARK: - Animated Gradient Background
struct AnimatedGradientBackground: View {
    let color: Color
    @State private var animate = false

    var body: some View {
        ZStack {
            DesignSystem.Colors.background

            // Animated blob 1
            Circle()
                .fill(color.opacity(0.1))
                .frame(width: 400, height: 400)
                .blur(radius: 80)
                .offset(x: animate ? 50 : -50, y: animate ? -100 : 100)

            // Animated blob 2
            Circle()
                .fill(color.opacity(0.08))
                .frame(width: 300, height: 300)
                .blur(radius: 60)
                .offset(x: animate ? -80 : 80, y: animate ? 150 : -50)
        }
        .animation(.easeInOut(duration: 8).repeatForever(autoreverses: true), value: animate)
        .animation(.easeInOut(duration: 0.8), value: color)
        .onAppear { animate = true }
    }
}

// MARK: - Onboarding Page View
struct OnboardingPageView: View {
    let page: OnboardingPage
    @Binding var isAnimating: Bool

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            Spacer()

            // Custom illustration
            illustrationView
                .frame(height: 280)
                .scaleEffect(isAnimating ? 1 : 0.8)
                .opacity(isAnimating ? 1 : 0)
                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1), value: isAnimating)

            // Text content
            VStack(spacing: DesignSystem.Spacing.sm) {
                Text(page.title)
                    .font(DesignSystem.Typography.displaySmall)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .multilineTextAlignment(.center)

                Text(page.subtitle)
                    .font(DesignSystem.Typography.titleSmall)
                    .foregroundColor(page.color)
                    .multilineTextAlignment(.center)

                Text(page.description)
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.top, DesignSystem.Spacing.xs)
            }
            .opacity(isAnimating ? 1 : 0)
            .offset(y: isAnimating ? 0 : 30)
            .animation(.easeOut(duration: 0.6).delay(0.3), value: isAnimating)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
    }

    @ViewBuilder
    private var illustrationView: some View {
        switch page.illustration {
        case .aiIntake:
            AIIntakeIllustration(color: page.color, isAnimating: isAnimating)
        case .redFlag:
            RedFlagIllustration(color: page.color, isAnimating: isAnimating)
        case .summary:
            SummaryIllustration(color: page.color, isAnimating: isAnimating)
        case .security:
            SecurityIllustration(color: page.color, isAnimating: isAnimating)
        }
    }
}

// MARK: - Custom Illustrations

struct AIIntakeIllustration: View {
    let color: Color
    let isAnimating: Bool
    @State private var phoneOffset: CGFloat = 0
    @State private var checkmarks: [Bool] = [false, false, false]

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(color.opacity(0.1))
                .frame(width: 220, height: 220)

            // Phone mockup
            RoundedRectangle(cornerRadius: 24)
                .fill(DesignSystem.Colors.surface)
                .frame(width: 140, height: 240)
                .shadow(color: color.opacity(0.2), radius: 20, y: 10)
                .overlay {
                    VStack(spacing: 12) {
                        // Form header
                        RoundedRectangle(cornerRadius: 8)
                            .fill(color.opacity(0.2))
                            .frame(width: 100, height: 20)

                        // Form fields
                        ForEach(0..<3, id: \.self) { index in
                            HStack {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(DesignSystem.Colors.surfaceSecondary)
                                    .frame(width: 80, height: 16)

                                Spacer()

                                if checkmarks[index] {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(DesignSystem.Colors.success)
                                        .font(.system(size: 16))
                                        .transition(.scale.combined(with: .opacity))
                                }
                            }
                            .frame(width: 110)
                        }

                        Spacer()

                        // Progress bar
                        GeometryReader { geo in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(DesignSystem.Colors.surfaceSecondary)
                                .frame(height: 8)
                                .overlay(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(color)
                                        .frame(width: isAnimating ? geo.size.width * 0.75 : 0)
                                        .animation(.easeOut(duration: 1.5).delay(0.5), value: isAnimating)
                                }
                        }
                        .frame(width: 100, height: 8)
                    }
                    .padding(20)
                }
                .offset(y: phoneOffset)

            // Floating emoji
            Text("🏠")
                .font(.system(size: 40))
                .offset(x: 80, y: -80)
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : 20)
                .animation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.8), value: isAnimating)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                phoneOffset = -10
            }

            // Animate checkmarks
            for i in 0..<3 {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.4 + 0.8) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        checkmarks[i] = true
                    }
                }
            }
        }
    }
}

struct RedFlagIllustration: View {
    let color: Color
    let isAnimating: Bool
    @State private var pulseScale: CGFloat = 1
    @State private var alertRotation: Double = 0

    var body: some View {
        ZStack {
            // Pulsing circles
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .stroke(color.opacity(0.3 - Double(index) * 0.1), lineWidth: 2)
                    .frame(width: CGFloat(100 + index * 50), height: CGFloat(100 + index * 50))
                    .scaleEffect(isAnimating ? 1.2 : 0.8)
                    .opacity(isAnimating ? 0 : 1)
                    .animation(
                        .easeOut(duration: 2)
                        .repeatForever(autoreverses: false)
                        .delay(Double(index) * 0.4),
                        value: isAnimating
                    )
            }

            // Shield with alert
            ZStack {
                // Shield background
                Image(systemName: "shield.fill")
                    .font(.system(size: 120))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [color, color.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                // Alert icon
                Image(systemName: "exclamationmark")
                    .font(.system(size: 50, weight: .bold))
                    .foregroundColor(.white)
                    .offset(y: 5)
            }
            .shadow(color: color.opacity(0.4), radius: 20, y: 10)
            .scaleEffect(pulseScale)

            // Floating badges
            Group {
                AlertBadge(text: "CHEST PAIN", color: color)
                    .offset(x: -90, y: -60)
                    .rotationEffect(.degrees(-10))

                AlertBadge(text: "URGENT", color: color)
                    .offset(x: 80, y: 50)
                    .rotationEffect(.degrees(8))
            }
            .opacity(isAnimating ? 1 : 0)
            .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.5), value: isAnimating)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulseScale = 1.05
            }
        }
    }
}

struct AlertBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color)
            .clipShape(Capsule())
            .shadow(color: color.opacity(0.3), radius: 5, y: 2)
    }
}

struct SummaryIllustration: View {
    let color: Color
    let isAnimating: Bool
    @State private var typingProgress: CGFloat = 0

    var body: some View {
        ZStack {
            // Background
            Circle()
                .fill(color.opacity(0.1))
                .frame(width: 200, height: 200)

            // Document card
            RoundedRectangle(cornerRadius: 20)
                .fill(DesignSystem.Colors.surface)
                .frame(width: 180, height: 220)
                .shadow(color: color.opacity(0.2), radius: 20, y: 10)
                .overlay {
                    VStack(alignment: .leading, spacing: 12) {
                        // Header
                        HStack {
                            Circle()
                                .fill(color)
                                .frame(width: 8, height: 8)
                            Text("AI Summary")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(color)
                        }

                        // Animated text lines
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(0..<4, id: \.self) { index in
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(DesignSystem.Colors.surfaceSecondary)
                                    .frame(
                                        width: CGFloat([120, 140, 100, 80][index]) * (typingProgress > CGFloat(index) * 0.25 ? 1 : 0),
                                        height: 10
                                    )
                                    .animation(.easeOut(duration: 0.5).delay(Double(index) * 0.2), value: typingProgress)
                            }
                        }

                        Spacer()

                        // Brain icon
                        HStack {
                            Spacer()
                            Image(systemName: "brain")
                                .font(.system(size: 24))
                                .foregroundStyle(
                                    LinearGradient(colors: [color, color.opacity(0.5)], startPoint: .top, endPoint: .bottom)
                                )
                            Spacer()
                        }
                    }
                    .padding(20)
                }

            // Sparkles
            ForEach(0..<5, id: \.self) { index in
                Image(systemName: "sparkle")
                    .font(.system(size: [12, 16, 10, 14, 8][index]))
                    .foregroundColor(color)
                    .offset(
                        x: CGFloat([-70, 80, -50, 60, 90][index]),
                        y: CGFloat([-80, -60, 70, 90, -30][index])
                    )
                    .opacity(isAnimating ? 1 : 0)
                    .scaleEffect(isAnimating ? 1 : 0)
                    .animation(
                        .spring(response: 0.5, dampingFraction: 0.5)
                        .delay(Double(index) * 0.1 + 0.5),
                        value: isAnimating
                    )
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 2).delay(0.3)) {
                typingProgress = 1
            }
        }
    }
}

struct SecurityIllustration: View {
    let color: Color
    let isAnimating: Bool
    @State private var lockScale: CGFloat = 1
    @State private var shieldRotation: Double = 0

    var body: some View {
        ZStack {
            // Rotating ring
            Circle()
                .stroke(
                    AngularGradient(
                        colors: [color.opacity(0.3), color, color.opacity(0.3)],
                        center: .center
                    ),
                    lineWidth: 3
                )
                .frame(width: 200, height: 200)
                .rotationEffect(.degrees(shieldRotation))

            // Inner elements
            ZStack {
                // Lock body
                RoundedRectangle(cornerRadius: 8)
                    .fill(color)
                    .frame(width: 60, height: 50)
                    .offset(y: 15)

                // Lock shackle
                Circle()
                    .stroke(color, lineWidth: 8)
                    .frame(width: 40, height: 40)
                    .offset(y: -15)
                    .mask {
                        Rectangle()
                            .frame(width: 50, height: 30)
                            .offset(y: -15)
                    }

                // Keyhole
                Circle()
                    .fill(DesignSystem.Colors.surface)
                    .frame(width: 12, height: 12)
                    .offset(y: 10)

                Rectangle()
                    .fill(DesignSystem.Colors.surface)
                    .frame(width: 6, height: 15)
                    .offset(y: 22)
            }
            .shadow(color: color.opacity(0.4), radius: 20, y: 10)
            .scaleEffect(lockScale)

            // Checkmark badges
            ForEach(0..<3, id: \.self) { index in
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 14))
                    Text(["HIPAA", "ENCRYPTED", "SECURE"][index])
                        .font(.system(size: 8, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(color)
                .clipShape(Capsule())
                .offset(
                    x: CGFloat([-80, 70, -60][index]),
                    y: CGFloat([-70, -20, 80][index])
                )
                .opacity(isAnimating ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(Double(index) * 0.2 + 0.4), value: isAnimating)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                shieldRotation = 360
            }
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                lockScale = 1.05
            }
        }
    }
}

// MARK: - Preview
#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
        .environmentObject(AppState())
}
