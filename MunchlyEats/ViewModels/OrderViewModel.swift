import Foundation
import Combine

@MainActor
class OrderViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var activeOrders: [Order] = []
    @Published var pastOrders: [Order] = []
    @Published var currentOrder: Order?
    
    @Published var isLoading = false
    @Published var isPlacingOrder = false
    @Published var error: Error?
    @Published var showError = false
    @Published var errorMessage = ""
    
    // Rating
    @Published var ratingOrder: Order?
    @Published var ratingValue: Int = 5
    @Published var reviewText = ""
    @Published var showRatingSheet = false
    
    // MARK: - Services
    private let orderService = OrderService.shared
    private let cartService = CartService.shared
    private let locationService = LocationService.shared
    private let notificationService = NotificationService.shared
    
    // MARK: - Computed Properties
    var hasActiveOrders: Bool {
        !activeOrders.isEmpty
    }
    
    var selectedAddress: Address? {
        locationService.selectedAddress
    }
    
    // MARK: - Initialization
    init() {
        refreshOrders()
    }
    
    // MARK: - Refresh Orders
    func refreshOrders() {
        activeOrders = orderService.activeOrders
        pastOrders = orderService.pastOrders
    }
    
    // MARK: - Place Order
    func placeOrder(
        paymentMethod: PaymentMethod,
        tipAmount: Double
    ) async throws -> Order {
        guard let address = selectedAddress else {
            throw OrderError.emptyCart
        }
        
        let cartSummary = cartService.summary
        
        isPlacingOrder = true
        defer { isPlacingOrder = false }
        
        let order = try await orderService.placeOrder(
            cartSummary: cartSummary,
            deliveryAddress: address,
            paymentMethod: paymentMethod,
            deliveryInstructions: nil,
            tipAmount: tipAmount
        )
        
        // Schedule notifications
        notificationService.scheduleOrderUpdateNotifications(
            orderId: order.id,
            restaurantName: order.restaurantName
        )
        
        // Refresh local orders
        refreshOrders()
        currentOrder = order
        
        return order
    }
    
    // MARK: - Track Order
    func trackOrder(_ orderId: String) {
        orderService.trackOrder(orderId)
        currentOrder = orderService.currentTrackingOrder
    }
    
    // MARK: - Cancel Order
    func cancelOrder(_ orderId: String) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await orderService.cancelOrder(orderId)
            notificationService.cancelOrderNotifications(orderId: orderId)
            refreshOrders()
        } catch {
            showError(message: error.localizedDescription)
        }
    }
    
    // MARK: - Rate Order
    func rateOrder(_ orderId: String, rating: Int, review: String?) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await orderService.rateOrder(orderId, rating: rating, review: review)
            refreshOrders()
            showRatingSheet = false
            ratingOrder = nil
            ratingValue = 5
            reviewText = ""
        } catch {
            showError(message: error.localizedDescription)
        }
    }
    
    // MARK: - Reorder
    func reorder(_ orderId: String) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await orderService.reorder(orderId)
        } catch {
            showError(message: error.localizedDescription)
        }
    }
    
    // MARK: - Get Order
    func getOrder(_ orderId: String) -> Order? {
        orderService.getOrder(id: orderId)
    }
    
    // MARK: - Start Rating
    func startRating(order: Order) {
        ratingOrder = order
        ratingValue = order.rating ?? 5
        reviewText = order.review ?? ""
        showRatingSheet = true
    }
    
    // MARK: - Private Helpers
    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
}
