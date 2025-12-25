import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showAddPatient = false
    @State private var animateStats = false
    @Namespace private var animation

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.stats == nil {
                    // Premium skeleton loading state
                    dashboardSkeleton
                } else if let error = viewModel.error, viewModel.stats == nil {
                    // Native error state
                    ContentUnavailableView {
                        Label("Unable to Load", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(error)
                    } actions: {
                        Button("Try Again") {
                            Task { await viewModel.loadDashboard() }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(DesignSystem.Colors.primary)
                    }
                } else {
                    // Main content
                    ScrollView {
                        LazyVStack(spacing: DesignSystem.Spacing.lg) {
                            // Welcome Header with material background
                            welcomeHeader

                            // Stats Grid with animations
                            if let stats = viewModel.stats {
                                statsGrid(stats)
                                    .transition(.asymmetric(
                                        insertion: .scale(scale: 0.95).combined(with: .opacity),
                                        removal: .opacity
                                    ))
                            }

                            // Red Flag Alerts with SF Symbol animation
                            if !viewModel.redFlagAlerts.isEmpty {
                                redFlagSection
                            }

                            // Recent Activity with native styling
                            if !viewModel.recentActivity.isEmpty {
                                recentActivitySection
                            }
                        }
                        .padding(.horizontal, DesignSystem.Spacing.md)
                        .padding(.bottom, DesignSystem.Spacing.xxl)
                    }
                    .refreshable {
                        await viewModel.refresh()
                    }
                    .sensoryFeedback(.success, trigger: viewModel.stats?.totalPatients)
                }
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddPatient = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(DesignSystem.Colors.primary)
                    }
                }
            }
            .sheet(isPresented: $showAddPatient) {
                AddPatientSheet()
            }
        }
        .task {
            if viewModel.stats == nil {
                await viewModel.loadDashboard()
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
                animateStats = true
            }
        }
    }

    // MARK: - Skeleton Loading

    private var dashboardSkeleton: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.lg) {
                // Welcome header skeleton
                SummaryCardSkeleton()

                // Stats grid skeleton
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: DesignSystem.Spacing.md),
                    GridItem(.flexible(), spacing: DesignSystem.Spacing.md)
                ], spacing: DesignSystem.Spacing.md) {
                    ForEach(0..<4, id: \.self) { _ in
                        DashboardCardSkeleton()
                    }
                }

                // Activity skeleton
                VStack(spacing: DesignSystem.Spacing.sm) {
                    ForEach(0..<3, id: \.self) { _ in
                        PatientRowSkeleton()
                    }
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.top, DesignSystem.Spacing.md)
        }
    }

    // MARK: - Welcome Header

    private var welcomeHeader: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            if let user = authViewModel.currentUser {
                // Avatar with subtle border
                ZStack {
                    Circle()
                        .fill(DesignSystem.Colors.primary.opacity(0.1))
                        .frame(width: 60, height: 60)

                    Text(user.initials)
                        .font(.system(.title2, design: .rounded, weight: .semibold))
                        .foregroundStyle(DesignSystem.Colors.primary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(greeting)
                        .font(.system(.subheadline, design: .default, weight: .regular))
                        .foregroundStyle(.secondary)

                    Text(user.displayName)
                        .font(.system(.title3, design: .default, weight: .semibold))
                        .foregroundStyle(.primary)

                    if let practiceName = user.practiceName {
                        Text(practiceName)
                            .font(.system(.caption, design: .default, weight: .regular))
                            .foregroundStyle(.tertiary)
                    }
                }

                Spacer()

                // Today's date indicator
                VStack(alignment: .trailing, spacing: 2) {
                    Text(Date(), format: .dateTime.weekday(.abbreviated))
                        .font(.system(.caption2, design: .default, weight: .semibold))
                        .foregroundStyle(DesignSystem.Colors.primary)
                        .textCase(.uppercase)

                    Text(Date(), format: .dateTime.day())
                        .font(.system(.title, design: .rounded, weight: .bold))
                        .foregroundStyle(.primary)
                }
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }

    // MARK: - Stats Grid

    private func statsGrid(_ stats: DashboardStats) -> some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: DesignSystem.Spacing.sm),
            GridItem(.flexible(), spacing: DesignSystem.Spacing.sm)
        ], spacing: DesignSystem.Spacing.sm) {
            StatCard(
                title: "Total Patients",
                value: stats.totalPatients,
                icon: "person.2.fill",
                color: DesignSystem.Colors.primary,
                trend: stats.patientsTrend
            )
            .opacity(animateStats ? 1 : 0)
            .offset(y: animateStats ? 0 : 20)

            StatCard(
                title: "Active Intakes",
                value: stats.activeIntakes,
                icon: "doc.text.fill",
                color: DesignSystem.Colors.info
            )
            .opacity(animateStats ? 1 : 0)
            .offset(y: animateStats ? 0 : 20)

            StatCard(
                title: "Completed Today",
                value: stats.completedToday,
                icon: "checkmark.circle.fill",
                color: DesignSystem.Colors.success
            )
            .opacity(animateStats ? 1 : 0)
            .offset(y: animateStats ? 0 : 20)

            StatCard(
                title: "Pending Review",
                value: stats.pendingReview,
                icon: "clock.fill",
                color: DesignSystem.Colors.warning
            )
            .opacity(animateStats ? 1 : 0)
            .offset(y: animateStats ? 0 : 20)

            if stats.redFlagAlerts > 0 {
                StatCard(
                    title: "Red Flags",
                    value: stats.redFlagAlerts,
                    icon: "exclamationmark.triangle.fill",
                    color: DesignSystem.Colors.error,
                    isAlert: true
                )
                .opacity(animateStats ? 1 : 0)
                .offset(y: animateStats ? 0 : 20)
            }
        }
    }

    // MARK: - Red Flag Section

    @State private var showAlertBounce = false

    private var redFlagSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            // Section header
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(.headline, weight: .semibold))
                    .foregroundStyle(DesignSystem.Colors.error)
                    .symbolEffect(.bounce, value: showAlertBounce)

                Text("Red Flag Alerts")
                    .font(.system(.headline, weight: .semibold))
                    .foregroundStyle(.primary)

                Spacer()

                let unacknowledgedCount = viewModel.redFlagAlerts.filter { !$0.isAcknowledged }.count
                if unacknowledgedCount > 0 {
                    Text("\(unacknowledgedCount) new")
                        .font(.system(.caption, weight: .medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(DesignSystem.Colors.error, in: Capsule())
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showAlertBounce = true
                }
            }

            // Alert cards with native styling
            ForEach(viewModel.redFlagAlerts.prefix(5)) { alert in
                RedFlagAlertRow(alert: alert)
                    .opacity(alert.isAcknowledged ? 0.6 : 1.0)
            }

            // View all button
            if viewModel.redFlagAlerts.count > 5 {
                Button {
                    // Navigate to all alerts
                } label: {
                    HStack {
                        Text("View all \(viewModel.redFlagAlerts.count) alerts")
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .font(.system(.subheadline, weight: .medium))
                    .foregroundStyle(DesignSystem.Colors.primary)
                }
                .padding(.top, DesignSystem.Spacing.xs)
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(DesignSystem.Colors.error.opacity(0.3), lineWidth: 1)
        }
    }

    // MARK: - Recent Activity Section

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            HStack {
                Text("Recent Activity")
                    .font(.system(.headline, weight: .semibold))
                    .foregroundStyle(.primary)

                Spacer()

                if viewModel.recentActivity.count > 5 {
                    Button {
                        // Navigate to activity log
                    } label: {
                        Text("See All")
                            .font(.system(.subheadline, weight: .medium))
                            .foregroundStyle(DesignSystem.Colors.primary)
                    }
                }
            }

            VStack(spacing: 0) {
                ForEach(Array(viewModel.recentActivity.prefix(5).enumerated()), id: \.element.id) { index, activity in
                    ActivityRow(activity: activity)

                    if index < min(4, viewModel.recentActivity.count - 1) {
                        Divider()
                            .padding(.leading, 52)
                    }
                }
            }
            .padding(DesignSystem.Spacing.sm)
            .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}

// MARK: - StatCard Component (Apple Health Style)
struct StatCard: View {
    let title: String
    let value: Int
    let icon: String
    let color: Color
    var trend: Trend? = nil
    var isAlert: Bool = false

    @State private var animateValue = false

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            HStack {
                Image(systemName: icon)
                    .font(.system(.title3, weight: .semibold))
                    .foregroundStyle(color)
                    .symbolEffect(.pulse, options: .repeating, isActive: isAlert)

                Spacer()

                if let trend = trend {
                    HStack(spacing: 2) {
                        Image(systemName: trend.isPositive ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(.caption2, weight: .bold))
                        Text("\(abs(trend.percentage))%")
                            .font(.system(.caption2, weight: .semibold))
                    }
                    .foregroundStyle(trend.isPositive ? Color.green : Color.red)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        (trend.isPositive ? Color.green : Color.red).opacity(0.12),
                        in: Capsule()
                    )
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("\(animateValue ? value : 0)")
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())

                Text(title)
                    .font(.system(.caption, weight: .regular))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(DesignSystem.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.3)) {
                animateValue = true
            }
        }
    }
}

// MARK: - Red Flag Alert Row
struct RedFlagAlertRow: View {
    let alert: RedFlagAlert

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            // Severity indicator
            Circle()
                .fill(severityColor)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(alert.redFlag.flag)
                    .font(.system(.subheadline, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(alert.patientName)
                    .font(.system(.caption, weight: .regular))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(alert.detectedAt.relativeFormatted)
                .font(.system(.caption2, weight: .regular))
                .foregroundStyle(.tertiary)

            Image(systemName: "chevron.right")
                .font(.system(.caption, weight: .semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, DesignSystem.Spacing.xs)
        .contentShape(Rectangle())
    }

    private var severityColor: Color {
        switch alert.redFlag.severity {
        case .high, .critical: return .red
        case .medium: return .orange
        case .low: return .yellow
        }
    }
}

// MARK: - Activity Row
struct ActivityRow: View {
    let activity: RecentActivity

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            // Activity icon with colored background
            ZStack {
                Circle()
                    .fill(activity.type.color.opacity(0.12))
                    .frame(width: 40, height: 40)

                Image(systemName: activity.type.icon)
                    .font(.system(.subheadline, weight: .semibold))
                    .foregroundStyle(activity.type.color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(activity.title)
                    .font(.system(.subheadline, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    if let patientName = activity.patientName {
                        Text(patientName)
                            .font(.system(.caption, weight: .medium))
                            .foregroundStyle(DesignSystem.Colors.primary)
                    }

                    if activity.patientName != nil && activity.subtitle != nil {
                        Text("·")
                            .foregroundStyle(.tertiary)
                    }

                    if let subtitle = activity.subtitle {
                        Text(subtitle)
                            .font(.system(.caption, weight: .regular))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            Text(activity.relativeTime)
                .font(.system(.caption2, weight: .regular))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, DesignSystem.Spacing.xs)
        .contentShape(Rectangle())
    }
}

// MARK: - Add Patient Sheet
/// Full-featured patient registration form with validation
/// Business Logic: Requires Name + DOB for identity verification when sending intake links
struct AddPatientSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = AddPatientViewModel()

    @State private var currentStep = 0
    @FocusState private var focusedField: Field?

    enum Field: Hashable {
        case firstName, lastName, email, phone
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Progress indicator
                    progressBar

                    // Form content
                    TabView(selection: $currentStep) {
                        personalInfoStep.tag(0)
                        contactInfoStep.tag(1)
                        reviewStep.tag(2)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentStep)

                    // Bottom buttons
                    bottomButtons
                }
            }
            .navigationTitle(stepTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                }
            }
            .overlay {
                if viewModel.isSubmitting {
                    submittingOverlay
                }
            }
            .sheet(isPresented: $viewModel.showSuccess) {
                successView
            }
        }
        .interactiveDismissDisabled(viewModel.hasUnsavedChanges)
    }

    private var stepTitle: String {
        switch currentStep {
        case 0: return "Patient Information"
        case 1: return "Contact Details"
        case 2: return "Review & Add"
        default: return "Add Patient"
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            HStack(spacing: DesignSystem.Spacing.xs) {
                ForEach(0..<3) { step in
                    Capsule()
                        .fill(step <= currentStep ? DesignSystem.Colors.primary : DesignSystem.Colors.surfaceSecondary)
                        .frame(height: 4)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.md)

            Text("Step \(currentStep + 1) of 3")
                .font(DesignSystem.Typography.labelSmall)
                .foregroundColor(DesignSystem.Colors.textTertiary)
        }
        .padding(.vertical, DesignSystem.Spacing.sm)
    }

    // MARK: - Step 1: Personal Info

    private var personalInfoStep: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.lg) {
                // Header
                VStack(spacing: DesignSystem.Spacing.xs) {
                    ZStack {
                        Circle()
                            .fill(DesignSystem.Colors.primary.opacity(0.1))
                            .frame(width: 80, height: 80)

                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 36))
                            .foregroundColor(DesignSystem.Colors.primary)
                    }

                    Text("Let's start with the basics")
                        .font(DesignSystem.Typography.headlineSmall)
                        .foregroundColor(DesignSystem.Colors.textPrimary)

                    Text("Enter the patient's name and date of birth")
                        .font(DesignSystem.Typography.bodySmall)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                .padding(.top, DesignSystem.Spacing.lg)

                // Form fields
                VStack(spacing: DesignSystem.Spacing.md) {
                    IATextField(
                        "First Name",
                        text: $viewModel.firstName,
                        icon: "person",
                        error: viewModel.fieldErrors["firstName"]
                    )
                    .textContentType(.givenName)
                    .autocapitalization(.words)
                    .focused($focusedField, equals: .firstName)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .lastName }

                    IATextField(
                        "Last Name",
                        text: $viewModel.lastName,
                        icon: "person",
                        error: viewModel.fieldErrors["lastName"]
                    )
                    .textContentType(.familyName)
                    .autocapitalization(.words)
                    .focused($focusedField, equals: .lastName)
                    .submitLabel(.done)
                    .onSubmit { focusedField = nil }

                    // Date of Birth
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Text("Date of Birth")
                            .font(DesignSystem.Typography.labelMedium)
                            .foregroundColor(DesignSystem.Colors.textSecondary)

                        DatePicker(
                            "",
                            selection: $viewModel.dateOfBirth,
                            in: ...Date(),
                            displayedComponents: .date
                        )
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .tint(DesignSystem.Colors.primary)

                        if let error = viewModel.fieldErrors["dateOfBirth"] {
                            Text(error)
                                .font(DesignSystem.Typography.labelSmall)
                                .foregroundColor(DesignSystem.Colors.error)
                        }
                    }
                    .padding(DesignSystem.Spacing.md)
                    .background(DesignSystem.Colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))

                    // Info callout
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(DesignSystem.Colors.info)

                        Text("Date of birth is used for identity verification when the patient opens their intake link.")
                            .font(DesignSystem.Typography.labelSmall)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                    .padding(DesignSystem.Spacing.md)
                    .background(DesignSystem.Colors.info.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.bottom, DesignSystem.Spacing.xxl)
        }
        .onAppear { focusedField = .firstName }
    }

    // MARK: - Step 2: Contact Info

    private var contactInfoStep: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.lg) {
                // Header
                VStack(spacing: DesignSystem.Spacing.xs) {
                    ZStack {
                        Circle()
                            .fill(DesignSystem.Colors.primary.opacity(0.1))
                            .frame(width: 80, height: 80)

                        Image(systemName: "envelope.badge")
                            .font(.system(size: 36))
                            .foregroundColor(DesignSystem.Colors.primary)
                    }

                    Text("How can we reach them?")
                        .font(DesignSystem.Typography.headlineSmall)
                        .foregroundColor(DesignSystem.Colors.textPrimary)

                    Text("Add contact information (optional)")
                        .font(DesignSystem.Typography.bodySmall)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                .padding(.top, DesignSystem.Spacing.lg)

                // Form fields
                VStack(spacing: DesignSystem.Spacing.md) {
                    IATextField(
                        "Email Address",
                        text: $viewModel.email,
                        icon: "envelope",
                        error: viewModel.fieldErrors["email"]
                    )
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .focused($focusedField, equals: .email)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .phone }

                    IATextField(
                        "Phone Number",
                        text: $viewModel.phone,
                        icon: "phone",
                        error: viewModel.fieldErrors["phone"]
                    )
                    .textContentType(.telephoneNumber)
                    .keyboardType(.phonePad)
                    .focused($focusedField, equals: .phone)

                    // Info callout
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(DesignSystem.Colors.success)

                        Text("We'll use this to send the intake link. You can also copy and share the link manually.")
                            .font(DesignSystem.Typography.labelSmall)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                    .padding(DesignSystem.Spacing.md)
                    .background(DesignSystem.Colors.success.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.bottom, DesignSystem.Spacing.xxl)
        }
        .onAppear { focusedField = .email }
    }

    // MARK: - Step 3: Review

    private var reviewStep: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.lg) {
                // Patient card preview
                IACard(padding: DesignSystem.Spacing.lg) {
                    VStack(spacing: DesignSystem.Spacing.md) {
                        IAAvatar(name: viewModel.fullName, size: .xxl)

                        Text(viewModel.fullName)
                            .font(DesignSystem.Typography.headlineMedium)
                            .foregroundColor(DesignSystem.Colors.textPrimary)

                        Divider()

                        VStack(spacing: DesignSystem.Spacing.sm) {
                            reviewRow(icon: "calendar", label: "Date of Birth", value: viewModel.formattedDOB)
                            reviewRow(icon: "person.text.rectangle", label: "Age", value: "\(viewModel.age) years old")

                            if !viewModel.email.isEmpty {
                                reviewRow(icon: "envelope", label: "Email", value: viewModel.email)
                            }

                            if !viewModel.phone.isEmpty {
                                reviewRow(icon: "phone", label: "Phone", value: viewModel.formattedPhone)
                            }
                        }
                    }
                }

                // Send intake link option
                IACard {
                    Toggle(isOn: $viewModel.sendIntakeLinkImmediately) {
                        HStack(spacing: DesignSystem.Spacing.sm) {
                            Image(systemName: "paperplane.fill")
                                .foregroundColor(DesignSystem.Colors.primary)

                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxxs) {
                                Text("Send Intake Link")
                                    .font(DesignSystem.Typography.titleSmall)
                                    .foregroundColor(DesignSystem.Colors.textPrimary)

                                Text("Create and send an intake link immediately")
                                    .font(DesignSystem.Typography.labelSmall)
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                            }
                        }
                    }
                    .tint(DesignSystem.Colors.primary)
                }

                if let error = viewModel.submitError {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(DesignSystem.Colors.error)

                        Text(error)
                            .font(DesignSystem.Typography.bodySmall)
                            .foregroundColor(DesignSystem.Colors.error)
                    }
                    .padding(DesignSystem.Spacing.md)
                    .frame(maxWidth: .infinity)
                    .background(DesignSystem.Colors.error.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.bottom, DesignSystem.Spacing.xxl)
        }
    }

    private func reviewRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: DesignSystem.IconSize.sm))
                .foregroundColor(DesignSystem.Colors.textTertiary)
                .frame(width: 24)

            Text(label)
                .font(DesignSystem.Typography.bodySmall)
                .foregroundColor(DesignSystem.Colors.textSecondary)

            Spacer()

            Text(value)
                .font(DesignSystem.Typography.bodyMedium)
                .foregroundColor(DesignSystem.Colors.textPrimary)
        }
    }

    // MARK: - Bottom Buttons

    private var bottomButtons: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            if currentStep > 0 {
                IAButton("Back", style: .secondary) {
                    withAnimation {
                        currentStep -= 1
                    }
                    appState.triggerHaptic(.light)
                }
            }

            if currentStep < 2 {
                IAButton("Continue", style: .primary) {
                    if viewModel.validateStep(currentStep) {
                        withAnimation {
                            currentStep += 1
                        }
                        appState.triggerHaptic(.light)
                    } else {
                        appState.triggerNotificationHaptic(.error)
                    }
                }
            } else {
                IAButton("Add Patient", style: .primary, isLoading: viewModel.isSubmitting) {
                    Task {
                        await viewModel.submit()
                        if viewModel.showSuccess {
                            appState.triggerNotificationHaptic(.success)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.vertical, DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.surface)
    }

    // MARK: - Overlays

    private var submittingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: DesignSystem.Spacing.md) {
                IALoadingAnimation(size: 50)

                Text("Creating patient...")
                    .font(DesignSystem.Typography.titleSmall)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
            }
            .padding(DesignSystem.Spacing.xl)
            .background(DesignSystem.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl))
        }
    }

    private var successView: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            Spacer()

            IASuccessAnimation(size: 120)

            VStack(spacing: DesignSystem.Spacing.sm) {
                Text("Patient Added!")
                    .font(DesignSystem.Typography.headlineLarge)
                    .foregroundColor(DesignSystem.Colors.textPrimary)

                Text("\(viewModel.fullName) has been added to your patient list.")
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            VStack(spacing: DesignSystem.Spacing.sm) {
                if viewModel.sendIntakeLinkImmediately {
                    IAButton("View & Share Link", style: .primary, icon: "link") {
                        dismiss()
                    }
                } else {
                    IAButton("Done", style: .primary) {
                        dismiss()
                    }
                }

                IAButton("Add Another Patient", style: .secondary, icon: "plus") {
                    viewModel.reset()
                    currentStep = 0
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.bottom, DesignSystem.Spacing.xl)
        }
        .background(DesignSystem.Colors.background)
    }
}

// MARK: - ViewModel

@MainActor
class AddPatientViewModel: ObservableObject {
    @Published var firstName = ""
    @Published var lastName = ""
    @Published var dateOfBirth = Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date()
    @Published var email = ""
    @Published var phone = ""
    @Published var sendIntakeLinkImmediately = true

    @Published var fieldErrors: [String: String] = [:]
    @Published var submitError: String?
    @Published var isSubmitting = false
    @Published var showSuccess = false

    var fullName: String {
        "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
    }

    var age: Int {
        Calendar.current.dateComponents([.year], from: dateOfBirth, to: Date()).year ?? 0
    }

    var formattedDOB: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: dateOfBirth)
    }

    var formattedPhone: String {
        let cleaned = phone.filter { $0.isNumber }
        guard cleaned.count >= 10 else { return phone }
        let areaCode = cleaned.prefix(3)
        let middle = cleaned.dropFirst(3).prefix(3)
        let last = cleaned.dropFirst(6).prefix(4)
        return "(\(areaCode)) \(middle)-\(last)"
    }

    var hasUnsavedChanges: Bool {
        !firstName.isEmpty || !lastName.isEmpty || !email.isEmpty || !phone.isEmpty
    }

    func validateStep(_ step: Int) -> Bool {
        fieldErrors = [:]

        switch step {
        case 0:
            if firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                fieldErrors["firstName"] = "First name is required"
            }
            if lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                fieldErrors["lastName"] = "Last name is required"
            }
            if age < 0 || age > 150 {
                fieldErrors["dateOfBirth"] = "Please enter a valid date of birth"
            }
        case 1:
            if !email.isEmpty {
                let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
                if email.range(of: emailRegex, options: .regularExpression) == nil {
                    fieldErrors["email"] = "Please enter a valid email address"
                }
            }
            if !phone.isEmpty {
                let phoneClean = phone.filter { $0.isNumber }
                if phoneClean.count < 10 {
                    fieldErrors["phone"] = "Please enter a valid 10-digit phone number"
                }
            }
        default:
            break
        }

        return fieldErrors.isEmpty
    }

    func submit() async {
        guard validateStep(0) && validateStep(1) else { return }

        isSubmitting = true
        submitError = nil

        do {
            let request = CreatePatientRequest(
                firstName: firstName.trimmingCharacters(in: .whitespacesAndNewlines),
                lastName: lastName.trimmingCharacters(in: .whitespacesAndNewlines),
                email: email.isEmpty ? nil : email.trimmingCharacters(in: .whitespacesAndNewlines),
                phone: phone.isEmpty ? nil : phone.filter { $0.isNumber },
                dateOfBirth: dateOfBirth
            )

            // Call API
            _ = try await NetworkClient.shared.request(
                .createPatient(request: request),
                responseType: Patient.self
            )

            // If we should send intake link immediately, create it
            if sendIntakeLinkImmediately {
                // This would create the intake link
            }

            isSubmitting = false
            showSuccess = true
        } catch {
            isSubmitting = false
            submitError = error.localizedDescription
        }
    }

    func reset() {
        firstName = ""
        lastName = ""
        dateOfBirth = Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date()
        email = ""
        phone = ""
        sendIntakeLinkImmediately = true
        fieldErrors = [:]
        submitError = nil
        showSuccess = false
    }
}

// MARK: - Preview
#Preview {
    let viewModel = DashboardViewModel()
    viewModel.loadSampleData()

    return DashboardView()
        .environmentObject(AuthViewModel())
}
