import Foundation
import Combine

// MARK: - Driver Service (For Driver Companion App)
@MainActor
class DriverService: ObservableObject {
    static let shared = DriverService()
    
    @Published var currentDriver: Driver?
    @Published var isOnline = false
    @Published var pendingRequests: [DeliveryRequest] = []
    @Published var currentDelivery: Order?
    @Published var todayEarnings: Double = 0
    @Published var todayDeliveries: Int = 0
    @Published var isLoading = false
    
    private var requestTimer: Timer?
    
    private init() {}
    
    // MARK: - Register as Driver
    func registerAsDriver(
        vehicleType: String,
        vehicleMake: String,
        vehicleModel: String,
        vehicleColor: String,
        vehiclePlate: String
    ) async throws {
        isLoading = true
        defer { isLoading = false }
        
        guard let user = AuthService.shared.currentUser else {
            throw DriverError.notAuthenticated
        }
        
        // Simulate API call
        try await Task.sleep(nanoseconds: 1_500_000_000)
        
        let driver = Driver(
            userId: user.id,
            fullName: user.fullName,
            email: user.email,
            phone: user.phoneNumber ?? "",
            profileImageURL: user.profileImageURL,
            vehicleType: vehicleType,
            vehicleMake: vehicleMake,
            vehicleModel: vehicleModel,
            vehicleColor: vehicleColor,
            vehiclePlate: vehiclePlate
        )
        
        currentDriver = driver
    }
    
    // MARK: - Go Online
    func goOnline() async throws {
        isLoading = true
        defer { isLoading = false }
        
        guard let driver = currentDriver else {
            throw DriverError.notRegistered
        }
        
        // Simulate API call
        try await Task.sleep(nanoseconds: 500_000_000)
        
        driver.isOnline = true
        currentDriver = driver
        isOnline = true
        
        // Start listening for delivery requests
        startListeningForRequests()
    }
    
    // MARK: - Go Offline
    func goOffline() async throws {
        isLoading = true
        defer { isLoading = false }
        
        guard currentDelivery == nil else {
            throw DriverError.activeDelivery
        }
        
        // Simulate API call
        try await Task.sleep(nanoseconds: 500_000_000)
        
        currentDriver?.isOnline = false
        isOnline = false
        
        stopListeningForRequests()
        pendingRequests.removeAll()
    }
    
    // MARK: - Accept Delivery
    func acceptDelivery(_ request: DeliveryRequest) async throws {
        isLoading = true
        defer { isLoading = false }
        
        // Simulate API call
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // Remove from pending requests
        pendingRequests.removeAll { $0.id == request.id }
        
        // Create order for tracking
        let order = Order(
            id: request.orderId,
            orderNumber: request.orderNumber,
            userId: "customer_id",
            restaurantId: "rest_id",
            restaurantName: request.restaurantName,
            restaurantImageURL: "",
            items: [],
            status: .driverAssigned,
            subtotal: 0,
            deliveryFee: 0,
            serviceFee: 0,
            tax: 0,
            total: 0,
            deliveryAddress: request.deliveryAddress,
            deliveryLatitude: request.deliveryLatitude,
            deliveryLongitude: request.deliveryLongitude,
            paymentMethodId: "",
            paymentMethodLast4: ""
        )
        
        currentDelivery = order
        currentDriver?.currentOrderId = order.id
        currentDriver?.isAvailable = false
    }
    
    // MARK: - Decline Delivery
    func declineDelivery(_ requestId: String) {
        pendingRequests.removeAll { $0.id == requestId }
    }
    
    // MARK: - Update Order Status
    func updateOrderStatus(_ status: OrderStatus) async throws {
        isLoading = true
        defer { isLoading = false }
        
        guard let delivery = currentDelivery else {
            throw DriverError.noActiveDelivery
        }
        
        // Simulate API call
        try await Task.sleep(nanoseconds: 500_000_000)
        
        delivery.status = status
        currentDelivery = delivery
        
        // If delivered, complete the delivery
        if status == .delivered {
            completeDelivery()
        }
    }
    
    // MARK: - Complete Delivery
    private func completeDelivery() {
        guard let delivery = currentDelivery else { return }
        
        // Update stats
        todayDeliveries += 1
        todayEarnings += calculateEarnings(for: delivery)
        
        // Clear current delivery
        currentDelivery = nil
        currentDriver?.currentOrderId = nil
        currentDriver?.isAvailable = true
        currentDriver?.totalDeliveries += 1
    }
    
    // MARK: - Calculate Earnings
    private func calculateEarnings(for order: Order) -> Double {
        // Base pay + distance bonus + tip
        let basePay = 3.00
        let distanceBonus = 0.50 * 2.5 // ~$0.50 per mile
        let tip = order.tipAmount
        
        return basePay + distanceBonus + tip
    }
    
    // MARK: - Update Location
    func updateLocation(latitude: Double, longitude: Double) async {
        currentDriver?.currentLatitude = latitude
        currentDriver?.currentLongitude = longitude
        
        // In production, send location to server for real-time tracking
    }
    
    // MARK: - Start Listening for Requests
    private func startListeningForRequests() {
        stopListeningForRequests()
        
        // Simulate incoming requests every 30 seconds
        requestTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.simulateIncomingRequest()
            }
        }
        
        // Simulate first request
        Task {
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            simulateIncomingRequest()
        }
    }
    
    // MARK: - Stop Listening for Requests
    private func stopListeningForRequests() {
        requestTimer?.invalidate()
        requestTimer = nil
    }
    
    // MARK: - Simulate Incoming Request
    private func simulateIncomingRequest() {
        guard isOnline, currentDelivery == nil, currentDriver?.isAvailable == true else { return }
        
        let restaurants = ["Tony's Pizzeria", "Burger Joint", "Sakura Sushi", "Taco Fiesta"]
        let addresses = [
            "123 Main St, San Francisco, CA",
            "456 Oak Ave, San Francisco, CA",
            "789 Pine St, San Francisco, CA"
        ]
        
        let request = DeliveryRequest(
            id: UUID().uuidString,
            orderId: UUID().uuidString,
            orderNumber: Order.generateOrderNumber(),
            restaurantName: restaurants.randomElement()!,
            restaurantAddress: "123 Restaurant St",
            restaurantLatitude: 37.7749 + Double.random(in: -0.02...0.02),
            restaurantLongitude: -122.4194 + Double.random(in: -0.02...0.02),
            customerName: "John D.",
            deliveryAddress: addresses.randomElement()!,
            deliveryLatitude: 37.7849 + Double.random(in: -0.02...0.02),
            deliveryLongitude: -122.4094 + Double.random(in: -0.02...0.02),
            estimatedDistance: Double.random(in: 1.5...5.0),
            estimatedTime: "\(Int.random(in: 15...25)) min",
            estimatedEarnings: Double.random(in: 8.0...15.0),
            itemCount: Int.random(in: 1...5),
            createdAt: Date(),
            expiresAt: Date().addingTimeInterval(60) // 1 minute to accept
        )
        
        pendingRequests.append(request)
        
        // Auto-remove after expiration
        Task {
            try? await Task.sleep(nanoseconds: 60_000_000_000)
            await MainActor.run {
                self.pendingRequests.removeAll { $0.id == request.id }
            }
        }
    }
    
    // MARK: - Get Earnings History
    func getEarningsHistory() async -> [DailyEarnings] {
        // Simulate API call
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // Mock data
        let calendar = Calendar.current
        var history: [DailyEarnings] = []
        
        for i in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -i, to: Date())!
            let earnings = Double.random(in: 50...150)
            let deliveries = Int.random(in: 5...15)
            let tips = earnings * 0.25
            
            history.append(DailyEarnings(
                date: date,
                totalEarnings: earnings,
                deliveries: deliveries,
                tips: tips,
                basePay: earnings - tips,
                bonuses: 0
            ))
        }
        
        return history
    }
}

// MARK: - Daily Earnings
struct DailyEarnings: Identifiable {
    let id = UUID()
    let date: Date
    let totalEarnings: Double
    let deliveries: Int
    let tips: Double
    let basePay: Double
    let bonuses: Double
}

// MARK: - Driver Errors
enum DriverError: Error, LocalizedError {
    case notAuthenticated
    case notRegistered
    case activeDelivery
    case noActiveDelivery
    case requestExpired
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Please sign in to continue"
        case .notRegistered:
            return "Please complete driver registration"
        case .activeDelivery:
            return "Please complete your current delivery first"
        case .noActiveDelivery:
            return "No active delivery"
        case .requestExpired:
            return "This delivery request has expired"
        }
    }
}
