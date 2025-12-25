import Foundation

// MARK: - Dashboard Statistics
struct DashboardStats: Codable, Equatable {
    let totalPatients: Int
    let activeIntakes: Int
    let completedToday: Int
    let pendingReview: Int
    let redFlagAlerts: Int
    let highSeverityAlerts: Int

    // Trends (compared to last week)
    let patientsTrend: Trend?
    let intakesTrend: Trend?

    struct Trend: Codable, Equatable {
        let value: Int
        let percentage: Double
        let isPositive: Bool

        var formattedPercentage: String {
            let sign = isPositive ? "+" : ""
            return "\(sign)\(Int(percentage))%"
        }

        var formattedValue: String {
            let sign = isPositive ? "+" : ""
            return "\(sign)\(value)"
        }
    }
}

// MARK: - Recent Activity Item
struct RecentActivity: Identifiable, Codable, Equatable {
    let id: String
    let type: ActivityType
    let title: String
    let subtitle: String?
    let patientId: String?
    let patientName: String?
    let timestamp: Date
    let metadata: [String: String]?

    enum ActivityType: String, Codable {
        case intakeCompleted = "INTAKE_COMPLETED"
        case intakeStarted = "INTAKE_STARTED"
        case summaryGenerated = "SUMMARY_GENERATED"
        case redFlagDetected = "RED_FLAG_DETECTED"
        case patientAdded = "PATIENT_ADDED"
        case linkSent = "LINK_SENT"
        case noteAdded = "NOTE_ADDED"

        var icon: String {
            switch self {
            case .intakeCompleted: return "checkmark.circle.fill"
            case .intakeStarted: return "pencil.circle.fill"
            case .summaryGenerated: return "brain"
            case .redFlagDetected: return "exclamationmark.triangle.fill"
            case .patientAdded: return "person.badge.plus"
            case .linkSent: return "paperplane.fill"
            case .noteAdded: return "note.text.badge.plus"
            }
        }

        var color: SwiftUI.Color {
            switch self {
            case .intakeCompleted: return DesignSystem.Colors.success
            case .intakeStarted: return DesignSystem.Colors.info
            case .summaryGenerated: return DesignSystem.Colors.primary
            case .redFlagDetected: return DesignSystem.Colors.error
            case .patientAdded: return DesignSystem.Colors.accent
            case .linkSent: return DesignSystem.Colors.info
            case .noteAdded: return DesignSystem.Colors.textSecondary
            }
        }
    }

    var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}

// MARK: - Red Flag Alert for Dashboard
struct RedFlagAlert: Identifiable, Codable, Equatable {
    let id: String
    let patientId: String
    let patientName: String
    let intakeId: String
    let summaryId: String
    let redFlag: RedFlag
    let detectedAt: Date
    let isAcknowledged: Bool

    var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: detectedAt, relativeTo: Date())
    }
}

// MARK: - Dashboard Response
struct DashboardResponse: Codable {
    let stats: DashboardStats
    let recentActivity: [RecentActivity]
    let redFlagAlerts: [RedFlagAlert]
    let upcomingTasks: [UpcomingTask]?
}

// MARK: - Upcoming Task
struct UpcomingTask: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let dueDate: Date?
    let patientId: String?
    let patientName: String?
    let taskType: TaskType
    let priority: Priority

    enum TaskType: String, Codable {
        case reviewIntake = "REVIEW_INTAKE"
        case followUp = "FOLLOW_UP"
        case renewPrescription = "RENEW_PRESCRIPTION"
        case scheduledCall = "SCHEDULED_CALL"

        var icon: String {
            switch self {
            case .reviewIntake: return "doc.text.magnifyingglass"
            case .followUp: return "arrow.triangle.2.circlepath"
            case .renewPrescription: return "pills.fill"
            case .scheduledCall: return "phone.fill"
            }
        }
    }

    enum Priority: String, Codable {
        case high
        case medium
        case low

        var color: SwiftUI.Color {
            switch self {
            case .high: return DesignSystem.Colors.error
            case .medium: return DesignSystem.Colors.warning
            case .low: return DesignSystem.Colors.info
            }
        }
    }
}

// MARK: - Sample Data
extension DashboardStats {
    static let sample = DashboardStats(
        totalPatients: 248,
        activeIntakes: 12,
        completedToday: 8,
        pendingReview: 5,
        redFlagAlerts: 3,
        highSeverityAlerts: 1,
        patientsTrend: Trend(value: 15, percentage: 12.5, isPositive: true),
        intakesTrend: Trend(value: 3, percentage: 8.2, isPositive: true)
    )
}

extension RecentActivity {
    static let samples: [RecentActivity] = [
        RecentActivity(
            id: "act_1",
            type: .redFlagDetected,
            title: "High-severity red flag detected",
            subtitle: "Chest pain with arm radiation",
            patientId: "pat_789012",
            patientName: "Jane Smith",
            timestamp: Date().addingTimeInterval(-1800),
            metadata: ["severity": "high"]
        ),
        RecentActivity(
            id: "act_2",
            type: .intakeCompleted,
            title: "Intake completed",
            subtitle: nil,
            patientId: "pat_123456",
            patientName: "John Doe",
            timestamp: Date().addingTimeInterval(-3600),
            metadata: nil
        ),
        RecentActivity(
            id: "act_3",
            type: .summaryGenerated,
            title: "AI summary generated",
            subtitle: "2 red flags identified",
            patientId: "pat_789012",
            patientName: "Jane Smith",
            timestamp: Date().addingTimeInterval(-3700),
            metadata: ["redFlagCount": "2"]
        ),
        RecentActivity(
            id: "act_4",
            type: .linkSent,
            title: "Intake link sent",
            subtitle: nil,
            patientId: "pat_345678",
            patientName: "Robert Johnson",
            timestamp: Date().addingTimeInterval(-7200),
            metadata: nil
        ),
        RecentActivity(
            id: "act_5",
            type: .patientAdded,
            title: "New patient added",
            subtitle: nil,
            patientId: "pat_901234",
            patientName: "Emily Davis",
            timestamp: Date().addingTimeInterval(-10800),
            metadata: nil
        )
    ]
}

extension RedFlagAlert {
    static let samples: [RedFlagAlert] = [
        RedFlagAlert(
            id: "alert_1",
            patientId: "pat_789012",
            patientName: "Jane Smith",
            intakeId: "int_345678",
            summaryId: "sum_789012",
            redFlag: RedFlag(
                flag: "Chest pain with radiation to arm",
                severity: .high,
                details: "Classic presentation concerning for acute coronary syndrome",
                recommendation: "Urgent cardiac evaluation recommended",
                source: .ai
            ),
            detectedAt: Date().addingTimeInterval(-1800),
            isAcknowledged: false
        ),
        RedFlagAlert(
            id: "alert_2",
            patientId: "pat_789012",
            patientName: "Jane Smith",
            intakeId: "int_345678",
            summaryId: "sum_789012",
            redFlag: RedFlag(
                flag: "Shortness of breath with orthopnea",
                severity: .high,
                details: "May indicate cardiac or pulmonary pathology",
                recommendation: "Consider chest X-ray and BNP",
                source: .ai
            ),
            detectedAt: Date().addingTimeInterval(-1800),
            isAcknowledged: false
        ),
        RedFlagAlert(
            id: "alert_3",
            patientId: "pat_789012",
            patientName: "Jane Smith",
            intakeId: "int_345678",
            summaryId: "sum_789012",
            redFlag: RedFlag(
                flag: "Feelings of hopelessness",
                severity: .medium,
                details: "Patient expressed some hopelessness during intake",
                recommendation: "Mental health screening recommended",
                source: .keyword
            ),
            detectedAt: Date().addingTimeInterval(-1800),
            isAcknowledged: true
        )
    ]
}
