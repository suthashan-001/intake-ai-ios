import Foundation
import SwiftUI

// MARK: - Intake Link Model
/// Represents a secure intake link sent to patients for form completion
/// Security: 64-character token = 2^256 combinations (cryptographically secure)
struct IntakeLink: Identifiable, Codable, Equatable {
    let id: String
    let patientId: String
    let token: String
    let expiresAt: Date
    let createdAt: Date
    var usedAt: Date?
    var requiresDOBVerification: Bool
    var verificationAttempts: Int
    var lockedAt: Date?

    // Computed properties
    var isUsed: Bool {
        usedAt != nil
    }

    var isVerified: Bool {
        !requiresDOBVerification || (verificationAttempts > 0 && lockedAt == nil && usedAt != nil)
    }

    var isExpired: Bool {
        Date() > expiresAt
    }

    var isLocked: Bool {
        lockedAt != nil
    }

    var isActive: Bool {
        !isUsed && !isExpired && !isLocked
    }

    var attemptsRemaining: Int {
        max(0, 3 - verificationAttempts)
    }

    var status: LinkStatus {
        if isUsed {
            return .used
        } else if isLocked {
            return .locked
        } else if isExpired {
            return .expired
        } else {
            return .active
        }
    }

    var timeRemaining: String? {
        guard isActive else { return nil }

        let remaining = expiresAt.timeIntervalSince(Date())
        if remaining <= 0 { return nil }

        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60

        if hours > 24 {
            let days = hours / 24
            return "\(days)d remaining"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m remaining"
        } else {
            return "\(minutes)m remaining"
        }
    }

    var shareableURL: String {
        "https://intakeai.app/intake/\(token)"
    }

    enum LinkStatus: String, CaseIterable, Codable {
        case active
        case used
        case expired
        case locked

        var label: String {
            switch self {
            case .active: return "Active"
            case .used: return "Completed"
            case .expired: return "Expired"
            case .locked: return "Locked"
            }
        }

        var color: Color {
            switch self {
            case .active: return DesignSystem.Colors.success
            case .used: return DesignSystem.Colors.primary
            case .expired: return DesignSystem.Colors.textTertiary
            case .locked: return DesignSystem.Colors.error
            }
        }

        var icon: String {
            switch self {
            case .active: return "link"
            case .used: return "checkmark.circle.fill"
            case .expired: return "clock.badge.xmark"
            case .locked: return "lock.fill"
            }
        }
    }

    // Custom initializer for creating new links
    init(
        id: String = UUID().uuidString,
        patientId: String,
        token: String = Self.generateSecureToken(),
        expiresAt: Date,
        createdAt: Date = Date(),
        usedAt: Date? = nil,
        requiresDOBVerification: Bool = true,
        verificationAttempts: Int = 0,
        lockedAt: Date? = nil
    ) {
        self.id = id
        self.patientId = patientId
        self.token = token
        self.expiresAt = expiresAt
        self.createdAt = createdAt
        self.usedAt = usedAt
        self.requiresDOBVerification = requiresDOBVerification
        self.verificationAttempts = verificationAttempts
        self.lockedAt = lockedAt
    }

    /// Generates a cryptographically secure 64-character hex token
    static func generateSecureToken() -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return bytes.map { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Create Link Request
struct CreateIntakeLinkRequest: Codable {
    let patientId: String
    let expiresInHours: Int
    let requiresDOBVerification: Bool

    init(patientId: String, expiresInHours: Int = 168, requiresDOBVerification: Bool = true) {
        self.patientId = patientId
        self.expiresInHours = expiresInHours
        self.requiresDOBVerification = requiresDOBVerification
    }
}

// MARK: - Create Link Response
struct CreateIntakeLinkResponse: Codable {
    let link: IntakeLink
    let url: String
}

// MARK: - Verify DOB Request
struct VerifyDOBRequest: Codable {
    let token: String
    let dateOfBirth: String // Format: YYYY-MM-DD
}

// MARK: - Verify DOB Response
struct VerifyDOBResponse: Codable {
    let verified: Bool
    let attemptsRemaining: Int?
    let locked: Bool?
    let message: String?
}

// MARK: - Sample Data
extension IntakeLink {
    static let sampleActive = IntakeLink(
        id: "lnk_123456",
        patientId: "pat_123456",
        token: "a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z6a7b8c9d0e1f2",
        expiresAt: Date().addingTimeInterval(86400 * 5),
        createdAt: Date().addingTimeInterval(-86400 * 2),
        usedAt: nil,
        requiresDOBVerification: true,
        verificationAttempts: 0,
        lockedAt: nil
    )

    static let sampleUsed = IntakeLink(
        id: "lnk_234567",
        patientId: "pat_123456",
        token: "b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z6a7b8c9d0e1f2g3",
        expiresAt: Date().addingTimeInterval(86400 * 3),
        createdAt: Date().addingTimeInterval(-86400 * 5),
        usedAt: Date().addingTimeInterval(-86400),
        requiresDOBVerification: true,
        verificationAttempts: 1,
        lockedAt: nil
    )

    static let sampleExpired = IntakeLink(
        id: "lnk_345678",
        patientId: "pat_789012",
        token: "c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z6a7b8c9d0e1f2g3h4",
        expiresAt: Date().addingTimeInterval(-86400),
        createdAt: Date().addingTimeInterval(-86400 * 8),
        usedAt: nil,
        requiresDOBVerification: true,
        verificationAttempts: 0,
        lockedAt: nil
    )

    static let sampleLocked = IntakeLink(
        id: "lnk_456789",
        patientId: "pat_789012",
        token: "d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z6a7b8c9d0e1f2g3h4i5",
        expiresAt: Date().addingTimeInterval(86400 * 2),
        createdAt: Date().addingTimeInterval(-86400 * 3),
        usedAt: nil,
        requiresDOBVerification: true,
        verificationAttempts: 3,
        lockedAt: Date().addingTimeInterval(-3600)
    )

    static let samples: [IntakeLink] = [
        sampleActive,
        sampleUsed,
        sampleExpired,
        sampleLocked
    ]
}
