import Foundation
import Combine
import SwiftData

// MARK: - Order Service
@MainActor
class OrderService: ObservableObject {
    static let shared = OrderService()
    
    @Published var activeOrders: [Order] = []
    @Published var pastOrders: [Order] = []
    @Published var currentTrackingOrder: Order?
    @Published var isLoading = false
    @Published var error: Error?
    
    private var orderUpdateTimer: Timer?
    
    private init() {
        loadOrders()
    }
    
    // MARK: - Load Orders
    func loadOrders() {
        Task {
            isLoading = true
            defer { isLoading = false }
            
            // Simulate API call
            try? await Task.sleep(nanoseconds: 500_000_000)
            
            // Load mock past orders
            pastOrders = generateMockPastOrders()
        }
    }
    
    // MARK: - Place Order
    func placeOrder(
        cartSummary: CartSummary,
        deliveryAddress: Address,
        paymentMethod: PaymentMethod,
        deliveryInstructions: String?,
        tipAmount: Double
    ) async throws -> Order {
        isLoading = true
        
        defer { isLoading = false }
        
        guard let firstItem = cartSummary.items.first else {
            throw OrderError.emptyCart
        }
        
        // Simulate API call
        try await Task.sleep(nanoseconds: 2_000_000_000)
        
        let orderItems = cartSummary.items.map { item in
            OrderItem(
                id: UUID().uuidString,
                menuItemId: item.menuItemId,
                name: item.menuItemName,
                imageURL: item.menuItemImageURL,
                quantity: item.quantity,
                basePrice: item.basePrice,
                customizations: item.selectedCustomizations,
                specialInstructions: item.specialInstructions
            )
        }
        
        let order = Order(
            userId: AuthService.shared.currentUser?.id ?? "guest",
            restaurantId: firstItem.restaurantId,
            restaurantName: firstItem.restaurantName,
            restaurantImageURL: firstItem.menuItemImageURL,
            items: orderItems,
            status: .confirmed,
            subtotal: cartSummary.subtotal,
            deliveryFee: cartSummary.deliveryFee,
            serviceFee: cartSummary.serviceFee,
            tax: cartSummary.tax,
            discount: cartSummary.discount,
            total: cartSummary.total + tipAmount,
            deliveryAddress: deliveryAddress.fullAddress,
            deliveryLatitude: deliveryAddress.latitude,
            deliveryLongitude: deliveryAddress.longitude,
            deliveryInstructions: deliveryInstructions,
            paymentMethodId: paymentMethod.id,
            paymentMethodLast4: paymentMethod.last4,
            estimatedDeliveryTime: Date().addingTimeInterval(35 * 60), // 35 minutes from now
            tipAmount: tipAmount
        )
        
        activeOrders.insert(order, at: 0)
        currentTrackingOrder = order
        
        // Start tracking updates
        startOrderTracking(orderId: order.id)
        
        // Clear cart after successful order
        CartService.shared.clearCart()
        
        return order
    }
    
    // MARK: - Get Order by ID
    func getOrder(id: String) -> Order? {
        if let activeOrder = activeOrders.first(where: { $0.id == id }) {
            return activeOrder
        }
        return pastOrders.first { $0.id == id }
    }
    
    // MARK: - Track Order
    func trackOrder(_ orderId: String) {
        if let order = getOrder(id: orderId) {
            currentTrackingOrder = order
            if order.status.isActive {
                startOrderTracking(orderId: orderId)
            }
        }
    }
    
    // MARK: - Start Order Tracking
    private func startOrderTracking(orderId: String) {
        stopOrderTracking()
        
        // Simulate real-time updates every 30 seconds
        orderUpdateTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor [weak self] in
                self?.simulateOrderUpdate(orderId: orderId)
            }
        }
    }
    
    // MARK: - Stop Order Tracking
    func stopOrderTracking() {
        orderUpdateTimer?.invalidate()
        orderUpdateTimer = nil
    }
    
    // MARK: - Simulate Order Update
    private func simulateOrderUpdate(orderId: String) {
        guard let index = activeOrders.firstIndex(where: { $0.id == orderId }) else { return }
        
        let currentStatus = activeOrders[index].status
        let nextStatus = getNextStatus(current: currentStatus)
        
        activeOrders[index].status = nextStatus
        activeOrders[index].updatedAt = Date()
        
        // Update driver location if en route
        if nextStatus == .onTheWay || nextStatus == .arriving {
            simulateDriverLocation(for: index)
        }
        
        // Assign driver when preparing
        if nextStatus == .driverAssigned && activeOrders[index].driverId == nil {
            assignDriver(to: index)
        }
        
        // Update current tracking order
        if currentTrackingOrder?.id == orderId {
            currentTrackingOrder = activeOrders[index]
        }
        
        // Move to past orders if delivered
        if nextStatus == .delivered {
            stopOrderTracking()
            let completedOrder = activeOrders.remove(at: index)
            completedOrder.actualDeliveryTime = Date()
            pastOrders.insert(completedOrder, at: 0)
            
            if currentTrackingOrder?.id == orderId {
                currentTrackingOrder = completedOrder
            }
        }
    }
    
    // MARK: - Get Next Status
    private func getNextStatus(current: OrderStatus) -> OrderStatus {
        switch current {
        case .pending: return .confirmed
        case .confirmed: return .preparing
        case .preparing: return .readyForPickup
        case .readyForPickup: return .driverAssigned
        case .driverAssigned: return .pickedUp
        case .pickedUp: return .onTheWay
        case .onTheWay: return .arriving
        case .arriving: return .delivered
        default: return current
        }
    }
    
    // MARK: - Assign Driver
    private func assignDriver(to orderIndex: Int) {
        activeOrders[orderIndex].driverId = "driver_\(UUID().uuidString)"
        activeOrders[orderIndex].driverName = "Michael S."
        activeOrders[orderIndex].driverPhone = "+1 (555) 123-4567"
        activeOrders[orderIndex].driverImageURL = "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150"
        activeOrders[orderIndex].driverVehicleInfo = "Silver Toyota Camry • ABC 1234"
    }
    
    // MARK: - Simulate Driver Location
    private func simulateDriverLocation(for orderIndex: Int) {
        // Simulate driver moving towards delivery location
        let deliveryLat = activeOrders[orderIndex].deliveryLatitude
        let deliveryLon = activeOrders[orderIndex].deliveryLongitude
        
        let offset = Double.random(in: -0.01...0.01)
        activeOrders[orderIndex].driverLatitude = deliveryLat + offset
        activeOrders[orderIndex].driverLongitude = deliveryLon + offset
    }
    
    // MARK: - Cancel Order
    func cancelOrder(_ orderId: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        guard let index = activeOrders.firstIndex(where: { $0.id == orderId }) else {
            throw OrderError.orderNotFound
        }
        
        let order = activeOrders[index]
        
        // Can only cancel if not yet picked up
        guard [.pending, .confirmed, .preparing].contains(order.status) else {
            throw OrderError.cannotCancel
        }
        
        // Simulate API call
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        activeOrders[index].status = .cancelled
        activeOrders[index].updatedAt = Date()
        
        let cancelledOrder = activeOrders.remove(at: index)
        pastOrders.insert(cancelledOrder, at: 0)
        
        stopOrderTracking()
    }
    
    // MARK: - Rate Order
    func rateOrder(_ orderId: String, rating: Int, review: String?) async throws {
        isLoading = true
        defer { isLoading = false }
        
        // Simulate API call
        try await Task.sleep(nanoseconds: 500_000_000)
        
        if let index = pastOrders.firstIndex(where: { $0.id == orderId }) {
            pastOrders[index].rating = rating
            pastOrders[index].review = review
        }
    }
    
    // MARK: - Reorder
    func reorder(_ orderId: String) async throws {
        guard let order = getOrder(id: orderId) else {
            throw OrderError.orderNotFound
        }
        
        // Get restaurant
        guard let restaurant = RestaurantService.shared.getRestaurant(id: order.restaurantId) else {
            throw OrderError.restaurantNotAvailable
        }
        
        // Clear current cart
        CartService.shared.clearCart()
        
        // Add items to cart
        for item in order.items {
            let menuItem = MenuItemDTO(
                id: item.menuItemId,
                restaurantId: order.restaurantId,
                name: item.name,
                description: "",
                price: item.basePrice,
                imageURL: item.imageURL,
                category: "",
                isPopular: false,
                isAvailable: true,
                calories: nil,
                preparationTime: "",
                ingredients: [],
                allergens: [],
                customizationOptions: []
            )
            
            try CartService.shared.addItem(
                menuItem: menuItem,
                restaurant: restaurant,
                quantity: item.quantity,
                specialInstructions: item.specialInstructions,
                selectedCustomizations: item.customizations
            )
        }
    }
    
    // MARK: - Generate Mock Past Orders
    private func generateMockPastOrders() -> [Order] {
        let now = Date()
        
        return [
            Order(
                id: "past_order_1",
                orderNumber: "XY789012",
                userId: "user_1",
                restaurantId: "rest_2",
                restaurantName: "Burger Joint",
                restaurantImageURL: "https://images.unsplash.com/photo-1571091718767-18b5b1457add?w=400",
                items: [
                    OrderItem(
                        id: "oi_1",
                        menuItemId: "item_2_1",
                        name: "Classic Smash Burger",
                        imageURL: "https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=400",
                        quantity: 2,
                        basePrice: 12.99,
                        customizations: [],
                        specialInstructions: nil
                    ),
                    OrderItem(
                        id: "oi_2",
                        menuItemId: "item_2_5",
                        name: "Loaded Fries",
                        imageURL: "https://images.unsplash.com/photo-1630384060421-cb20d0e0649d?w=400",
                        quantity: 1,
                        basePrice: 8.99,
                        customizations: [],
                        specialInstructions: nil
                    )
                ],
                status: .delivered,
                subtotal: 34.97,
                deliveryFee: 1.99,
                serviceFee: 1.75,
                tax: 3.06,
                total: 41.77,
                deliveryAddress: "123 Main St, Apt 4B, San Francisco, CA 94102",
                deliveryLatitude: 37.7749,
                deliveryLongitude: -122.4194,
                paymentMethodId: "pm_1",
                paymentMethodLast4: "4242",
                actualDeliveryTime: now.addingTimeInterval(-86400 * 3),
                createdAt: now.addingTimeInterval(-86400 * 3 - 2400),
                rating: 5,
                review: "Great burgers! Fast delivery.",
                tipAmount: 4.00
            ),
            Order(
                id: "past_order_2",
                orderNumber: "AB345678",
                userId: "user_1",
                restaurantId: "rest_3",
                restaurantName: "Sakura Sushi",
                restaurantImageURL: "https://images.unsplash.com/photo-1579871494447-9811cf80d66c?w=400",
                items: [
                    OrderItem(
                        id: "oi_3",
                        menuItemId: "item_3_1",
                        name: "Dragon Roll",
                        imageURL: "https://images.unsplash.com/photo-1579871494447-9811cf80d66c?w=400",
                        quantity: 1,
                        basePrice: 16.99,
                        customizations: [],
                        specialInstructions: nil
                    ),
                    OrderItem(
                        id: "oi_4",
                        menuItemId: "item_3_2",
                        name: "Rainbow Roll",
                        imageURL: "https://images.unsplash.com/photo-1617196034796-73dfa7b1fd56?w=400",
                        quantity: 1,
                        basePrice: 18.99,
                        customizations: [],
                        specialInstructions: nil
                    )
                ],
                status: .delivered,
                subtotal: 35.98,
                deliveryFee: 3.99,
                serviceFee: 1.80,
                tax: 3.15,
                total: 44.92,
                deliveryAddress: "456 Oak Ave, San Francisco, CA 94103",
                deliveryLatitude: 37.7849,
                deliveryLongitude: -122.4094,
                paymentMethodId: "pm_1",
                paymentMethodLast4: "4242",
                actualDeliveryTime: now.addingTimeInterval(-86400 * 7),
                createdAt: now.addingTimeInterval(-86400 * 7 - 3000),
                rating: 4,
                review: nil,
                tipAmount: 5.00
            )
        ]
    }
}

// MARK: - Order Errors
enum OrderError: Error, LocalizedError {
    case emptyCart
    case orderNotFound
    case cannotCancel
    case restaurantNotAvailable
    case paymentFailed
    
    var errorDescription: String? {
        switch self {
        case .emptyCart:
            return "Your cart is empty"
        case .orderNotFound:
            return "Order not found"
        case .cannotCancel:
            return "This order cannot be cancelled as it's already being prepared"
        case .restaurantNotAvailable:
            return "This restaurant is currently unavailable"
        case .paymentFailed:
            return "Payment failed. Please try again"
        }
    }
}
