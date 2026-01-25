import Foundation
import SwiftData

@Model
final class Restaurant {
    @Attribute(.unique) var id: String
    var name: String
    var restaurantDescription: String
    var imageURL: String
    var coverImageURL: String
    var rating: Double
    var reviewCount: Int
    var deliveryTime: String
    var deliveryFee: Double
    var minimumOrder: Double
    var distance: Double
    var cuisineTypes: [String]
    var address: String
    var latitude: Double
    var longitude: Double
    var isOpen: Bool
    var openingTime: String
    var closingTime: String
    var isFeatured: Bool
    var isPromoted: Bool
    
    init(
        id: String = UUID().uuidString,
        name: String,
        restaurantDescription: String,
        imageURL: String,
        coverImageURL: String,
        rating: Double,
        reviewCount: Int,
        deliveryTime: String,
        deliveryFee: Double,
        minimumOrder: Double,
        distance: Double,
        cuisineTypes: [String],
        address: String,
        latitude: Double,
        longitude: Double,
        isOpen: Bool = true,
        openingTime: String = "09:00",
        closingTime: String = "22:00",
        isFeatured: Bool = false,
        isPromoted: Bool = false
    ) {
        self.id = id
        self.name = name
        self.restaurantDescription = restaurantDescription
        self.imageURL = imageURL
        self.coverImageURL = coverImageURL
        self.rating = rating
        self.reviewCount = reviewCount
        self.deliveryTime = deliveryTime
        self.deliveryFee = deliveryFee
        self.minimumOrder = minimumOrder
        self.distance = distance
        self.cuisineTypes = cuisineTypes
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.isOpen = isOpen
        self.openingTime = openingTime
        self.closingTime = closingTime
        self.isFeatured = isFeatured
        self.isPromoted = isPromoted
    }
    
    func toDTO() -> RestaurantDTO {
        RestaurantDTO(
            id: id,
            name: name,
            description: restaurantDescription,
            imageURL: imageURL,
            coverImageURL: coverImageURL,
            rating: rating,
            reviewCount: reviewCount,
            deliveryTime: deliveryTime,
            deliveryFee: deliveryFee,
            minimumOrder: minimumOrder,
            distance: distance,
            cuisineTypes: cuisineTypes,
            address: address,
            latitude: latitude,
            longitude: longitude,
            isOpen: isOpen,
            openingTime: openingTime,
            closingTime: closingTime,
            isFeatured: isFeatured,
            isPromoted: isPromoted
        )
    }
}

// MARK: - Restaurant DTO for JSON Decoding
struct RestaurantDTO: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let description: String
    let imageURL: String
    let coverImageURL: String
    let rating: Double
    let reviewCount: Int
    let deliveryTime: String
    let deliveryFee: Double
    let minimumOrder: Double
    let distance: Double
    let cuisineTypes: [String]
    let address: String
    let latitude: Double
    let longitude: Double
    let isOpen: Bool
    let openingTime: String
    let closingTime: String
    let isFeatured: Bool
    let isPromoted: Bool
    
    func toRestaurant() -> Restaurant {
        Restaurant(
            id: id,
            name: name,
            restaurantDescription: description,
            imageURL: imageURL,
            coverImageURL: coverImageURL,
            rating: rating,
            reviewCount: reviewCount,
            deliveryTime: deliveryTime,
            deliveryFee: deliveryFee,
            minimumOrder: minimumOrder,
            distance: distance,
            cuisineTypes: cuisineTypes,
            address: address,
            latitude: latitude,
            longitude: longitude,
            isOpen: isOpen,
            openingTime: openingTime,
            closingTime: closingTime,
            isFeatured: isFeatured,
            isPromoted: isPromoted
        )
    }
}

// MARK: - Category
struct Category: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let imageURL: String
    let iconName: String
}
