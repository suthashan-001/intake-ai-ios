import SwiftUI

@main
struct IntakeAIApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var networkMonitor = NetworkMonitor()

    init() {
        // Initialize crash reporting first
        CrashReporting.shared.configure()
        CrashReporting.shared.addBreadcrumb(category: "app", message: "App launched")

        configureAppearance()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(authViewModel)
                .environmentObject(networkMonitor)
                .preferredColorScheme(appState.colorScheme)
        }
    }

    private func configureAppearance() {
        // Configure navigation bar appearance
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = UIColor(DesignSystem.Colors.background)
        navAppearance.titleTextAttributes = [
            .foregroundColor: UIColor(DesignSystem.Colors.textPrimary),
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        navAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor(DesignSystem.Colors.textPrimary),
            .font: UIFont.systemFont(ofSize: 34, weight: .bold)
        ]

        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance

        // Configure tab bar appearance
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = UIColor(DesignSystem.Colors.surface)

        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance

        // Configure table view appearance
        UITableView.appearance().backgroundColor = UIColor(DesignSystem.Colors.background)
    }
}

// MARK: - Root View with Authentication State
struct RootView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var appState: AppState
    @State private var showSplash = true
    @State private var hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")

    var body: some View {
        ZStack {
            if showSplash {
                SplashScreen()
                    .transition(.opacity)
            } else if !hasCompletedOnboarding {
                // Show onboarding for first-time users
                OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
                    .transition(.asymmetric(
                        insertion: .opacity,
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            } else {
                Group {
                    if authViewModel.isAuthenticated {
                        DeviceAdaptiveView()
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                    } else {
                        AuthenticationFlow()
                            .transition(.asymmetric(
                                insertion: .move(edge: .leading).combined(with: .opacity),
                                removal: .move(edge: .trailing).combined(with: .opacity)
                            ))
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.4), value: showSplash)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: authViewModel.isAuthenticated)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: hasCompletedOnboarding)
        .onAppear {
            // Check for existing session
            Task {
                await authViewModel.checkExistingSession()
                try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds for splash
                withAnimation {
                    showSplash = false
                }
            }
        }
    }
}

// MARK: - App State
@MainActor
class AppState: ObservableObject {
    @Published var colorScheme: ColorScheme? = nil
    @Published var hapticFeedbackEnabled: Bool = true
    @Published var notificationsEnabled: Bool = true
    @Published var biometricEnabled: Bool = false

    init() {
        loadSettings()
    }

    func loadSettings() {
        let defaults = UserDefaults.standard

        if let schemeRaw = defaults.string(forKey: "colorScheme") {
            switch schemeRaw {
            case "light": colorScheme = .light
            case "dark": colorScheme = .dark
            default: colorScheme = nil
            }
        }

        hapticFeedbackEnabled = defaults.bool(forKey: "hapticFeedback")
        notificationsEnabled = defaults.bool(forKey: "notifications")
        biometricEnabled = defaults.bool(forKey: "biometric")
    }

    func saveSettings() {
        let defaults = UserDefaults.standard

        switch colorScheme {
        case .light: defaults.set("light", forKey: "colorScheme")
        case .dark: defaults.set("dark", forKey: "colorScheme")
        case .none: defaults.removeObject(forKey: "colorScheme")
        @unknown default: defaults.removeObject(forKey: "colorScheme")
        }

        defaults.set(hapticFeedbackEnabled, forKey: "hapticFeedback")
        defaults.set(notificationsEnabled, forKey: "notifications")
        defaults.set(biometricEnabled, forKey: "biometric")
    }

    func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        guard hapticFeedbackEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }

    func triggerNotificationHaptic(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard hapticFeedbackEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
}
