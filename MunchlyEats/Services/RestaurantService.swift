import Foundation
import Combine

// MARK: - Restaurant Service
@MainActor
class RestaurantService: ObservableObject {
    static let shared = RestaurantService()
    
    @Published var restaurants: [RestaurantDTO] = []
    @Published var featuredRestaurants: [RestaurantDTO] = []
    @Published var nearbyRestaurants: [RestaurantDTO] = []
    @Published var categories: [Category] = []
    @Published var promotions: [PromotionDTO] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private init() {}
    
    // MARK: - Load All Data
    func loadInitialData() async {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        do {
            // Load data in parallel
            async let categoriesTask = loadCategories()
            async let restaurantsTask = loadRestaurants()
            async let promotionsTask = loadPromotions()
            
            let (loadedCategories, loadedRestaurants, loadedPromotions) = try await (
                categoriesTask,
                restaurantsTask,
                promotionsTask
            )
            
            categories = loadedCategories
            restaurants = loadedRestaurants
            promotions = loadedPromotions
            
            // Filter featured and nearby
            featuredRestaurants = restaurants.filter { $0.isFeatured }
            nearbyRestaurants = restaurants.filter { $0.distance < 3.0 }.sorted { $0.distance < $1.distance }
            
        } catch {
            self.error = error
        }
    }
    
    // MARK: - Load Categories
    private func loadCategories() async throws -> [Category] {
        try await Task.sleep(nanoseconds: 300_000_000)
        
        return [
            Category(id: "1", name: "Pizza", imageURL: "https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=200", iconName: "🍕"),
            Category(id: "2", name: "Burgers", imageURL: "https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=200", iconName: "🍔"),
            Category(id: "3", name: "Sushi", imageURL: "https://images.unsplash.com/photo-1579871494447-9811cf80d66c?w=200", iconName: "🍣"),
            Category(id: "4", name: "Chinese", imageURL: "https://images.unsplash.com/photo-1585032226651-759b368d7246?w=200", iconName: "🥡"),
            Category(id: "5", name: "Mexican", imageURL: "https://images.unsplash.com/photo-1565299585323-38d6b0865b47?w=200", iconName: "🌮"),
            Category(id: "6", name: "Indian", imageURL: "https://images.unsplash.com/photo-1585937421612-70a008356fbe?w=200", iconName: "🍛"),
            Category(id: "7", name: "Thai", imageURL: "https://images.unsplash.com/photo-1562565652-a0d8f0c59eb4?w=200", iconName: "🍜"),
            Category(id: "8", name: "Italian", imageURL: "https://images.unsplash.com/photo-1551183053-bf91a1d81141?w=200", iconName: "🍝"),
            Category(id: "9", name: "Desserts", imageURL: "https://images.unsplash.com/photo-1551024601-bec78aea704b?w=200", iconName: "🍰"),
            Category(id: "10", name: "Healthy", imageURL: "https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=200", iconName: "🥗"),
            Category(id: "11", name: "Coffee", imageURL: "https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=200", iconName: "☕"),
            Category(id: "12", name: "Fast Food", imageURL: "https://images.unsplash.com/photo-1561758033-d89a9ad46330?w=200", iconName: "🍟")
        ]
    }
    
    // MARK: - Load Restaurants
    private func loadRestaurants() async throws -> [RestaurantDTO] {
        try await Task.sleep(nanoseconds: 500_000_000)
        
        return [
            RestaurantDTO(
                id: "rest_1",
                name: "Tony's Pizzeria",
                description: "Authentic New York style pizza made with fresh ingredients and traditional recipes.",
                imageURL: "https://images.unsplash.com/photo-1513104890138-7c749659a591?w=400",
                coverImageURL: "https://images.unsplash.com/photo-1574071318508-1cdbab80d002?w=800",
                rating: 4.8,
                reviewCount: 1250,
                deliveryTime: "20-35 min",
                deliveryFee: 2.99,
                minimumOrder: 15.0,
                distance: 1.2,
                cuisineTypes: ["Pizza", "Italian"],
                address: "123 Main Street, Downtown",
                latitude: 37.7749,
                longitude: -122.4194,
                isOpen: true,
                openingTime: "10:00",
                closingTime: "23:00",
                isFeatured: true,
                isPromoted: false
            ),
            RestaurantDTO(
                id: "rest_2",
                name: "Burger Joint",
                description: "Gourmet burgers crafted with premium beef and fresh toppings. Home of the famous Double Smash.",
                imageURL: "https://images.unsplash.com/photo-1571091718767-18b5b1457add?w=400",
                coverImageURL: "https://images.unsplash.com/photo-1550547660-d9450f859349?w=800",
                rating: 4.6,
                reviewCount: 890,
                deliveryTime: "15-25 min",
                deliveryFee: 1.99,
                minimumOrder: 12.0,
                distance: 0.8,
                cuisineTypes: ["Burgers", "American", "Fast Food"],
                address: "456 Oak Avenue, Midtown",
                latitude: 37.7849,
                longitude: -122.4094,
                isOpen: true,
                openingTime: "11:00",
                closingTime: "22:00",
                isFeatured: true,
                isPromoted: true
            ),
            RestaurantDTO(
                id: "rest_3",
                name: "Sakura Sushi",
                description: "Premium Japanese cuisine featuring fresh sashimi, creative rolls, and traditional dishes.",
                imageURL: "https://images.unsplash.com/photo-1579871494447-9811cf80d66c?w=400",
                coverImageURL: "https://images.unsplash.com/photo-1617196034796-73dfa7b1fd56?w=800",
                rating: 4.9,
                reviewCount: 2100,
                deliveryTime: "25-40 min",
                deliveryFee: 3.99,
                minimumOrder: 25.0,
                distance: 2.1,
                cuisineTypes: ["Sushi", "Japanese"],
                address: "789 Cherry Blossom Lane",
                latitude: 37.7649,
                longitude: -122.4294,
                isOpen: true,
                openingTime: "11:30",
                closingTime: "21:30",
                isFeatured: true,
                isPromoted: false
            ),
            RestaurantDTO(
                id: "rest_4",
                name: "Dragon Palace",
                description: "Authentic Chinese cuisine from Sichuan to Cantonese. Famous for our dim sum and Peking duck.",
                imageURL: "https://images.unsplash.com/photo-1585032226651-759b368d7246?w=400",
                coverImageURL: "https://images.unsplash.com/photo-1526318896980-cf78c088247c?w=800",
                rating: 4.5,
                reviewCount: 756,
                deliveryTime: "30-45 min",
                deliveryFee: 2.49,
                minimumOrder: 20.0,
                distance: 1.8,
                cuisineTypes: ["Chinese", "Asian"],
                address: "321 Dragon Street",
                latitude: 37.7549,
                longitude: -122.4394,
                isOpen: true,
                openingTime: "10:30",
                closingTime: "22:30",
                isFeatured: false,
                isPromoted: true
            ),
            RestaurantDTO(
                id: "rest_5",
                name: "Taco Fiesta",
                description: "Street-style Mexican tacos, burritos, and quesadillas. Made fresh with authentic recipes.",
                imageURL: "https://images.unsplash.com/photo-1565299585323-38d6b0865b47?w=400",
                coverImageURL: "https://images.unsplash.com/photo-1599974579688-8dbdd335c77f?w=800",
                rating: 4.7,
                reviewCount: 1456,
                deliveryTime: "15-30 min",
                deliveryFee: 1.49,
                minimumOrder: 10.0,
                distance: 0.5,
                cuisineTypes: ["Mexican", "Tacos"],
                address: "567 Fiesta Road",
                latitude: 37.7949,
                longitude: -122.3994,
                isOpen: true,
                openingTime: "09:00",
                closingTime: "23:00",
                isFeatured: true,
                isPromoted: false
            ),
            RestaurantDTO(
                id: "rest_6",
                name: "Curry House",
                description: "Traditional Indian curries, biryanis, and tandoori specialties. Vegetarian options available.",
                imageURL: "https://images.unsplash.com/photo-1585937421612-70a008356fbe?w=400",
                coverImageURL: "https://images.unsplash.com/photo-1596797038530-2c107229654b?w=800",
                rating: 4.4,
                reviewCount: 623,
                deliveryTime: "25-40 min",
                deliveryFee: 2.99,
                minimumOrder: 18.0,
                distance: 2.5,
                cuisineTypes: ["Indian", "Curry"],
                address: "890 Spice Lane",
                latitude: 37.7349,
                longitude: -122.4494,
                isOpen: true,
                openingTime: "11:00",
                closingTime: "22:00",
                isFeatured: false,
                isPromoted: false
            ),
            RestaurantDTO(
                id: "rest_7",
                name: "Thai Orchid",
                description: "Authentic Thai cuisine with bold flavors. Famous for Pad Thai and Green Curry.",
                imageURL: "https://images.unsplash.com/photo-1562565652-a0d8f0c59eb4?w=400",
                coverImageURL: "https://images.unsplash.com/photo-1559314809-0d155014e29e?w=800",
                rating: 4.6,
                reviewCount: 892,
                deliveryTime: "20-35 min",
                deliveryFee: 2.49,
                minimumOrder: 15.0,
                distance: 1.4,
                cuisineTypes: ["Thai", "Asian"],
                address: "432 Orchid Way",
                latitude: 37.7849,
                longitude: -122.4094,
                isOpen: true,
                openingTime: "11:00",
                closingTime: "21:00",
                isFeatured: false,
                isPromoted: false
            ),
            RestaurantDTO(
                id: "rest_8",
                name: "Pasta La Vista",
                description: "Handmade pasta and classic Italian dishes. Our recipes come straight from Nonna's kitchen.",
                imageURL: "https://images.unsplash.com/photo-1551183053-bf91a1d81141?w=400",
                coverImageURL: "https://images.unsplash.com/photo-1556761223-4c4282c73f77?w=800",
                rating: 4.7,
                reviewCount: 1034,
                deliveryTime: "25-40 min",
                deliveryFee: 3.49,
                minimumOrder: 22.0,
                distance: 1.9,
                cuisineTypes: ["Italian", "Pasta"],
                address: "765 Roma Street",
                latitude: 37.7649,
                longitude: -122.4194,
                isOpen: true,
                openingTime: "11:30",
                closingTime: "22:30",
                isFeatured: true,
                isPromoted: false
            ),
            RestaurantDTO(
                id: "rest_9",
                name: "Sweet Treats",
                description: "Artisan desserts, cakes, and pastries. Perfect for satisfying your sweet tooth.",
                imageURL: "https://images.unsplash.com/photo-1551024601-bec78aea704b?w=400",
                coverImageURL: "https://images.unsplash.com/photo-1486427944299-d1955d23e34d?w=800",
                rating: 4.8,
                reviewCount: 567,
                deliveryTime: "20-30 min",
                deliveryFee: 2.99,
                minimumOrder: 15.0,
                distance: 1.1,
                cuisineTypes: ["Desserts", "Bakery"],
                address: "234 Sugar Lane",
                latitude: 37.7749,
                longitude: -122.4294,
                isOpen: true,
                openingTime: "08:00",
                closingTime: "20:00",
                isFeatured: false,
                isPromoted: true
            ),
            RestaurantDTO(
                id: "rest_10",
                name: "Green Bowl",
                description: "Fresh salads, grain bowls, and healthy smoothies. Nutrition-focused food that tastes great.",
                imageURL: "https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400",
                coverImageURL: "https://images.unsplash.com/photo-1540420773420-3366772f4999?w=800",
                rating: 4.5,
                reviewCount: 445,
                deliveryTime: "15-25 min",
                deliveryFee: 1.99,
                minimumOrder: 12.0,
                distance: 0.7,
                cuisineTypes: ["Healthy", "Salads", "Bowls"],
                address: "111 Wellness Avenue",
                latitude: 37.7849,
                longitude: -122.4094,
                isOpen: true,
                openingTime: "07:00",
                closingTime: "21:00",
                isFeatured: false,
                isPromoted: false
            )
        ]
    }
    
    // MARK: - Load Promotions
    private func loadPromotions() async throws -> [PromotionDTO] {
        try await Task.sleep(nanoseconds: 200_000_000)
        
        return [
            PromotionDTO(
                id: "promo_1",
                title: "50% Off First Order",
                description: "Welcome to MunchlyEats! Enjoy 50% off your first order, up to $15.",
                imageURL: "https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=600",
                promoCode: "WELCOME50",
                discountPercentage: 50,
                restaurantId: nil,
                validFrom: "2025-01-01T00:00:00Z",
                validUntil: "2026-12-31T23:59:59Z",
                termsAndConditions: "Valid for new users only. Maximum discount $15."
            ),
            PromotionDTO(
                id: "promo_2",
                title: "Free Delivery Weekend",
                description: "No delivery fees on all orders this weekend!",
                imageURL: "https://images.unsplash.com/photo-1526367790999-0150786686a2?w=600",
                promoCode: "FREEDELIVERY",
                discountPercentage: nil,
                restaurantId: nil,
                validFrom: "2026-01-17T00:00:00Z",
                validUntil: "2026-01-19T23:59:59Z",
                termsAndConditions: "Valid Friday to Sunday. Minimum order $15."
            ),
            PromotionDTO(
                id: "promo_3",
                title: "Pizza Party Deal",
                description: "Buy 2 large pizzas, get 1 free at Tony's Pizzeria!",
                imageURL: "https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=600",
                promoCode: "PIZZAPARTY",
                discountPercentage: 33,
                restaurantId: "rest_1",
                validFrom: "2026-01-01T00:00:00Z",
                validUntil: "2026-02-28T23:59:59Z",
                termsAndConditions: "Valid at Tony's Pizzeria only. Must order 3 large pizzas."
            )
        ]
    }
    
    // MARK: - Get Restaurant by ID
    func getRestaurant(id: String) -> RestaurantDTO? {
        return restaurants.first { $0.id == id }
    }
    
    // MARK: - Search Restaurants
    func searchRestaurants(query: String) -> [RestaurantDTO] {
        guard !query.isEmpty else { return restaurants }
        
        let lowercaseQuery = query.lowercased()
        return restaurants.filter { restaurant in
            restaurant.name.lowercased().contains(lowercaseQuery) ||
            restaurant.description.lowercased().contains(lowercaseQuery) ||
            restaurant.cuisineTypes.contains { $0.lowercased().contains(lowercaseQuery) }
        }
    }
    
    // MARK: - Filter by Category
    func filterByCategory(_ category: String) -> [RestaurantDTO] {
        return restaurants.filter { restaurant in
            restaurant.cuisineTypes.contains { $0.lowercased() == category.lowercased() }
        }
    }
}
