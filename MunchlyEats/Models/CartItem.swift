import Foundation
import SwiftData

@Model
final class CartItem {
    @Attribute(.unique) var id: String
    var menuItemId: String
    var menuItemName: String
    var menuItemImageURL: String
    var restaurantId: String
    var restaurantName: String
    var basePrice: Double
    var quantity: Int
    var specialInstructions: String?
    var selectedCustomizations: [SelectedCustomization]
    var addedAt: Date
    
    var totalPrice: Double {
        let customizationPrice = selectedCustomizations.reduce(0) { $0 + $1.price }
        return (basePrice + customizationPrice) * Double(quantity)
    }
    
    init(
        id: String = UUID().uuidString,
        menuItemId: String,
        menuItemName: String,
        menuItemImageURL: String,
        restaurantId: String,
        restaurantName: String,
        basePrice: Double,
        quantity: Int = 1,
        specialInstructions: String? = nil,
        selectedCustomizations: [SelectedCustomization] = [],
        addedAt: Date = Date()
    ) {
        self.id = id
        self.menuItemId = menuItemId
        self.menuItemName = menuItemName
        self.menuItemImageURL = menuItemImageURL
        self.restaurantId = restaurantId
        self.restaurantName = restaurantName
        self.basePrice = basePrice
        self.quantity = quantity
        self.specialInstructions = specialInstructions
        self.selectedCustomizations = selectedCustomizations
        self.addedAt = addedAt
    }
}

struct SelectedCustomization: Codable, Identifiable, Hashable {
    let id: String
    let groupName: String
    let optionName: String
    let price: Double
}

// MARK: - Cart Summary
struct CartSummary {
    let items: [CartItem]
    let subtotal: Double
    let deliveryFee: Double
    let serviceFee: Double
    let tax: Double
    let discount: Double
    let total: Double
    
    var itemCount: Int {
        items.reduce(0) { $0 + $1.quantity }
    }
}

// MARK: - Promo Code
struct PromoCode: Codable, Identifiable {
    let id: String
    let code: String
    let description: String
    let discountType: DiscountType
    let discountValue: Double
    let minimumOrder: Double
    let maxDiscount: Double?
    let validUntil: Date
    let usageLimit: Int
    let usedCount: Int
    
    enum DiscountType: String, Codable {
        case percentage
        case fixed
        case freeDelivery
    }
    
    var isValid: Bool {
        validUntil > Date() && usedCount < usageLimit
    }
}
