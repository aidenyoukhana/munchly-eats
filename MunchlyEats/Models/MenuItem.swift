import Foundation
import Combine
import SwiftData

@Model
final class MenuItem {
    @Attribute(.unique) var id: String
    var restaurantId: String
    var name: String
    var menuItemDescription: String
    var price: Double
    var imageURL: String
    var category: String
    var isPopular: Bool
    var isAvailable: Bool
    var calories: Int?
    var preparationTime: String
    var ingredients: [String]
    var allergens: [String]
    var customizationOptions: [CustomizationGroup]
    
    init(
        id: String = UUID().uuidString,
        restaurantId: String,
        name: String,
        menuItemDescription: String,
        price: Double,
        imageURL: String,
        category: String,
        isPopular: Bool = false,
        isAvailable: Bool = true,
        calories: Int? = nil,
        preparationTime: String = "10-15 min",
        ingredients: [String] = [],
        allergens: [String] = [],
        customizationOptions: [CustomizationGroup] = []
    ) {
        self.id = id
        self.restaurantId = restaurantId
        self.name = name
        self.menuItemDescription = menuItemDescription
        self.price = price
        self.imageURL = imageURL
        self.category = category
        self.isPopular = isPopular
        self.isAvailable = isAvailable
        self.calories = calories
        self.preparationTime = preparationTime
        self.ingredients = ingredients
        self.allergens = allergens
        self.customizationOptions = customizationOptions
    }
    
    func toDTO() -> MenuItemDTO {
        MenuItemDTO(
            id: id,
            restaurantId: restaurantId,
            name: name,
            description: menuItemDescription,
            price: price,
            imageURL: imageURL,
            category: category,
            isPopular: isPopular,
            isAvailable: isAvailable,
            calories: calories,
            preparationTime: preparationTime,
            ingredients: ingredients,
            allergens: allergens,
            customizationOptions: customizationOptions
        )
    }
}

// MARK: - Customization
struct CustomizationGroup: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let isRequired: Bool
    let maxSelections: Int
    let options: [CustomizationOption]
}

struct CustomizationOption: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let price: Double
    var isSelected: Bool = false
}

// MARK: - MenuItem DTO for JSON Decoding
struct MenuItemDTO: Codable, Identifiable {
    let id: String
    let restaurantId: String
    let name: String
    let description: String
    let price: Double
    let imageURL: String
    let category: String
    let isPopular: Bool
    let isAvailable: Bool
    let calories: Int?
    let preparationTime: String
    let ingredients: [String]
    let allergens: [String]
    let customizationOptions: [CustomizationGroup]
    
    func toMenuItem() -> MenuItem {
        MenuItem(
            id: id,
            restaurantId: restaurantId,
            name: name,
            menuItemDescription: description,
            price: price,
            imageURL: imageURL,
            category: category,
            isPopular: isPopular,
            isAvailable: isAvailable,
            calories: calories,
            preparationTime: preparationTime,
            ingredients: ingredients,
            allergens: allergens,
            customizationOptions: customizationOptions
        )
    }
}
