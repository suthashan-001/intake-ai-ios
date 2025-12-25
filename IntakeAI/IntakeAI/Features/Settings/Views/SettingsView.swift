import SwiftUI
import LocalAuthentication

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showLogoutConfirmation = false
    @State private var showChangePassword = false
    @State private var showEditProfile = false
    @State private var biometricType: LABiometryType = .none

    var body: some View {
        NavigationStack {
            List {
                // Profile Section with material background
                Section {
                    profileHeader
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())

                // Account Section
                Section {
                    NavigationLink {
                        EditProfileView()
                    } label: {
                        SettingsRow(icon: "person.circle.fill", iconColor: DesignSystem.Colors.primary, title: "Edit Profile")
                    }

                    Button {
                        showChangePassword = true
                    } label: {
                        SettingsRow(icon: "key.fill", iconColor: .orange, title: "Change Password")
                    }
                    .foregroundStyle(.primary)

                    if biometricType != .none {
                        Toggle(isOn: $appState.biometricEnabled) {
                            SettingsRow(
                                icon: biometricType == .faceID ? "faceid" : "touchid",
                                iconColor: .green,
                                title: biometricType == .faceID ? "Face ID" : "Touch ID"
                            )
                        }
                        .tint(DesignSystem.Colors.primary)
                        .sensoryFeedback(.impact(flexibility: .soft), trigger: appState.biometricEnabled)
                    }
                } header: {
                    Text("Account")
                }

                // Preferences Section
                Section {
                    Picker(selection: $appState.colorScheme) {
                        Text("System").tag(Optional<ColorScheme>.none)
                        Text("Light").tag(Optional<ColorScheme>.some(.light))
                        Text("Dark").tag(Optional<ColorScheme>.some(.dark))
                    } label: {
                        SettingsRow(icon: "moon.circle.fill", iconColor: .indigo, title: "Appearance")
                    }
                    .sensoryFeedback(.selection, trigger: appState.colorScheme)
                    .onChange(of: appState.colorScheme) { _, _ in
                        appState.saveSettings()
                    }

                    Toggle(isOn: $appState.hapticFeedbackEnabled) {
                        SettingsRow(icon: "waveform", iconColor: .cyan, title: "Haptic Feedback")
                    }
                    .tint(DesignSystem.Colors.primary)
                    .sensoryFeedback(.impact(flexibility: .soft), trigger: appState.hapticFeedbackEnabled)
                    .onChange(of: appState.hapticFeedbackEnabled) { _, _ in
                        appState.saveSettings()
                    }

                    Toggle(isOn: $appState.notificationsEnabled) {
                        SettingsRow(icon: "bell.badge.fill", iconColor: .red, title: "Notifications")
                    }
                    .tint(DesignSystem.Colors.primary)
                    .sensoryFeedback(.impact(flexibility: .soft), trigger: appState.notificationsEnabled)
                    .onChange(of: appState.notificationsEnabled) { _, _ in
                        appState.saveSettings()
                    }
                } header: {
                    Text("Preferences")
                }

                // Support Section
                Section {
                    NavigationLink {
                        AboutView()
                    } label: {
                        SettingsRow(icon: "info.circle.fill", iconColor: .gray, title: "About IntakeAI")
                    }

                    Link(destination: URL(string: "https://intakeai.app/help")!) {
                        SettingsRow(icon: "questionmark.circle.fill", iconColor: .blue, title: "Help Center", showChevron: true)
                    }

                    Link(destination: URL(string: "https://intakeai.app/privacy")!) {
                        SettingsRow(icon: "hand.raised.fill", iconColor: .gray, title: "Privacy Policy", showChevron: true)
                    }

                    Link(destination: URL(string: "https://intakeai.app/terms")!) {
                        SettingsRow(icon: "doc.text.fill", iconColor: .gray, title: "Terms of Service", showChevron: true)
                    }
                } header: {
                    Text("Support")
                }

                // Sign Out
                Section {
                    Button(role: .destructive) {
                        showLogoutConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.forward")
                                .font(.system(.subheadline, weight: .medium))
                            Text("Sign Out")
                                .font(.system(.body, weight: .regular))
                            Spacer()
                        }
                    }
                }

                // App Version
                Section {
                    HStack {
                        Text("Version")
                            .font(.system(.body, weight: .regular))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("1.0.0 (1)")
                            .font(.system(.body, weight: .regular))
                            .foregroundStyle(.tertiary)
                    }
                } footer: {
                    Text("Made with care for healthcare providers")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, DesignSystem.Spacing.lg)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .confirmationDialog("Sign Out", isPresented: $showLogoutConfirmation, titleVisibility: .visible) {
                Button("Sign Out", role: .destructive) {
                    Task {
                        await authViewModel.logout()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .sheet(isPresented: $showChangePassword) {
                ChangePasswordView()
            }
        }
        .onAppear {
            checkBiometricType()
        }
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            if let user = authViewModel.currentUser {
                // Avatar with gradient background
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [DesignSystem.Colors.primary, DesignSystem.Colors.primary.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 64, height: 64)

                    Text(user.initials)
                        .font(.system(.title2, design: .rounded, weight: .semibold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(user.displayName)
                        .font(.system(.title3, weight: .semibold))
                        .foregroundStyle(.primary)

                    Text(user.email)
                        .font(.system(.subheadline, weight: .regular))
                        .foregroundStyle(.secondary)

                    if let practiceName = user.practiceName {
                        Text(practiceName)
                            .font(.system(.caption, weight: .regular))
                            .foregroundStyle(.tertiary)
                    }
                }

                Spacer()

                // Edit button
                NavigationLink {
                    EditProfileView()
                } label: {
                    Image(systemName: "pencil.circle.fill")
                        .font(.title2)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(DesignSystem.Colors.primary)
                }
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.vertical, DesignSystem.Spacing.sm)
    }

    // MARK: - Biometric Check

    private func checkBiometricType() {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            biometricType = context.biometryType
        }
    }
}

// MARK: - Settings Row
struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    var showChevron: Bool = false

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            // Icon with background
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(iconColor)
                    .frame(width: 28, height: 28)

                Image(systemName: icon)
                    .font(.system(.caption, weight: .semibold))
                    .foregroundStyle(.white)
            }

            Text(title)
                .font(.system(.body, weight: .regular))
                .foregroundStyle(.primary)

            if showChevron {
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.system(.caption, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
        }
    }
}

// MARK: - Edit Profile View
struct EditProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var title = ""
    @State private var practiceName = ""
    @State private var isLoading = false
    @State private var error: String?

    var body: some View {
        Form {
            Section("Personal Information") {
                TextField("First Name", text: $firstName)
                TextField("Last Name", text: $lastName)
            }

            Section("Professional Details") {
                TextField("Title (e.g., MD, ND)", text: $title)
                TextField("Practice Name", text: $practiceName)
            }

            if let error = error {
                Section {
                    Text(error)
                        .foregroundColor(DesignSystem.Colors.error)
                }
            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    saveProfile()
                }
                .fontWeight(.semibold)
                .disabled(isLoading)
            }
        }
        .onAppear {
            if let user = authViewModel.currentUser {
                firstName = user.firstName
                lastName = user.lastName
                title = user.title ?? ""
                practiceName = user.practiceName ?? ""
            }
        }
    }

    private func saveProfile() {
        isLoading = true
        // TODO: Implement profile update API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isLoading = false
            dismiss()
        }
    }
}

// MARK: - Change Password View
struct ChangePasswordView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Current Password") {
                    SecureField("Enter current password", text: $currentPassword)
                }

                Section("New Password") {
                    SecureField("Enter new password", text: $newPassword)
                    SecureField("Confirm new password", text: $confirmPassword)
                }

                Section {
                    Text("Password must be at least 8 characters with uppercase, lowercase, and numbers.")
                        .font(DesignSystem.Typography.labelSmall)
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                }

                if let error = error {
                    Section {
                        Text(error)
                            .foregroundColor(DesignSystem.Colors.error)
                    }
                }
            }
            .navigationTitle("Change Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        changePassword()
                    }
                    .fontWeight(.semibold)
                    .disabled(isLoading || newPassword.isEmpty || confirmPassword.isEmpty)
                }
            }
        }
    }

    private func changePassword() {
        guard newPassword == confirmPassword else {
            error = "Passwords do not match"
            return
        }

        guard newPassword.count >= 8 else {
            error = "Password must be at least 8 characters"
            return
        }

        isLoading = true
        // TODO: Implement password change API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isLoading = false
            dismiss()
        }
    }
}

// MARK: - About View
struct AboutView: View {
    @State private var showLogo = false

    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.xl) {
                // Logo with animation
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [DesignSystem.Colors.primary.opacity(0.2), DesignSystem.Colors.primary.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)

                    Image(systemName: "heart.text.square.fill")
                        .font(.system(size: 56, weight: .medium))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(DesignSystem.Colors.primary)
                        .scaleEffect(showLogo ? 1 : 0.8)
                        .opacity(showLogo ? 1 : 0)
                }
                .padding(.top, DesignSystem.Spacing.xl)

                VStack(spacing: 4) {
                    Text("IntakeAI")
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .foregroundStyle(.primary)

                    Text("AI-Powered Patient Intake")
                        .font(.system(.subheadline, weight: .regular))
                        .foregroundStyle(.secondary)

                    Text("Version 1.0.0")
                        .font(.system(.caption, weight: .medium))
                        .foregroundStyle(.tertiary)
                        .padding(.top, 4)
                }

                // Features with native styling
                VStack(spacing: 0) {
                    FeatureRow(icon: "brain.head.profile", title: "AI-Powered Summaries", description: "Intelligent clinical summaries generated by Google Gemini", color: .purple)
                    Divider().padding(.leading, 56)
                    FeatureRow(icon: "exclamationmark.triangle.fill", title: "Red Flag Detection", description: "8-layer safety system to catch critical conditions", color: .red)
                    Divider().padding(.leading, 56)
                    FeatureRow(icon: "shield.checkered", title: "Healthcare-Grade Security", description: "HIPAA-ready with HttpOnly cookie authentication", color: .green)
                    Divider().padding(.leading, 56)
                    FeatureRow(icon: "link.badge.plus", title: "Easy Patient Intake", description: "Send secure links for patients to complete forms", color: .blue)
                }
                .padding(DesignSystem.Spacing.md)
                .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(.horizontal, DesignSystem.Spacing.md)

                // Credits
                VStack(spacing: 4) {
                    Text("Built with care for healthcare providers")
                        .font(.system(.footnote, weight: .regular))
                        .foregroundStyle(.tertiary)

                    Text("© 2024 Suthashan Tharmarajah")
                        .font(.system(.caption2, weight: .regular))
                        .foregroundStyle(.quaternary)
                }
                .padding(.top, DesignSystem.Spacing.lg)
                .padding(.bottom, DesignSystem.Spacing.xxl)
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
                showLogo = true
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    var color: Color = DesignSystem.Colors.primary

    var body: some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.sm) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(.subheadline, weight: .semibold))
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.subheadline, weight: .medium))
                    .foregroundStyle(.primary)

                Text(description)
                    .font(.system(.caption, weight: .regular))
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, DesignSystem.Spacing.sm)
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
        .environmentObject(AuthViewModel())
}
