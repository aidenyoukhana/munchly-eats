import Foundation
import Combine
import SwiftData

// MARK: - Cart Service
@MainActor
class CartService: ObservableObject {
    static let shared = CartService()
    
    @Published var items: [CartItem] = []
    @Published var appliedPromoCode: PromoCode?
    @Published var isLoading = false
    
    private init() {}
    
    // MARK: - Computed Properties
    var itemCount: Int {
        items.reduce(0) { $0 + $1.quantity }
    }
    
    var currentRestaurantId: String? {
        items.first?.restaurantId
    }
    
    var currentRestaurantName: String? {
        items.first?.restaurantName
    }
    
    var subtotal: Double {
        items.reduce(0) { $0 + $1.totalPrice }
    }
    
    var deliveryFee: Double {
        guard !items.isEmpty else { return 0 }
        if let promo = appliedPromoCode, promo.discountType == .freeDelivery {
            return 0
        }
        return 2.99
    }
    
    var serviceFee: Double {
        guard !items.isEmpty else { return 0 }
        return subtotal * 0.05 // 5% service fee
    }
    
    var tax: Double {
        subtotal * 0.0875 // 8.75% tax
    }
    
    var discount: Double {
        guard let promo = appliedPromoCode else { return 0 }
        
        switch promo.discountType {
        case .percentage:
            let calculatedDiscount = subtotal * (promo.discountValue / 100)
            if let maxDiscount = promo.maxDiscount {
                return min(calculatedDiscount, maxDiscount)
            }
            return calculatedDiscount
        case .fixed:
            return promo.discountValue
        case .freeDelivery:
            return 0
        }
    }
    
    var total: Double {
        subtotal + deliveryFee + serviceFee + tax - discount
    }
    
    var summary: CartSummary {
        CartSummary(
            items: items,
            subtotal: subtotal,
            deliveryFee: deliveryFee,
            serviceFee: serviceFee,
            tax: tax,
            discount: discount,
            total: total
        )
    }
    
    // MARK: - Add Item
    func addItem(
        menuItem: MenuItemDTO,
        restaurant: RestaurantDTO,
        quantity: Int = 1,
        specialInstructions: String? = nil,
        selectedCustomizations: [SelectedCustomization] = []
    ) throws {
        // Check if adding from different restaurant
        if let currentId = currentRestaurantId, currentId != restaurant.id {
            throw CartError.differentRestaurant(currentName: currentRestaurantName ?? "another restaurant")
        }
        
        // Check if same item with same customizations exists
        if let existingIndex = items.firstIndex(where: { item in
            item.menuItemId == menuItem.id &&
            item.selectedCustomizations == selectedCustomizations &&
            item.specialInstructions == specialInstructions
        }) {
            items[existingIndex].quantity += quantity
        } else {
            let cartItem = CartItem(
                menuItemId: menuItem.id,
                menuItemName: menuItem.name,
                menuItemImageURL: menuItem.imageURL,
                restaurantId: restaurant.id,
                restaurantName: restaurant.name,
                basePrice: menuItem.price,
                quantity: quantity,
                specialInstructions: specialInstructions,
                selectedCustomizations: selectedCustomizations
            )
            items.append(cartItem)
        }
    }
    
    // MARK: - Update Quantity
    func updateQuantity(for itemId: String, quantity: Int) {
        guard let index = items.firstIndex(where: { $0.id == itemId }) else { return }
        
        if quantity <= 0 {
            items.remove(at: index)
        } else {
            items[index].quantity = quantity
        }
    }
    
    // MARK: - Remove Item
    func removeItem(_ itemId: String) {
        items.removeAll { $0.id == itemId }
        
        // Clear promo code if cart is empty
        if items.isEmpty {
            appliedPromoCode = nil
        }
    }
    
    // MARK: - Clear Cart
    func clearCart() {
        items.removeAll()
        appliedPromoCode = nil
    }
    
    // MARK: - Replace Cart (for switching restaurants)
    func replaceCart(
        with menuItem: MenuItemDTO,
        restaurant: RestaurantDTO,
        quantity: Int = 1,
        specialInstructions: String? = nil,
        selectedCustomizations: [SelectedCustomization] = []
    ) {
        clearCart()
        try? addItem(
            menuItem: menuItem,
            restaurant: restaurant,
            quantity: quantity,
            specialInstructions: specialInstructions,
            selectedCustomizations: selectedCustomizations
        )
    }
    
    // MARK: - Apply Promo Code
    func applyPromoCode(_ code: String) async throws -> PromoCode {
        isLoading = true
        defer { isLoading = false }
        
        // Simulate API call
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Mock promo codes
        let promoCodes: [PromoCode] = [
            PromoCode(
                id: "promo_1",
                code: "WELCOME50",
                description: "50% off your first order",
                discountType: .percentage,
                discountValue: 50,
                minimumOrder: 15.0,
                maxDiscount: 15.0,
                validUntil: Date().addingTimeInterval(86400 * 365),
                usageLimit: 1,
                usedCount: 0
            ),
            PromoCode(
                id: "promo_2",
                code: "FREEDELIVERY",
                description: "Free delivery on your order",
                discountType: .freeDelivery,
                discountValue: 0,
                minimumOrder: 15.0,
                maxDiscount: nil,
                validUntil: Date().addingTimeInterval(86400 * 30),
                usageLimit: 100,
                usedCount: 45
            ),
            PromoCode(
                id: "promo_3",
                code: "SAVE10",
                description: "$10 off orders over $30",
                discountType: .fixed,
                discountValue: 10,
                minimumOrder: 30.0,
                maxDiscount: nil,
                validUntil: Date().addingTimeInterval(86400 * 14),
                usageLimit: 50,
                usedCount: 20
            )
        ]
        
        guard let promo = promoCodes.first(where: { $0.code.uppercased() == code.uppercased() }) else {
            throw CartError.invalidPromoCode
        }
        
        guard promo.isValid else {
            throw CartError.expiredPromoCode
        }
        
        guard subtotal >= promo.minimumOrder else {
            throw CartError.minimumOrderNotMet(minimum: promo.minimumOrder)
        }
        
        appliedPromoCode = promo
        return promo
    }
    
    // MARK: - Remove Promo Code
    func removePromoCode() {
        appliedPromoCode = nil
    }
}

// MARK: - Cart Errors
enum CartError: Error, LocalizedError {
    case differentRestaurant(currentName: String)
    case invalidPromoCode
    case expiredPromoCode
    case minimumOrderNotMet(minimum: Double)
    case itemNotFound
    
    var errorDescription: String? {
        switch self {
        case .differentRestaurant(let name):
            return "You have items from \(name) in your cart. Would you like to clear your cart and add items from this restaurant?"
        case .invalidPromoCode:
            return "This promo code is invalid"
        case .expiredPromoCode:
            return "This promo code has expired"
        case .minimumOrderNotMet(let minimum):
            return "Minimum order of $\(String(format: "%.2f", minimum)) required for this promo code"
        case .itemNotFound:
            return "Item not found in cart"
        }
    }
}
