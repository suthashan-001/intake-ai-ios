import SwiftUI

// MARK: - Success Animation
struct IASuccessAnimation: View {
    @State private var showCircle = false
    @State private var showCheckmark = false
    @State private var showPulse = false

    let size: CGFloat
    let color: Color
    let onComplete: (() -> Void)?

    init(size: CGFloat = 100, color: Color = DesignSystem.Colors.success, onComplete: (() -> Void)? = nil) {
        self.size = size
        self.color = color
        self.onComplete = onComplete
    }

    var body: some View {
        ZStack {
            // Pulse rings
            ForEach(0..<3) { index in
                Circle()
                    .stroke(color.opacity(0.3 - Double(index) * 0.1), lineWidth: 2)
                    .frame(width: size + CGFloat(index) * 30, height: size + CGFloat(index) * 30)
                    .scaleEffect(showPulse ? 1.2 : 0.8)
                    .opacity(showPulse ? 0 : 1)
                    .animation(
                        .easeOut(duration: 1.0)
                        .delay(Double(index) * 0.15)
                        .repeatCount(1, autoreverses: false),
                        value: showPulse
                    )
            }

            // Background circle
            Circle()
                .fill(color)
                .frame(width: size, height: size)
                .scaleEffect(showCircle ? 1 : 0)
                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: showCircle)

            // Checkmark
            CheckmarkShape()
                .trim(from: 0, to: showCheckmark ? 1 : 0)
                .stroke(Color.white, style: StrokeStyle(lineWidth: size * 0.08, lineCap: .round, lineJoin: .round))
                .frame(width: size * 0.45, height: size * 0.45)
                .offset(y: size * 0.02)
                .animation(.easeOut(duration: 0.4).delay(0.2), value: showCheckmark)
        }
        .onAppear {
            showCircle = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                showCheckmark = true
                showPulse = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                onComplete?()
            }
        }
    }
}

// MARK: - Error Animation
struct IAErrorAnimation: View {
    @State private var showCircle = false
    @State private var showX = false
    @State private var shake = false

    let size: CGFloat
    let color: Color
    let onComplete: (() -> Void)?

    init(size: CGFloat = 100, color: Color = DesignSystem.Colors.error, onComplete: (() -> Void)? = nil) {
        self.size = size
        self.color = color
        self.onComplete = onComplete
    }

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(color)
                .frame(width: size, height: size)
                .scaleEffect(showCircle ? 1 : 0)
                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: showCircle)

            // X mark
            XMarkShape()
                .trim(from: 0, to: showX ? 1 : 0)
                .stroke(Color.white, style: StrokeStyle(lineWidth: size * 0.08, lineCap: .round, lineJoin: .round))
                .frame(width: size * 0.35, height: size * 0.35)
                .animation(.easeOut(duration: 0.3).delay(0.2), value: showX)
        }
        .offset(x: shake ? -10 : 0)
        .animation(
            shake ? Animation.linear(duration: 0.08).repeatCount(5, autoreverses: true) : .default,
            value: shake
        )
        .onAppear {
            showCircle = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                showX = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                shake = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                onComplete?()
            }
        }
    }
}

// MARK: - Warning Animation
struct IAWarningAnimation: View {
    @State private var showTriangle = false
    @State private var showExclamation = false
    @State private var bounce = false

    let size: CGFloat
    let color: Color
    let onComplete: (() -> Void)?

    init(size: CGFloat = 100, color: Color = DesignSystem.Colors.warning, onComplete: (() -> Void)? = nil) {
        self.size = size
        self.color = color
        self.onComplete = onComplete
    }

    var body: some View {
        ZStack {
            // Triangle background
            TriangleShape()
                .fill(color)
                .frame(width: size, height: size * 0.9)
                .scaleEffect(showTriangle ? 1 : 0)
                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: showTriangle)

            // Exclamation mark
            VStack(spacing: size * 0.06) {
                RoundedRectangle(cornerRadius: size * 0.03)
                    .fill(Color.white)
                    .frame(width: size * 0.08, height: size * 0.3)

                Circle()
                    .fill(Color.white)
                    .frame(width: size * 0.1, height: size * 0.1)
            }
            .offset(y: size * 0.08)
            .opacity(showExclamation ? 1 : 0)
            .scaleEffect(showExclamation ? 1 : 0.5)
            .animation(.spring(response: 0.3, dampingFraction: 0.5).delay(0.2), value: showExclamation)
        }
        .offset(y: bounce ? -5 : 0)
        .animation(
            bounce ? Animation.easeInOut(duration: 0.15).repeatCount(3, autoreverses: true) : .default,
            value: bounce
        )
        .onAppear {
            showTriangle = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                showExclamation = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                bounce = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                onComplete?()
            }
        }
    }
}

// MARK: - Loading Animation
struct IALoadingAnimation: View {
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 1

    let size: CGFloat
    let color: Color

    init(size: CGFloat = 50, color: Color = DesignSystem.Colors.primary) {
        self.size = size
        self.color = color
    }

    var body: some View {
        ZStack {
            // Outer spinning ring
            Circle()
                .trim(from: 0, to: 0.7)
                .stroke(color, style: StrokeStyle(lineWidth: size * 0.08, lineCap: .round))
                .frame(width: size, height: size)
                .rotationEffect(.degrees(rotation))

            // Inner pulsing circle
            Circle()
                .fill(color.opacity(0.3))
                .frame(width: size * 0.4, height: size * 0.4)
                .scaleEffect(scale)
        }
        .onAppear {
            withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                rotation = 360
            }
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                scale = 1.2
            }
        }
    }
}

// MARK: - Sending Animation (for messages/links)
struct IASendingAnimation: View {
    @State private var offset: CGFloat = 0
    @State private var opacity: Double = 1
    @State private var scale: CGFloat = 1

    let size: CGFloat
    let color: Color

    init(size: CGFloat = 60, color: Color = DesignSystem.Colors.primary) {
        self.size = size
        self.color = color
    }

    var body: some View {
        ZStack {
            // Paper plane
            Image(systemName: "paperplane.fill")
                .font(.system(size: size * 0.5))
                .foregroundColor(color)
                .offset(x: offset, y: -offset * 0.5)
                .opacity(opacity)
                .scaleEffect(scale)

            // Trail dots
            ForEach(0..<3) { index in
                Circle()
                    .fill(color.opacity(0.3 - Double(index) * 0.1))
                    .frame(width: size * 0.1, height: size * 0.1)
                    .offset(x: offset - CGFloat(index + 1) * 15, y: (-offset * 0.5) + CGFloat(index + 1) * 7.5)
                    .opacity(opacity)
            }
        }
        .onAppear {
            withAnimation(.easeIn(duration: 0.8).repeatForever(autoreverses: false)) {
                offset = 100
                opacity = 0
                scale = 0.8
            }
        }
    }
}

// MARK: - Confetti Animation
struct IAConfettiAnimation: View {
    @State private var particles: [ConfettiParticle] = []

    let colors: [Color]
    let particleCount: Int

    init(colors: [Color] = [.red, .blue, .green, .yellow, .orange, .purple, .pink], particleCount: Int = 50) {
        self.colors = colors
        self.particleCount = particleCount
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    ConfettiPiece(particle: particle)
                }
            }
            .onAppear {
                createParticles(in: geometry.size)
            }
        }
    }

    private func createParticles(in size: CGSize) {
        particles = (0..<particleCount).map { _ in
            ConfettiParticle(
                color: colors.randomElement() ?? .red,
                startX: size.width / 2,
                startY: size.height / 2,
                endX: CGFloat.random(in: 0...size.width),
                endY: CGFloat.random(in: 0...size.height),
                rotation: Double.random(in: 0...720),
                scale: CGFloat.random(in: 0.5...1.5)
            )
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id = UUID()
    let color: Color
    let startX: CGFloat
    let startY: CGFloat
    let endX: CGFloat
    let endY: CGFloat
    let rotation: Double
    let scale: CGFloat
}

struct ConfettiPiece: View {
    let particle: ConfettiParticle
    @State private var animate = false

    var body: some View {
        Rectangle()
            .fill(particle.color)
            .frame(width: 8, height: 12)
            .position(x: animate ? particle.endX : particle.startX, y: animate ? particle.endY : particle.startY)
            .rotationEffect(.degrees(animate ? particle.rotation : 0))
            .scaleEffect(animate ? particle.scale : 0)
            .opacity(animate ? 0 : 1)
            .onAppear {
                withAnimation(.easeOut(duration: 1.5)) {
                    animate = true
                }
            }
    }
}

// MARK: - Shape Definitions
struct CheckmarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height

        path.move(to: CGPoint(x: 0, y: height * 0.5))
        path.addLine(to: CGPoint(x: width * 0.35, y: height))
        path.addLine(to: CGPoint(x: width, y: 0))

        return path
    }
}

struct XMarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        // First line (top-left to bottom-right)
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))

        // Second line (top-right to bottom-left)
        path.move(to: CGPoint(x: rect.width, y: 0))
        path.addLine(to: CGPoint(x: 0, y: rect.height))

        return path
    }
}

struct TriangleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: rect.midX, y: 0))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: 0, y: rect.maxY))
        path.closeSubpath()

        return path
    }
}

// MARK: - Animated Toast
struct IAAnimatedToast: View {
    enum ToastType {
        case success, error, warning, info

        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .error: return "xmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .info: return "info.circle.fill"
            }
        }

        var color: Color {
            switch self {
            case .success: return DesignSystem.Colors.success
            case .error: return DesignSystem.Colors.error
            case .warning: return DesignSystem.Colors.warning
            case .info: return DesignSystem.Colors.primary
            }
        }
    }

    let type: ToastType
    let message: String
    @Binding var isVisible: Bool

    @State private var offset: CGFloat = -100
    @State private var opacity: Double = 0

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: type.icon)
                .font(.system(size: 20))
                .foregroundColor(type.color)

            Text(message)
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.textPrimary)
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.vertical, DesignSystem.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.lg)
                .fill(DesignSystem.Colors.surface)
                .shadow(color: .black.opacity(0.15), radius: 10, y: 5)
        )
        .offset(y: offset)
        .opacity(opacity)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                offset = 0
                opacity = 1
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.easeIn(duration: 0.3)) {
                    offset = -100
                    opacity = 0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isVisible = false
                }
            }
        }
    }
}

// MARK: - Full Screen Feedback Overlay
struct IAFeedbackOverlay: View {
    enum FeedbackType {
        case success(message: String)
        case error(message: String)
        case warning(message: String)
    }

    let type: FeedbackType
    @Binding var isVisible: Bool
    let onDismiss: (() -> Void)?

    init(type: FeedbackType, isVisible: Binding<Bool>, onDismiss: (() -> Void)? = nil) {
        self.type = type
        self._isVisible = isVisible
        self.onDismiss = onDismiss
    }

    @State private var showContent = false

    var body: some View {
        ZStack {
            // Backdrop
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .opacity(showContent ? 1 : 0)
                .onTapGesture {
                    dismiss()
                }

            // Content card
            VStack(spacing: DesignSystem.Spacing.lg) {
                switch type {
                case .success(let message):
                    IASuccessAnimation(size: 80)
                    Text(message)
                        .font(DesignSystem.Typography.headline)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .multilineTextAlignment(.center)

                case .error(let message):
                    IAErrorAnimation(size: 80)
                    Text(message)
                        .font(DesignSystem.Typography.headline)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .multilineTextAlignment(.center)

                case .warning(let message):
                    IAWarningAnimation(size: 80)
                    Text(message)
                        .font(DesignSystem.Typography.headline)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(DesignSystem.Spacing.xl)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.xl)
                    .fill(DesignSystem.Colors.surface)
            )
            .padding(.horizontal, DesignSystem.Spacing.xl)
            .scaleEffect(showContent ? 1 : 0.8)
            .opacity(showContent ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                showContent = true
            }

            // Auto dismiss after animation completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                dismiss()
            }
        }
    }

    private func dismiss() {
        withAnimation(.easeIn(duration: 0.2)) {
            showContent = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            isVisible = false
            onDismiss?()
        }
    }
}

// MARK: - View Extension for Easy Toast Usage
extension View {
    func toast(isPresented: Binding<Bool>, type: IAAnimatedToast.ToastType, message: String) -> some View {
        ZStack(alignment: .top) {
            self

            if isPresented.wrappedValue {
                IAAnimatedToast(type: type, message: message, isVisible: isPresented)
                    .padding(.top, 50)
                    .zIndex(100)
            }
        }
    }

    func feedbackOverlay(isPresented: Binding<Bool>, type: IAFeedbackOverlay.FeedbackType, onDismiss: (() -> Void)? = nil) -> some View {
        ZStack {
            self

            if isPresented.wrappedValue {
                IAFeedbackOverlay(type: type, isVisible: isPresented, onDismiss: onDismiss)
                    .zIndex(100)
            }
        }
    }
}

// MARK: - Preview
#Preview("Success Animation") {
    IASuccessAnimation()
}

#Preview("Error Animation") {
    IAErrorAnimation()
}

#Preview("Warning Animation") {
    IAWarningAnimation()
}

#Preview("Loading Animation") {
    IALoadingAnimation()
}

#Preview("Toast Demo") {
    VStack {
        Text("Toast Demo")
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .toast(isPresented: .constant(true), type: .success, message: "Action completed successfully!")
}
