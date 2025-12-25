import SwiftUI

// MARK: - iPad Main View with Split Navigation
struct iPadMainView: View {
    @State private var selectedSidebarItem: SidebarItem? = .dashboard
    @State private var selectedPatient: PatientWithDetails?
    @State private var columnVisibility = NavigationSplitViewVisibility.all

    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authViewModel: AuthViewModel

    enum SidebarItem: String, CaseIterable, Identifiable {
        case dashboard = "Dashboard"
        case patients = "Patients"
        case links = "Intake Links"
        case settings = "Settings"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .dashboard: return "house.fill"
            case .patients: return "person.2.fill"
            case .links: return "link.circle.fill"
            case .settings: return "gearshape.fill"
            }
        }

        var color: Color {
            switch self {
            case .dashboard: return DesignSystem.Colors.primary
            case .patients: return DesignSystem.Colors.info
            case .links: return DesignSystem.Colors.accent
            case .settings: return DesignSystem.Colors.textSecondary
            }
        }
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // Sidebar
            List(SidebarItem.allCases, selection: $selectedSidebarItem) { item in
                NavigationLink(value: item) {
                    Label {
                        Text(item.rawValue)
                    } icon: {
                        Image(systemName: item.icon)
                            .foregroundColor(item.color)
                    }
                }
            }
            .navigationTitle("IntakeAI")
            .listStyle(.sidebar)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    if let user = authViewModel.currentUser {
                        Menu {
                            Text(user.email)
                            Divider()
                            Button {
                                Task { await authViewModel.logout() }
                            } label: {
                                Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.forward")
                            }
                        } label: {
                            IAAvatar(name: user.fullName, size: .small)
                        }
                    }
                }
            }
        } content: {
            // Content area based on selection
            Group {
                switch selectedSidebarItem {
                case .dashboard:
                    iPadDashboardView()
                case .patients:
                    iPadPatientsListView(selectedPatient: $selectedPatient)
                case .links:
                    IntakeLinksView()
                case .settings:
                    SettingsView()
                case .none:
                    Text("Select an item from the sidebar")
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
            }
        } detail: {
            // Detail view for patients
            if selectedSidebarItem == .patients {
                if let patient = selectedPatient {
                    PatientDetailView(patient: patient)
                } else {
                    ContentUnavailableView {
                        Label("No Patient Selected", systemImage: "person.crop.circle")
                    } description: {
                        Text("Select a patient from the list to view their details.")
                    }
                }
            } else {
                EmptyView()
            }
        }
        .navigationSplitViewStyle(.balanced)
    }
}

// MARK: - iPad Dashboard View
struct iPadDashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.lg) {
                // Welcome Header
                if let user = authViewModel.currentUser {
                    HStack {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            Text(greeting)
                                .font(DesignSystem.Typography.bodyMedium)
                                .foregroundColor(DesignSystem.Colors.textSecondary)

                            Text(user.displayName)
                                .font(DesignSystem.Typography.displayMedium)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                        }

                        Spacer()

                        // Quick Actions
                        HStack(spacing: DesignSystem.Spacing.sm) {
                            IAButton("Add Patient", style: .primary, icon: "person.badge.plus") {}
                            IAButton("New Link", style: .secondary, icon: "link") {}
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                }

                // Stats Grid - 3 columns for iPad
                if let stats = viewModel.stats {
                    LazyVGrid(columns: columns, spacing: DesignSystem.Spacing.md) {
                        IAStatsCard(
                            title: "Total Patients",
                            value: "\(stats.totalPatients)",
                            icon: "person.2.fill",
                            iconColor: DesignSystem.Colors.primary,
                            trend: stats.patientsTrend.map { .init(value: $0.value, percentage: $0.percentage, isPositive: $0.isPositive) }
                        )

                        IAStatsCard(
                            title: "Active Intakes",
                            value: "\(stats.activeIntakes)",
                            icon: "doc.text.fill",
                            iconColor: DesignSystem.Colors.info
                        )

                        IAStatsCard(
                            title: "Completed Today",
                            value: "\(stats.completedToday)",
                            icon: "checkmark.circle.fill",
                            iconColor: DesignSystem.Colors.success
                        )

                        IAStatsCard(
                            title: "Pending Review",
                            value: "\(stats.pendingReview)",
                            icon: "clock.fill",
                            iconColor: DesignSystem.Colors.warning
                        )

                        IAStatsCard(
                            title: "Red Flag Alerts",
                            value: "\(stats.redFlagAlerts)",
                            subtitle: "\(stats.highSeverityAlerts) high severity",
                            icon: "exclamationmark.triangle.fill",
                            iconColor: DesignSystem.Colors.error
                        )
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                }

                // Two-column layout for alerts and activity
                HStack(alignment: .top, spacing: DesignSystem.Spacing.lg) {
                    // Red Flag Alerts
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(DesignSystem.Colors.error)
                            Text("Red Flag Alerts")
                                .font(DesignSystem.Typography.headlineSmall)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                            Spacer()
                        }

                        ForEach(viewModel.redFlagAlerts.prefix(5)) { alert in
                            IAAlertCard(
                                title: alert.redFlag.flag,
                                message: "\(alert.patientName) - \(alert.redFlag.details ?? "")",
                                severity: alert.redFlag.severity,
                                timestamp: alert.detectedAt
                            )
                        }

                        if viewModel.redFlagAlerts.isEmpty {
                            IACard {
                                HStack {
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundColor(DesignSystem.Colors.success)
                                    Text("No active red flags")
                                        .foregroundColor(DesignSystem.Colors.textSecondary)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)

                    // Recent Activity
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Text("Recent Activity")
                            .font(DesignSystem.Typography.headlineSmall)
                            .foregroundColor(DesignSystem.Colors.textPrimary)

                        IACard {
                            VStack(spacing: 0) {
                                ForEach(Array(viewModel.recentActivity.prefix(8).enumerated()), id: \.element.id) { index, activity in
                                    ActivityRow(activity: activity)

                                    if index < min(7, viewModel.recentActivity.count - 1) {
                                        Divider()
                                            .padding(.leading, 44)
                                    }
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, DesignSystem.Spacing.lg)
            }
            .padding(.vertical, DesignSystem.Spacing.lg)
        }
        .background(DesignSystem.Colors.background)
        .navigationTitle("Dashboard")
        .task {
            if viewModel.stats == nil {
                viewModel.loadSampleData()
            }
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }
}

// MARK: - iPad Patients List View
struct iPadPatientsListView: View {
    @Binding var selectedPatient: PatientWithDetails?
    @StateObject private var viewModel = PatientsViewModel()
    @State private var showAddPatient = false

    var body: some View {
        List(viewModel.filteredPatients, selection: $selectedPatient) { patient in
            PatientListRow(patient: patient)
                .tag(patient)
        }
        .listStyle(.sidebar)
        .searchable(text: $viewModel.searchQuery, prompt: "Search patients")
        .onChange(of: viewModel.searchQuery) { _, _ in
            viewModel.search()
        }
        .navigationTitle("Patients")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAddPatient = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddPatient) {
            AddPatientSheet()
        }
        .task {
            if viewModel.patients.isEmpty {
                viewModel.loadSampleData()
            }
        }
    }
}

struct PatientListRow: View {
    let patient: PatientWithDetails

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            ZStack(alignment: .topTrailing) {
                IAAvatar(name: patient.patient.fullName, size: .medium)

                if patient.hasRedFlags {
                    Circle()
                        .fill(DesignSystem.Colors.error)
                        .frame(width: 10, height: 10)
                        .overlay(Circle().stroke(DesignSystem.Colors.surface, lineWidth: 2))
                        .offset(x: 2, y: -2)
                }
            }

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxxs) {
                Text(patient.patient.fullName)
                    .font(DesignSystem.Typography.titleSmall)
                    .foregroundColor(DesignSystem.Colors.textPrimary)

                Text("\(patient.patient.age) years old")
                    .font(DesignSystem.Typography.bodySmall)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }

            Spacer()

            if let status = patient.displayStatus {
                Circle()
                    .fill(status.color)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.vertical, DesignSystem.Spacing.xxs)
    }
}

// MARK: - Device Adaptive View
struct DeviceAdaptiveView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var networkMonitor: NetworkMonitor

    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                // iPad layout
                iPadMainView()
            } else {
                // iPhone layout
                MainTabView()
            }
        }
    }
}

#Preview("iPad") {
    iPadMainView()
        .environmentObject(AppState())
        .environmentObject(AuthViewModel())
        .previewDevice("iPad Pro (12.9-inch) (6th generation)")
}

#Preview("iPhone") {
    MainTabView()
        .environmentObject(AppState())
        .environmentObject(AuthViewModel())
        .environmentObject(NetworkMonitor())
}
