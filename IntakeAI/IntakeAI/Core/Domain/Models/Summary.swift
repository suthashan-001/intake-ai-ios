import Foundation

// MARK: - Summary Model (AI-Generated Clinical Summary)
struct Summary: Identifiable, Codable, Equatable {
    let id: String
    let intakeId: String
    let chiefComplaint: String
    let medications: [Medication]
    let systemsReview: SystemsReview
    let relevantHistory: String
    let lifestyle: LifestyleFactors
    let redFlags: [RedFlag]
    let hasRedFlags: Bool
    let redFlagCount: Int
    let doctorEdits: DoctorEdits?
    let editedAt: Date?
    let editedByUserId: String?
    let createdAt: Date
    let updatedAt: Date

    // Computed properties
    var highSeverityRedFlags: [RedFlag] {
        redFlags.filter { $0.severity == .high }
    }

    var mediumSeverityRedFlags: [RedFlag] {
        redFlags.filter { $0.severity == .medium }
    }

    var lowSeverityRedFlags: [RedFlag] {
        redFlags.filter { $0.severity == .low }
    }

    var hasHighSeverityRedFlags: Bool {
        !highSeverityRedFlags.isEmpty
    }

    var wasEdited: Bool {
        doctorEdits != nil
    }
}

// MARK: - Medication
struct Medication: Codable, Equatable, Identifiable {
    var id: String { name }
    let name: String
    let dosage: String?
    let frequency: String?
    let purpose: String?
    let isVerified: Bool? // Whether it was found in patient input (hallucination check)
}

// MARK: - Systems Review
struct SystemsReview: Codable, Equatable {
    let general: String?
    let cardiovascular: String?
    let respiratory: String?
    let gastrointestinal: String?
    let neurological: String?
    let musculoskeletal: String?
    let psychiatric: String?
    let integumentary: String?
    let endocrine: String?

    var allSystems: [(name: String, value: String?)] {
        [
            ("General", general),
            ("Cardiovascular", cardiovascular),
            ("Respiratory", respiratory),
            ("Gastrointestinal", gastrointestinal),
            ("Neurological", neurological),
            ("Musculoskeletal", musculoskeletal),
            ("Psychiatric", psychiatric),
            ("Integumentary", integumentary),
            ("Endocrine", endocrine)
        ]
    }

    var nonEmptySystems: [(name: String, value: String)] {
        allSystems.compactMap { name, value in
            guard let value = value, !value.isEmpty else { return nil }
            return (name, value)
        }
    }
}

// MARK: - Lifestyle Factors
struct LifestyleFactors: Codable, Equatable {
    let smoking: String?
    let alcohol: String?
    let exercise: String?
    let diet: String?
    let sleep: String?
    let stress: String?

    var allFactors: [(name: String, value: String?, icon: String)] {
        [
            ("Smoking", smoking, "smoke.fill"),
            ("Alcohol", alcohol, "wineglass.fill"),
            ("Exercise", exercise, "figure.run"),
            ("Diet", diet, "fork.knife"),
            ("Sleep", sleep, "bed.double.fill"),
            ("Stress", stress, "brain.head.profile")
        ]
    }

    var nonEmptyFactors: [(name: String, value: String, icon: String)] {
        allFactors.compactMap { name, value, icon in
            guard let value = value, !value.isEmpty else { return nil }
            return (name, value, icon)
        }
    }
}

// MARK: - Red Flag
struct RedFlag: Codable, Equatable, Identifiable {
    var id: String { "\(flag)-\(severity.rawValue)" }
    let flag: String
    let severity: RedFlagSeverity
    let details: String?
    let recommendation: String?
    let source: RedFlagSource?

    enum RedFlagSource: String, Codable {
        case ai = "AI"
        case keyword = "KEYWORD"
        case manual = "MANUAL"
    }
}

// MARK: - Doctor Edits
struct DoctorEdits: Codable, Equatable {
    let chiefComplaint: String?
    let relevantHistory: String?
    let additionalNotes: String?
    let dismissedRedFlags: [String]? // IDs of dismissed red flags
    let addedRedFlags: [RedFlag]?
}

// MARK: - Update Summary Request
struct UpdateSummaryRequest: Codable {
    let doctorEdits: DoctorEdits
}

// MARK: - Generate Summary Request
struct GenerateSummaryRequest: Codable {
    let intakeId: String
}

// MARK: - Sample Data
extension Summary {
    static let sample = Summary(
        id: "sum_123456",
        intakeId: "int_123456",
        chiefComplaint: "Patient presents with persistent lower back pain for the past 3 weeks, worse with prolonged sitting. Pain is described as dull and aching, rated 5/10.",
        medications: [
            Medication(name: "Ibuprofen", dosage: "400mg", frequency: "As needed", purpose: "Pain relief", isVerified: true)
        ],
        systemsReview: SystemsReview(
            general: "Generally healthy, no recent weight changes",
            cardiovascular: "No chest pain or palpitations reported",
            respiratory: "No shortness of breath or cough",
            gastrointestinal: "Occasional acid reflux, managed with OTC antacids",
            neurological: "No headaches, dizziness, or numbness",
            musculoskeletal: "Lower back pain as chief complaint, no joint swelling",
            psychiatric: "No depression or anxiety reported",
            integumentary: nil,
            endocrine: nil
        ),
        relevantHistory: "History of hypertension, managed with medication. Appendectomy in 2015. Family history significant for Type 2 Diabetes (father) and Hypertension (mother).",
        lifestyle: LifestyleFactors(
            smoking: "Never smoked",
            alcohol: "Occasional, 2-3 drinks per week",
            exercise: "3 times per week, mostly walking and light weights",
            diet: "Balanced diet, actively reducing sodium intake",
            sleep: "Good quality, 7-8 hours per night",
            stress: "Moderate, primarily work-related"
        ),
        redFlags: [],
        hasRedFlags: false,
        redFlagCount: 0,
        doctorEdits: nil,
        editedAt: nil,
        editedByUserId: nil,
        createdAt: Date().addingTimeInterval(-86400),
        updatedAt: Date().addingTimeInterval(-86400)
    )

    static let sampleWithRedFlags = Summary(
        id: "sum_789012",
        intakeId: "int_345678",
        chiefComplaint: "Severe chest pain and difficulty breathing for the past 2 days. Pain is described as pressure-like, radiating to left arm, worse with exertion.",
        medications: [
            Medication(name: "Metformin", dosage: "500mg", frequency: "Twice daily", purpose: "Diabetes management", isVerified: true),
            Medication(name: "Lisinopril", dosage: "10mg", frequency: "Once daily", purpose: "Blood pressure control", isVerified: true)
        ],
        systemsReview: SystemsReview(
            general: "Declining over past week, fatigue",
            cardiovascular: "Chest pain with exertion, occasional palpitations",
            respiratory: "Shortness of breath, orthopnea",
            gastrointestinal: "Normal appetite",
            neurological: "Dizziness reported",
            musculoskeletal: "No complaints",
            psychiatric: "Anxiety about symptoms, some hopelessness",
            integumentary: nil,
            endocrine: "Known Type 2 Diabetes"
        ),
        relevantHistory: "Type 2 Diabetes and Hypertension. Father had MI at age 55. Former smoker (quit 5 years ago).",
        lifestyle: LifestyleFactors(
            smoking: "Former smoker, quit 5 years ago",
            alcohol: "None",
            exercise: "Unable due to symptoms",
            diet: "Diabetic diet, compliant",
            sleep: "Poor, waking with dyspnea",
            stress: "High"
        ),
        redFlags: [
            RedFlag(
                flag: "Chest pain with radiation to arm",
                severity: .high,
                details: "Classic presentation concerning for acute coronary syndrome",
                recommendation: "Urgent cardiac evaluation recommended",
                source: .ai
            ),
            RedFlag(
                flag: "Shortness of breath with orthopnea",
                severity: .high,
                details: "May indicate cardiac or pulmonary pathology",
                recommendation: "Consider chest X-ray and BNP",
                source: .ai
            ),
            RedFlag(
                flag: "Feelings of hopelessness",
                severity: .medium,
                details: "Patient expressed some hopelessness during intake",
                recommendation: "Mental health screening recommended",
                source: .keyword
            )
        ],
        hasRedFlags: true,
        redFlagCount: 3,
        doctorEdits: nil,
        editedAt: nil,
        editedByUserId: nil,
        createdAt: Date().addingTimeInterval(-7200),
        updatedAt: Date().addingTimeInterval(-7200)
    )
}
