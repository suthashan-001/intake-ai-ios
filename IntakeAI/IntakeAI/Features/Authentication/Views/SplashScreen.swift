import SwiftUI

struct SplashScreen: View {
    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var pulseScale: CGFloat = 1

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(hex: "F8FAF9"),
                    Color(hex: "E8F0EC")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: DesignSystem.Spacing.xl) {
                Spacer()

                // Logo with pulse effect
                ZStack {
                    // Pulse circles
                    Circle()
                        .fill(DesignSystem.Colors.primary.opacity(0.1))
                        .frame(width: 160, height: 160)
                        .scaleEffect(pulseScale)
                        .opacity(2 - pulseScale)

                    Circle()
                        .fill(DesignSystem.Colors.primary.opacity(0.15))
                        .frame(width: 120, height: 120)

                    // Logo icon
                    ZStack {
                        // Heart with AI pulse
                        Image(systemName: "heart.text.square.fill")
                            .font(.system(size: 56, weight: .medium))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(hex: "4A7C59"), Color(hex: "6B9B7A")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)

                // App name
                VStack(spacing: DesignSystem.Spacing.xs) {
                    Text("IntakeAI")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(DesignSystem.Colors.textPrimary)

                    Text("AI-Powered Patient Intake")
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                .opacity(textOpacity)

                Spacer()
                Spacer()

                // Loading indicator
                HStack(spacing: DesignSystem.Spacing.sm) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: DesignSystem.Colors.primary))
                        .scaleEffect(0.8)

                    Text("Loading...")
                        .font(DesignSystem.Typography.bodySmall)
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                }
                .opacity(textOpacity)
                .padding(.bottom, DesignSystem.Spacing.huge)
            }
        }
        .onAppear {
            // Animate logo
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                logoScale = 1
                logoOpacity = 1
            }

            // Animate text
            withAnimation(.easeOut(duration: 0.4).delay(0.4)) {
                textOpacity = 1
            }

            // Pulse animation
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                pulseScale = 1.5
            }
        }
    }
}

#Preview {
    SplashScreen()
}
