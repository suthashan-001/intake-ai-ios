import SwiftUI

// MARK: - AI Summary Generation View
/// Animated view for generating AI summaries with streaming text effect
/// Business Logic: Doctor clicks "Generate AI Summary" → AI processes via Google Gemini
/// → Returns structured summary in ~3-5 seconds with streaming animation
struct AISummaryGenerationView: View {
    let intakeId: String
    let patientName: String
    let onComplete: (Summary) -> Void
    let onCancel: () -> Void

    @State private var currentStep = 0
    @State private var progress: Double = 0
    @State private var streamedText = ""
    @State private var detectedRedFlags: [StreamingRedFlag] = []
    @State private var isComplete = false
    @State private var generatedSummary: Summary?

    private let steps = [
        GenerationStep(icon: "doc.text.magnifyingglass", title: "Reading Intake Form", duration: 1.2),
        GenerationStep(icon: "brain", title: "Analyzing Content", duration: 1.5),
        GenerationStep(icon: "exclamationmark.triangle", title: "Scanning for Red Flags", duration: 1.0),
        GenerationStep(icon: "list.bullet.clipboard", title: "Generating Summary", duration: 1.8),
        GenerationStep(icon: "checkmark.seal", title: "Validating Results", duration: 0.8)
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            header

            // Main content
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.lg) {
                    // Progress steps
                    progressSteps

                    // Streaming preview
                    if currentStep >= 2 {
                        streamingPreview
                    }

                    // Red flags detected
                    if !detectedRedFlags.isEmpty {
                        redFlagsDetected
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.vertical, DesignSystem.Spacing.lg)
            }

            // Bottom action
            if isComplete {
                completeAction
            }
        }
        .background(DesignSystem.Colors.background)
        .onAppear {
            startGeneration()
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            HStack {
                Button("Cancel") {
                    onCancel()
                }
                .foregroundColor(DesignSystem.Colors.textSecondary)

                Spacer()

                if !isComplete {
                    Text("\(Int(progress * 100))%")
                        .font(DesignSystem.Typography.titleSmall)
                        .foregroundColor(DesignSystem.Colors.primary)
                        .monospacedDigit()
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.top, DesignSystem.Spacing.md)

            // Animated brain icon
            ZStack {
                // Pulsing background
                Circle()
                    .fill(DesignSystem.Colors.primary.opacity(0.1))
                    .frame(width: 100, height: 100)
                    .scaleEffect(isComplete ? 1 : 1.2)
                    .opacity(isComplete ? 1 : 0.5)
                    .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: isComplete)

                Circle()
                    .fill(DesignSystem.Colors.primary.opacity(0.2))
                    .frame(width: 80, height: 80)

                if isComplete {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(DesignSystem.Colors.success)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Image(systemName: "brain")
                        .font(.system(size: 40))
                        .foregroundStyle(DesignSystem.Colors.primaryGradient)
                        .symbolEffect(.pulse, options: .repeating)
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isComplete)

            Text(isComplete ? "Summary Generated!" : "Generating AI Summary")
                .font(DesignSystem.Typography.headlineMedium)
                .foregroundColor(DesignSystem.Colors.textPrimary)

            Text(isComplete ? "Review the summary for \(patientName)" : "Analyzing intake for \(patientName)")
                .font(DesignSystem.Typography.bodySmall)
                .foregroundColor(DesignSystem.Colors.textSecondary)

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(DesignSystem.Colors.surfaceSecondary)
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [DesignSystem.Colors.primary, DesignSystem.Colors.primaryLight],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * progress, height: 8)
                }
            }
            .frame(height: 8)
            .padding(.horizontal, DesignSystem.Spacing.xl)
            .padding(.top, DesignSystem.Spacing.sm)
        }
        .padding(.bottom, DesignSystem.Spacing.lg)
        .background(DesignSystem.Colors.surface)
    }

    // MARK: - Progress Steps

    private var progressSteps: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                HStack(spacing: DesignSystem.Spacing.md) {
                    // Step indicator
                    ZStack {
                        Circle()
                            .fill(stepColor(for: index).opacity(0.15))
                            .frame(width: 44, height: 44)

                        if index < currentStep {
                            Image(systemName: "checkmark")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(DesignSystem.Colors.success)
                        } else if index == currentStep {
                            Image(systemName: step.icon)
                                .font(.system(size: 18))
                                .foregroundColor(DesignSystem.Colors.primary)
                                .symbolEffect(.pulse, options: .repeating)
                        } else {
                            Image(systemName: step.icon)
                                .font(.system(size: 18))
                                .foregroundColor(DesignSystem.Colors.textTertiary)
                        }
                    }

                    // Step info
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxxs) {
                        Text(step.title)
                            .font(DesignSystem.Typography.titleSmall)
                            .foregroundColor(stepColor(for: index))

                        if index == currentStep && !isComplete {
                            Text("Processing...")
                                .font(DesignSystem.Typography.labelSmall)
                                .foregroundColor(DesignSystem.Colors.primary)
                        } else if index < currentStep {
                            Text("Complete")
                                .font(DesignSystem.Typography.labelSmall)
                                .foregroundColor(DesignSystem.Colors.success)
                        }
                    }

                    Spacer()

                    // Timing
                    if index < currentStep {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(DesignSystem.Colors.success)
                    }
                }
                .padding(DesignSystem.Spacing.sm)
                .background(index == currentStep ? DesignSystem.Colors.primary.opacity(0.05) : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
            }
        }
    }

    private func stepColor(for index: Int) -> Color {
        if index < currentStep {
            return DesignSystem.Colors.success
        } else if index == currentStep {
            return DesignSystem.Colors.primary
        } else {
            return DesignSystem.Colors.textTertiary
        }
    }

    // MARK: - Streaming Preview

    private var streamingPreview: some View {
        IACard {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                HStack {
                    Image(systemName: "text.bubble")
                        .foregroundColor(DesignSystem.Colors.primary)
                    Text("Summary Preview")
                        .font(DesignSystem.Typography.titleSmall)
                        .foregroundColor(DesignSystem.Colors.textPrimary)

                    Spacer()

                    if !isComplete {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }

                // Streaming text
                Text(streamedText)
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)

                if !isComplete && !streamedText.isEmpty {
                    // Typing cursor
                    Rectangle()
                        .fill(DesignSystem.Colors.primary)
                        .frame(width: 2, height: 16)
                        .opacity(0.8)
                        .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: streamedText)
                }
            }
        }
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    // MARK: - Red Flags Detected

    private var redFlagsDetected: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(DesignSystem.Colors.error)
                Text("Red Flags Detected")
                    .font(DesignSystem.Typography.titleSmall)
                    .foregroundColor(DesignSystem.Colors.error)

                Spacer()

                Text("\(detectedRedFlags.count)")
                    .font(DesignSystem.Typography.titleSmall)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(DesignSystem.Colors.error)
                    .clipShape(Capsule())
            }

            ForEach(detectedRedFlags) { flag in
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Circle()
                        .fill(flag.severity.color)
                        .frame(width: 8, height: 8)

                    Text(flag.text)
                        .font(DesignSystem.Typography.bodySmall)
                        .foregroundColor(DesignSystem.Colors.textPrimary)

                    Spacer()

                    IABadge(flag.severity.label, style: .severity(flag.severity), size: .small)
                }
                .padding(DesignSystem.Spacing.sm)
                .background(flag.severity.color.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm))
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.error.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
        .overlay {
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .stroke(DesignSystem.Colors.error.opacity(0.2), lineWidth: 1)
        }
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    // MARK: - Complete Action

    private var completeAction: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            IAButton("View Summary", style: .primary, icon: "doc.text.fill") {
                if let summary = generatedSummary {
                    onComplete(summary)
                }
            }

            IAButton("Generate Again", style: .secondary, icon: "arrow.clockwise") {
                resetAndRegenerate()
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.vertical, DesignSystem.Spacing.lg)
        .background(DesignSystem.Colors.surface)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Generation Logic

    private func startGeneration() {
        // Simulate AI generation process
        Task {
            for (index, step) in steps.enumerated() {
                currentStep = index

                // Update progress
                let startProgress = Double(index) / Double(steps.count)
                let endProgress = Double(index + 1) / Double(steps.count)

                // Animate progress
                withAnimation(.linear(duration: step.duration)) {
                    progress = endProgress
                }

                // Step-specific animations
                if index == 2 {
                    // Red flag scanning - add flags with delay
                    await simulateRedFlagDetection()
                }

                if index == 3 {
                    // Summary generation - stream text
                    await simulateSummaryStreaming()
                }

                try? await Task.sleep(nanoseconds: UInt64(step.duration * 1_000_000_000))
            }

            // Complete
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                isComplete = true
                generatedSummary = Summary.sampleWithRedFlags
            }
        }
    }

    private func simulateRedFlagDetection() async {
        let sampleFlags = [
            StreamingRedFlag(text: "Chest pain mentioned", severity: .high),
            StreamingRedFlag(text: "Difficulty breathing", severity: .medium)
        ]

        for flag in sampleFlags {
            try? await Task.sleep(nanoseconds: 400_000_000)
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                detectedRedFlags.append(flag)
            }
        }
    }

    private func simulateSummaryStreaming() async {
        let summaryParts = [
            "Patient presents with ",
            "chronic fatigue and ",
            "unexplained weight loss ",
            "over the past 3 months. ",
            "Reports difficulty sleeping ",
            "and occasional chest discomfort. ",
            "Currently taking Lisinopril 10mg daily."
        ]

        for part in summaryParts {
            try? await Task.sleep(nanoseconds: 150_000_000)
            withAnimation(.easeOut(duration: 0.1)) {
                streamedText += part
            }
        }
    }

    private func resetAndRegenerate() {
        currentStep = 0
        progress = 0
        streamedText = ""
        detectedRedFlags = []
        isComplete = false
        generatedSummary = nil
        startGeneration()
    }
}

// MARK: - Supporting Types

struct GenerationStep {
    let icon: String
    let title: String
    let duration: Double
}

struct StreamingRedFlag: Identifiable {
    let id = UUID()
    let text: String
    let severity: RedFlagSeverity
}

// MARK: - Preview

#Preview {
    AISummaryGenerationView(
        intakeId: "int_123",
        patientName: "Sarah Johnson"
    ) { summary in
        print("Complete: \(summary.id)")
    } onCancel: {
        print("Cancelled")
    }
}
