import Foundation
import SwiftData

@Model
final class User {
    @Attribute(.unique) var id: String
    var email: String
    var fullName: String
    var phoneNumber: String?
    var profileImageURL: String?
    var createdAt: Date
    var isDriver: Bool
    var driverInfo: DriverInfo?
    
    @Relationship(deleteRule: .cascade)
    var addresses: [Address]
    
    @Relationship(deleteRule: .cascade)
    var paymentMethods: [PaymentMethod]
    
    init(
        id: String = UUID().uuidString,
        email: String,
        fullName: String,
        phoneNumber: String? = nil,
        profileImageURL: String? = nil,
        createdAt: Date = Date(),
        isDriver: Bool = false,
        driverInfo: DriverInfo? = nil,
        addresses: [Address] = [],
        paymentMethods: [PaymentMethod] = []
    ) {
        self.id = id
        self.email = email
        self.fullName = fullName
        self.phoneNumber = phoneNumber
        self.profileImageURL = profileImageURL
        self.createdAt = createdAt
        self.isDriver = isDriver
        self.driverInfo = driverInfo
        self.addresses = addresses
        self.paymentMethods = paymentMethods
    }
}

// MARK: - User DTO for JSON Decoding
struct UserDTO: Codable, Identifiable {
    let id: String
    let email: String
    let fullName: String
    let phoneNumber: String?
    let profileImageURL: String?
    let isDriver: Bool
    
    func toUser() -> User {
        User(
            id: id,
            email: email,
            fullName: fullName,
            phoneNumber: phoneNumber,
            profileImageURL: profileImageURL,
            isDriver: isDriver
        )
    }
}

// MARK: - Driver Info
@Model
final class DriverInfo {
    var vehicleType: String
    var vehiclePlate: String
    var vehicleColor: String
    var rating: Double
    var totalDeliveries: Int
    var isAvailable: Bool
    var currentLatitude: Double?
    var currentLongitude: Double?
    
    init(
        vehicleType: String,
        vehiclePlate: String,
        vehicleColor: String,
        rating: Double = 5.0,
        totalDeliveries: Int = 0,
        isAvailable: Bool = true,
        currentLatitude: Double? = nil,
        currentLongitude: Double? = nil
    ) {
        self.vehicleType = vehicleType
        self.vehiclePlate = vehiclePlate
        self.vehicleColor = vehicleColor
        self.rating = rating
        self.totalDeliveries = totalDeliveries
        self.isAvailable = isAvailable
        self.currentLatitude = currentLatitude
        self.currentLongitude = currentLongitude
    }
}

struct DriverInfoDTO: Codable {
    let vehicleType: String
    let vehiclePlate: String
    let vehicleColor: String
    let rating: Double
    let totalDeliveries: Int
    let isAvailable: Bool
    
    func toDriverInfo() -> DriverInfo {
        DriverInfo(
            vehicleType: vehicleType,
            vehiclePlate: vehiclePlate,
            vehicleColor: vehicleColor,
            rating: rating,
            totalDeliveries: totalDeliveries,
            isAvailable: isAvailable
        )
    }
}
