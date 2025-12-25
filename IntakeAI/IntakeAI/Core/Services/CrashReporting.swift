import Foundation
#if canImport(Sentry)
import Sentry
#endif

/// Crash Reporting Service using Sentry
/// To add Sentry to your project:
/// 1. In Xcode, go to File > Add Package Dependencies
/// 2. Enter: https://github.com/getsentry/sentry-cocoa
/// 3. Add to your target
final class CrashReporting {
    static let shared = CrashReporting()

    private init() {}

    /// Initialize Sentry SDK
    /// Call this in your App's init() method
    func configure() {
        #if canImport(Sentry)
        SentrySDK.start { options in
            // Get DSN from environment or use placeholder
            options.dsn = Bundle.main.object(forInfoDictionaryKey: "SENTRY_DSN") as? String
                ?? ProcessInfo.processInfo.environment["SENTRY_DSN"]
                ?? ""

            // Performance Monitoring
            options.tracesSampleRate = 1.0

            // Enable profiling (available in Sentry 8.x+)
            options.profilesSampleRate = 1.0

            // Enable all auto-instrumentation
            options.enableAutoPerformanceTracing = true
            options.enableUIViewControllerTracing = true
            options.enableNetworkTracking = true
            options.enableFileIOTracing = true
            options.enableCoreDataTracing = true

            // Capture screenshots on crashes
            options.attachScreenshot = true

            // Attach view hierarchy
            options.attachViewHierarchy = true

            // Environment
            #if DEBUG
            options.environment = "development"
            options.debug = true
            #else
            options.environment = "production"
            #endif

            // App version
            if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
               let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                options.releaseName = "intakeai-ios@\(version)+\(build)"
            }
        }
        #endif
    }

    /// Set the current user for crash reports
    func setUser(id: String, email: String?, name: String?) {
        #if canImport(Sentry)
        let user = User(userId: id)
        user.email = email
        user.username = name
        SentrySDK.setUser(user)
        #endif
    }

    /// Clear user data on logout
    func clearUser() {
        #if canImport(Sentry)
        SentrySDK.setUser(nil)
        #endif
    }

    /// Capture a non-fatal error
    func capture(error: Error, context: [String: Any]? = nil) {
        #if canImport(Sentry)
        SentrySDK.capture(error: error) { scope in
            if let context = context {
                scope.setContext(value: context, key: "additional_context")
            }
        }
        #endif

        // Always log locally in debug
        #if DEBUG
        print("❌ Error captured: \(error.localizedDescription)")
        if let context = context {
            print("   Context: \(context)")
        }
        #endif
    }

    /// Capture a message
    func capture(message: String, level: CrashReportingLevel = .info) {
        #if canImport(Sentry)
        SentrySDK.capture(message: message) { scope in
            scope.setLevel(level.sentryLevel)
        }
        #endif

        #if DEBUG
        print("📝 Message captured [\(level)]: \(message)")
        #endif
    }

    /// Add breadcrumb for debugging
    func addBreadcrumb(category: String, message: String, data: [String: Any]? = nil) {
        #if canImport(Sentry)
        let crumb = Breadcrumb()
        crumb.category = category
        crumb.message = message
        crumb.level = .info
        if let data = data {
            crumb.data = data
        }
        SentrySDK.addBreadcrumb(crumb)
        #endif
    }

    /// Start a performance transaction
    func startTransaction(name: String, operation: String) -> Any? {
        #if canImport(Sentry)
        return SentrySDK.startTransaction(name: name, operation: operation)
        #else
        return nil
        #endif
    }

    /// Finish a performance transaction
    func finishTransaction(_ transaction: Any?) {
        #if canImport(Sentry)
        (transaction as? Span)?.finish()
        #endif
    }
}

// MARK: - Log Level
enum CrashReportingLevel {
    case debug
    case info
    case warning
    case error
    case fatal

    #if canImport(Sentry)
    var sentryLevel: SentryLevel {
        switch self {
        case .debug: return .debug
        case .info: return .info
        case .warning: return .warning
        case .error: return .error
        case .fatal: return .fatal
        }
    }
    #endif
}

// MARK: - Convenience Extensions
extension Error {
    /// Capture this error to Sentry
    func capture(context: [String: Any]? = nil) {
        CrashReporting.shared.capture(error: self, context: context)
    }
}
