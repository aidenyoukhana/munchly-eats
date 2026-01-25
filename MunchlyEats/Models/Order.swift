import Foundation
import Combine
import SwiftData

@Model
final class Order {
    @Attribute(.unique) var id: String
    var orderNumber: String
    var userId: String
    var restaurantId: String
    var restaurantName: String
    var restaurantImageURL: String
    var items: [OrderItem]
    var status: OrderStatus
    var subtotal: Double
    var deliveryFee: Double
    var serviceFee: Double
    var tax: Double
    var discount: Double
    var total: Double
    var deliveryAddress: String
    var deliveryLatitude: Double
    var deliveryLongitude: Double
    var deliveryInstructions: String?
    var paymentMethodId: String
    var paymentMethodLast4: String
    var driverId: String?
    var driverName: String?
    var driverPhone: String?
    var driverImageURL: String?
    var driverLatitude: Double?
    var driverLongitude: Double?
    var driverVehicleInfo: String?
    var estimatedDeliveryTime: Date?
    var actualDeliveryTime: Date?
    var createdAt: Date
    var updatedAt: Date
    var rating: Int?
    var review: String?
    var tipAmount: Double
    
    init(
        id: String = UUID().uuidString,
        orderNumber: String = "",
        userId: String,
        restaurantId: String,
        restaurantName: String,
        restaurantImageURL: String,
        items: [OrderItem],
        status: OrderStatus = .pending,
        subtotal: Double,
        deliveryFee: Double,
        serviceFee: Double,
        tax: Double,
        discount: Double = 0,
        total: Double,
        deliveryAddress: String,
        deliveryLatitude: Double,
        deliveryLongitude: Double,
        deliveryInstructions: String? = nil,
        paymentMethodId: String,
        paymentMethodLast4: String,
        driverId: String? = nil,
        driverName: String? = nil,
        driverPhone: String? = nil,
        driverImageURL: String? = nil,
        driverLatitude: Double? = nil,
        driverLongitude: Double? = nil,
        driverVehicleInfo: String? = nil,
        estimatedDeliveryTime: Date? = nil,
        actualDeliveryTime: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        rating: Int? = nil,
        review: String? = nil,
        tipAmount: Double = 0
    ) {
        self.id = id
        self.orderNumber = orderNumber.isEmpty ? Order.generateOrderNumber() : orderNumber
        self.userId = userId
        self.restaurantId = restaurantId
        self.restaurantName = restaurantName
        self.restaurantImageURL = restaurantImageURL
        self.items = items
        self.status = status
        self.subtotal = subtotal
        self.deliveryFee = deliveryFee
        self.serviceFee = serviceFee
        self.tax = tax
        self.discount = discount
        self.total = total
        self.deliveryAddress = deliveryAddress
        self.deliveryLatitude = deliveryLatitude
        self.deliveryLongitude = deliveryLongitude
        self.deliveryInstructions = deliveryInstructions
        self.paymentMethodId = paymentMethodId
        self.paymentMethodLast4 = paymentMethodLast4
        self.driverId = driverId
        self.driverName = driverName
        self.driverPhone = driverPhone
        self.driverImageURL = driverImageURL
        self.driverLatitude = driverLatitude
        self.driverLongitude = driverLongitude
        self.driverVehicleInfo = driverVehicleInfo
        self.estimatedDeliveryTime = estimatedDeliveryTime
        self.actualDeliveryTime = actualDeliveryTime
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.rating = rating
        self.review = review
        self.tipAmount = tipAmount
    }
    
    static func generateOrderNumber() -> String {
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        let randomLetters = String((0..<2).map { _ in letters.randomElement()! })
        let randomNumbers = String(format: "%06d", Int.random(in: 100000...999999))
        return "\(randomLetters)\(randomNumbers)"
    }
}

// MARK: - Order Status
enum OrderStatus: String, Codable, CaseIterable {
    case pending = "Pending"
    case confirmed = "Confirmed"
    case preparing = "Preparing"
    case readyForPickup = "Ready for Pickup"
    case driverAssigned = "Driver Assigned"
    case pickedUp = "Picked Up"
    case onTheWay = "On the Way"
    case arriving = "Arriving"
    case delivered = "Delivered"
    case cancelled = "Cancelled"
    case refunded = "Refunded"
    
    var icon: String {
        switch self {
        case .pending: return "clock"
        case .confirmed: return "checkmark.circle"
        case .preparing: return "flame"
        case .readyForPickup: return "bag"
        case .driverAssigned: return "person.circle"
        case .pickedUp: return "car"
        case .onTheWay: return "car.fill"
        case .arriving: return "location"
        case .delivered: return "checkmark.seal.fill"
        case .cancelled: return "xmark.circle"
        case .refunded: return "arrow.uturn.backward.circle"
        }
    }
    
    var color: String {
        switch self {
        case .pending: return "gray"
        case .confirmed, .preparing, .readyForPickup: return "orange"
        case .driverAssigned, .pickedUp, .onTheWay, .arriving: return "blue"
        case .delivered: return "green"
        case .cancelled, .refunded: return "red"
        }
    }
    
    var isActive: Bool {
        switch self {
        case .pending, .confirmed, .preparing, .readyForPickup, .driverAssigned, .pickedUp, .onTheWay, .arriving:
            return true
        case .delivered, .cancelled, .refunded:
            return false
        }
    }
}

// MARK: - Order Item
struct OrderItem: Codable, Identifiable, Hashable {
    let id: String
    let menuItemId: String
    let name: String
    let imageURL: String
    let quantity: Int
    let basePrice: Double
    let customizations: [SelectedCustomization]
    let specialInstructions: String?
    
    var totalPrice: Double {
        let customizationPrice = customizations.reduce(0) { $0 + $1.price }
        return (basePrice + customizationPrice) * Double(quantity)
    }
}

// MARK: - Order DTO for JSON Decoding
struct OrderDTO: Codable, Identifiable {
    let id: String
    let orderNumber: String
    let userId: String
    let restaurantId: String
    let restaurantName: String
    let restaurantImageURL: String
    let items: [OrderItem]
    let status: String
    let subtotal: Double
    let deliveryFee: Double
    let serviceFee: Double
    let tax: Double
    let discount: Double
    let total: Double
    let deliveryAddress: String
    let deliveryLatitude: Double
    let deliveryLongitude: Double
    let deliveryInstructions: String?
    let paymentMethodId: String
    let paymentMethodLast4: String
    let driverId: String?
    let driverName: String?
    let driverPhone: String?
    let driverImageURL: String?
    let estimatedDeliveryTime: String?
    let createdAt: String
    let tipAmount: Double
    
    func toOrder() -> Order {
        let dateFormatter = ISO8601DateFormatter()
        
        return Order(
            id: id,
            orderNumber: orderNumber,
            userId: userId,
            restaurantId: restaurantId,
            restaurantName: restaurantName,
            restaurantImageURL: restaurantImageURL,
            items: items,
            status: OrderStatus(rawValue: status) ?? .pending,
            subtotal: subtotal,
            deliveryFee: deliveryFee,
            serviceFee: serviceFee,
            tax: tax,
            discount: discount,
            total: total,
            deliveryAddress: deliveryAddress,
            deliveryLatitude: deliveryLatitude,
            deliveryLongitude: deliveryLongitude,
            deliveryInstructions: deliveryInstructions,
            paymentMethodId: paymentMethodId,
            paymentMethodLast4: paymentMethodLast4,
            driverId: driverId,
            driverName: driverName,
            driverPhone: driverPhone,
            driverImageURL: driverImageURL,
            estimatedDeliveryTime: estimatedDeliveryTime.flatMap { dateFormatter.date(from: $0) },
            createdAt: dateFormatter.date(from: createdAt) ?? Date(),
            tipAmount: tipAmount
        )
    }
}
