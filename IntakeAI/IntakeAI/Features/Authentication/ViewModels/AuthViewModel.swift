import Foundation
import SwiftUI
import LocalAuthentication

// MARK: - Auth View Model
@MainActor
class AuthViewModel: ObservableObject {
    // Published state
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var error: String?

    // Form state
    @Published var loginEmail = ""
    @Published var loginPassword = ""
    @Published var registerEmail = ""
    @Published var registerPassword = ""
    @Published var registerConfirmPassword = ""
    @Published var registerFirstName = ""
    @Published var registerLastName = ""
    @Published var registerTitle = ""
    @Published var registerPracticeName = ""

    // Validation state
    @Published var loginEmailError: String?
    @Published var loginPasswordError: String?
    @Published var registerEmailError: String?
    @Published var registerPasswordError: String?
    @Published var registerConfirmPasswordError: String?
    @Published var registerFirstNameError: String?
    @Published var registerLastNameError: String?

    private let networkClient = NetworkClient.shared
    private let keychain = KeychainManager.shared

    // MARK: - Session Management

    func checkExistingSession() async {
        isLoading = true
        defer { isLoading = false }

        // Check for stored access token
        if let token = keychain.getAccessToken() {
            await networkClient.setAccessToken(token)

            do {
                let response = try await networkClient.request(
                    .currentUser,
                    responseType: User.self
                )
                self.currentUser = response
                self.isAuthenticated = true
            } catch {
                // Token invalid or expired
                await networkClient.clearTokens()
                keychain.clearTokens()
                self.isAuthenticated = false
            }
        }
    }

    // MARK: - Login

    func login() async {
        guard validateLoginForm() else { return }

        isLoading = true
        error = nil

        do {
            let response = try await networkClient.request(
                .login(email: loginEmail.lowercased().trimmingCharacters(in: .whitespaces), password: loginPassword),
                responseType: AuthResponse.self
            )

            // Store token
            await networkClient.setAccessToken(response.accessToken)
            keychain.saveAccessToken(response.accessToken)

            // Update state
            self.currentUser = response.user
            self.isAuthenticated = true
            clearLoginForm()

            // Set user in crash reporting
            CrashReporting.shared.setUser(
                id: response.user.id,
                email: response.user.email,
                name: response.user.displayName
            )
            CrashReporting.shared.addBreadcrumb(category: "auth", message: "User logged in")

            // Haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)

        } catch let networkError as NetworkError {
            self.error = networkError.errorDescription
            networkError.capture(context: ["action": "login"])
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        } catch {
            self.error = "An unexpected error occurred"
            error.capture(context: ["action": "login"])
        }

        isLoading = false
    }

    // MARK: - Register

    func register() async {
        guard validateRegistrationForm() else { return }

        isLoading = true
        error = nil

        let request = RegisterRequest(
            email: registerEmail.lowercased().trimmingCharacters(in: .whitespaces),
            password: registerPassword,
            firstName: registerFirstName.trimmingCharacters(in: .whitespaces),
            lastName: registerLastName.trimmingCharacters(in: .whitespaces),
            title: registerTitle.isEmpty ? nil : registerTitle.trimmingCharacters(in: .whitespaces),
            practiceName: registerPracticeName.isEmpty ? nil : registerPracticeName.trimmingCharacters(in: .whitespaces)
        )

        do {
            let response = try await networkClient.request(
                .register(request: request),
                responseType: AuthResponse.self
            )

            // Store token
            await networkClient.setAccessToken(response.accessToken)
            keychain.saveAccessToken(response.accessToken)

            // Update state
            self.currentUser = response.user
            self.isAuthenticated = true
            clearRegistrationForm()

            // Set user in crash reporting
            CrashReporting.shared.setUser(
                id: response.user.id,
                email: response.user.email,
                name: response.user.displayName
            )
            CrashReporting.shared.addBreadcrumb(category: "auth", message: "User registered")

            // Haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)

        } catch let networkError as NetworkError {
            self.error = networkError.errorDescription
            networkError.capture(context: ["action": "register"])
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        } catch {
            self.error = "An unexpected error occurred"
            error.capture(context: ["action": "register"])
        }

        isLoading = false
    }

    // MARK: - Logout

    func logout() async {
        isLoading = true

        do {
            try await networkClient.request(.logout)
        } catch {
            // Ignore logout errors - clear local state anyway
        }

        await networkClient.clearTokens()
        keychain.clearTokens()

        // Clear user from crash reporting
        CrashReporting.shared.clearUser()
        CrashReporting.shared.addBreadcrumb(category: "auth", message: "User logged out")

        self.currentUser = nil
        self.isAuthenticated = false
        isLoading = false
    }

    // MARK: - Biometric Authentication

    func authenticateWithBiometrics() async -> Bool {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return false
        }

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Authenticate to access IntakeAI"
            )
            return success
        } catch {
            return false
        }
    }

    // MARK: - Validation

    private func validateLoginForm() -> Bool {
        var isValid = true

        // Email validation
        if loginEmail.isEmpty {
            loginEmailError = "Email is required"
            isValid = false
        } else if !isValidEmail(loginEmail) {
            loginEmailError = "Please enter a valid email"
            isValid = false
        } else {
            loginEmailError = nil
        }

        // Password validation
        if loginPassword.isEmpty {
            loginPasswordError = "Password is required"
            isValid = false
        } else {
            loginPasswordError = nil
        }

        return isValid
    }

    private func validateRegistrationForm() -> Bool {
        var isValid = true

        // First name
        if registerFirstName.trimmingCharacters(in: .whitespaces).isEmpty {
            registerFirstNameError = "First name is required"
            isValid = false
        } else {
            registerFirstNameError = nil
        }

        // Last name
        if registerLastName.trimmingCharacters(in: .whitespaces).isEmpty {
            registerLastNameError = "Last name is required"
            isValid = false
        } else {
            registerLastNameError = nil
        }

        // Email
        if registerEmail.isEmpty {
            registerEmailError = "Email is required"
            isValid = false
        } else if !isValidEmail(registerEmail) {
            registerEmailError = "Please enter a valid email"
            isValid = false
        } else {
            registerEmailError = nil
        }

        // Password
        if registerPassword.isEmpty {
            registerPasswordError = "Password is required"
            isValid = false
        } else if registerPassword.count < 8 {
            registerPasswordError = "Password must be at least 8 characters"
            isValid = false
        } else if !hasUppercase(registerPassword) || !hasLowercase(registerPassword) || !hasNumber(registerPassword) {
            registerPasswordError = "Password must contain uppercase, lowercase, and numbers"
            isValid = false
        } else {
            registerPasswordError = nil
        }

        // Confirm password
        if registerConfirmPassword.isEmpty {
            registerConfirmPasswordError = "Please confirm your password"
            isValid = false
        } else if registerConfirmPassword != registerPassword {
            registerConfirmPasswordError = "Passwords do not match"
            isValid = false
        } else {
            registerConfirmPasswordError = nil
        }

        return isValid
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return email.range(of: emailRegex, options: .regularExpression) != nil
    }

    private func hasUppercase(_ string: String) -> Bool {
        string.range(of: "[A-Z]", options: .regularExpression) != nil
    }

    private func hasLowercase(_ string: String) -> Bool {
        string.range(of: "[a-z]", options: .regularExpression) != nil
    }

    private func hasNumber(_ string: String) -> Bool {
        string.range(of: "[0-9]", options: .regularExpression) != nil
    }

    // MARK: - Form Clearing

    private func clearLoginForm() {
        loginEmail = ""
        loginPassword = ""
        loginEmailError = nil
        loginPasswordError = nil
    }

    private func clearRegistrationForm() {
        registerEmail = ""
        registerPassword = ""
        registerConfirmPassword = ""
        registerFirstName = ""
        registerLastName = ""
        registerTitle = ""
        registerPracticeName = ""
        registerEmailError = nil
        registerPasswordError = nil
        registerConfirmPasswordError = nil
        registerFirstNameError = nil
        registerLastNameError = nil
    }

    func clearError() {
        error = nil
    }
}

// MARK: - Keychain Manager
class KeychainManager {
    static let shared = KeychainManager()

    private let accessTokenKey = "com.intakeai.accessToken"
    private let service = "com.intakeai.app"

    private init() {}

    func saveAccessToken(_ token: String) {
        let data = Data(token.utf8)

        // Delete existing
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: accessTokenKey
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        // Add new
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: accessTokenKey,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        SecItemAdd(addQuery as CFDictionary, nil)
    }

    func getAccessToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: accessTokenKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            return nil
        }

        return token
    }

    func clearTokens() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]
        SecItemDelete(query as CFDictionary)
    }
}
