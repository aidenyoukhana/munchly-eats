import Foundation
import Combine
import MapKit
import SwiftUI

@MainActor
class TrackingViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var order: Order?
    @Published var driverLocation: CLLocationCoordinate2D?
    @Published var restaurantLocation: CLLocationCoordinate2D?
    @Published var deliveryLocation: CLLocationCoordinate2D?
    @Published var route: MKRoute?
    @Published var driver: Driver?
    @Published var driverProgress: Double = 0.0 // 0.0 to 1.0 representing journey progress
    @Published var routeCoordinates: [CLLocationCoordinate2D] = [] // Generated route points
    
    @Published var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(
            latitude: Constants.Map.defaultLatitude,
            longitude: Constants.Map.defaultLongitude
        ),
        span: MKCoordinateSpan(
            latitudeDelta: Constants.Map.defaultSpan,
            longitudeDelta: Constants.Map.defaultSpan
        )
    )
    
    @Published var isLoading = false
    @Published var error: Error?
    
    // MARK: - Services
    private let orderService = OrderService.shared
    private let locationService = LocationService.shared
    
    private var updateTimer: Timer?
    private var simulationProgress: Double = 0.0
    
    // MARK: - Computed Properties
    var statusSteps: [OrderStatusStep] {
        let allSteps: [(OrderStatus, String)] = [
            (.confirmed, "Order Confirmed"),
            (.preparing, "Preparing"),
            (.driverAssigned, "Driver Assigned"),
            (.pickedUp, "Picked Up"),
            (.onTheWay, "On the Way"),
            (.delivered, "Delivered")
        ]
        
        guard let currentStatus = order?.status else { return [] }
        
        return allSteps.map { status, title in
            let isCompleted = orderStatusIndex(status) <= orderStatusIndex(currentStatus)
            let isCurrent = status == currentStatus
            return OrderStatusStep(
                status: status,
                title: title,
                isCompleted: isCompleted,
                isCurrent: isCurrent
            )
        }
    }
    
    var estimatedArrival: String {
        guard let eta = order?.estimatedDeliveryTime else { return "--" }
        return eta.toTimeString()
    }
    
    var timeRemaining: String {
        guard let eta = order?.estimatedDeliveryTime else { return "Calculating..." }
        let minutes = Int(eta.timeIntervalSinceNow / 60)
        if minutes <= 0 {
            return "Arriving now"
        }
        return "\(minutes) min"
    }
    
    var canContactDriver: Bool {
        guard let status = order?.status else { return false }
        return [.driverAssigned, .pickedUp, .onTheWay, .arriving].contains(status)
    }
    
    var canCancelOrder: Bool {
        guard let status = order?.status else { return false }
        return [.pending, .confirmed, .preparing].contains(status)
    }
    
    // Computed properties for view binding
    var restaurantCoordinate: CLLocationCoordinate2D? { restaurantLocation }
    var deliveryCoordinate: CLLocationCoordinate2D? { deliveryLocation }
    var driverCoordinate: CLLocationCoordinate2D? { driverLocation }
    
    var currentStatus: OrderStatus {
        order?.status ?? .pending
    }
    
    var statusTitle: String {
        switch currentStatus {
        case .pending: return "Order Pending"
        case .confirmed: return "Order Confirmed"
        case .preparing: return "Preparing Your Order"
        case .readyForPickup: return "Ready for Pickup"
        case .driverAssigned: return "Driver On the Way"
        case .pickedUp: return "Order Picked Up"
        case .onTheWay: return "On the Way"
        case .arriving: return "Almost There!"
        case .delivered: return "Order Delivered"
        case .cancelled: return "Order Cancelled"
        case .refunded: return "Order Refunded"
        }
    }
    
    var statusSubtitle: String {
        switch currentStatus {
        case .pending: return "Waiting for restaurant confirmation"
        case .confirmed: return "Restaurant is preparing your order"
        case .preparing: return "Your food is being made"
        case .readyForPickup: return "Waiting for driver"
        case .driverAssigned: return "Driver is heading to restaurant"
        case .pickedUp: return "Driver has your order"
        case .onTheWay: return "Your order is on its way"
        case .arriving: return "Driver is nearby"
        case .delivered: return "Enjoy your meal!"
        case .cancelled: return "This order was cancelled"
        case .refunded: return "Refund has been processed"
        }
    }
    
    var etaMinutes: String {
        guard let eta = order?.estimatedDeliveryTime else { return "--" }
        let minutes = Int(eta.timeIntervalSinceNow / 60)
        return minutes > 0 ? "\(minutes)" : "0"
    }
    
    // MARK: - Initializer
    init() {}
    
    convenience init(order: Order) {
        self.init()
        loadOrder(order.id)
    }
    
    // MARK: - Recenter Map
    func recenterMap() {
        updateMapRegion()
    }
    
    // MARK: - Load Order
    func loadOrder(_ orderId: String) {
        order = orderService.getOrder(id: orderId)
        
        guard let order = order else { return }
        
        // Set locations
        if let restaurant = RestaurantService.shared.getRestaurant(id: order.restaurantId) {
            restaurantLocation = CLLocationCoordinate2D(
                latitude: restaurant.latitude,
                longitude: restaurant.longitude
            )
        } else {
            // Default restaurant location if not found
            restaurantLocation = CLLocationCoordinate2D(
                latitude: order.deliveryLatitude + 0.015,
                longitude: order.deliveryLongitude + 0.01
            )
        }
        
        deliveryLocation = CLLocationCoordinate2D(
            latitude: order.deliveryLatitude,
            longitude: order.deliveryLongitude
        )
        
        // Initialize driver at restaurant for active orders
        if order.status.isActive {
            // Start driver at restaurant
            driverLocation = restaurantLocation
            simulationProgress = 0.0
            driverProgress = 0.0
            
            // Generate a realistic route
            generateRoute()
            
            // Create a simulated driver if not present
            if driver == nil {
                driver = Driver(
                    userId: UUID().uuidString,
                    fullName: order.driverName ?? "Alex Johnson",
                    email: "driver@munchlyeats.com",
                    phone: order.driverPhone ?? "+1 (555) 123-4567",
                    profileImageURL: order.driverImageURL ?? "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150",
                    vehicleType: "Car",
                    vehicleMake: "Toyota",
                    vehicleModel: "Camry",
                    vehicleColor: "White",
                    vehiclePlate: "ABC 1234"
                )
            }
        }
        
        updateMapRegion()
        
        if order.status.isActive {
            startTracking()
        }
    }
    
    // MARK: - Generate Realistic Route
    private func generateRoute() {
        guard let start = restaurantLocation, let end = deliveryLocation else { return }
        
        // Generate a curved route with multiple waypoints to simulate real roads
        var points: [CLLocationCoordinate2D] = []
        let numPoints = 30
        
        // Calculate route distance and direction
        let latDiff = end.latitude - start.latitude
        let lonDiff = end.longitude - start.longitude
        
        // Create a curved path that simulates street navigation
        for i in 0...numPoints {
            let progress = Double(i) / Double(numPoints)
            
            // Add some curve to the path (simulating turns on roads)
            let curveIntensity = sin(progress * .pi) * 0.003
            
            // Alternate curve direction based on distance
            let curveDirection = (i / 5) % 2 == 0 ? 1.0 : -1.0
            
            // Calculate base position with linear interpolation
            var lat = start.latitude + (latDiff * progress)
            var lon = start.longitude + (lonDiff * progress)
            
            // Add perpendicular offset for curve effect (perpendicular to the main direction)
            let perpLat = -lonDiff  // Perpendicular direction
            let perpLon = latDiff
            let perpLength = sqrt(perpLat * perpLat + perpLon * perpLon)
            
            if perpLength > 0 {
                lat += (perpLat / perpLength) * curveIntensity * curveDirection
                lon += (perpLon / perpLength) * curveIntensity * curveDirection
            }
            
            // Add small random jitter to simulate real GPS data (except start/end)
            if i > 0 && i < numPoints {
                lat += Double.random(in: -0.0001...0.0001)
                lon += Double.random(in: -0.0001...0.0001)
            }
            
            points.append(CLLocationCoordinate2D(latitude: lat, longitude: lon))
        }
        
        routeCoordinates = points
    }
    
    // MARK: - Start Tracking
    func startTracking() {
        stopTracking()
        
        // Update more frequently for smoother animation (every 2 seconds)
        updateTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateTracking()
            }
        }
    }
    
    // MARK: - Stop Tracking
    func stopTracking() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    // MARK: - Update Tracking
    private func updateTracking() {
        guard let orderId = order?.id else { return }
        
        // Refresh order from service
        order = orderService.currentTrackingOrder ?? orderService.getOrder(id: orderId)
        
        guard let order = order else { return }
        
        // Simulate driver movement from restaurant to delivery
        simulateDriverMovement()
        
        // Calculate route if driver is en route
        if order.status == .onTheWay || order.status == .arriving,
           let driverLoc = driverLocation,
           let deliveryLoc = deliveryLocation {
            calculateRoute(from: driverLoc, to: deliveryLoc)
        }
        
        updateMapRegion()
        
        // Stop tracking if delivered or cancelled
        if !order.status.isActive {
            stopTracking()
        }
    }
    
    // MARK: - Simulate Driver Movement
    private func simulateDriverMovement() {
        guard !routeCoordinates.isEmpty,
              let status = order?.status,
              status.isActive else { return }
        
        // Determine target progress based on order status
        let targetProgress: Double
        switch status {
        case .confirmed, .preparing:
            targetProgress = 0.0 // Driver at restaurant
        case .readyForPickup, .driverAssigned:
            targetProgress = 0.05 // Driver arriving at restaurant
        case .pickedUp:
            targetProgress = 0.15 // Just left restaurant
        case .onTheWay:
            // Gradually increase progress (increment by 3% each update)
            targetProgress = min(simulationProgress + 0.03, 0.85)
        case .arriving:
            targetProgress = min(simulationProgress + 0.02, 0.98)
        case .delivered:
            targetProgress = 1.0
        default:
            targetProgress = simulationProgress
        }
        
        // Smoothly animate to target progress
        withAnimation(.easeInOut(duration: 1.8)) {
            simulationProgress = targetProgress
            driverProgress = simulationProgress
            
            // Get the driver position along the route
            let routeIndex = min(Int(Double(routeCoordinates.count - 1) * simulationProgress), routeCoordinates.count - 1)
            driverLocation = routeCoordinates[routeIndex]
        }
    }
    
    // MARK: - Calculate Route
    private func calculateRoute(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) {
        Task {
            route = await locationService.calculateRoute(from: source, to: destination)
        }
    }
    
    // MARK: - Update Map Region
    private func updateMapRegion() {
        var coordinates: [CLLocationCoordinate2D] = []
        
        if let restaurant = restaurantLocation {
            coordinates.append(restaurant)
        }
        if let delivery = deliveryLocation {
            coordinates.append(delivery)
        }
        if let driver = driverLocation {
            coordinates.append(driver)
        }
        
        guard !coordinates.isEmpty else { return }
        
        let latitudes = coordinates.map { $0.latitude }
        let longitudes = coordinates.map { $0.longitude }
        
        let centerLat = (latitudes.min()! + latitudes.max()!) / 2
        let centerLon = (longitudes.min()! + longitudes.max()!) / 2
        
        let latDelta = (latitudes.max()! - latitudes.min()!) * 1.5
        let lonDelta = (longitudes.max()! - longitudes.min()!) * 1.5
        
        mapRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
            span: MKCoordinateSpan(
                latitudeDelta: max(latDelta, 0.01),
                longitudeDelta: max(lonDelta, 0.01)
            )
        )
    }
    
    // MARK: - Call Driver
    func callDriver() {
        guard let phone = order?.driverPhone else { return }
        let phoneURL = URL(string: "tel://\(phone.replacingOccurrences(of: " ", with: ""))")!
        if UIApplication.shared.canOpenURL(phoneURL) {
            UIApplication.shared.open(phoneURL)
        }
    }
    
    // MARK: - Message Driver
    func messageDriver() {
        guard let phone = order?.driverPhone else { return }
        let smsURL = URL(string: "sms://\(phone.replacingOccurrences(of: " ", with: ""))")!
        if UIApplication.shared.canOpenURL(smsURL) {
            UIApplication.shared.open(smsURL)
        }
    }
    
    // MARK: - Helper
    private func orderStatusIndex(_ status: OrderStatus) -> Int {
        let order: [OrderStatus] = [.pending, .confirmed, .preparing, .readyForPickup, .driverAssigned, .pickedUp, .onTheWay, .arriving, .delivered]
        return order.firstIndex(of: status) ?? 0
    }
    
    deinit {
        updateTimer?.invalidate()
    }
}

// MARK: - Order Status Step
struct OrderStatusStep: Identifiable {
    let id = UUID()
    let status: OrderStatus
    let title: String
    let isCompleted: Bool
    let isCurrent: Bool
}
