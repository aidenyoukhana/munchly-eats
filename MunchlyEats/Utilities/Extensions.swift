import Foundation
import SwiftUI

// MARK: - String Extensions
extension String {
    var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: self)
    }
    
    var isValidPhone: Bool {
        let phoneRegex = "^[0-9+]{10,15}$"
        let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        return phonePredicate.evaluate(with: self.replacingOccurrences(of: " ", with: ""))
    }
    
    func toPhoneFormat() -> String {
        let cleaned = self.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        guard cleaned.count == 10 else { return self }
        
        let mask = "(XXX) XXX-XXXX"
        var result = ""
        var index = cleaned.startIndex
        
        for char in mask {
            if index == cleaned.endIndex { break }
            if char == "X" {
                result.append(cleaned[index])
                index = cleaned.index(after: index)
            } else {
                result.append(char)
            }
        }
        
        return result
    }
}

// MARK: - Double Extensions
extension Double {
    func toCurrency() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: self)) ?? "$0.00"
    }
    
    var asCurrency: String {
        toCurrency()
    }
    
    func toDistance() -> String {
        if self < 0.1 {
            return "< 0.1 mi"
        } else if self < 10 {
            return String(format: "%.1f mi", self)
        } else {
            return String(format: "%.0f mi", self)
        }
    }
}

// MARK: - Date Extensions
extension Date {
    func toRelativeString() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: self, relativeTo: Date())
    }
    
    func toTimeString() -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
    
    func toDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: self)
    }
    
    func toFullString() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
    
    func toOrderDateString() -> String {
        let calendar = Calendar.current
        
        if calendar.isDateInToday(self) {
            return "Today, \(toTimeString())"
        } else if calendar.isDateInYesterday(self) {
            return "Yesterday, \(toTimeString())"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d, h:mm a"
            return formatter.string(from: self)
        }
    }
}

// MARK: - Array Extensions
extension Array where Element: Identifiable {
    func findIndex(by id: Element.ID) -> Int? {
        firstIndex { $0.id == id }
    }
}

// MARK: - View Extensions
extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    func onFirstAppear(perform action: @escaping () -> Void) -> some View {
        modifier(FirstAppearModifier(action: action))
    }
}

struct FirstAppearModifier: ViewModifier {
    let action: () -> Void
    @State private var hasAppeared = false
    
    func body(content: Content) -> some View {
        content.onAppear {
            if !hasAppeared {
                hasAppeared = true
                action()
            }
        }
    }
}

// MARK: - Image Loading
struct AsyncImageView: View {
    let url: String
    var placeholder: String = "photo"
    var contentMode: ContentMode = .fill
    
    var body: some View {
        if url.isEmpty {
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .overlay {
                    Image(systemName: placeholder)
                        .font(.title)
                        .foregroundColor(.gray)
                }
        } else {
            AsyncImage(url: URL(string: url)) { phase in
                switch phase {
                case .empty:
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .overlay {
                            ProgressView()
                        }
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: contentMode)
                case .failure:
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .overlay {
                            Image(systemName: placeholder)
                                .font(.title)
                                .foregroundColor(.gray)
                        }
                @unknown default:
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                }
            }
        }
    }
}

// MARK: - Rating Stars
struct RatingStarsView: View {
    let rating: Double
    let maxRating: Int = 5
    var size: CGFloat = 14
    var color: Color = .primary
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...maxRating, id: \.self) { index in
                Image(systemName: starType(for: index))
                    .font(.system(size: size))
                    .foregroundColor(color)
            }
        }
    }
    
    private func starType(for index: Int) -> String {
        let rating = self.rating
        if rating >= Double(index) {
            return "star.fill"
        } else if rating >= Double(index) - 0.5 {
            return "star.leadinghalf.filled"
        } else {
            return "star"
        }
    }
}

// MARK: - Loading Overlay
struct LoadingOverlay: View {
    let isLoading: Bool
    var message: String = "Loading..."
    
    var body: some View {
        if isLoading {
            ZStack {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                    
                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(.white)
                }
            }
        }
    }
}

// MARK: - Empty State
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var buttonTitle: String? = nil
    var action: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            if let buttonTitle = buttonTitle, let action = action {
                Button(action: action) {
                    Text(buttonTitle)
                        .primaryButtonStyle()
                }
                .padding(.horizontal, 48)
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Shimmer Effect
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.clear,
                            Color.white.opacity(0.5),
                            Color.clear
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 2)
                    .offset(x: -geometry.size.width + phase * geometry.size.width * 2)
                }
            )
            .mask(content)
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}
