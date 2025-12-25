import Foundation

// MARK: - Intake Model
struct Intake: Identifiable, Codable, Equatable {
    let id: String
    let patientId: String
    let intakeLinkId: String?
    let status: IntakeStatus
    let responses: IntakeResponses?
    let consentGiven: Bool
    let consentTimestamp: Date?
    let consentIpAddress: String?
    let completedAt: Date?
    let reviewedAt: Date?
    let createdAt: Date
    let updatedAt: Date

    var isComplete: Bool {
        status == .completed || status == .reviewed
    }

    var formattedCompletedAt: String? {
        guard let completedAt = completedAt else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: completedAt)
    }
}

// MARK: - Intake Responses (JSON structure)
struct IntakeResponses: Codable, Equatable {
    // Demographics
    let firstName: String?
    let lastName: String?
    let dateOfBirth: String?
    let phone: String?
    let email: String?
    let address: String?
    let emergencyContact: String?
    let emergencyPhone: String?

    // Medical History
    let chiefComplaint: String?
    let currentMedications: String?
    let allergies: String?
    let medicalHistory: String?
    let surgicalHistory: String?
    let familyHistory: String?

    // Systems Review
    let generalHealth: String?
    let cardiovascular: String?
    let respiratory: String?
    let gastrointestinal: String?
    let neurological: String?
    let musculoskeletal: String?
    let psychiatric: String?

    // Lifestyle
    let smokingStatus: String?
    let alcoholUse: String?
    let exerciseFrequency: String?
    let diet: String?
    let sleepQuality: String?
    let stressLevel: String?

    // Additional
    let additionalConcerns: String?
    let goalsForVisit: String?
}

// MARK: - Intake with Summary
struct IntakeWithSummary: Identifiable, Codable, Equatable {
    let id: String
    let intake: Intake
    let summary: Summary?
    let patient: Patient?
}

// MARK: - Sample Data
extension Intake {
    static let sample = Intake(
        id: "int_123456",
        patientId: "pat_123456",
        intakeLinkId: "lnk_123456",
        status: .completed,
        responses: IntakeResponses.sample,
        consentGiven: true,
        consentTimestamp: Date().addingTimeInterval(-86400),
        consentIpAddress: "192.168.1.1",
        completedAt: Date().addingTimeInterval(-86400),
        reviewedAt: nil,
        createdAt: Date().addingTimeInterval(-86400 * 2),
        updatedAt: Date().addingTimeInterval(-86400)
    )

    static let samplePending = Intake(
        id: "int_234567",
        patientId: "pat_123456",
        intakeLinkId: "lnk_234567",
        status: .pending,
        responses: nil,
        consentGiven: false,
        consentTimestamp: nil,
        consentIpAddress: nil,
        completedAt: nil,
        reviewedAt: nil,
        createdAt: Date().addingTimeInterval(-3600),
        updatedAt: Date().addingTimeInterval(-3600)
    )

    static let sampleWithRedFlags = Intake(
        id: "int_345678",
        patientId: "pat_789012",
        intakeLinkId: "lnk_345678",
        status: .completed,
        responses: IntakeResponses.sampleWithConcerns,
        consentGiven: true,
        consentTimestamp: Date().addingTimeInterval(-7200),
        consentIpAddress: "192.168.1.2",
        completedAt: Date().addingTimeInterval(-7200),
        reviewedAt: nil,
        createdAt: Date().addingTimeInterval(-86400),
        updatedAt: Date().addingTimeInterval(-7200)
    )
}

extension IntakeResponses {
    static let sample = IntakeResponses(
        firstName: "John",
        lastName: "Doe",
        dateOfBirth: "1989-05-15",
        phone: "555-123-4567",
        email: "john.doe@email.com",
        address: "123 Main St, City, ST 12345",
        emergencyContact: "Jane Doe",
        emergencyPhone: "555-987-6543",
        chiefComplaint: "Persistent lower back pain for the past 3 weeks",
        currentMedications: "Ibuprofen 400mg as needed",
        allergies: "Penicillin",
        medicalHistory: "Hypertension, managed with medication",
        surgicalHistory: "Appendectomy (2015)",
        familyHistory: "Father - Type 2 Diabetes, Mother - Hypertension",
        generalHealth: "Generally good",
        cardiovascular: "No chest pain or palpitations",
        respiratory: "No shortness of breath",
        gastrointestinal: "Occasional acid reflux",
        neurological: "No headaches or dizziness",
        musculoskeletal: "Lower back pain, worse with prolonged sitting",
        psychiatric: "No depression or anxiety",
        smokingStatus: "Never smoked",
        alcoholUse: "Occasional, 2-3 drinks per week",
        exerciseFrequency: "3 times per week",
        diet: "Balanced diet, trying to reduce sodium",
        sleepQuality: "Good, 7-8 hours per night",
        stressLevel: "Moderate, work-related",
        additionalConcerns: "Would like to discuss preventive health measures",
        goalsForVisit: "Pain management and exercise recommendations"
    )

    static let sampleWithConcerns = IntakeResponses(
        firstName: "Jane",
        lastName: "Smith",
        dateOfBirth: "1982-08-22",
        phone: "555-987-6543",
        email: "jane.smith@email.com",
        address: "456 Oak Ave, Town, ST 67890",
        emergencyContact: "John Smith",
        emergencyPhone: "555-123-4567",
        chiefComplaint: "Severe chest pain and difficulty breathing for the past 2 days",
        currentMedications: "Metformin 500mg, Lisinopril 10mg",
        allergies: "None known",
        medicalHistory: "Type 2 Diabetes, Hypertension",
        surgicalHistory: "None",
        familyHistory: "Father - Heart disease (MI at 55), Mother - Diabetes",
        generalHealth: "Declining over past week",
        cardiovascular: "Chest pain, especially with exertion. Occasional palpitations.",
        respiratory: "Shortness of breath, worse when lying down",
        gastrointestinal: "Normal",
        neurological: "Some dizziness",
        musculoskeletal: "Normal",
        psychiatric: "Feeling anxious about symptoms. Sometimes feeling hopeless.",
        smokingStatus: "Former smoker, quit 5 years ago",
        alcoholUse: "None",
        exerciseFrequency: "Unable to exercise due to symptoms",
        diet: "Diabetic diet",
        sleepQuality: "Poor, waking up short of breath",
        stressLevel: "High",
        additionalConcerns: "Worried about heart problems given family history",
        goalsForVisit: "Understand what's causing these symptoms"
    )
}
