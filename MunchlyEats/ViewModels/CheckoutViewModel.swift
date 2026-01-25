import Foundation
import Combine

@MainActor
class CheckoutViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var selectedAddress: Address?
    @Published var deliveryOption: DeliveryOption = .standard
    @Published var scheduledTime: Date = Date().addingTimeInterval(3600)
    @Published var selectedPaymentMethod: PaymentMethod?
    @Published var selectedTip: TipOption = .twentyPercent
    @Published var customTip: String = ""
    
    @Published var isPlacingOrder = false
    @Published var placedOrder: Order?
    @Published var showError = false
    @Published var errorMessage = ""
    
    // MARK: - Services
    private let orderService = OrderService.shared
    private let locationService = LocationService.shared
    private let cartService = CartService.shared
    
    // MARK: - Computed Properties
    var tipAmount: Double {
        switch selectedTip {
        case .none:
            return 0
        case .custom:
            return Double(customTip) ?? 0
        default:
            return cartService.subtotal * selectedTip.percentage
        }
    }
    
    // MARK: - Initialization
    init() {
        loadDefaults()
    }
    
    // MARK: - Load Defaults
    func loadDefaults() {
        selectedAddress = locationService.selectedAddress
        
        // Load default payment method
        // For now, create a mock payment method
        if selectedPaymentMethod == nil {
            selectedPaymentMethod = PaymentMethod(
                type: .creditCard,
                last4: "4242",
                brand: "Visa",
                expiryMonth: 12,
                expiryYear: 2025,
                holderName: "John Doe"
            )
        }
    }
    
    // MARK: - Place Order
    func placeOrder() async -> Order? {
        guard let address = selectedAddress,
              let paymentMethod = selectedPaymentMethod else {
            showError(message: "Please select delivery address and payment method")
            return nil
        }
        
        isPlacingOrder = true
        
        do {
            let cartSummary = cartService.summary
            
            let order = try await orderService.placeOrder(
                cartSummary: cartSummary,
                deliveryAddress: address,
                paymentMethod: paymentMethod,
                deliveryInstructions: nil,
                tipAmount: tipAmount
            )
            
            placedOrder = order
            isPlacingOrder = false
            return order
        } catch {
            showError(message: error.localizedDescription)
            isPlacingOrder = false
            return nil
        }
    }
    
    // MARK: - Error Handling
    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
}

// MARK: - Delivery Option
enum DeliveryOption {
    case standard
    case priority
    case scheduled
}

// MARK: - Tip Option
enum TipOption: Hashable {
    case none
    case fifteenPercent
    case twentyPercent
    case twentyFivePercent
    case custom
    
    var displayText: String {
        switch self {
        case .none: return "None"
        case .fifteenPercent: return "15%"
        case .twentyPercent: return "20%"
        case .twentyFivePercent: return "25%"
        case .custom: return "Custom"
        }
    }
    
    var percentage: Double {
        switch self {
        case .none: return 0
        case .fifteenPercent: return 0.15
        case .twentyPercent: return 0.20
        case .twentyFivePercent: return 0.25
        case .custom: return 0
        }
    }
}