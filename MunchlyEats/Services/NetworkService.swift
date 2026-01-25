import Foundation
import Combine

// MARK: - API Response Wrapper
struct APIResponse<T: Codable>: Codable {
    let success: Bool
    let data: T?
    let message: String?
    let error: APIError?
}

struct APIError: Codable, Error {
    let code: String
    let message: String
    let details: [String: String]?
}

// MARK: - Network Service
@MainActor
class NetworkService {
    static let shared = NetworkService()
    
    private let baseURL = "https://api.munchlyeats.com/v1"
    private var authToken: String?
    
    private init() {}
    
    func setAuthToken(_ token: String?) {
        self.authToken = token
    }
    
    // MARK: - Generic Request
    func request<T: Codable>(
        endpoint: String,
        method: HTTPMethod = .get,
        body: Encodable? = nil,
        queryParams: [String: String]? = nil
    ) async throws -> T {
        var urlString = "\(baseURL)\(endpoint)"
        
        if let params = queryParams {
            let queryString = params.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
            urlString += "?\(queryString)"
        }
        
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.httpError(statusCode: httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        return try decoder.decode(T.self, from: data)
    }
    
    // MARK: - Load Local JSON
    func loadLocalJSON<T: Codable>(_ filename: String) throws -> T {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
            throw NetworkError.fileNotFound
        }
        
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        return try decoder.decode(T.self, from: data)
    }
}

// MARK: - HTTP Method
enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

// MARK: - Network Errors
enum NetworkError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingError
    case fileNotFound
    case noConnection
    case timeout
    case unauthorized
    case serverError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let statusCode):
            return "HTTP Error: \(statusCode)"
        case .decodingError:
            return "Failed to decode response"
        case .fileNotFound:
            return "Resource file not found"
        case .noConnection:
            return "No internet connection"
        case .timeout:
            return "Request timed out"
        case .unauthorized:
            return "Unauthorized access"
        case .serverError:
            return "Server error occurred"
        }
    }
}
