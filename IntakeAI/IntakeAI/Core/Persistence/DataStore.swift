import Foundation
import SwiftData
import SwiftUI

// MARK: - SwiftData Models for Offline Persistence

@Model
final class CachedPatient {
    @Attribute(.unique) var id: String
    var firstName: String
    var lastName: String
    var email: String?
    var phone: String?
    var dateOfBirth: Date
    var userId: String
    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?
    var hasRedFlags: Bool
    var redFlagCount: Int
    var latestIntakeStatus: String?
    var lastSyncedAt: Date

    init(from patient: Patient, hasRedFlags: Bool = false, redFlagCount: Int = 0, latestStatus: IntakeStatus? = nil) {
        self.id = patient.id
        self.firstName = patient.firstName
        self.lastName = patient.lastName
        self.email = patient.email
        self.phone = patient.phone
        self.dateOfBirth = patient.dateOfBirth
        self.userId = patient.userId
        self.createdAt = patient.createdAt
        self.updatedAt = patient.updatedAt
        self.deletedAt = patient.deletedAt
        self.hasRedFlags = hasRedFlags
        self.redFlagCount = redFlagCount
        self.latestIntakeStatus = latestStatus?.rawValue
        self.lastSyncedAt = Date()
    }

    func toPatient() -> Patient {
        Patient(
            id: id,
            firstName: firstName,
            lastName: lastName,
            email: email,
            phone: phone,
            dateOfBirth: dateOfBirth,
            userId: userId,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt
        )
    }

    func toPatientWithDetails() -> PatientWithDetails {
        PatientWithDetails(
            id: id,
            patient: toPatient(),
            intakeLinks: nil,
            intakes: nil,
            latestIntake: nil,
            hasRedFlags: hasRedFlags,
            redFlagCount: redFlagCount
        )
    }
}

@Model
final class CachedIntakeLink {
    @Attribute(.unique) var id: String
    var patientId: String
    var token: String
    var expiresAt: Date
    var createdAt: Date
    var usedAt: Date?
    var requiresDOBVerification: Bool
    var verificationAttempts: Int
    var lockedAt: Date?
    var lastSyncedAt: Date

    init(from link: IntakeLink) {
        self.id = link.id
        self.patientId = link.patientId
        self.token = link.token
        self.expiresAt = link.expiresAt
        self.createdAt = link.createdAt
        self.usedAt = link.usedAt
        self.requiresDOBVerification = link.requiresDOBVerification
        self.verificationAttempts = link.verificationAttempts
        self.lockedAt = link.lockedAt
        self.lastSyncedAt = Date()
    }

    func toIntakeLink() -> IntakeLink {
        IntakeLink(
            id: id,
            patientId: patientId,
            token: token,
            expiresAt: expiresAt,
            createdAt: createdAt,
            usedAt: usedAt,
            requiresDOBVerification: requiresDOBVerification,
            verificationAttempts: verificationAttempts,
            lockedAt: lockedAt
        )
    }
}

@Model
final class CachedSummary {
    @Attribute(.unique) var id: String
    var intakeId: String
    var chiefComplaint: String
    var medicationsJSON: Data?
    var systemsReviewJSON: Data?
    var relevantHistory: String
    var lifestyleJSON: Data?
    var redFlagsJSON: Data?
    var hasRedFlags: Bool
    var redFlagCount: Int
    var doctorEditsJSON: Data?
    var editedAt: Date?
    var editedByUserId: String?
    var createdAt: Date
    var updatedAt: Date
    var lastSyncedAt: Date

    init(from summary: Summary) {
        self.id = summary.id
        self.intakeId = summary.intakeId
        self.chiefComplaint = summary.chiefComplaint
        self.relevantHistory = summary.relevantHistory
        self.hasRedFlags = summary.hasRedFlags
        self.redFlagCount = summary.redFlagCount
        self.editedAt = summary.editedAt
        self.editedByUserId = summary.editedByUserId
        self.createdAt = summary.createdAt
        self.updatedAt = summary.updatedAt
        self.lastSyncedAt = Date()

        let encoder = JSONEncoder()
        self.medicationsJSON = try? encoder.encode(summary.medications)
        self.systemsReviewJSON = try? encoder.encode(summary.systemsReview)
        self.lifestyleJSON = try? encoder.encode(summary.lifestyle)
        self.redFlagsJSON = try? encoder.encode(summary.redFlags)
        self.doctorEditsJSON = try? encoder.encode(summary.doctorEdits)
    }
}

@Model
final class PendingAction {
    @Attribute(.unique) var id: String
    var actionType: String
    var entityType: String
    var entityId: String
    var payloadJSON: Data
    var createdAt: Date
    var retryCount: Int
    var lastError: String?

    enum ActionType: String {
        case create, update, delete
    }

    enum EntityType: String {
        case patient, intakeLink, summary, note
    }

    init(actionType: ActionType, entityType: EntityType, entityId: String, payload: Encodable) {
        self.id = UUID().uuidString
        self.actionType = actionType.rawValue
        self.entityType = entityType.rawValue
        self.entityId = entityId
        self.payloadJSON = (try? JSONEncoder().encode(AnyEncodable(payload))) ?? Data()
        self.createdAt = Date()
        self.retryCount = 0
    }
}

// MARK: - Data Store Manager

@MainActor
class DataStore: ObservableObject {
    static let shared = DataStore()

    let container: ModelContainer
    let context: ModelContext

    @Published var isSyncing = false
    @Published var lastSyncError: String?
    @Published var pendingActionsCount = 0

    private init() {
        let schema = Schema([
            CachedPatient.self,
            CachedIntakeLink.self,
            CachedSummary.self,
            PendingAction.self
        ])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none
        )

        do {
            container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            context = container.mainContext
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    // MARK: - Patient Operations

    func cachePatients(_ patients: [PatientWithDetails]) {
        for patient in patients {
            let cached = CachedPatient(
                from: patient.patient,
                hasRedFlags: patient.hasRedFlags,
                redFlagCount: patient.redFlagCount,
                latestStatus: patient.displayStatus
            )
            context.insert(cached)
        }
        try? context.save()
    }

    func getCachedPatients() -> [PatientWithDetails] {
        let descriptor = FetchDescriptor<CachedPatient>(
            sortBy: [SortDescriptor(\.lastName)]
        )

        guard let cached = try? context.fetch(descriptor) else {
            return []
        }

        return cached.map { $0.toPatientWithDetails() }
    }

    func cachePatient(_ patient: PatientWithDetails) {
        let cached = CachedPatient(
            from: patient.patient,
            hasRedFlags: patient.hasRedFlags,
            redFlagCount: patient.redFlagCount,
            latestStatus: patient.displayStatus
        )
        context.insert(cached)
        try? context.save()
    }

    func deleteCachedPatient(_ id: String) {
        let descriptor = FetchDescriptor<CachedPatient>(
            predicate: #Predicate { $0.id == id }
        )

        if let patients = try? context.fetch(descriptor) {
            for patient in patients {
                context.delete(patient)
            }
            try? context.save()
        }
    }

    // MARK: - Intake Link Operations

    func cacheIntakeLinks(_ links: [IntakeLink]) {
        for link in links {
            let cached = CachedIntakeLink(from: link)
            context.insert(cached)
        }
        try? context.save()
    }

    func getCachedIntakeLinks(forPatient patientId: String? = nil) -> [IntakeLink] {
        var descriptor = FetchDescriptor<CachedIntakeLink>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        if let patientId = patientId {
            descriptor.predicate = #Predicate { $0.patientId == patientId }
        }

        guard let cached = try? context.fetch(descriptor) else {
            return []
        }

        return cached.map { $0.toIntakeLink() }
    }

    // MARK: - Pending Actions (Offline Queue)

    func queueAction<T: Encodable>(type: PendingAction.ActionType, entityType: PendingAction.EntityType, entityId: String, payload: T) {
        let action = PendingAction(actionType: type, entityType: entityType, entityId: entityId, payload: payload)
        context.insert(action)
        try? context.save()
        updatePendingCount()
    }

    func getPendingActions() -> [PendingAction] {
        let descriptor = FetchDescriptor<PendingAction>(
            sortBy: [SortDescriptor(\.createdAt)]
        )

        return (try? context.fetch(descriptor)) ?? []
    }

    func removePendingAction(_ id: String) {
        let descriptor = FetchDescriptor<PendingAction>(
            predicate: #Predicate { $0.id == id }
        )

        if let actions = try? context.fetch(descriptor) {
            for action in actions {
                context.delete(action)
            }
            try? context.save()
        }
        updatePendingCount()
    }

    private func updatePendingCount() {
        let descriptor = FetchDescriptor<PendingAction>()
        pendingActionsCount = (try? context.fetchCount(descriptor)) ?? 0
    }

    // MARK: - Sync Operations

    func syncPendingActions() async {
        guard !isSyncing else { return }

        isSyncing = true
        lastSyncError = nil

        let actions = getPendingActions()

        for action in actions {
            do {
                try await processPendingAction(action)
                removePendingAction(action.id)
            } catch {
                // Update retry count
                action.retryCount += 1
                action.lastError = error.localizedDescription
                try? context.save()

                // If too many retries, remove the action
                if action.retryCount > 5 {
                    removePendingAction(action.id)
                }
            }
        }

        isSyncing = false
    }

    private func processPendingAction(_ action: PendingAction) async throws {
        // Process based on action type and entity type
        // This would call the NetworkClient to sync with the server
        // For now, we just simulate the sync

        try await Task.sleep(nanoseconds: 500_000_000) // 0.5s simulated delay
    }

    // MARK: - Clear Cache

    func clearAllCache() {
        try? context.delete(model: CachedPatient.self)
        try? context.delete(model: CachedIntakeLink.self)
        try? context.delete(model: CachedSummary.self)
        try? context.save()
    }
}

// MARK: - Helper

private struct AnyEncodable: Encodable {
    private let encodable: Encodable

    init(_ encodable: Encodable) {
        self.encodable = encodable
    }

    func encode(to encoder: Encoder) throws {
        try encodable.encode(to: encoder)
    }
}
