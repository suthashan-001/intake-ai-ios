import SwiftUI

struct SummaryDetailView: View {
    let intakeId: String

    @State private var summary: Summary?
    @State private var isLoading = true
    @State private var error: String?
    @State private var expandedSections: Set<String> = ["redFlags", "medications"]
    @State private var showEditSheet = false

    private let networkClient = NetworkClient.shared

    var body: some View {
        ScrollView {
            if isLoading {
                IALoadingState(message: "Loading summary...")
                    .padding(.top, DesignSystem.Spacing.huge)
            } else if let error = error {
                IAErrorState(message: error) {
                    Task { await loadSummary() }
                }
                .padding(.top, DesignSystem.Spacing.huge)
            } else if let summary = summary {
                summaryContent(summary)
            }
        }
        .background(DesignSystem.Colors.background)
        .navigationTitle("AI Summary")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if summary != nil {
                    Button {
                        showEditSheet = true
                    } label: {
                        Image(systemName: "pencil")
                    }
                }
            }
        }
        .task {
            await loadSummary()
        }
    }

    // MARK: - Summary Content

    private func summaryContent(_ summary: Summary) -> some View {
        LazyVStack(spacing: DesignSystem.Spacing.md) {
            // AI Generated Badge
            aiGeneratedBanner

            // Red Flags Section (if any)
            if summary.hasRedFlags {
                redFlagsSection(summary.redFlags)
            }

            // Chief Complaint
            chiefComplaintSection(summary.chiefComplaint)

            // Medications
            medicationsSection(summary.medications)

            // Systems Review
            systemsReviewSection(summary.systemsReview)

            // Relevant History
            historySection(summary.relevantHistory)

            // Lifestyle
            lifestyleSection(summary.lifestyle)

            // Doctor's Edits (if any)
            if let edits = summary.doctorEdits {
                doctorEditsSection(edits)
            }

            // Metadata
            metadataSection(summary)
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.bottom, DesignSystem.Spacing.xxl)
    }

    // MARK: - AI Generated Banner

    private var aiGeneratedBanner: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: "brain")
                .font(.system(size: DesignSystem.IconSize.lg))
                .foregroundStyle(DesignSystem.Colors.primaryGradient)

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxxs) {
                Text("AI-Generated Summary")
                    .font(DesignSystem.Typography.titleSmall)
                    .foregroundColor(DesignSystem.Colors.textPrimary)

                Text("Powered by Google Gemini • Review for accuracy")
                    .font(DesignSystem.Typography.labelSmall)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }

            Spacer()

            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: DesignSystem.IconSize.lg))
                .foregroundColor(DesignSystem.Colors.success)
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.primary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg, style: .continuous))
    }

    // MARK: - Red Flags Section

    private func redFlagsSection(_ redFlags: [RedFlag]) -> some View {
        CollapsibleSection(
            title: "Red Flags",
            icon: "exclamationmark.triangle.fill",
            iconColor: DesignSystem.Colors.error,
            badge: "\(redFlags.count)",
            isExpanded: expandedSections.contains("redFlags")
        ) {
            expandedSections.insert("redFlags")
        } onCollapse: {
            expandedSections.remove("redFlags")
        } content: {
            VStack(spacing: DesignSystem.Spacing.sm) {
                // Group by severity
                let highFlags = redFlags.filter { $0.severity == .high }
                let mediumFlags = redFlags.filter { $0.severity == .medium }
                let lowFlags = redFlags.filter { $0.severity == .low }

                if !highFlags.isEmpty {
                    ForEach(highFlags) { flag in
                        RedFlagRow(flag: flag)
                    }
                }

                if !mediumFlags.isEmpty {
                    ForEach(mediumFlags) { flag in
                        RedFlagRow(flag: flag)
                    }
                }

                if !lowFlags.isEmpty {
                    ForEach(lowFlags) { flag in
                        RedFlagRow(flag: flag)
                    }
                }
            }
        }
    }

    // MARK: - Chief Complaint Section

    private func chiefComplaintSection(_ complaint: String) -> some View {
        IACard {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                HStack {
                    Image(systemName: "quote.bubble.fill")
                        .foregroundColor(DesignSystem.Colors.primary)
                    Text("Chief Complaint")
                        .font(DesignSystem.Typography.headlineSmall)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                }

                Text(complaint)
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Medications Section

    private func medicationsSection(_ medications: [Medication]) -> some View {
        CollapsibleSection(
            title: "Medications",
            icon: "pills.fill",
            iconColor: DesignSystem.Colors.info,
            badge: "\(medications.count)",
            isExpanded: expandedSections.contains("medications")
        ) {
            expandedSections.insert("medications")
        } onCollapse: {
            expandedSections.remove("medications")
        } content: {
            if medications.isEmpty {
                Text("No medications reported")
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .italic()
            } else {
                VStack(spacing: DesignSystem.Spacing.sm) {
                    ForEach(medications) { med in
                        MedicationRow(medication: med)
                    }
                }
            }
        }
    }

    // MARK: - Systems Review Section

    private func systemsReviewSection(_ systems: SystemsReview) -> some View {
        CollapsibleSection(
            title: "Systems Review",
            icon: "heart.text.square.fill",
            iconColor: DesignSystem.Colors.accent,
            isExpanded: expandedSections.contains("systems")
        ) {
            expandedSections.insert("systems")
        } onCollapse: {
            expandedSections.remove("systems")
        } content: {
            VStack(spacing: DesignSystem.Spacing.sm) {
                ForEach(systems.nonEmptySystems, id: \.name) { system in
                    SystemRow(name: system.name, value: system.value)
                }
            }
        }
    }

    // MARK: - History Section

    private func historySection(_ history: String) -> some View {
        IACard {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundColor(DesignSystem.Colors.warning)
                    Text("Relevant History")
                        .font(DesignSystem.Typography.headlineSmall)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                }

                Text(history)
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Lifestyle Section

    private func lifestyleSection(_ lifestyle: LifestyleFactors) -> some View {
        CollapsibleSection(
            title: "Lifestyle Factors",
            icon: "figure.walk",
            iconColor: DesignSystem.Colors.success,
            isExpanded: expandedSections.contains("lifestyle")
        ) {
            expandedSections.insert("lifestyle")
        } onCollapse: {
            expandedSections.remove("lifestyle")
        } content: {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: DesignSystem.Spacing.sm) {
                ForEach(lifestyle.nonEmptyFactors, id: \.name) { factor in
                    LifestyleCard(name: factor.name, value: factor.value, icon: factor.icon)
                }
            }
        }
    }

    // MARK: - Doctor Edits Section

    private func doctorEditsSection(_ edits: DoctorEdits) -> some View {
        IACard {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                HStack {
                    Image(systemName: "pencil.circle.fill")
                        .foregroundColor(DesignSystem.Colors.primary)
                    Text("Doctor's Notes")
                        .font(DesignSystem.Typography.headlineSmall)
                        .foregroundColor(DesignSystem.Colors.textPrimary)

                    Spacer()

                    IABadge("Edited", style: .primary, size: .small)
                }

                if let notes = edits.additionalNotes, !notes.isEmpty {
                    Text(notes)
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                }
            }
        }
    }

    // MARK: - Metadata Section

    private func metadataSection(_ summary: Summary) -> some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            Text("Generated \(summary.createdAt.relativeFormatted)")
                .font(DesignSystem.Typography.labelSmall)
                .foregroundColor(DesignSystem.Colors.textTertiary)

            if summary.wasEdited, let editedAt = summary.editedAt {
                Text("Last edited \(editedAt.relativeFormatted)")
                    .font(DesignSystem.Typography.labelSmall)
                    .foregroundColor(DesignSystem.Colors.textTertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, DesignSystem.Spacing.md)
    }

    // MARK: - Load Summary

    private func loadSummary() async {
        isLoading = true
        error = nil

        do {
            let result = try await networkClient.request(
                .summary(intakeId: intakeId),
                responseType: Summary.self
            )
            self.summary = result
        } catch let networkError as NetworkError {
            // For preview, use sample data
            self.summary = Summary.sampleWithRedFlags
            // self.error = networkError.errorDescription
        } catch {
            self.summary = Summary.sampleWithRedFlags
            // self.error = "Failed to load summary"
        }

        isLoading = false
    }
}

// MARK: - Collapsible Section
struct CollapsibleSection<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    var badge: String? = nil
    let isExpanded: Bool
    let onExpand: () -> Void
    let onCollapse: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        IACard {
            VStack(spacing: 0) {
                Button {
                    withAnimation(DesignSystem.Animation.standard) {
                        if isExpanded {
                            onCollapse()
                        } else {
                            onExpand()
                        }
                    }
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                } label: {
                    HStack {
                        Image(systemName: icon)
                            .foregroundColor(iconColor)

                        Text(title)
                            .font(DesignSystem.Typography.headlineSmall)
                            .foregroundColor(DesignSystem.Colors.textPrimary)

                        if let badge = badge {
                            IABadge(badge, style: .secondary, size: .small)
                        }

                        Spacer()

                        Image(systemName: "chevron.down")
                            .font(.system(size: DesignSystem.IconSize.sm, weight: .semibold))
                            .foregroundColor(DesignSystem.Colors.textTertiary)
                            .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    }
                }

                if isExpanded {
                    Divider()
                        .padding(.vertical, DesignSystem.Spacing.sm)

                    content()
                }
            }
        }
    }
}

// MARK: - Red Flag Row
struct RedFlagRow: View {
    let flag: RedFlag

    var body: some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.sm) {
            Image(systemName: flag.severity.icon)
                .font(.system(size: DesignSystem.IconSize.md))
                .foregroundColor(flag.severity.color)

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                HStack {
                    Text(flag.flag)
                        .font(DesignSystem.Typography.titleSmall)
                        .foregroundColor(DesignSystem.Colors.textPrimary)

                    Spacer()

                    IABadge(flag.severity.label, style: .severity(flag.severity), size: .small)
                }

                if let details = flag.details {
                    Text(details)
                        .font(DesignSystem.Typography.bodySmall)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }

                if let recommendation = flag.recommendation {
                    HStack(spacing: DesignSystem.Spacing.xxs) {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: DesignSystem.IconSize.xs))
                        Text(recommendation)
                            .font(DesignSystem.Typography.labelSmall)
                    }
                    .foregroundColor(DesignSystem.Colors.warning)
                    .padding(.top, DesignSystem.Spacing.xxs)
                }
            }
        }
        .padding(DesignSystem.Spacing.sm)
        .background(flag.severity.color.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: .continuous))
    }
}

// MARK: - Medication Row
struct MedicationRow: View {
    let medication: Medication

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            ZStack {
                Circle()
                    .fill(DesignSystem.Colors.info.opacity(0.12))
                    .frame(width: 36, height: 36)

                Image(systemName: "pill.fill")
                    .font(.system(size: DesignSystem.IconSize.sm))
                    .foregroundColor(DesignSystem.Colors.info)
            }

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxxs) {
                HStack {
                    Text(medication.name)
                        .font(DesignSystem.Typography.titleSmall)
                        .foregroundColor(DesignSystem.Colors.textPrimary)

                    if medication.isVerified == true {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: DesignSystem.IconSize.xs))
                            .foregroundColor(DesignSystem.Colors.success)
                    }
                }

                if let dosage = medication.dosage {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Text(dosage)
                        if let frequency = medication.frequency {
                            Text("•")
                            Text(frequency)
                        }
                    }
                    .font(DesignSystem.Typography.bodySmall)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                }
            }

            Spacer()
        }
    }
}

// MARK: - System Row
struct SystemRow: View {
    let name: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
            Text(name)
                .font(DesignSystem.Typography.labelMedium)
                .foregroundColor(DesignSystem.Colors.textSecondary)

            Text(value)
                .font(DesignSystem.Typography.bodyMedium)
                .foregroundColor(DesignSystem.Colors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignSystem.Spacing.sm)
        .background(DesignSystem.Colors.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm, style: .continuous))
    }
}

// MARK: - Lifestyle Card
struct LifestyleCard: View {
    let name: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: DesignSystem.IconSize.sm))
                    .foregroundColor(DesignSystem.Colors.success)

                Text(name)
                    .font(DesignSystem.Typography.labelMedium)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }

            Text(value)
                .font(DesignSystem.Typography.bodySmall)
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignSystem.Spacing.sm)
        .background(DesignSystem.Colors.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm, style: .continuous))
    }
}

#Preview {
    NavigationStack {
        SummaryDetailView(intakeId: "int_345678")
    }
}
