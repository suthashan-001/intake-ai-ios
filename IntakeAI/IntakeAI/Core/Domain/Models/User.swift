import Foundation

// MARK: - User Model
struct User: Identifiable, Codable, Equatable {
    let id: String
    let email: String
    let firstName: String
    let lastName: String
    let title: String?
    let practiceName: String?
    let createdAt: Date
    let updatedAt: Date

    var fullName: String {
        "\(firstName) \(lastName)"
    }

    var displayName: String {
        if let title = title {
            return "\(title) \(firstName) \(lastName)"
        }
        return fullName
    }

    var initials: String {
        let firstInitial = firstName.prefix(1)
        let lastInitial = lastName.prefix(1)
        return "\(firstInitial)\(lastInitial)".uppercased()
    }
}

// MARK: - User Registration Request
struct RegisterRequest: Codable {
    let email: String
    let password: String
    let firstName: String
    let lastName: String
    let title: String?
    let practiceName: String?
}

// MARK: - User Login Request
struct LoginRequest: Codable {
    let email: String
    let password: String
}

// MARK: - Auth Response
struct AuthResponse: Codable {
    let user: User
    let accessToken: String
    let message: String?
}

// MARK: - Token Refresh Response
struct TokenRefreshResponse: Codable {
    let accessToken: String
    let user: User?
}

// MARK: - Update User Request
struct UpdateUserRequest: Codable {
    let firstName: String?
    let lastName: String?
    let title: String?
    let practiceName: String?
}

// MARK: - Change Password Request
struct ChangePasswordRequest: Codable {
    let currentPassword: String
    let newPassword: String
}

// MARK: - Sample Data for Previews
extension User {
    static let sample = User(
        id: "usr_123456",
        email: "dr.smith@clinic.com",
        firstName: "Sarah",
        lastName: "Smith",
        title: "MD",
        practiceName: "Smith Family Practice",
        createdAt: Date().addingTimeInterval(-86400 * 30),
        updatedAt: Date()
    )

    static let sampleND = User(
        id: "usr_789012",
        email: "dr.johnson@clinic.com",
        firstName: "Michael",
        lastName: "Johnson",
        title: "ND",
        practiceName: "Holistic Health Center",
        createdAt: Date().addingTimeInterval(-86400 * 60),
        updatedAt: Date()
    )
}
