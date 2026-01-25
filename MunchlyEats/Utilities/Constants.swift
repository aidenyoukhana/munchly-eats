import Foundation
import Combine
import SwiftUI

// MARK: - App Constants
struct Constants {
    
    // MARK: - API
    struct API {
        static let baseURL = "https://api.munchlyeats.com/v1"
        static let timeout: TimeInterval = 30
    }
    
    // MARK: - Colors
    struct Colors {
        static let primary = Color.primary
        static let secondary = Color.secondary
        static let background = Color(.systemBackground)
        static let secondaryBackground = Color(.secondarySystemBackground)
        static let success = Color.primary
        static let warning = Color.secondary
        static let error = Color.secondary
        static let text = Color(.label)
        static let secondaryText = Color(.secondaryLabel)
    }
    
    // MARK: - Fonts
    struct Fonts {
        static let largeTitle = Font.system(size: 34, weight: .bold)
        static let title = Font.system(size: 28, weight: .bold)
        static let title2 = Font.system(size: 22, weight: .bold)
        static let title3 = Font.system(size: 20, weight: .semibold)
        static let headline = Font.system(size: 17, weight: .semibold)
        static let body = Font.system(size: 17, weight: .regular)
        static let callout = Font.system(size: 16, weight: .regular)
        static let subheadline = Font.system(size: 15, weight: .regular)
        static let footnote = Font.system(size: 13, weight: .regular)
        static let caption = Font.system(size: 12, weight: .regular)
    }
    
    // MARK: - Layout
    struct Layout {
        static let screenPadding: CGFloat = 16
        static let cardPadding: CGFloat = 12
        static let itemSpacing: CGFloat = 12
        static let cornerRadius: CGFloat = 12
        static let smallCornerRadius: CGFloat = 8
        static let buttonHeight: CGFloat = 50
        static let iconSize: CGFloat = 24
        static let smallIconSize: CGFloat = 20
        static let avatarSize: CGFloat = 40
        static let largeAvatarSize: CGFloat = 80
    }
    
    // MARK: - Animation
    struct Animation {
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.2)
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.5)
        static let spring = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.7)
    }
    
    // MARK: - Fees
    struct Fees {
        static let serviceFeePercentage = 0.05 // 5%
        static let taxPercentage = 0.0875 // 8.75%
        static let defaultDeliveryFee = 2.99
    }
    
    // MARK: - Order
    struct Order {
        static let minimumOrderAmount = 10.0
        static let maxScheduleDays = 7
        static let defaultTipPercentages = [10, 15, 20, 25]
    }
    
    // MARK: - Map
    struct Map {
        static let defaultLatitude = 37.7749
        static let defaultLongitude = -122.4194
        static let defaultSpan = 0.05
    }
    
    // MARK: - Images
    struct Images {
        static let placeholder = "photo"
        static let logo = "fork.knife.circle.fill"
        static let home = "house.fill"
        static let search = "magnifyingglass"
        static let orders = "bag.fill"
        static let profile = "person.fill"
        static let cart = "cart.fill"
        static let location = "location.fill"
        static let star = "star.fill"
        static let clock = "clock.fill"
        static let delivery = "car.fill"
    }
}

// MARK: - Color Extension
extension Color {
    static let appPrimary = Color.primary
    static let appSecondary = Color.secondary
    static let appBackground = Color(UIColor.systemBackground)
    static let appCardBackground = Color(UIColor.secondarySystemBackground)
    static let appSuccess = Color.primary
    static let appWarning = Color.secondary
    static let appError = Color.secondary
}

// MARK: - View Modifiers
struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.appCardBackground)
            .cornerRadius(Constants.Layout.cornerRadius)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct PrimaryButtonModifier: ViewModifier {
    let isEnabled: Bool
    
    func body(content: Content) -> some View {
        content
            .font(.headline)
            .foregroundColor(Color(.systemBackground))
            .frame(maxWidth: .infinity)
            .frame(height: Constants.Layout.buttonHeight)
            .background(isEnabled ? Color.primary : Color.secondary)
            .cornerRadius(Constants.Layout.cornerRadius)
    }
}

struct SecondaryButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.headline)
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity)
            .frame(height: Constants.Layout.buttonHeight)
            .background(Color.primary.opacity(0.1))
            .cornerRadius(Constants.Layout.cornerRadius)
    }
}

// MARK: - View Extensions
extension View {
    func cardStyle() -> some View {
        modifier(CardModifier())
    }
    
    func primaryButtonStyle(isEnabled: Bool = true) -> some View {
        modifier(PrimaryButtonModifier(isEnabled: isEnabled))
    }
    
    func secondaryButtonStyle() -> some View {
        modifier(SecondaryButtonModifier())
    }
    
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
