import SwiftUI

// MARK: - Patient Kanban View
/// Apple Health/Fitness-quality kanban dashboard with native iOS interactions
/// Status-based patient monitoring: Pending → Ready for Review → Reviewed
struct PatientKanbanView: View {
    @ObservedObject var viewModel: PatientsViewModel
    @Namespace private var animation
    @State private var selectedStatus: IntakeStatus = .readyForReview
    @State private var selectedPatient: PatientWithDetails?
    @State private var showAISummary = false
    @State private var summaryPatient: PatientWithDetails?

    var body: some View {
        VStack(spacing: 0) {
            // Status tab bar
            statusTabBar

            // Patient list for selected status
            Group {
                if viewModel.isLoading && viewModel.patients.isEmpty {
                    loadingState
                } else {
                    patientContent
                }
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationDestination(item: $selectedPatient) { patient in
            PatientDetailView(patient: patient)
        }
        .sheet(isPresented: $showAISummary) {
            if let patient = summaryPatient {
                AISummaryGenerationView(
                    intakeId: patient.latestIntake?.id ?? "",
                    patientName: patient.patient.fullName
                ) { summary in
                    showAISummary = false
                } onCancel: {
                    showAISummary = false
                }
            }
        }
    }

    // MARK: - Loading State
    private var loadingState: some View {
        ScrollView {
            KanbanColumnSkeleton()
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.top, DesignSystem.Spacing.md)
        }
    }

    // MARK: - Patient Content
    @ViewBuilder
    private var patientContent: some View {
        let patients = patientsForStatus(selectedStatus)

        if patients.isEmpty {
            emptyStateForStatus(selectedStatus)
        } else {
            List {
                Section {
                    ForEach(patients) { patient in
                        KanbanPatientRow(patient: patient)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedPatient = patient
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                // Status-specific trailing actions
                                if selectedStatus == .pending {
                                    Button(role: .destructive) {
                                        // Archive/remove
                                    } label: {
                                        Label("Archive", systemImage: "archivebox")
                                    }

                                    Button {
                                        // Resend link
                                    } label: {
                                        Label("Resend", systemImage: "arrow.clockwise")
                                    }
                                    .tint(DesignSystem.Colors.primary)
                                } else if selectedStatus == .readyForReview {
                                    Button {
                                        // Mark as reviewed
                                        DesignSystem.Haptics.notification(.success)
                                    } label: {
                                        Label("Complete", systemImage: "checkmark.circle")
                                    }
                                    .tint(DesignSystem.Colors.success)

                                    Button {
                                        summaryPatient = patient
                                        showAISummary = true
                                    } label: {
                                        Label("AI Summary", systemImage: "brain")
                                    }
                                    .tint(DesignSystem.Colors.primary)
                                } else if selectedStatus == .expired {
                                    Button {
                                        // Send new link
                                    } label: {
                                        Label("New Link", systemImage: "link.badge.plus")
                                    }
                                    .tint(DesignSystem.Colors.primary)
                                }
                            }
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                if let phone = patient.patient.phone {
                                    Button {
                                        callPatient(phone)
                                    } label: {
                                        Label("Call", systemImage: "phone.fill")
                                    }
                                    .tint(DesignSystem.Colors.success)
                                }
                            }
                    }
                } header: {
                    Text("\(patients.count) patient\(patients.count == 1 ? "" : "s")")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .textCase(nil)
                }
            }
            .listStyle(.insetGrouped)
            .refreshable {
                await viewModel.refresh()
            }
            .scrollContentBackground(.hidden)
        }
    }

    // MARK: - Status Tab Bar
    private var statusTabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignSystem.Spacing.xs) {
                ForEach(IntakeStatus.allCases, id: \.self) { status in
                    StatusTabButton(
                        status: status,
                        count: patientsForStatus(status).count,
                        isSelected: selectedStatus == status,
                        animation: animation
                    ) {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            selectedStatus = status
                        }
                        DesignSystem.Haptics.selection()
                    }
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.sm)
        }
        .background(.ultraThinMaterial)
        .overlay(alignment: .bottom) {
            Divider()
        }
    }

    // MARK: - Empty State
    private func emptyStateForStatus(_ status: IntakeStatus) -> some View {
        ContentUnavailableView {
            Label(emptyTitle(for: status), systemImage: status.icon)
                .foregroundStyle(status.color)
        } description: {
            Text(emptyMessage(for: status))
        } actions: {
            if status == .pending {
                Button {
                    // Add patient action
                } label: {
                    Label("Add Patient", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .tint(DesignSystem.Colors.primary)
            }
        }
    }

    // MARK: - Helper Methods
    private func patientsForStatus(_ status: IntakeStatus) -> [PatientWithDetails] {
        viewModel.patients.filter { $0.displayStatus == status }
    }

    private func emptyTitle(for status: IntakeStatus) -> String {
        switch status {
        case .pending: return "No Pending Intakes"
        case .readyForReview: return "All Caught Up!"
        case .reviewed: return "No Reviewed Intakes"
        case .expired: return "No Expired Links"
        }
    }

    private func emptyMessage(for status: IntakeStatus) -> String {
        switch status {
        case .pending:
            return "Send intake links to patients to start collecting their health information."
        case .readyForReview:
            return "Great job! You've reviewed all submitted intakes. New submissions will appear here."
        case .reviewed:
            return "Reviewed intakes will appear here after you complete your review."
        case .expired:
            return "Expired intake links will appear here. You can resend links to these patients."
        }
    }

    private func callPatient(_ phone: String) {
        let cleaned = phone.filter { $0.isNumber }
        if let url = URL(string: "tel://\(cleaned)") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Status Tab Button
struct StatusTabButton: View {
    let status: IntakeStatus
    let count: Int
    let isSelected: Bool
    let animation: Namespace.ID
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: status.icon)
                        .font(.system(size: 14, weight: .semibold))
                        .symbolEffect(.bounce, value: isSelected)

                    Text(status.shortLabel)
                        .font(.subheadline.weight(.medium))

                    if count > 0 {
                        Text("\(count)")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(status.color, in: Capsule())
                    }
                }
                .foregroundStyle(isSelected ? status.color : .secondary)

                // Selection indicator
                ZStack {
                    if isSelected {
                        Capsule()
                            .fill(status.color)
                            .frame(height: 3)
                            .matchedGeometryEffect(id: "tab_indicator", in: animation)
                    } else {
                        Capsule()
                            .fill(Color.clear)
                            .frame(height: 3)
                    }
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.sm)
            .padding(.vertical, DesignSystem.Spacing.xs)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Kanban Patient Row
struct KanbanPatientRow: View {
    let patient: PatientWithDetails
    @State private var showSymbolBounce = false

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            // Avatar with red flag indicator
            ZStack(alignment: .topTrailing) {
                IAAvatar(name: patient.patient.fullName, size: .large)

                if patient.hasRedFlags {
                    ZStack {
                        Circle()
                            .fill(DesignSystem.Colors.error)
                            .frame(width: 22, height: 22)

                        Image(systemName: "exclamationmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .offset(x: 4, y: -4)
                    .symbolEffect(.pulse, options: .repeating, value: patient.hasRedFlags)
                }
            }

            // Patient info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(patient.patient.fullName)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)

                    if patient.hasRedFlags {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(DesignSystem.Colors.error)
                            .symbolEffect(.bounce, value: showSymbolBounce)
                    }
                }

                Text(statusText(for: patient.displayStatus, patient: patient))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                if let timeText = timeText(for: patient) {
                    Text(timeText)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            // Status indicator
            if let status = patient.displayStatus {
                VStack(alignment: .trailing, spacing: 4) {
                    Image(systemName: statusIndicatorIcon(for: status))
                        .font(.title3.weight(.medium))
                        .foregroundStyle(status.color)
                        .symbolRenderingMode(.hierarchical)

                    if patient.hasRedFlags {
                        Text("\(patient.redFlagCount) flag\(patient.redFlagCount == 1 ? "" : "s")")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(DesignSystem.Colors.error)
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onAppear {
            if patient.hasRedFlags {
                showSymbolBounce = true
            }
        }
    }

    private func statusIndicatorIcon(for status: IntakeStatus) -> String {
        switch status {
        case .pending: return "clock.badge.questionmark"
        case .readyForReview: return "doc.text.magnifyingglass"
        case .reviewed: return "checkmark.seal.fill"
        case .expired: return "clock.badge.exclamationmark"
        }
    }

    private func statusText(for status: IntakeStatus?, patient: PatientWithDetails) -> String {
        guard let status = status else { return "" }
        switch status {
        case .pending:
            return "Awaiting intake completion"
        case .readyForReview:
            return "Ready for your review"
        case .reviewed:
            return "Review completed"
        case .expired:
            return "Intake link expired"
        }
    }

    private func timeText(for patient: PatientWithDetails) -> String? {
        if let intake = patient.latestIntake {
            if let completedAt = intake.completedAt {
                return "Submitted \(completedAt.relativeFormatted)"
            } else {
                return "Link sent \(intake.createdAt.relativeFormatted)"
            }
        }
        return nil
    }
}

// MARK: - IntakeStatus Extensions
extension IntakeStatus {
    var shortLabel: String {
        switch self {
        case .pending: return "Pending"
        case .readyForReview: return "Review"
        case .reviewed: return "Done"
        case .expired: return "Expired"
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        PatientKanbanView(viewModel: {
            let vm = PatientsViewModel()
            vm.loadSampleData()
            return vm
        }())
    }
}
