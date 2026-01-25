import Foundation
import Combine
import AuthenticationServices
import SwiftUI

@MainActor
class AuthViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var fullName = ""
    @Published var phoneNumber = ""
    
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var showSuccessMessage = false
    @Published var successMessage = ""
    
    @Published var isAuthenticated = false
    
    // MARK: - Services
    private let authService = AuthService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initializer
    init() {
        // Observe auth service authentication state
        authService.$isAuthenticated
            .receive(on: DispatchQueue.main)
            .assign(to: &$isAuthenticated)
    }
    
    // MARK: - Computed Properties
    var currentUser: User? {
        authService.currentUser
    }
    
    var isLoginFormValid: Bool {
        !email.isEmpty && !password.isEmpty && email.isValidEmail
    }
    
    var isSignUpFormValid: Bool {
        !email.isEmpty &&
        !password.isEmpty &&
        !fullName.isEmpty &&
        email.isValidEmail &&
        password.count >= 8 &&
        password == confirmPassword
    }
    
    var isResetFormValid: Bool {
        !email.isEmpty && email.isValidEmail
    }
    
    // MARK: - Validation Messages
    var emailValidationMessage: String? {
        if email.isEmpty { return nil }
        return email.isValidEmail ? nil : "Please enter a valid email"
    }
    
    var passwordValidationMessage: String? {
        if password.isEmpty { return nil }
        return password.count >= 8 ? nil : "Password must be at least 8 characters"
    }
    
    var confirmPasswordValidationMessage: String? {
        if confirmPassword.isEmpty { return nil }
        return password == confirmPassword ? nil : "Passwords don't match"
    }
    
    // MARK: - Sign In
    func signIn() {
        guard isLoginFormValid else {
            showError(message: "Please fill in all fields correctly")
            return
        }
        
        Task {
            isLoading = true
            defer { isLoading = false }
            
            do {
                try await authService.signIn(email: email, password: password)
                clearForm()
            } catch {
                showError(message: error.localizedDescription)
            }
        }
    }
    
    // MARK: - Sign Up
    func signUp() {
        guard isSignUpFormValid else {
            showError(message: "Please fill in all fields correctly")
            return
        }
        
        Task {
            isLoading = true
            defer { isLoading = false }
            
            do {
                try await authService.signUp(
                    email: email,
                    password: password,
                    fullName: fullName,
                    phoneNumber: phoneNumber.isEmpty ? nil : phoneNumber
                )
                clearForm()
            } catch {
                showError(message: error.localizedDescription)
            }
        }
    }
    
    // MARK: - Apple Sign In
    func handleAppleSignIn(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                showError(message: "Invalid Apple credential")
                return
            }
            
            Task {
                isLoading = true
                defer { isLoading = false }
                
                do {
                    try await authService.signInWithApple(credential: credential)
                } catch {
                    showError(message: error.localizedDescription)
                }
            }
            
        case .failure(let error):
            // Don't show error for user cancellation
            if (error as NSError).code != ASAuthorizationError.canceled.rawValue {
                showError(message: error.localizedDescription)
            }
        }
    }
    
    // MARK: - Google Sign In
    func signInWithGoogle() {
        Task {
            isLoading = true
            defer { isLoading = false }
            
            do {
                try await authService.signInWithGoogle()
            } catch {
                showError(message: error.localizedDescription)
            }
        }
    }
    
    // MARK: - Forgot Password
    func sendPasswordReset() {
        guard isResetFormValid else {
            showError(message: "Please enter a valid email address")
            return
        }
        
        Task {
            isLoading = true
            defer { isLoading = false }
            
            do {
                try await authService.sendPasswordReset(email: email)
                showSuccess(message: "Password reset email sent to \(email)")
                ToastManager.shared.showSuccess("Email Sent", message: "Check your inbox for password reset link")
            } catch {
                showError(message: error.localizedDescription)
                ToastManager.shared.showError("Failed", message: error.localizedDescription)
            }
        }
    }
    
    // MARK: - Sign Out
    func signOut() {
        authService.signOut()
        clearForm()
        ToastManager.shared.showInfo("Signed Out")
    }
    
    // MARK: - Private Helpers
    private func clearForm() {
        email = ""
        password = ""
        confirmPassword = ""
        fullName = ""
        phoneNumber = ""
    }
    
    private func showError(message: String) {
        errorMessage = message
        showError = true
        ToastManager.shared.showError("Error", message: message)
    }
    
    private func showSuccess(message: String) {
        successMessage = message
        showSuccessMessage = true
    }
}
