import Foundation
import Combine
import SwiftData

@Model
final class Address {
    @Attribute(.unique) var id: String
    var label: String
    var street: String
    var apartment: String?
    var city: String
    var state: String
    var zipCode: String
    var country: String
    var latitude: Double
    var longitude: Double
    var isDefault: Bool
    var instructions: String?
    var addressType: AddressType
    
    var fullAddress: String {
        var parts = [street]
        if let apt = apartment, !apt.isEmpty {
            parts.append("Apt \(apt)")
        }
        parts.append("\(city), \(state) \(zipCode)")
        return parts.joined(separator: ", ")
    }
    
    init(
        id: String = UUID().uuidString,
        label: String,
        street: String,
        apartment: String? = nil,
        city: String,
        state: String,
        zipCode: String,
        country: String = "USA",
        latitude: Double,
        longitude: Double,
        isDefault: Bool = false,
        instructions: String? = nil,
        addressType: AddressType = .home
    ) {
        self.id = id
        self.label = label
        self.street = street
        self.apartment = apartment
        self.city = city
        self.state = state
        self.zipCode = zipCode
        self.country = country
        self.latitude = latitude
        self.longitude = longitude
        self.isDefault = isDefault
        self.instructions = instructions
        self.addressType = addressType
    }
}

enum AddressType: String, Codable, CaseIterable {
    case home = "Home"
    case work = "Work"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .work: return "briefcase.fill"
        case .other: return "mappin.circle.fill"
        }
    }
}

// MARK: - Address DTO
struct AddressDTO: Codable, Identifiable {
    let id: String
    let label: String
    let street: String
    let apartment: String?
    let city: String
    let state: String
    let zipCode: String
    let country: String
    let latitude: Double
    let longitude: Double
    let isDefault: Bool
    let instructions: String?
    let addressType: String
    
    func toAddress() -> Address {
        Address(
            id: id,
            label: label,
            street: street,
            apartment: apartment,
            city: city,
            state: state,
            zipCode: zipCode,
            country: country,
            latitude: latitude,
            longitude: longitude,
            isDefault: isDefault,
            instructions: instructions,
            addressType: AddressType(rawValue: addressType) ?? .other
        )
    }
}
