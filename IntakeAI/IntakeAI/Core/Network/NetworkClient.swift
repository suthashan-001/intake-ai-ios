import Foundation

// MARK: - Network Client
/// A robust networking client with HttpOnly cookie support for secure authentication
actor NetworkClient {
    static let shared = NetworkClient()

    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    // Token management
    private var accessToken: String?
    private var isRefreshing = false
    private var pendingRequests: [CheckedContinuation<Data, Error>] = []

    private init() {
        // Configuration
        #if DEBUG
        self.baseURL = URL(string: "http://localhost:3001/api")!
        #else
        self.baseURL = URL(string: "https://api.intakeai.app/api")!
        #endif

        // Session configuration with cookie support
        let config = URLSessionConfiguration.default
        config.httpCookieAcceptPolicy = .always
        config.httpShouldSetCookies = true
        config.httpCookieStorage = HTTPCookieStorage.shared
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60

        self.session = URLSession(configuration: config)

        // JSON decoder with date handling
        self.decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)

            // Try ISO8601 first
            let iso8601Formatter = ISO8601DateFormatter()
            iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = iso8601Formatter.date(from: dateString) {
                return date
            }

            // Try without fractional seconds
            iso8601Formatter.formatOptions = [.withInternetDateTime]
            if let date = iso8601Formatter.date(from: dateString) {
                return date
            }

            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date: \(dateString)")
        }

        // JSON encoder
        self.encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
    }

    // MARK: - Token Management

    func setAccessToken(_ token: String?) {
        self.accessToken = token
    }

    func getAccessToken() -> String? {
        return accessToken
    }

    func clearTokens() {
        self.accessToken = nil
        // Clear cookies
        if let cookies = HTTPCookieStorage.shared.cookies(for: baseURL) {
            for cookie in cookies {
                HTTPCookieStorage.shared.deleteCookie(cookie)
            }
        }
    }

    // MARK: - Request Methods

    func request<T: Decodable>(
        _ endpoint: Endpoint,
        responseType: T.Type
    ) async throws -> T {
        let data = try await performRequest(endpoint)
        return try decoder.decode(T.self, from: data)
    }

    func request(_ endpoint: Endpoint) async throws {
        _ = try await performRequest(endpoint)
    }

    private func performRequest(_ endpoint: Endpoint) async throws -> Data {
        var request = try buildRequest(for: endpoint)

        // Add authorization header if we have a token
        if let token = accessToken, endpoint.requiresAuth {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }

            // Handle different status codes
            switch httpResponse.statusCode {
            case 200...299:
                return data

            case 401:
                // Token expired - try to refresh
                if endpoint.requiresAuth && !isRefreshing {
                    return try await handleTokenRefresh(originalEndpoint: endpoint)
                }
                throw NetworkError.unauthorized

            case 403:
                throw NetworkError.forbidden

            case 404:
                throw NetworkError.notFound

            case 429:
                throw NetworkError.rateLimited

            case 400...499:
                let errorResponse = try? decoder.decode(APIError.self, from: data)
                throw NetworkError.clientError(httpResponse.statusCode, errorResponse?.message ?? "Client error")

            case 500...599:
                throw NetworkError.serverError(httpResponse.statusCode)

            default:
                throw NetworkError.unknown(httpResponse.statusCode)
            }
        } catch let error as NetworkError {
            throw error
        } catch {
            throw NetworkError.networkFailure(error)
        }
    }

    private func buildRequest(for endpoint: Endpoint) throws -> URLRequest {
        let url = baseURL.appendingPathComponent(endpoint.path)
        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)

        // Add query parameters
        if let queryItems = endpoint.queryItems, !queryItems.isEmpty {
            components?.queryItems = queryItems
        }

        guard let finalURL = components?.url else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: finalURL)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        // Add body for POST/PUT/PATCH requests
        if let body = endpoint.body {
            request.httpBody = try encoder.encode(body)
        }

        return request
    }

    private func handleTokenRefresh(originalEndpoint: Endpoint) async throws -> Data {
        isRefreshing = true
        defer { isRefreshing = false }

        do {
            // Attempt to refresh the token
            let refreshEndpoint = Endpoint.refreshToken
            var request = try buildRequest(for: refreshEndpoint)

            // No auth header for refresh - uses HttpOnly cookie
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw NetworkError.unauthorized
            }

            // Parse new access token
            let tokenResponse = try decoder.decode(TokenRefreshResponse.self, from: data)
            self.accessToken = tokenResponse.accessToken

            // Retry original request
            return try await performRequest(originalEndpoint)
        } catch {
            // Refresh failed - clear tokens and throw unauthorized
            clearTokens()
            throw NetworkError.unauthorized
        }
    }
}

// MARK: - HTTP Method
enum HTTPMethod: String {
    case GET
    case POST
    case PUT
    case PATCH
    case DELETE
}

// MARK: - Endpoint
struct Endpoint {
    let path: String
    let method: HTTPMethod
    let body: Encodable?
    let queryItems: [URLQueryItem]?
    let requiresAuth: Bool

    init(
        path: String,
        method: HTTPMethod = .GET,
        body: Encodable? = nil,
        queryItems: [URLQueryItem]? = nil,
        requiresAuth: Bool = true
    ) {
        self.path = path
        self.method = method
        self.body = body
        self.queryItems = queryItems
        self.requiresAuth = requiresAuth
    }
}

// MARK: - Auth Endpoints
extension Endpoint {
    static func login(email: String, password: String) -> Endpoint {
        Endpoint(
            path: "auth/login",
            method: .POST,
            body: LoginRequest(email: email, password: password),
            requiresAuth: false
        )
    }

    static func register(request: RegisterRequest) -> Endpoint {
        Endpoint(
            path: "auth/register",
            method: .POST,
            body: request,
            requiresAuth: false
        )
    }

    static var refreshToken: Endpoint {
        Endpoint(
            path: "auth/refresh",
            method: .POST,
            requiresAuth: false
        )
    }

    static var logout: Endpoint {
        Endpoint(
            path: "auth/logout",
            method: .POST
        )
    }

    static var currentUser: Endpoint {
        Endpoint(path: "auth/me")
    }
}

// MARK: - Patient Endpoints
extension Endpoint {
    static func patients(page: Int = 1, pageSize: Int = 20, search: String? = nil) -> Endpoint {
        var queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "pageSize", value: "\(pageSize)")
        ]
        if let search = search, !search.isEmpty {
            queryItems.append(URLQueryItem(name: "search", value: search))
        }
        return Endpoint(path: "patients", queryItems: queryItems)
    }

    static func patient(id: String) -> Endpoint {
        Endpoint(path: "patients/\(id)")
    }

    static func createPatient(request: CreatePatientRequest) -> Endpoint {
        Endpoint(
            path: "patients",
            method: .POST,
            body: request
        )
    }

    static func updatePatient(id: String, request: UpdatePatientRequest) -> Endpoint {
        Endpoint(
            path: "patients/\(id)",
            method: .PATCH,
            body: request
        )
    }

    static func deletePatient(id: String) -> Endpoint {
        Endpoint(
            path: "patients/\(id)",
            method: .DELETE
        )
    }
}

// MARK: - Intake Link Endpoints
extension Endpoint {
    static func intakeLinks(patientId: String? = nil) -> Endpoint {
        var queryItems: [URLQueryItem]? = nil
        if let patientId = patientId {
            queryItems = [URLQueryItem(name: "patientId", value: patientId)]
        }
        return Endpoint(path: "intake-links", queryItems: queryItems)
    }

    static func createIntakeLink(request: CreateIntakeLinkRequest) -> Endpoint {
        Endpoint(
            path: "intake-links",
            method: .POST,
            body: request
        )
    }

    static func revokeIntakeLink(id: String) -> Endpoint {
        Endpoint(
            path: "intake-links/\(id)",
            method: .DELETE
        )
    }
}

// MARK: - Summary Endpoints
extension Endpoint {
    static func summary(intakeId: String) -> Endpoint {
        Endpoint(path: "summaries/intake/\(intakeId)")
    }

    static func generateSummary(intakeId: String) -> Endpoint {
        Endpoint(
            path: "summaries/generate",
            method: .POST,
            body: GenerateSummaryRequest(intakeId: intakeId)
        )
    }

    static func updateSummary(id: String, request: UpdateSummaryRequest) -> Endpoint {
        Endpoint(
            path: "summaries/\(id)",
            method: .PATCH,
            body: request
        )
    }
}

// MARK: - Dashboard Endpoints
extension Endpoint {
    static var dashboard: Endpoint {
        Endpoint(path: "dashboard")
    }
}

// MARK: - Network Errors
enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case forbidden
    case notFound
    case rateLimited
    case clientError(Int, String)
    case serverError(Int)
    case networkFailure(Error)
    case decodingError(Error)
    case unknown(Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .unauthorized:
            return "Session expired. Please log in again."
        case .forbidden:
            return "You don't have permission to access this resource"
        case .notFound:
            return "Resource not found"
        case .rateLimited:
            return "Too many requests. Please wait a moment."
        case .clientError(_, let message):
            return message
        case .serverError(let code):
            return "Server error (\(code)). Please try again later."
        case .networkFailure(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Data error: \(error.localizedDescription)"
        case .unknown(let code):
            return "Unknown error (\(code))"
        }
    }
}

// MARK: - API Error Response
struct APIError: Codable {
    let message: String
    let error: String?
    let statusCode: Int?
}

// MARK: - Encodable Extension for Body
private struct AnyEncodable: Encodable {
    private let encodable: Encodable

    init(_ encodable: Encodable) {
        self.encodable = encodable
    }

    func encode(to encoder: Encoder) throws {
        try encodable.encode(to: encoder)
    }
}
