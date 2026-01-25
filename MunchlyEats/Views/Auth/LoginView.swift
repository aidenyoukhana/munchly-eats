import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @StateObject private var viewModel = AuthViewModel()
    @State private var showSignUp = false
    @State private var showForgotPassword = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Logo and Title
                    VStack(spacing: 16) {
                        Image(systemName: "fork.knife.circle.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(.primary)
                        
                        Text("MunchlyEats")
                            .font(.system(size: 32, weight: .bold))
                        
                        Text("Delicious food, delivered fast")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)
                    
                    // Login Form
                    VStack(spacing: 16) {
                        // Email Field
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
                        
                        // Password Field
                        VStack(alignment: .leading, spacing: 8) {
                            SecureField("Password", text: $viewModel.password)
                                .textFieldStyle(.plain)
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(12)
                                .textContentType(.password)
                        }
                        
                        // Forgot Password
                        HStack {
                            Spacer()
                            Button("Forgot Password?") {
                                showForgotPassword = true
                            }
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Login Button
                    Button(action: viewModel.signIn) {
                        Text("Sign In")
                            .primaryButtonStyle(isEnabled: viewModel.isLoginFormValid)
                    }
                    .disabled(!viewModel.isLoginFormValid || viewModel.isLoading)
                    .padding(.horizontal)
                    
                    // Divider
                    HStack {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 1)
                        
                        Text("or continue with")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 1)
                    }
                    .padding(.horizontal)
                    
                    // Social Login Buttons
                    VStack(spacing: 12) {
                        // Apple Sign In
                        SignInWithAppleButton(.signIn) { request in
                            request.requestedScopes = [.fullName, .email]
                        } onCompletion: { result in
                            viewModel.handleAppleSignIn(result: result)
                        }
                        .signInWithAppleButtonStyle(.black)
                        .frame(height: 50)
                        .cornerRadius(12)
                        
                        // Google Sign In
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
                    
                    // Sign Up Link
                    HStack {
                        Text("Don't have an account?")
                            .foregroundColor(.secondary)
                        
                        Button("Sign Up") {
                            showSignUp = true
                        }
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    }
                    .font(.subheadline)
                    .padding(.top, 8)
                    
                    Spacer(minLength: 40)
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $showSignUp) {
                SignUpView()
            }
            .navigationDestination(isPresented: $showForgotPassword) {
                ForgotPasswordView()
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
            }
            .overlay {
                if viewModel.isLoading {
                    LoadingOverlay(isLoading: true, message: "Signing in...")
                }
            }
        }
    }
}

#Preview {
    LoginView()
}
