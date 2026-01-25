import Foundation
import SwiftData

@Model
final class Driver {
    @Attribute(.unique) var id: String
    var userId: String
    var fullName: String
    var email: String
    var phone: String
    var profileImageURL: String?
    var vehicleType: String
    var vehicleMake: String
    var vehicleModel: String
    var vehicleColor: String
    var vehiclePlate: String
    var rating: Double
    var totalDeliveries: Int
    var totalEarnings: Double
    var isOnline: Bool
    var isAvailable: Bool
    var currentLatitude: Double?
    var currentLongitude: Double?
    var currentOrderId: String?
    var acceptanceRate: Double
    var completionRate: Double
    var joinedDate: Date
    
    init(
        id: String = UUID().uuidString,
        userId: String,
        fullName: String,
        email: String,
        phone: String,
        profileImageURL: String? = nil,
        vehicleType: String,
        vehicleMake: String,
        vehicleModel: String,
        vehicleColor: String,
        vehiclePlate: String,
        rating: Double = 5.0,
        totalDeliveries: Int = 0,
        totalEarnings: Double = 0,
        isOnline: Bool = false,
        isAvailable: Bool = true,
        currentLatitude: Double? = nil,
        currentLongitude: Double? = nil,
        currentOrderId: String? = nil,
        acceptanceRate: Double = 100,
        completionRate: Double = 100,
        joinedDate: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.fullName = fullName
        self.email = email
        self.phone = phone
        self.profileImageURL = profileImageURL
        self.vehicleType = vehicleType
        self.vehicleMake = vehicleMake
        self.vehicleModel = vehicleModel
        self.vehicleColor = vehicleColor
        self.vehiclePlate = vehiclePlate
        self.rating = rating
        self.totalDeliveries = totalDeliveries
        self.totalEarnings = totalEarnings
        self.isOnline = isOnline
        self.isAvailable = isAvailable
        self.currentLatitude = currentLatitude
        self.currentLongitude = currentLongitude
        self.currentOrderId = currentOrderId
        self.acceptanceRate = acceptanceRate
        self.completionRate = completionRate
        self.joinedDate = joinedDate
    }
    
    var vehicleInfo: String {
        "\(vehicleColor) \(vehicleMake) \(vehicleModel)"
    }
}

// MARK: - Driver DTO
struct DriverDTO: Codable, Identifiable {
    let id: String
    let userId: String
    let fullName: String
    let email: String
    let phone: String
    let profileImageURL: String?
    let vehicleType: String
    let vehicleMake: String
    let vehicleModel: String
    let vehicleColor: String
    let vehiclePlate: String
    let rating: Double
    let totalDeliveries: Int
    let isOnline: Bool
    let isAvailable: Bool
    
    func toDriver() -> Driver {
        Driver(
            id: id,
            userId: userId,
            fullName: fullName,
            email: email,
            phone: phone,
            profileImageURL: profileImageURL,
            vehicleType: vehicleType,
            vehicleMake: vehicleMake,
            vehicleModel: vehicleModel,
            vehicleColor: vehicleColor,
            vehiclePlate: vehiclePlate,
            rating: rating,
            totalDeliveries: totalDeliveries,
            isOnline: isOnline,
            isAvailable: isAvailable
        )
    }
}

// MARK: - Delivery Request (for driver app)
struct DeliveryRequest: Codable, Identifiable {
    let id: String
    let orderId: String
    let orderNumber: String
    let restaurantName: String
    let restaurantAddress: String
    let restaurantLatitude: Double
    let restaurantLongitude: Double
    let customerName: String
    let deliveryAddress: String
    let deliveryLatitude: Double
    let deliveryLongitude: Double
    let estimatedDistance: Double
    let estimatedTime: String
    let estimatedEarnings: Double
    let itemCount: Int
    let createdAt: Date
    let expiresAt: Date
}
