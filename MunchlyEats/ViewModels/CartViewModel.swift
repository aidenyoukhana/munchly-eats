import Foundation
import Combine
import SwiftUI

@MainActor
class CartViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var promoCodeInput = ""
    @Published var showPromoCodeError = false
    @Published var promoCodeErrorMessage = ""
    @Published var showPromoCodeSuccess = false
    
    @Published var showDifferentRestaurantAlert = false
    @Published var pendingItem: (menuItem: MenuItemDTO, restaurant: RestaurantDTO, quantity: Int, customizations: [SelectedCustomization], instructions: String?)?
    
    @Published var deliveryInstructions = ""
    @Published var selectedTipPercentage: Int? = 15
    @Published var customTipAmount: Double = 0
    
    // MARK: - Services
    let cartService = CartService.shared
    
    // MARK: - Computed Properties
    var items: [CartItem] {
        cartService.items
    }
    
    var isEmpty: Bool {
        items.isEmpty
    }
    
    var itemCount: Int {
        cartService.itemCount
    }
    
    var subtotal: Double {
        cartService.subtotal
    }
    
    var deliveryFee: Double {
        cartService.deliveryFee
    }
    
    var serviceFee: Double {
        cartService.serviceFee
    }
    
    var tax: Double {
        cartService.tax
    }
    
    var discount: Double {
        cartService.discount
    }
    
    var tipAmount: Double {
        if let percentage = selectedTipPercentage {
            return subtotal * Double(percentage) / 100
        }
        return customTipAmount
    }
    
    var total: Double {
        cartService.total + tipAmount
    }
    
    var restaurantName: String? {
        cartService.currentRestaurantName
    }
    
    var appliedPromoCode: PromoCode? {
        cartService.appliedPromoCode
    }
    
    var summary: CartSummary {
        cartService.summary
    }
    
    // MARK: - Add Item
    func addItem(
        menuItem: MenuItemDTO,
        restaurant: RestaurantDTO,
        quantity: Int = 1,
        specialInstructions: String? = nil,
        selectedCustomizations: [SelectedCustomization] = []
    ) {
        do {
            try cartService.addItem(
                menuItem: menuItem,
                restaurant: restaurant,
                quantity: quantity,
                specialInstructions: specialInstructions,
                selectedCustomizations: selectedCustomizations
            )
        } catch let error as CartError {
            if case .differentRestaurant = error {
                // Store pending item and show alert
                pendingItem = (menuItem, restaurant, quantity, selectedCustomizations, specialInstructions)
                showDifferentRestaurantAlert = true
            }
        } catch {
            print("Error adding item: \(error)")
        }
    }
    
    // MARK: - Replace Cart and Add
    func replaceCartAndAdd() {
        guard let pending = pendingItem else { return }
        
        cartService.replaceCart(
            with: pending.menuItem,
            restaurant: pending.restaurant,
            quantity: pending.quantity,
            specialInstructions: pending.instructions,
            selectedCustomizations: pending.customizations
        )
        
        pendingItem = nil
    }
    
    // MARK: - Update Quantity
    func updateQuantity(for itemId: String, quantity: Int) {
        cartService.updateQuantity(for: itemId, quantity: quantity)
    }
    
    func incrementQuantity(for itemId: String) {
        if let item = items.first(where: { $0.id == itemId }) {
            cartService.updateQuantity(for: itemId, quantity: item.quantity + 1)
        }
    }
    
    func decrementQuantity(for itemId: String) {
        if let item = items.first(where: { $0.id == itemId }) {
            cartService.updateQuantity(for: itemId, quantity: item.quantity - 1)
        }
    }
    
    // MARK: - Remove Item
    func removeItem(_ itemId: String) {
        cartService.removeItem(itemId)
    }
    
    // MARK: - Clear Cart
    func clearCart() {
        cartService.clearCart()
        resetPromoCode()
        resetTip()
    }
    
    // MARK: - Apply Promo Code
    func applyPromoCode() {
        guard !promoCodeInput.isEmpty else { return }
        
        Task {
            do {
                let promo = try await cartService.applyPromoCode(promoCodeInput)
                showPromoCodeSuccess = true
                promoCodeInput = ""
                ToastManager.shared.showSuccess("Promo Applied!", message: promo.description)
                
                // Auto dismiss success after 2 seconds
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                showPromoCodeSuccess = false
            } catch {
                promoCodeErrorMessage = error.localizedDescription
                showPromoCodeError = true
                ToastManager.shared.showError("Invalid Code", message: error.localizedDescription)
            }
        }
    }
    
    // MARK: - Remove Promo Code
    func removePromoCode() {
        cartService.removePromoCode()
        ToastManager.shared.showInfo("Promo Code Removed")
    }
    
    func resetPromoCode() {
        promoCodeInput = ""
        showPromoCodeError = false
        showPromoCodeSuccess = false
    }
    
    // MARK: - Tip
    func selectTip(percentage: Int?) {
        selectedTipPercentage = percentage
        if percentage != nil {
            customTipAmount = 0
        }
    }
    
    func setCustomTip(_ amount: Double) {
        customTipAmount = amount
        selectedTipPercentage = nil
    }
    
    func resetTip() {
        selectedTipPercentage = 15
        customTipAmount = 0
    }
}
