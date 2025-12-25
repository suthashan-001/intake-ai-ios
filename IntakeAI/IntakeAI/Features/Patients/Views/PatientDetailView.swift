import SwiftUI

struct PatientDetailView: View {
    let patient: PatientWithDetails

    @State private var selectedTab = 0
    @State private var showCreateIntakeLink = false
    @State private var showAddNote = false
    @State private var showEditPatient = false
    @State private var selectedIntake: Intake?
    @State private var showRedFlagBounce = false
    @Namespace private var tabAnimation

    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.lg) {
                // Patient Header Card with material background
                patientHeaderCard

                // Quick Actions with SF Symbol animations
                quickActionsBar

                // Red Flags Alert (if any) with animation
                if patient.hasRedFlags {
                    redFlagsAlert
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.95).combined(with: .opacity),
                            removal: .opacity
                        ))
                }

                // Native segmented tab selector
                tabSelector

                // Tab Content with transitions
                tabContent
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.bottom, DesignSystem.Spacing.xxl)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle(patient.patient.fullName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showEditPatient = true
                    } label: {
                        Label("Edit Patient", systemImage: "pencil")
                    }

                    Button {
                        showCreateIntakeLink = true
                    } label: {
                        Label("Send Intake Link", systemImage: "link")
                    }

                    if let phone = patient.patient.phone {
                        Button {
                            callPatient(phone)
                        } label: {
                            Label("Call Patient", systemImage: "phone.fill")
                        }
                    }

                    if let email = patient.patient.email {
                        Button {
                            emailPatient(email)
                        } label: {
                            Label("Email Patient", systemImage: "envelope.fill")
                        }
                    }

                    Divider()

                    Button(role: .destructive) {
                        // Delete patient
                    } label: {
                        Label("Delete Patient", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle.fill")
                        .font(.title3)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(DesignSystem.Colors.primary)
                }
            }
        }
        .sheet(isPresented: $showCreateIntakeLink) {
            CreateIntakeLinkSheet(patientId: patient.id, patientName: patient.patient.fullName)
        }
        .sheet(isPresented: $showAddNote) {
            AddNoteSheet(patientId: patient.id)
        }
        .sheet(isPresented: $showEditPatient) {
            EditPatientSheet(patient: patient.patient)
        }
        .sheet(item: $selectedIntake) { intake in
            IntakeSummaryView(intake: intake)
        }
        .sensoryFeedback(.selection, trigger: selectedTab)
    }

    // MARK: - Patient Header Card

    private var patientHeaderCard: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Profile section
            HStack(spacing: DesignSystem.Spacing.md) {
                // Large avatar with initials
                ZStack {
                    Circle()
                        .fill(DesignSystem.Colors.primary.opacity(0.12))
                        .frame(width: 72, height: 72)

                    Text(patient.patient.initials)
                        .font(.system(.title, design: .rounded, weight: .semibold))
                        .foregroundStyle(DesignSystem.Colors.primary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(patient.patient.fullName)
                        .font(.system(.title3, weight: .semibold))
                        .foregroundStyle(.primary)

                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.system(.caption, weight: .medium))
                        Text("\(patient.patient.age) years old")
                        Text("·")
                        Text(patient.patient.formattedDateOfBirth)
                    }
                    .font(.system(.subheadline, weight: .regular))
                    .foregroundStyle(.secondary)

                    if let status = patient.displayStatus {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(status.color)
                                .frame(width: 8, height: 8)
                            Text(status.label)
                                .font(.system(.caption, weight: .medium))
                                .foregroundStyle(status.color)
                        }
                        .padding(.top, 2)
                    }
                }

                Spacer()
            }

            Divider()

            // Contact Info with native buttons
            VStack(spacing: 0) {
                if let email = patient.patient.email {
                    contactRow(icon: "envelope.fill", value: email, tint: .blue) {
                        emailPatient(email)
                    }

                    if patient.patient.phone != nil {
                        Divider()
                            .padding(.leading, 44)
                    }
                }

                if let phone = patient.patient.formattedPhone {
                    contactRow(icon: "phone.fill", value: phone, tint: .green) {
                        callPatient(patient.patient.phone!)
                    }
                }
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func contactRow(icon: String, value: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(.subheadline, weight: .medium))
                    .foregroundStyle(tint)
                    .frame(width: 32)

                Text(value)
                    .font(.system(.subheadline, weight: .regular))
                    .foregroundStyle(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(.caption, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, DesignSystem.Spacing.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Quick Actions Bar

    private var quickActionsBar: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            QuickActionButton(icon: "link.badge.plus", label: "Send Link", color: DesignSystem.Colors.primary) {
                showCreateIntakeLink = true
            }

            QuickActionButton(icon: "note.text.badge.plus", label: "Add Note", color: DesignSystem.Colors.info) {
                showAddNote = true
            }

            if let phone = patient.patient.phone {
                QuickActionButton(icon: "phone.fill", label: "Call", color: .green) {
                    callPatient(phone)
                }
            }

            if let email = patient.patient.email {
                QuickActionButton(icon: "envelope.fill", label: "Email", color: .blue) {
                    emailPatient(email)
                }
            }
        }
    }

    // MARK: - Red Flags Alert

    private var redFlagsAlert: some View {
        Button {
            if let intake = patient.latestIntake {
                selectedIntake = intake
            }
        } label: {
            HStack(spacing: DesignSystem.Spacing.sm) {
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.12))
                        .frame(width: 48, height: 48)

                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(.title3, weight: .semibold))
                        .foregroundStyle(.red)
                        .symbolEffect(.bounce, value: showRedFlagBounce)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(patient.redFlagCount) Red Flag\(patient.redFlagCount == 1 ? "" : "s") Detected")
                        .font(.system(.subheadline, weight: .semibold))
                        .foregroundStyle(.red)

                    Text("Review the latest intake summary for details")
                        .font(.system(.caption, weight: .regular))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(.caption, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(DesignSystem.Spacing.md)
            .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.red.opacity(0.3), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showRedFlagBounce = true
            }
        }
    }

    // MARK: - Tab Selector

    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(Array(["Intakes", "Notes", "Links"].enumerated()), id: \.offset) { index, title in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        selectedTab = index
                    }
                } label: {
                    VStack(spacing: 8) {
                        Text(title)
                            .font(.system(.subheadline, weight: selectedTab == index ? .semibold : .regular))
                            .foregroundStyle(selectedTab == index ? DesignSystem.Colors.primary : .secondary)

                        ZStack {
                            Rectangle()
                                .fill(Color.clear)
                                .frame(height: 3)

                            if selectedTab == index {
                                Rectangle()
                                    .fill(DesignSystem.Colors.primary)
                                    .frame(height: 3)
                                    .matchedGeometryEffect(id: "tabIndicator", in: tabAnimation)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
            }
        }
        .padding(.top, DesignSystem.Spacing.xs)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case 0:
            intakesTab
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
        case 1:
            notesTab
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
        case 2:
            linksTab
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
        default:
            EmptyView()
        }
    }

    private var intakesTab: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            if let intakes = patient.intakes, !intakes.isEmpty {
                ForEach(intakes) { intake in
                    IntakeRow(intake: intake) {
                        selectedIntake = intake
                    }
                }
            } else {
                ContentUnavailableView {
                    Label("No Intakes Yet", systemImage: "doc.text")
                } description: {
                    Text("Send an intake link to collect patient information.")
                } actions: {
                    Button {
                        showCreateIntakeLink = true
                    } label: {
                        Label("Send Intake Link", systemImage: "link.badge.plus")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(DesignSystem.Colors.primary)
                }
            }
        }
    }

    private var notesTab: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            ContentUnavailableView {
                Label("No Clinical Notes", systemImage: "note.text")
            } description: {
                Text("Add notes to track patient progress and observations.")
            } actions: {
                Button {
                    showAddNote = true
                } label: {
                    Label("Add Note", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .tint(DesignSystem.Colors.primary)
            }
        }
    }

    private var linksTab: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            if let links = patient.intakeLinks, !links.isEmpty {
                ForEach(links) { link in
                    IntakeLinkRow(link: link)
                }
            } else {
                ContentUnavailableView {
                    Label("No Intake Links", systemImage: "link")
                } description: {
                    Text("Create a link to send to your patient.")
                } actions: {
                    Button {
                        showCreateIntakeLink = true
                    } label: {
                        Label("Create Link", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(DesignSystem.Colors.primary)
                }
            }
        }
    }

    // MARK: - Actions

    private func callPatient(_ phone: String) {
        let cleaned = phone.filter { $0.isNumber }
        if let url = URL(string: "tel://\(cleaned)") {
            UIApplication.shared.open(url)
        }
    }

    private func emailPatient(_ email: String) {
        if let url = URL(string: "mailto:\(email)") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Quick Action Button
struct QuickActionButton: View {
    let icon: String
    let label: String
    var color: Color = DesignSystem.Colors.primary
    let action: () -> Void

    @State private var isPressed = false
    @State private var showSymbolBounce = false

    var body: some View {
        Button {
            showSymbolBounce.toggle()
            action()
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.12))
                        .frame(width: 52, height: 52)

                    Image(systemName: icon)
                        .font(.system(.title3, weight: .semibold))
                        .foregroundStyle(color)
                        .symbolEffect(.bounce, value: showSymbolBounce)
                }

                Text(label)
                    .font(.system(.caption2, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .scaleEffect(isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact(flexibility: .soft), trigger: showSymbolBounce)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Intake Row
struct IntakeRow: View {
    let intake: Intake
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                ZStack {
                    Circle()
                        .fill(intake.status.color.opacity(0.12))
                        .frame(width: 44, height: 44)

                    Image(systemName: intake.status.icon)
                        .font(.system(.subheadline, weight: .semibold))
                        .foregroundStyle(intake.status.color)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Intake Form")
                        .font(.system(.subheadline, weight: .medium))
                        .foregroundStyle(.primary)

                    if let completedAt = intake.formattedCompletedAt {
                        Text("Completed \(completedAt)")
                            .font(.system(.caption, weight: .regular))
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Created \(intake.createdAt.relativeFormatted)")
                            .font(.system(.caption, weight: .regular))
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // Status badge
                Text(intake.status.label)
                    .font(.system(.caption2, weight: .semibold))
                    .foregroundStyle(intake.status.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(intake.status.color.opacity(0.12), in: Capsule())

                Image(systemName: "chevron.right")
                    .font(.system(.caption, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(DesignSystem.Spacing.md)
            .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Intake Link Row
struct IntakeLinkRow: View {
    let link: IntakeLink
    @State private var showShareSheet = false
    @State private var showCopied = false

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            ZStack {
                Circle()
                    .fill(link.status.color.opacity(0.12))
                    .frame(width: 44, height: 44)

                Image(systemName: link.status.icon)
                    .font(.system(.subheadline, weight: .semibold))
                    .foregroundStyle(link.status.color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Intake Link")
                    .font(.system(.subheadline, weight: .medium))
                    .foregroundStyle(.primary)

                Text(link.status.label)
                    .font(.system(.caption, weight: .medium))
                    .foregroundStyle(link.status.color)

                if let timeRemaining = link.timeRemaining {
                    Text(timeRemaining)
                        .font(.system(.caption2, weight: .regular))
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            if link.isActive {
                HStack(spacing: 8) {
                    // Copy button
                    Button {
                        UIPasteboard.general.string = link.shareableURL
                        showCopied = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            showCopied = false
                        }
                    } label: {
                        Image(systemName: showCopied ? "checkmark" : "doc.on.doc")
                            .font(.system(.subheadline, weight: .medium))
                            .foregroundStyle(showCopied ? .green : DesignSystem.Colors.primary)
                            .contentTransition(.symbolEffect(.replace))
                    }
                    .sensoryFeedback(.success, trigger: showCopied)

                    // Share button
                    Button {
                        showShareSheet = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(.subheadline, weight: .medium))
                            .foregroundStyle(DesignSystem.Colors.primary)
                    }
                }
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [link.shareableURL])
        }
    }
}

// MARK: - Create Intake Link Sheet
struct CreateIntakeLinkSheet: View {
    let patientId: String
    let patientName: String
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState

    @State private var expirationHours: Int = 24
    @State private var requiresDOBVerification = true
    @State private var isCreating = false
    @State private var createdLink: IntakeLink?
    @State private var errorMessage: String?

    private let expirationOptions = [
        (hours: 1, label: "1 hour"),
        (hours: 6, label: "6 hours"),
        (hours: 24, label: "24 hours"),
        (hours: 48, label: "48 hours"),
        (hours: 72, label: "72 hours"),
        (hours: 168, label: "1 week")
    ]

    var body: some View {
        NavigationStack {
            Group {
                if let link = createdLink {
                    linkCreatedView(link: link)
                } else {
                    createLinkForm
                }
            }
            .navigationTitle(createdLink == nil ? "New Intake Link" : "Link Created")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(createdLink == nil ? "Cancel" : "Done") {
                        dismiss()
                    }
                }

                if createdLink == nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Create") {
                            createLink()
                        }
                        .fontWeight(.semibold)
                        .disabled(isCreating)
                    }
                }
            }
        }
    }

    private var createLinkForm: some View {
        Form {
            Section {
                HStack(spacing: DesignSystem.Spacing.md) {
                    IAAvatar(name: patientName, size: .large)

                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxxs) {
                        Text(patientName)
                            .font(DesignSystem.Typography.titleMedium)
                            .foregroundColor(DesignSystem.Colors.textPrimary)

                        Text("Patient")
                            .font(DesignSystem.Typography.bodySmall)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                }
                .padding(.vertical, DesignSystem.Spacing.xs)
            }

            Section("Link Settings") {
                Picker("Expires After", selection: $expirationHours) {
                    ForEach(expirationOptions, id: \.hours) { option in
                        Text(option.label).tag(option.hours)
                    }
                }

                Toggle(isOn: $requiresDOBVerification) {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxxs) {
                        Text("Require DOB Verification")
                            .font(DesignSystem.Typography.bodyMedium)

                        Text("Patient must verify their date of birth to access the form")
                            .font(DesignSystem.Typography.labelSmall)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                }
                .tint(DesignSystem.Colors.primary)
            }

            Section {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Label {
                        Text("The link will be sent to the patient's registered contact")
                    } icon: {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(DesignSystem.Colors.info)
                    }
                    .font(DesignSystem.Typography.bodySmall)
                    .foregroundColor(DesignSystem.Colors.textSecondary)

                    Label {
                        Text("The patient can complete the intake form on any device")
                    } icon: {
                        Image(systemName: "iphone")
                            .foregroundColor(DesignSystem.Colors.info)
                    }
                    .font(DesignSystem.Typography.bodySmall)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                }
            }

            if let error = errorMessage {
                Section {
                    Text(error)
                        .font(DesignSystem.Typography.bodySmall)
                        .foregroundColor(DesignSystem.Colors.error)
                }
            }
        }
        .overlay {
            if isCreating {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    ProgressView("Creating link...")
                        .padding()
                        .background(DesignSystem.Colors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
                }
            }
        }
    }

    private func linkCreatedView(link: IntakeLink) -> some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.xl) {
                // Success animation
                ZStack {
                    Circle()
                        .fill(DesignSystem.Colors.success.opacity(0.12))
                        .frame(width: 100, height: 100)

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(DesignSystem.Colors.success)
                }
                .padding(.top, DesignSystem.Spacing.xl)

                VStack(spacing: DesignSystem.Spacing.xs) {
                    Text("Link Created Successfully")
                        .font(DesignSystem.Typography.headlineMedium)
                        .foregroundColor(DesignSystem.Colors.textPrimary)

                    Text("The intake link is ready to share with \(patientName)")
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }

                // Link URL card
                IACard {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Text("Shareable Link")
                            .font(DesignSystem.Typography.labelMedium)
                            .foregroundColor(DesignSystem.Colors.textSecondary)

                        Text(link.shareableURL)
                            .font(DesignSystem.Typography.monoSmall)
                            .foregroundColor(DesignSystem.Colors.primary)
                            .lineLimit(2)

                        HStack(spacing: DesignSystem.Spacing.sm) {
                            IAButton("Copy Link", style: .secondary, icon: "doc.on.doc") {
                                UIPasteboard.general.string = link.shareableURL
                                appState.triggerHaptic(.success)
                            }

                            IAButton("Share", style: .primary, icon: "square.and.arrow.up") {
                                // Share sheet would be presented here
                            }
                        }
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.md)

                // Link info
                IACard {
                    VStack(spacing: DesignSystem.Spacing.sm) {
                        HStack {
                            Text("Expires")
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                            Spacer()
                            Text(link.timeRemaining ?? "Unknown")
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                        }
                        .font(DesignSystem.Typography.bodySmall)

                        Divider()

                        HStack {
                            Text("DOB Verification")
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                            Spacer()
                            Text(link.requiresDOBVerification ? "Required" : "Not Required")
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                        }
                        .font(DesignSystem.Typography.bodySmall)
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.md)
            }
            .padding(.bottom, DesignSystem.Spacing.xxl)
        }
        .background(DesignSystem.Colors.background)
    }

    private func createLink() {
        isCreating = true
        errorMessage = nil
        appState.triggerHaptic(.light)

        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isCreating = false

            // Create mock link
            let link = IntakeLink(
                id: UUID().uuidString,
                patientId: patientId,
                token: UUID().uuidString,
                expiresAt: Date().addingTimeInterval(TimeInterval(expirationHours * 3600)),
                createdAt: Date(),
                usedAt: nil,
                requiresDOBVerification: requiresDOBVerification,
                verificationAttempts: 0
            )

            createdLink = link
            appState.triggerHaptic(.success)
        }
    }
}

// MARK: - Add Note Sheet
struct AddNoteSheet: View {
    let patientId: String
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState

    @State private var noteContent = ""
    @State private var noteType: NoteType = .general
    @State private var isPrivate = false
    @State private var isSaving = false
    @State private var errorMessage: String?

    @FocusState private var isNoteFocused: Bool

    enum NoteType: String, CaseIterable {
        case general = "General"
        case clinical = "Clinical Observation"
        case followUp = "Follow-up"
        case treatment = "Treatment Plan"
        case referral = "Referral"

        var icon: String {
            switch self {
            case .general: return "note.text"
            case .clinical: return "stethoscope"
            case .followUp: return "calendar.badge.clock"
            case .treatment: return "cross.case.fill"
            case .referral: return "arrow.triangle.branch"
            }
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Note Type") {
                    Picker("Type", selection: $noteType) {
                        ForEach(NoteType.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.icon)
                                .tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section("Note") {
                    TextEditor(text: $noteContent)
                        .frame(minHeight: 200)
                        .focused($isNoteFocused)
                        .overlay(alignment: .topLeading) {
                            if noteContent.isEmpty {
                                Text("Enter your clinical note here...")
                                    .font(DesignSystem.Typography.bodyMedium)
                                    .foregroundColor(DesignSystem.Colors.textTertiary)
                                    .padding(.top, 8)
                                    .padding(.leading, 4)
                                    .allowsHitTesting(false)
                            }
                        }
                }

                Section {
                    Toggle(isOn: $isPrivate) {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxxs) {
                            Text("Private Note")
                                .font(DesignSystem.Typography.bodyMedium)

                            Text("Only visible to you, not shared with other providers")
                                .font(DesignSystem.Typography.labelSmall)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        }
                    }
                    .tint(DesignSystem.Colors.primary)
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .font(DesignSystem.Typography.bodySmall)
                            .foregroundColor(DesignSystem.Colors.error)
                    }
                }
            }
            .navigationTitle("New Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveNote()
                    }
                    .fontWeight(.semibold)
                    .disabled(noteContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
                }

                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Spacer()
                        Button("Done") {
                            isNoteFocused = false
                        }
                    }
                }
            }
            .overlay {
                if isSaving {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                        ProgressView("Saving...")
                            .padding()
                            .background(DesignSystem.Colors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
                    }
                }
            }
            .onAppear {
                isNoteFocused = true
            }
        }
    }

    private func saveNote() {
        guard !noteContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please enter a note"
            return
        }

        isSaving = true
        errorMessage = nil
        appState.triggerHaptic(.light)

        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isSaving = false
            appState.triggerHaptic(.success)
            dismiss()
        }
    }
}

// MARK: - Edit Patient Sheet
struct EditPatientSheet: View {
    let patient: Patient
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState

    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var phone: String = ""
    @State private var dateOfBirth: Date = Date()
    @State private var isSaving = false
    @State private var showDeleteConfirmation = false
    @State private var errorMessage: String?
    @State private var fieldErrors: [String: String] = [:]

    var body: some View {
        NavigationStack {
            Form {
                Section("Personal Information") {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxxs) {
                        TextField("First Name", text: $firstName)
                            .textContentType(.givenName)
                            .autocapitalization(.words)

                        if let error = fieldErrors["firstName"] {
                            Text(error)
                                .font(DesignSystem.Typography.labelSmall)
                                .foregroundColor(DesignSystem.Colors.error)
                        }
                    }

                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxxs) {
                        TextField("Last Name", text: $lastName)
                            .textContentType(.familyName)
                            .autocapitalization(.words)

                        if let error = fieldErrors["lastName"] {
                            Text(error)
                                .font(DesignSystem.Typography.labelSmall)
                                .foregroundColor(DesignSystem.Colors.error)
                        }
                    }

                    DatePicker("Date of Birth", selection: $dateOfBirth, in: ...Date(), displayedComponents: .date)
                }

                Section("Contact Information") {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxxs) {
                        TextField("Email", text: $email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)

                        if let error = fieldErrors["email"] {
                            Text(error)
                                .font(DesignSystem.Typography.labelSmall)
                                .foregroundColor(DesignSystem.Colors.error)
                        }
                    }

                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxxs) {
                        TextField("Phone", text: $phone)
                            .textContentType(.telephoneNumber)
                            .keyboardType(.phonePad)

                        if let error = fieldErrors["phone"] {
                            Text(error)
                                .font(DesignSystem.Typography.labelSmall)
                                .foregroundColor(DesignSystem.Colors.error)
                        }
                    }
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .font(DesignSystem.Typography.bodySmall)
                            .foregroundColor(DesignSystem.Colors.error)
                    }
                }

                Section {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete Patient")
                        }
                    }
                }
            }
            .navigationTitle("Edit Patient")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        savePatient()
                    }
                    .fontWeight(.semibold)
                    .disabled(isSaving)
                }
            }
            .confirmationDialog("Delete Patient", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
                Button("Delete Patient", role: .destructive) {
                    // Delete patient
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete this patient? This action cannot be undone and will remove all associated intakes and notes.")
            }
            .overlay {
                if isSaving {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                        ProgressView("Saving...")
                            .padding()
                            .background(DesignSystem.Colors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
                    }
                }
            }
            .onAppear {
                firstName = patient.firstName
                lastName = patient.lastName
                email = patient.email ?? ""
                phone = patient.phone ?? ""
                dateOfBirth = patient.dateOfBirth
            }
        }
    }

    private func validateForm() -> Bool {
        fieldErrors = [:]

        if firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            fieldErrors["firstName"] = "First name is required"
        }

        if lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            fieldErrors["lastName"] = "Last name is required"
        }

        if !email.isEmpty {
            let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
            if email.range(of: emailRegex, options: .regularExpression) == nil {
                fieldErrors["email"] = "Please enter a valid email address"
            }
        }

        if !phone.isEmpty {
            let phoneClean = phone.filter { $0.isNumber }
            if phoneClean.count < 10 {
                fieldErrors["phone"] = "Please enter a valid phone number"
            }
        }

        return fieldErrors.isEmpty
    }

    private func savePatient() {
        guard validateForm() else {
            appState.triggerHaptic(.error)
            return
        }

        isSaving = true
        errorMessage = nil
        appState.triggerHaptic(.light)

        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isSaving = false
            appState.triggerHaptic(.success)
            dismiss()
        }
    }
}

struct IntakeSummaryView: View {
    let intake: Intake
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            SummaryDetailView(intakeId: intake.id)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Done") { dismiss() }
                    }
                }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        PatientDetailView(patient: PatientWithDetails.sampleWithRedFlags)
    }
}
