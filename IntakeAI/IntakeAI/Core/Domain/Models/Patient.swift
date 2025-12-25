import Foundation

// MARK: - Patient Model
struct Patient: Identifiable, Codable, Equatable {
    let id: String
    let firstName: String
    let lastName: String
    let email: String?
    let phone: String?
    let dateOfBirth: Date
    let userId: String
    let createdAt: Date
    let updatedAt: Date
    let deletedAt: Date?

    // Computed properties
    var fullName: String {
        "\(firstName) \(lastName)"
    }

    var initials: String {
        let firstInitial = firstName.prefix(1)
        let lastInitial = lastName.prefix(1)
        return "\(firstInitial)\(lastInitial)".uppercased()
    }

    var age: Int {
        Calendar.current.dateComponents([.year], from: dateOfBirth, to: Date()).year ?? 0
    }

    var formattedDateOfBirth: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: dateOfBirth)
    }

    var formattedPhone: String? {
        guard let phone = phone else { return nil }
        // Format as (XXX) XXX-XXXX
        let cleaned = phone.filter { $0.isNumber }
        guard cleaned.count == 10 else { return phone }
        let areaCode = cleaned.prefix(3)
        let middle = cleaned.dropFirst(3).prefix(3)
        let last = cleaned.suffix(4)
        return "(\(areaCode)) \(middle)-\(last)"
    }

    var isDeleted: Bool {
        deletedAt != nil
    }
}

// MARK: - Patient with Relationships
struct PatientWithDetails: Identifiable, Codable, Equatable {
    let id: String
    let patient: Patient
    let intakeLinks: [IntakeLink]?
    let intakes: [Intake]?
    let latestIntake: Intake?
    let hasRedFlags: Bool
    let redFlagCount: Int

    var displayStatus: IntakeStatus? {
        latestIntake?.status
    }
}

// MARK: - Create Patient Request
struct CreatePatientRequest: Codable {
    let firstName: String
    let lastName: String
    let email: String?
    let phone: String?
    let dateOfBirth: Date
}

// MARK: - Update Patient Request
struct UpdatePatientRequest: Codable {
    let firstName: String?
    let lastName: String?
    let email: String?
    let phone: String?
    let dateOfBirth: Date?
}

// MARK: - Patient List Response
struct PatientListResponse: Codable {
    let patients: [PatientWithDetails]
    let total: Int
    let page: Int
    let pageSize: Int
    let hasMore: Bool
}

// MARK: - Patient Search/Filter
struct PatientFilter {
    var searchQuery: String = ""
    var status: IntakeStatus?
    var hasRedFlags: Bool?
    var sortBy: SortBy = .name
    var sortOrder: SortOrder = .ascending

    enum SortBy: String, CaseIterable {
        case name = "name"
        case dateOfBirth = "dateOfBirth"
        case createdAt = "createdAt"
        case updatedAt = "updatedAt"

        var displayName: String {
            switch self {
            case .name: return "Name"
            case .dateOfBirth: return "Date of Birth"
            case .createdAt: return "Created Date"
            case .updatedAt: return "Last Updated"
            }
        }
    }

    enum SortOrder: String, CaseIterable {
        case ascending = "asc"
        case descending = "desc"

        var displayName: String {
            switch self {
            case .ascending: return "Ascending"
            case .descending: return "Descending"
            }
        }

        var icon: String {
            switch self {
            case .ascending: return "arrow.up"
            case .descending: return "arrow.down"
            }
        }
    }
}

// MARK: - Sample Data
extension Patient {
    static let sample = Patient(
        id: "pat_123456",
        firstName: "John",
        lastName: "Doe",
        email: "john.doe@email.com",
        phone: "5551234567",
        dateOfBirth: Calendar.current.date(byAdding: .year, value: -35, to: Date())!,
        userId: "usr_123456",
        createdAt: Date().addingTimeInterval(-86400 * 7),
        updatedAt: Date(),
        deletedAt: nil
    )

    static let sampleWithRedFlags = Patient(
        id: "pat_789012",
        firstName: "Jane",
        lastName: "Smith",
        email: "jane.smith@email.com",
        phone: "5559876543",
        dateOfBirth: Calendar.current.date(byAdding: .year, value: -42, to: Date())!,
        userId: "usr_123456",
        createdAt: Date().addingTimeInterval(-86400 * 14),
        updatedAt: Date().addingTimeInterval(-3600),
        deletedAt: nil
    )

    static let samples: [Patient] = [
        sample,
        sampleWithRedFlags,
        Patient(
            id: "pat_345678",
            firstName: "Robert",
            lastName: "Johnson",
            email: "robert.j@email.com",
            phone: nil,
            dateOfBirth: Calendar.current.date(byAdding: .year, value: -58, to: Date())!,
            userId: "usr_123456",
            createdAt: Date().addingTimeInterval(-86400 * 21),
            updatedAt: Date().addingTimeInterval(-86400 * 2),
            deletedAt: nil
        ),
        Patient(
            id: "pat_901234",
            firstName: "Emily",
            lastName: "Davis",
            email: "emily.d@email.com",
            phone: "5551112222",
            dateOfBirth: Calendar.current.date(byAdding: .year, value: -29, to: Date())!,
            userId: "usr_123456",
            createdAt: Date().addingTimeInterval(-86400 * 3),
            updatedAt: Date().addingTimeInterval(-86400),
            deletedAt: nil
        )
    ]
}

extension PatientWithDetails {
    static let sample = PatientWithDetails(
        id: Patient.sample.id,
        patient: Patient.sample,
        intakeLinks: [],
        intakes: [],
        latestIntake: nil,
        hasRedFlags: false,
        redFlagCount: 0
    )

    static let sampleWithRedFlags = PatientWithDetails(
        id: Patient.sampleWithRedFlags.id,
        patient: Patient.sampleWithRedFlags,
        intakeLinks: [],
        intakes: [Intake.sampleWithRedFlags],
        latestIntake: Intake.sampleWithRedFlags,
        hasRedFlags: true,
        redFlagCount: 2
    )
}
