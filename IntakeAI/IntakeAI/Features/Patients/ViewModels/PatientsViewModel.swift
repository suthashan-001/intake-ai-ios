import Foundation
import SwiftUI

@MainActor
class PatientsViewModel: ObservableObject {
    @Published var patients: [PatientWithDetails] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var error: String?

    @Published var searchQuery = ""
    @Published var selectedStatus: IntakeStatus?
    @Published var showRedFlagsOnly = false
    @Published var sortBy: PatientFilter.SortBy = .name
    @Published var sortOrder: PatientFilter.SortOrder = .ascending

    @Published var currentPage = 1
    @Published var hasMore = true
    @Published var totalPatients = 0

    private let pageSize = 20
    private let networkClient = NetworkClient.shared
    private var searchTask: Task<Void, Never>?

    // MARK: - Computed Properties

    var filteredPatients: [PatientWithDetails] {
        var result = patients

        // Apply local filters for immediate feedback
        if showRedFlagsOnly {
            result = result.filter { $0.hasRedFlags }
        }

        if let status = selectedStatus {
            result = result.filter { $0.displayStatus == status }
        }

        return result
    }

    var activeFiltersCount: Int {
        var count = 0
        if selectedStatus != nil { count += 1 }
        if showRedFlagsOnly { count += 1 }
        if sortBy != .name || sortOrder != .ascending { count += 1 }
        return count
    }

    // MARK: - Load Patients

    func loadPatients(reset: Bool = true) async {
        if reset {
            currentPage = 1
            hasMore = true
            isLoading = true
        } else {
            isLoadingMore = true
        }
        error = nil

        do {
            let response = try await networkClient.request(
                .patients(page: currentPage, pageSize: pageSize, search: searchQuery.isEmpty ? nil : searchQuery),
                responseType: PatientListResponse.self
            )

            if reset {
                self.patients = response.patients
            } else {
                self.patients.append(contentsOf: response.patients)
            }

            self.totalPatients = response.total
            self.hasMore = response.hasMore
            self.currentPage = response.page

        } catch let networkError as NetworkError {
            self.error = networkError.errorDescription
        } catch {
            self.error = "Failed to load patients"
        }

        isLoading = false
        isLoadingMore = false
    }

    // MARK: - Load More

    func loadMoreIfNeeded(currentPatient: PatientWithDetails) async {
        guard hasMore && !isLoadingMore else { return }

        let thresholdIndex = patients.index(patients.endIndex, offsetBy: -5)
        if let index = patients.firstIndex(where: { $0.id == currentPatient.id }),
           index >= thresholdIndex {
            currentPage += 1
            await loadPatients(reset: false)
        }
    }

    // MARK: - Search

    func search() {
        searchTask?.cancel()

        searchTask = Task {
            // Debounce
            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms

            if !Task.isCancelled {
                await loadPatients(reset: true)
            }
        }
    }

    // MARK: - Refresh

    func refresh() async {
        await loadPatients(reset: true)
    }

    // MARK: - Delete Patient

    func deletePatient(_ patient: PatientWithDetails) async -> Bool {
        do {
            try await networkClient.request(.deletePatient(id: patient.id))

            // Remove from local list
            patients.removeAll { $0.id == patient.id }
            totalPatients -= 1

            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)

            return true
        } catch {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
            return false
        }
    }

    // MARK: - Clear Filters

    func clearFilters() {
        selectedStatus = nil
        showRedFlagsOnly = false
        sortBy = .name
        sortOrder = .ascending

        Task {
            await loadPatients(reset: true)
        }
    }

    // MARK: - Sample Data

    func loadSampleData() {
        patients = [
            PatientWithDetails.sample,
            PatientWithDetails.sampleWithRedFlags,
            PatientWithDetails(
                id: "pat_345678",
                patient: Patient.samples[2],
                intakeLinks: [],
                intakes: [],
                latestIntake: Intake.samplePending,
                hasRedFlags: false,
                redFlagCount: 0
            ),
            PatientWithDetails(
                id: "pat_901234",
                patient: Patient.samples[3],
                intakeLinks: [],
                intakes: [],
                latestIntake: nil,
                hasRedFlags: false,
                redFlagCount: 0
            )
        ]
        totalPatients = patients.count
        hasMore = false
    }
}
