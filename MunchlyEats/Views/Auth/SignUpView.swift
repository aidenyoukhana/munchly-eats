import SwiftUI
import Combine
import AuthenticationServices

struct SignUpView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AuthViewModel()
    
    var body: some View {
        ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Create Account")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Sign up to get started with MunchlyEats")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    // Form
                    VStack(spacing: 16) {
                        // Full Name
                        VStack(alignment: .leading, spacing: 8) {
                            TextField("Full Name", text: $viewModel.fullName)
                                .textFieldStyle(.plain)
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(12)
                                .textContentType(.name)
                                .autocapitalization(.words)
                        }
                        
                        // Email
                        VStack(alignment: .leading, spacing: 8) {
                            TextField("Email", text: $viewModel.email)
                                .textFieldStyle(.plain)
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(12)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                            
                            if let error = viewModel.emailValidationMessage {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Phone (Optional)
                        VStack(alignment: .leading, spacing: 8) {
                            TextField("Phone Number (optional)", text: $viewModel.phoneNumber)
                                .textFieldStyle(.plain)
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(12)
                                .textContentType(.telephoneNumber)
                                .keyboardType(.phonePad)
                        }
                        
                        // Password
                        VStack(alignment: .leading, spacing: 8) {
                            SecureField("Password", text: $viewModel.password)
                                .textFieldStyle(.plain)
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(12)
                                .textContentType(.newPassword)
                            
                            if let error = viewModel.passwordValidationMessage {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Confirm Password
                        VStack(alignment: .leading, spacing: 8) {
                            SecureField("Confirm Password", text: $viewModel.confirmPassword)
                                .textFieldStyle(.plain)
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(12)
                                .textContentType(.newPassword)
                            
                            if let error = viewModel.confirmPasswordValidationMessage {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Terms
                    Text("By signing up, you agree to our Terms of Service and Privacy Policy")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    // Sign Up Button
                    Button(action: viewModel.signUp) {
                        Text("Create Account")
                            .primaryButtonStyle(isEnabled: viewModel.isSignUpFormValid)
                    }
                    .disabled(!viewModel.isSignUpFormValid || viewModel.isLoading)
                    .padding(.horizontal)
                    
                    // Divider
                    HStack {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 1)
                        
                        Text("or")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 1)
                    }
                    .padding(.horizontal)
                    
                    // Social Sign Up
                    VStack(spacing: 12) {
                        SignInWithAppleButton(.signUp) { request in
                            request.requestedScopes = [.fullName, .email]
                        } onCompletion: { result in
                            viewModel.handleAppleSignIn(result: result)
                        }
                        .signInWithAppleButtonStyle(.black)
                        .frame(height: 50)
                        .cornerRadius(12)
                        
                        Button(action: viewModel.signInWithGoogle) {
                            HStack(spacing: 12) {
                                Image(systemName: "g.circle.fill")
                                    .font(.title2)
                                Text("Continue with Google")
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color(.secondarySystemBackground))
                            .foregroundColor(.primary)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Sign In Link
                    HStack {
                        Text("Already have an account?")
                            .foregroundColor(.secondary)
                        
                        Button("Sign In") {
                            dismiss()
                        }
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    }
                    .font(.subheadline)
                    .padding(.vertical)
                }
            }
            .navigationTitle("Sign Up")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
            }
            .overlay {
                if viewModel.isLoading {
                    LoadingOverlay(isLoading: true, message: "Creating account...")
                }
            }
            .onChange(of: viewModel.isAuthenticated) { _, isAuthenticated in
                if isAuthenticated {
                    dismiss()
                }
            }
    }
}

#Preview {
    SignUpView()
}
