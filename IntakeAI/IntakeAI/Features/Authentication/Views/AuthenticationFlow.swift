import SwiftUI

struct AuthenticationFlow: View {
    @State private var showLogin = true
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                DesignSystem.Colors.background
                    .ignoresSafeArea()

                if showLogin {
                    LoginView(showLogin: $showLogin)
                        .transition(.asymmetric(
                            insertion: .move(edge: .leading).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                } else {
                    RegisterView(showLogin: $showLogin)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .trailing).combined(with: .opacity)
                        ))
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showLogin)
        }
    }
}

// MARK: - Login View
struct LoginView: View {
    @Binding var showLogin: Bool
    @EnvironmentObject var authViewModel: AuthViewModel
    @FocusState private var focusedField: Field?

    enum Field {
        case email
        case password
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: DesignSystem.Spacing.md) {
                    // Logo
                    ZStack {
                        Circle()
                            .fill(DesignSystem.Colors.primary.opacity(0.1))
                            .frame(width: 80, height: 80)

                        Image(systemName: "heart.text.square.fill")
                            .font(.system(size: 40, weight: .medium))
                            .foregroundStyle(DesignSystem.Colors.primaryGradient)
                    }

                    VStack(spacing: DesignSystem.Spacing.xs) {
                        Text("Welcome back")
                            .font(DesignSystem.Typography.displayMedium)
                            .foregroundColor(DesignSystem.Colors.textPrimary)

                        Text("Sign in to continue managing your patients")
                            .font(DesignSystem.Typography.bodyMedium)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.top, DesignSystem.Spacing.xxl)
                .padding(.bottom, DesignSystem.Spacing.xxxl)

                // Form
                VStack(spacing: DesignSystem.Spacing.lg) {
                    IATextField(
                        "Email",
                        text: $authViewModel.loginEmail,
                        icon: "envelope",
                        keyboardType: .emailAddress,
                        textContentType: .emailAddress,
                        autocapitalization: .never,
                        errorMessage: authViewModel.loginEmailError
                    )
                    .focused($focusedField, equals: .email)
                    .submitLabel(.next)
                    .onSubmit {
                        focusedField = .password
                    }

                    IATextField(
                        "Password",
                        text: $authViewModel.loginPassword,
                        icon: "lock",
                        isSecure: true,
                        textContentType: .password,
                        autocapitalization: .never,
                        errorMessage: authViewModel.loginPasswordError
                    )
                    .focused($focusedField, equals: .password)
                    .submitLabel(.go)
                    .onSubmit {
                        Task {
                            await authViewModel.login()
                        }
                    }

                    // Forgot password
                    HStack {
                        Spacer()
                        Button("Forgot Password?") {
                            // TODO: Implement forgot password
                        }
                        .font(DesignSystem.Typography.labelMedium)
                        .foregroundColor(DesignSystem.Colors.primary)
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.lg)

                // Error message
                if let error = authViewModel.error {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Image(systemName: "exclamationmark.circle.fill")
                        Text(error)
                    }
                    .font(DesignSystem.Typography.bodySmall)
                    .foregroundColor(DesignSystem.Colors.error)
                    .padding(DesignSystem.Spacing.md)
                    .frame(maxWidth: .infinity)
                    .background(DesignSystem.Colors.error.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.top, DesignSystem.Spacing.md)
                    .onTapGesture {
                        authViewModel.clearError()
                    }
                }

                // Sign in button
                IAButton(
                    "Sign In",
                    style: .primary,
                    size: .large,
                    isLoading: authViewModel.isLoading,
                    isFullWidth: true
                ) {
                    focusedField = nil
                    Task {
                        await authViewModel.login()
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.lg)
                .padding(.top, DesignSystem.Spacing.xl)

                // Divider
                HStack {
                    Rectangle()
                        .fill(DesignSystem.Colors.divider)
                        .frame(height: 1)
                    Text("or")
                        .font(DesignSystem.Typography.labelMedium)
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                        .padding(.horizontal, DesignSystem.Spacing.md)
                    Rectangle()
                        .fill(DesignSystem.Colors.divider)
                        .frame(height: 1)
                }
                .padding(.horizontal, DesignSystem.Spacing.lg)
                .padding(.vertical, DesignSystem.Spacing.xl)

                // Sign up link
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Text("Don't have an account?")
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(DesignSystem.Colors.textSecondary)

                    Button("Create Account") {
                        showLogin = false
                    }
                    .font(DesignSystem.Typography.titleSmall)
                    .foregroundColor(DesignSystem.Colors.primary)
                }
                .padding(.bottom, DesignSystem.Spacing.xxl)
            }
        }
        .scrollDismissesKeyboard(.interactively)
    }
}

// MARK: - Register View
struct RegisterView: View {
    @Binding var showLogin: Bool
    @EnvironmentObject var authViewModel: AuthViewModel
    @FocusState private var focusedField: Field?

    enum Field: Hashable {
        case firstName
        case lastName
        case title
        case practiceName
        case email
        case password
        case confirmPassword
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: DesignSystem.Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(DesignSystem.Colors.primary.opacity(0.1))
                            .frame(width: 80, height: 80)

                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 36, weight: .medium))
                            .foregroundStyle(DesignSystem.Colors.primaryGradient)
                    }

                    VStack(spacing: DesignSystem.Spacing.xs) {
                        Text("Create Account")
                            .font(DesignSystem.Typography.displayMedium)
                            .foregroundColor(DesignSystem.Colors.textPrimary)

                        Text("Join IntakeAI to streamline patient intake")
                            .font(DesignSystem.Typography.bodyMedium)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.top, DesignSystem.Spacing.xl)
                .padding(.bottom, DesignSystem.Spacing.xxl)

                // Form
                VStack(spacing: DesignSystem.Spacing.md) {
                    // Name row
                    HStack(spacing: DesignSystem.Spacing.md) {
                        IATextField(
                            "First Name",
                            text: $authViewModel.registerFirstName,
                            textContentType: .givenName,
                            autocapitalization: .words,
                            errorMessage: authViewModel.registerFirstNameError
                        )
                        .focused($focusedField, equals: .firstName)

                        IATextField(
                            "Last Name",
                            text: $authViewModel.registerLastName,
                            textContentType: .familyName,
                            autocapitalization: .words,
                            errorMessage: authViewModel.registerLastNameError
                        )
                        .focused($focusedField, equals: .lastName)
                    }

                    // Title and Practice (optional)
                    HStack(spacing: DesignSystem.Spacing.md) {
                        IATextField(
                            "Title (e.g., MD, ND)",
                            text: $authViewModel.registerTitle,
                            autocapitalization: .characters,
                            helperText: "Optional"
                        )
                        .focused($focusedField, equals: .title)

                        IATextField(
                            "Practice Name",
                            text: $authViewModel.registerPracticeName,
                            autocapitalization: .words,
                            helperText: "Optional"
                        )
                        .focused($focusedField, equals: .practiceName)
                    }

                    IATextField(
                        "Email",
                        text: $authViewModel.registerEmail,
                        icon: "envelope",
                        keyboardType: .emailAddress,
                        textContentType: .emailAddress,
                        autocapitalization: .never,
                        errorMessage: authViewModel.registerEmailError
                    )
                    .focused($focusedField, equals: .email)

                    IATextField(
                        "Password",
                        text: $authViewModel.registerPassword,
                        icon: "lock",
                        isSecure: true,
                        textContentType: .newPassword,
                        autocapitalization: .never,
                        errorMessage: authViewModel.registerPasswordError,
                        helperText: authViewModel.registerPasswordError == nil ? "Min 8 chars, uppercase, lowercase, and number" : nil
                    )
                    .focused($focusedField, equals: .password)

                    IATextField(
                        "Confirm Password",
                        text: $authViewModel.registerConfirmPassword,
                        icon: "lock.shield",
                        isSecure: true,
                        textContentType: .newPassword,
                        autocapitalization: .never,
                        errorMessage: authViewModel.registerConfirmPasswordError
                    )
                    .focused($focusedField, equals: .confirmPassword)
                }
                .padding(.horizontal, DesignSystem.Spacing.lg)

                // Error message
                if let error = authViewModel.error {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Image(systemName: "exclamationmark.circle.fill")
                        Text(error)
                    }
                    .font(DesignSystem.Typography.bodySmall)
                    .foregroundColor(DesignSystem.Colors.error)
                    .padding(DesignSystem.Spacing.md)
                    .frame(maxWidth: .infinity)
                    .background(DesignSystem.Colors.error.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.top, DesignSystem.Spacing.md)
                    .onTapGesture {
                        authViewModel.clearError()
                    }
                }

                // Create account button
                IAButton(
                    "Create Account",
                    style: .primary,
                    size: .large,
                    isLoading: authViewModel.isLoading,
                    isFullWidth: true
                ) {
                    focusedField = nil
                    Task {
                        await authViewModel.register()
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.lg)
                .padding(.top, DesignSystem.Spacing.xl)

                // Terms
                Text("By creating an account, you agree to our Terms of Service and Privacy Policy")
                    .font(DesignSystem.Typography.labelSmall)
                    .foregroundColor(DesignSystem.Colors.textTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DesignSystem.Spacing.xl)
                    .padding(.top, DesignSystem.Spacing.md)

                // Sign in link
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Text("Already have an account?")
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(DesignSystem.Colors.textSecondary)

                    Button("Sign In") {
                        showLogin = true
                    }
                    .font(DesignSystem.Typography.titleSmall)
                    .foregroundColor(DesignSystem.Colors.primary)
                }
                .padding(.top, DesignSystem.Spacing.xl)
                .padding(.bottom, DesignSystem.Spacing.xxl)
            }
        }
        .scrollDismissesKeyboard(.interactively)
    }
}

#Preview {
    AuthenticationFlow()
        .environmentObject(AuthViewModel())
}
