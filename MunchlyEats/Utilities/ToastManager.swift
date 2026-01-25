import SwiftUI
import Combine

// MARK: - Toast Type
enum ToastType {
    case success
    case error
    case warning
    case info
    
    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .success: return .primary
        case .error: return .secondary
        case .warning: return .secondary
        case .info: return .secondary
        }
    }
}

// MARK: - Toast Item
struct ToastItem: Identifiable, Equatable {
    let id = UUID()
    let type: ToastType
    let title: String
    let message: String?
    
    static func == (lhs: ToastItem, rhs: ToastItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Toast Manager
@MainActor
class ToastManager: ObservableObject {
    static let shared = ToastManager()
    
    @Published var currentToast: ToastItem?
    
    private init() {}
    
    func show(_ type: ToastType, title: String, message: String? = nil, duration: Double = 2.5) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            currentToast = ToastItem(type: type, title: title, message: message)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            withAnimation(.easeOut(duration: 0.2)) {
                self?.currentToast = nil
            }
        }
    }
    
    func showSuccess(_ title: String, message: String? = nil) {
        show(.success, title: title, message: message)
    }
    
    func showError(_ title: String, message: String? = nil) {
        show(.error, title: title, message: message)
    }
    
    func showWarning(_ title: String, message: String? = nil) {
        show(.warning, title: title, message: message)
    }
    
    func showInfo(_ title: String, message: String? = nil) {
        show(.info, title: title, message: message)
    }
    
    func dismiss() {
        withAnimation(.easeOut(duration: 0.2)) {
            currentToast = nil
        }
    }
}

// MARK: - Toast View
struct ToastView: View {
    let toast: ToastItem
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: toast.type.icon)
                .font(.title2)
                .foregroundColor(toast.type.color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(toast.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                if let message = toast.message {
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button {
                ToastManager.shared.dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.15), radius: 10, y: 5)
        )
        .padding(.horizontal, 16)
    }
}

// MARK: - Toast Container Modifier
struct ToastContainerModifier: ViewModifier {
    @ObservedObject var toastManager = ToastManager.shared
    
    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content
            
            if let toast = toastManager.currentToast {
                ToastView(toast: toast)
                    .padding(.top, 50)
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .opacity
                    ))
                    .zIndex(100)
            }
        }
    }
}

// MARK: - View Extension
extension View {
    func withToastContainer() -> some View {
        modifier(ToastContainerModifier())
    }
}
