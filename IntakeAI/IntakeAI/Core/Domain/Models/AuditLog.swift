import Foundation

// MARK: - Audit Log Model (HIPAA Compliance)
struct AuditLog: Identifiable, Codable, Equatable {
    let id: String
    let action: AuditAction
    let entityType: EntityType
    let entityId: String
    let userId: String?
    let oldValues: [String: AnyCodable]?
    let newValues: [String: AnyCodable]?
    let ipAddress: String?
    let userAgent: String?
    let createdAt: Date

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }

    var actionDescription: String {
        switch action {
        case .create:
            return "Created \(entityType.displayName)"
        case .read:
            return "Viewed \(entityType.displayName)"
        case .update:
            return "Updated \(entityType.displayName)"
        case .delete:
            return "Deleted \(entityType.displayName)"
        case .generateSummary:
            return "Generated AI Summary"
        case .exportData:
            return "Exported Data"
        case .login:
            return "Logged In"
        case .logout:
            return "Logged Out"
        case .passwordChange:
            return "Changed Password"
        }
    }
}

// MARK: - Audit Action
enum AuditAction: String, Codable, CaseIterable {
    case create = "CREATE"
    case read = "READ"
    case update = "UPDATE"
    case delete = "DELETE"
    case generateSummary = "GENERATE_SUMMARY"
    case exportData = "EXPORT_DATA"
    case login = "LOGIN"
    case logout = "LOGOUT"
    case passwordChange = "PASSWORD_CHANGE"

    var icon: String {
        switch self {
        case .create: return "plus.circle"
        case .read: return "eye"
        case .update: return "pencil"
        case .delete: return "trash"
        case .generateSummary: return "brain"
        case .exportData: return "square.and.arrow.up"
        case .login: return "person.badge.key"
        case .logout: return "rectangle.portrait.and.arrow.forward"
        case .passwordChange: return "key"
        }
    }

    var color: SwiftUI.Color {
        switch self {
        case .create: return DesignSystem.Colors.success
        case .read: return DesignSystem.Colors.info
        case .update: return DesignSystem.Colors.warning
        case .delete: return DesignSystem.Colors.error
        case .generateSummary: return DesignSystem.Colors.primary
        case .exportData: return DesignSystem.Colors.accent
        case .login, .logout: return DesignSystem.Colors.textSecondary
        case .passwordChange: return DesignSystem.Colors.warning
        }
    }
}

// MARK: - Entity Type
enum EntityType: String, Codable, CaseIterable {
    case user = "USER"
    case patient = "PATIENT"
    case intake = "INTAKE"
    case intakeLink = "INTAKE_LINK"
    case summary = "SUMMARY"
    case clinicalNote = "CLINICAL_NOTE"

    var displayName: String {
        switch self {
        case .user: return "User"
        case .patient: return "Patient"
        case .intake: return "Intake"
        case .intakeLink: return "Intake Link"
        case .summary: return "Summary"
        case .clinicalNote: return "Clinical Note"
        }
    }

    var icon: String {
        switch self {
        case .user: return "person"
        case .patient: return "person.crop.circle"
        case .intake: return "doc.text"
        case .intakeLink: return "link"
        case .summary: return "doc.richtext"
        case .clinicalNote: return "note.text"
        }
    }
}

// MARK: - AnyCodable for dynamic JSON values
struct AnyCodable: Codable, Equatable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self.value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
            self.value = bool
        } else if let int = try? container.decode(Int.self) {
            self.value = int
        } else if let double = try? container.decode(Double.self) {
            self.value = double
        } else if let string = try? container.decode(String.self) {
            self.value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            self.value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            self.value = dictionary.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "AnyCodable cannot decode value")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case is NSNull:
            try container.encodeNil()
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dictionary as [String: Any]:
            try container.encode(dictionary.mapValues { AnyCodable($0) })
        default:
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "AnyCodable cannot encode value"))
        }
    }

    static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
        // Simple equality check for common types
        switch (lhs.value, rhs.value) {
        case (let l as String, let r as String): return l == r
        case (let l as Int, let r as Int): return l == r
        case (let l as Double, let r as Double): return l == r
        case (let l as Bool, let r as Bool): return l == r
        case (is NSNull, is NSNull): return true
        default: return false
        }
    }
}

// MARK: - Clinical Note Model
struct ClinicalNote: Identifiable, Codable, Equatable {
    let id: String
    let patientId: String
    let userId: String
    let intakeId: String?
    let content: String
    let noteType: NoteType
    let createdAt: Date
    let updatedAt: Date

    enum NoteType: String, Codable, CaseIterable {
        case general = "GENERAL"
        case followUp = "FOLLOW_UP"
        case assessment = "ASSESSMENT"
        case plan = "PLAN"
        case progress = "PROGRESS"

        var displayName: String {
            switch self {
            case .general: return "General Note"
            case .followUp: return "Follow-Up"
            case .assessment: return "Assessment"
            case .plan: return "Treatment Plan"
            case .progress: return "Progress Note"
            }
        }

        var icon: String {
            switch self {
            case .general: return "note.text"
            case .followUp: return "arrow.triangle.2.circlepath"
            case .assessment: return "stethoscope"
            case .plan: return "list.bullet.clipboard"
            case .progress: return "chart.line.uptrend.xyaxis"
            }
        }
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }
}

// MARK: - Create Clinical Note Request
struct CreateClinicalNoteRequest: Codable {
    let patientId: String
    let intakeId: String?
    let content: String
    let noteType: ClinicalNote.NoteType
}

// MARK: - Sample Data
extension ClinicalNote {
    static let sample = ClinicalNote(
        id: "note_123456",
        patientId: "pat_123456",
        userId: "usr_123456",
        intakeId: "int_123456",
        content: "Patient appears comfortable. Lower back pain localized to L4-L5 region. No neurological deficits noted. Recommend physical therapy and continue current medication regimen.",
        noteType: .assessment,
        createdAt: Date().addingTimeInterval(-86400),
        updatedAt: Date().addingTimeInterval(-86400)
    )

    static let samples: [ClinicalNote] = [
        sample,
        ClinicalNote(
            id: "note_234567",
            patientId: "pat_123456",
            userId: "usr_123456",
            intakeId: nil,
            content: "Follow-up scheduled in 2 weeks. Patient to continue exercises and report any worsening symptoms.",
            noteType: .followUp,
            createdAt: Date().addingTimeInterval(-43200),
            updatedAt: Date().addingTimeInterval(-43200)
        )
    ]
}
