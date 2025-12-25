import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var networkMonitor: NetworkMonitor

    var body: some View {
        ZStack(alignment: .top) {
            TabView(selection: $selectedTab) {
                DashboardView()
                    .tabItem {
                        Label("Dashboard", systemImage: selectedTab == 0 ? "house.fill" : "house")
                    }
                    .tag(0)

                PatientsListView()
                    .tabItem {
                        Label("Patients", systemImage: selectedTab == 1 ? "person.2.fill" : "person.2")
                    }
                    .tag(1)

                IntakeLinksView()
                    .tabItem {
                        Label("Links", systemImage: selectedTab == 2 ? "link.circle.fill" : "link.circle")
                    }
                    .tag(2)

                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: selectedTab == 3 ? "gearshape.fill" : "gearshape")
                    }
                    .tag(3)
            }
            .tint(DesignSystem.Colors.primary)
            .onChange(of: selectedTab) { oldValue, newValue in
                if oldValue != newValue {
                    appState.triggerHaptic(.light)
                }
            }

            // Offline Banner
            if !networkMonitor.isConnected {
                OfflineBanner()
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: networkMonitor.isConnected)
    }
}

// MARK: - Intake Links View
struct IntakeLinksView: View {
    @State private var links: [IntakeLink] = []
    @State private var isLoading = false
    @State private var showCreateLink = false
    @State private var selectedLink: IntakeLink?

    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background
                    .ignoresSafeArea()

                if isLoading && links.isEmpty {
                    IALoadingState(message: "Loading intake links...")
                } else if links.isEmpty {
                    IAEmptyState(
                        icon: "link.circle",
                        title: "No Intake Links",
                        message: "Create intake links to send to your patients for form completion.",
                        actionTitle: "Create Link"
                    ) {
                        showCreateLink = true
                    }
                } else {
                    linksList
                }
            }
            .navigationTitle("Intake Links")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    IAIconButton(icon: "plus", style: .primary, size: .small) {
                        showCreateLink = true
                    }
                }
            }
            .sheet(isPresented: $showCreateLink) {
                SelectPatientForLinkSheet()
            }
            .sheet(item: $selectedLink) { link in
                LinkDetailSheet(link: link)
            }
        }
        .task {
            await loadLinks()
        }
    }

    private var linksList: some View {
        ScrollView {
            LazyVStack(spacing: DesignSystem.Spacing.sm) {
                // Stats
                HStack(spacing: DesignSystem.Spacing.md) {
                    let activeCount = links.filter { $0.isActive }.count
                    let usedCount = links.filter { $0.isUsed }.count

                    StatPill(value: "\(activeCount)", label: "Active", color: DesignSystem.Colors.success)
                    StatPill(value: "\(usedCount)", label: "Used", color: DesignSystem.Colors.primary)
                    StatPill(value: "\(links.count - activeCount - usedCount)", label: "Expired", color: DesignSystem.Colors.textTertiary)
                }
                .padding(.horizontal, DesignSystem.Spacing.md)

                // Group links by status
                let activeLinks = links.filter { $0.isActive }
                let usedLinks = links.filter { $0.isUsed }
                let expiredLinks = links.filter { !$0.isActive && !$0.isUsed }

                if !activeLinks.isEmpty {
                    linkSection(title: "Active Links", links: activeLinks)
                }

                if !usedLinks.isEmpty {
                    linkSection(title: "Used Links", links: usedLinks)
                }

                if !expiredLinks.isEmpty {
                    linkSection(title: "Expired Links", links: expiredLinks)
                }
            }
            .padding(.bottom, DesignSystem.Spacing.xxl)
        }
        .refreshable {
            await loadLinks()
        }
    }

    private func linkSection(title: String, links: [IntakeLink]) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text(title)
                .font(DesignSystem.Typography.headlineSmall)
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.top, DesignSystem.Spacing.md)

            ForEach(links) { link in
                LinkRow(link: link) {
                    selectedLink = link
                }
                .padding(.horizontal, DesignSystem.Spacing.md)
            }
        }
    }

    private func loadLinks() async {
        isLoading = true
        // Simulate API call
        try? await Task.sleep(nanoseconds: 500_000_000)
        links = IntakeLink.samples
        isLoading = false
    }
}

// MARK: - Stat Pill
struct StatPill: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xxxs) {
            Text(value)
                .font(DesignSystem.Typography.headlineMedium)
                .foregroundColor(color)

            Text(label)
                .font(DesignSystem.Typography.labelSmall)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignSystem.Spacing.sm)
        .background(DesignSystem.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: .continuous))
        .shadow(
            color: DesignSystem.Shadows.small.color,
            radius: DesignSystem.Shadows.small.radius,
            x: DesignSystem.Shadows.small.x,
            y: DesignSystem.Shadows.small.y
        )
    }
}

// MARK: - Link Row
struct LinkRow: View {
    let link: IntakeLink
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                ZStack {
                    Circle()
                        .fill(link.status.color.opacity(0.12))
                        .frame(width: 44, height: 44)

                    Image(systemName: link.status.icon)
                        .font(.system(size: DesignSystem.IconSize.md))
                        .foregroundColor(link.status.color)
                }

                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxxs) {
                    Text("Patient Link")
                        .font(DesignSystem.Typography.titleSmall)
                        .foregroundColor(DesignSystem.Colors.textPrimary)

                    HStack(spacing: DesignSystem.Spacing.xs) {
                        IABadge(link.status.label, style: link.isActive ? .success : (link.isUsed ? .primary : .neutral), size: .small)

                        if let remaining = link.timeRemaining {
                            Text(remaining)
                                .font(DesignSystem.Typography.labelSmall)
                                .foregroundColor(DesignSystem.Colors.textTertiary)
                        }
                    }
                }

                Spacer()

                if link.isActive {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: DesignSystem.IconSize.md))
                        .foregroundColor(DesignSystem.Colors.primary)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: DesignSystem.IconSize.sm))
                    .foregroundColor(DesignSystem.Colors.textTertiary)
            }
            .padding(DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg, style: .continuous))
            .shadow(
                color: DesignSystem.Shadows.small.color,
                radius: DesignSystem.Shadows.small.radius,
                x: DesignSystem.Shadows.small.x,
                y: DesignSystem.Shadows.small.y
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(DesignSystem.Animation.quick, value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Select Patient Sheet
struct SelectPatientForLinkSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchQuery = ""
    @State private var patients: [Patient] = Patient.samples

    var filteredPatients: [Patient] {
        if searchQuery.isEmpty {
            return patients
        }
        return patients.filter { $0.fullName.localizedCaseInsensitiveContains(searchQuery) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                IASearchField(text: $searchQuery, placeholder: "Search patients...")
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .padding(.vertical, DesignSystem.Spacing.sm)

                List(filteredPatients) { patient in
                    Button {
                        // Create link for patient
                        dismiss()
                    } label: {
                        HStack(spacing: DesignSystem.Spacing.sm) {
                            IAAvatar(name: patient.fullName, size: .medium)

                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxxs) {
                                Text(patient.fullName)
                                    .font(DesignSystem.Typography.titleSmall)
                                    .foregroundColor(DesignSystem.Colors.textPrimary)

                                Text("\(patient.age) years old")
                                    .font(DesignSystem.Typography.bodySmall)
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                            }

                            Spacer()
                        }
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Select Patient")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Link Detail Sheet
struct LinkDetailSheet: View {
    let link: IntakeLink
    @Environment(\.dismiss) private var dismiss
    @State private var showShareSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.lg) {
                    // Status Icon
                    ZStack {
                        Circle()
                            .fill(link.status.color.opacity(0.12))
                            .frame(width: 80, height: 80)

                        Image(systemName: link.status.icon)
                            .font(.system(size: 36))
                            .foregroundColor(link.status.color)
                    }
                    .padding(.top, DesignSystem.Spacing.lg)

                    // Status
                    VStack(spacing: DesignSystem.Spacing.xs) {
                        Text(link.status.label)
                            .font(DesignSystem.Typography.headlineMedium)
                            .foregroundColor(DesignSystem.Colors.textPrimary)

                        if let remaining = link.timeRemaining {
                            Text(remaining)
                                .font(DesignSystem.Typography.bodyMedium)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        }
                    }

                    // Link URL
                    if link.isActive {
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
                                        let generator = UINotificationFeedbackGenerator()
                                        generator.notificationOccurred(.success)
                                    }

                                    IAButton("Share", style: .primary, icon: "square.and.arrow.up") {
                                        showShareSheet = true
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, DesignSystem.Spacing.md)
                    }

                    // Details
                    IACard {
                        VStack(spacing: DesignSystem.Spacing.sm) {
                            DetailRow(label: "Created", value: link.createdAt.relativeFormatted)
                            Divider()
                            DetailRow(label: "Expires", value: DateFormatter.localizedString(from: link.expiresAt, dateStyle: .medium, timeStyle: .short))
                            Divider()
                            DetailRow(label: "Verification Attempts", value: "\(link.verificationAttempts)")
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.md)
                }
            }
            .background(DesignSystem.Colors.background)
            .navigationTitle("Link Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(items: [link.shareableURL])
            }
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(DesignSystem.Typography.bodySmall)
                .foregroundColor(DesignSystem.Colors.textSecondary)
            Spacer()
            Text(value)
                .font(DesignSystem.Typography.bodyMedium)
                .foregroundColor(DesignSystem.Colors.textPrimary)
        }
    }
}

// MARK: - iPad Adaptive Layout
struct AdaptiveNavigationView<Content: View>: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        if horizontalSizeClass == .regular {
            // iPad - use NavigationSplitView
            NavigationSplitView {
                content
            } detail: {
                Text("Select an item")
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
        } else {
            // iPhone - use NavigationStack
            NavigationStack {
                content
            }
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AppState())
        .environmentObject(AuthViewModel())
        .environmentObject(NetworkMonitor())
}
