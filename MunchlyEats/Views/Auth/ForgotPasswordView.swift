import SwiftUI

struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AuthViewModel()
    
    var body: some View {
        VStack(spacing: 32) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "lock.rotation")
                        .font(.system(size: 60))
                        .foregroundColor(.primary)
                    
                    Text("Reset Password")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Enter your email address and we'll send you instructions to reset your password.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .padding(.top, 40)
                
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
                .padding(.horizontal)
                
                // Send Button
                Button(action: viewModel.sendPasswordReset) {
                    Text("Send Reset Link")
                        .primaryButtonStyle(isEnabled: viewModel.isResetFormValid)
                }
                .disabled(!viewModel.isResetFormValid || viewModel.isLoading)
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Reset Password")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
            }
            .alert("Success", isPresented: $viewModel.showSuccessMessage) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text(viewModel.successMessage)
            }
            .overlay {
                if viewModel.isLoading {
                    LoadingOverlay(isLoading: true, message: "Sending...")
                }
            }
    }
}

#Preview {
    ForgotPasswordView()
}
