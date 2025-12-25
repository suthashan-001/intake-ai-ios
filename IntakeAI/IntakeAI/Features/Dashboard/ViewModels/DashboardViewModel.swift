import Foundation
import SwiftUI

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var stats: DashboardStats?
    @Published var recentActivity: [RecentActivity] = []
    @Published var redFlagAlerts: [RedFlagAlert] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var selectedTimeRange: TimeRange = .week

    enum TimeRange: String, CaseIterable {
        case today = "Today"
        case week = "This Week"
        case month = "This Month"

        var icon: String {
            switch self {
            case .today: return "sun.max"
            case .week: return "calendar"
            case .month: return "calendar.badge.clock"
            }
        }
    }

    private let networkClient = NetworkClient.shared

    // MARK: - Load Dashboard Data

    func loadDashboard() async {
        isLoading = true
        error = nil

        do {
            let response = try await networkClient.request(
                .dashboard,
                responseType: DashboardResponse.self
            )

            self.stats = response.stats
            self.recentActivity = response.recentActivity
            self.redFlagAlerts = response.redFlagAlerts

        } catch let networkError as NetworkError {
            self.error = networkError.errorDescription
        } catch {
            self.error = "Failed to load dashboard"
        }

        isLoading = false
    }

    // MARK: - Refresh

    func refresh() async {
        await loadDashboard()
    }

    // MARK: - Acknowledge Red Flag

    func acknowledgeRedFlag(_ alert: RedFlagAlert) {
        if let index = redFlagAlerts.firstIndex(where: { $0.id == alert.id }) {
            // Create updated alert
            let updated = RedFlagAlert(
                id: alert.id,
                patientId: alert.patientId,
                patientName: alert.patientName,
                intakeId: alert.intakeId,
                summaryId: alert.summaryId,
                redFlag: alert.redFlag,
                detectedAt: alert.detectedAt,
                isAcknowledged: true
            )
            redFlagAlerts[index] = updated

            // Haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
    }

    // MARK: - Sample Data for Preview

    func loadSampleData() {
        stats = DashboardStats.sample
        recentActivity = RecentActivity.samples
        redFlagAlerts = RedFlagAlert.samples
    }
}
