import Foundation
import Combine
import AuthenticationServices

// MARK: - Auth Service
@MainActor
class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var error: AuthError?
    
    private let userDefaults = UserDefaults.standard
    private let tokenKey = "authToken"
    private let userIdKey = "userId"
    
    private init() {
        checkAuthStatus()
    }
    
    // MARK: - Check Auth Status
    func checkAuthStatus() {
        if let token = userDefaults.string(forKey: tokenKey),
           let userId = userDefaults.string(forKey: userIdKey) {
            NetworkService.shared.setAuthToken(token)
            isAuthenticated = true
            Task {
                await fetchCurrentUser(userId: userId)
            }
        }
    }
    
    // MARK: - Email Sign In
    func signIn(email: String, password: String) async throws {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        // Validate inputs
        guard isValidEmail(email) else {
            throw AuthError.invalidEmail
        }
        
        guard password.count >= 6 else {
            throw AuthError.weakPassword
        }
        
        // Simulate API call - in production, this would be a real network request
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Check for dummy test user
        if email.lowercased() == "0@0.com" && password == "Pass@word1" {
            let testUser = User(
                id: "test-user-001",
                email: "0@0.com",
                fullName: "Test User",
                phoneNumber: "+1555555555"
            )
            saveAuthData(token: "test_token_001", userId: testUser.id)
            currentUser = testUser
            isAuthenticated = true
            return
        }
        
        // Mock successful login for other users
        let mockUser = User(
            id: UUID().uuidString,
            email: email,
            fullName: "John Doe",
            phoneNumber: "+1234567890"
        )
        
        saveAuthData(token: "mock_token_\(UUID().uuidString)", userId: mockUser.id)
        currentUser = mockUser
        isAuthenticated = true
    }
    
    // MARK: - Email Sign Up
    func signUp(email: String, password: String, fullName: String, phoneNumber: String?) async throws {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        // Validate inputs
        guard isValidEmail(email) else {
            throw AuthError.invalidEmail
        }
        
        guard password.count >= 8 else {
            throw AuthError.weakPassword
        }
        
        guard !fullName.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw AuthError.invalidName
        }
        
        // Simulate API call
        try await Task.sleep(nanoseconds: 1_500_000_000)
        
        // Mock successful signup
        let mockUser = User(
            id: UUID().uuidString,
            email: email,
            fullName: fullName,
            phoneNumber: phoneNumber
        )
        
        saveAuthData(token: "mock_token_\(UUID().uuidString)", userId: mockUser.id)
        currentUser = mockUser
        isAuthenticated = true
    }
    
    // MARK: - Apple Sign In
    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        let userId = credential.user
        let email = credential.email ?? "apple_\(userId)@munchlyeats.com"
        let fullName = [credential.fullName?.givenName, credential.fullName?.familyName]
            .compactMap { $0 }
            .joined(separator: " ")
        
        // Simulate API call
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        let mockUser = User(
            id: userId,
            email: email,
            fullName: fullName.isEmpty ? "Apple User" : fullName
        )
        
        saveAuthData(token: "apple_token_\(UUID().uuidString)", userId: mockUser.id)
        currentUser = mockUser
        isAuthenticated = true
    }
    
    // MARK: - Google Sign In
    func signInWithGoogle() async throws {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        // Simulate Google Sign In - in production, use GoogleSignIn SDK
        try await Task.sleep(nanoseconds: 1_500_000_000)
        
        let mockUser = User(
            id: UUID().uuidString,
            email: "google_user@gmail.com",
            fullName: "Google User"
        )
        
        saveAuthData(token: "google_token_\(UUID().uuidString)", userId: mockUser.id)
        currentUser = mockUser
        isAuthenticated = true
    }
    
    // MARK: - Forgot Password
    func sendPasswordReset(email: String) async throws {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        guard isValidEmail(email) else {
            throw AuthError.invalidEmail
        }
        
        // Simulate API call
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        // In production, this would send an actual password reset email
    }
    
    // MARK: - Sign Out
    func signOut() {
        userDefaults.removeObject(forKey: tokenKey)
        userDefaults.removeObject(forKey: userIdKey)
        NetworkService.shared.setAuthToken(nil)
        currentUser = nil
        isAuthenticated = false
    }
    
    // MARK: - Update Profile
    func updateProfile(fullName: String?, phoneNumber: String?, profileImageURL: String?) async throws {
        isLoading = true
        
        defer { isLoading = false }
        
        guard let user = currentUser else {
            throw AuthError.notAuthenticated
        }
        
        // Simulate API call
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        if let name = fullName { user.fullName = name }
        if let phone = phoneNumber { user.phoneNumber = phone }
        if let image = profileImageURL { user.profileImageURL = image }
        
        currentUser = user
    }
    
    // MARK: - Delete Account
    func deleteAccount() async throws {
        isLoading = true
        
        defer { isLoading = false }
        
        // Simulate API call
        try await Task.sleep(nanoseconds: 1_500_000_000)
        
        signOut()
    }
    
    // MARK: - Private Helpers
    private func saveAuthData(token: String, userId: String) {
        userDefaults.set(token, forKey: tokenKey)
        userDefaults.set(userId, forKey: userIdKey)
        NetworkService.shared.setAuthToken(token)
    }
    
    private func fetchCurrentUser(userId: String) async {
        // In production, fetch from API
        // For now, create mock user
        currentUser = User(
            id: userId,
            email: "user@munchlyeats.com",
            fullName: "Munchly User"
        )
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}

// MARK: - Auth Errors
enum AuthError: Error, LocalizedError {
    case invalidEmail
    case weakPassword
    case invalidName
    case invalidCredentials
    case emailAlreadyInUse
    case notAuthenticated
    case networkError
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Please enter a valid email address"
        case .weakPassword:
            return "Password must be at least 8 characters"
        case .invalidName:
            return "Please enter your full name"
        case .invalidCredentials:
            return "Invalid email or password"
        case .emailAlreadyInUse:
            return "An account with this email already exists"
        case .notAuthenticated:
            return "Please sign in to continue"
        case .networkError:
            return "Network error. Please check your connection"
        case .unknownError:
            return "An unknown error occurred"
        }
    }
}
