import Foundation
import Combine

@MainActor
class FavoritesService: ObservableObject {
    static let shared = FavoritesService()
    
    @Published var favoriteRestaurantIds: Set<String> = []
    @Published var favoriteMenuItemIds: Set<String> = []
    
    private let restaurantKey = "favoriteRestaurants"
    private let menuItemKey = "favoriteMenuItems"
    
    private init() {
        loadFavorites()
    }
    
    // MARK: - Load Favorites
    private func loadFavorites() {
        if let restaurantIds = UserDefaults.standard.stringArray(forKey: restaurantKey) {
            favoriteRestaurantIds = Set(restaurantIds)
        }
        if let menuItemIds = UserDefaults.standard.stringArray(forKey: menuItemKey) {
            favoriteMenuItemIds = Set(menuItemIds)
        }
    }
    
    // MARK: - Restaurant Favorites
    func isRestaurantFavorite(_ id: String) -> Bool {
        favoriteRestaurantIds.contains(id)
    }
    
    func toggleRestaurantFavorite(_ id: String) {
        if favoriteRestaurantIds.contains(id) {
            favoriteRestaurantIds.remove(id)
        } else {
            favoriteRestaurantIds.insert(id)
        }
        saveFavorites()
    }
    
    // MARK: - Menu Item Favorites
    func isMenuItemFavorite(_ id: String) -> Bool {
        favoriteMenuItemIds.contains(id)
    }
    
    func toggleMenuItemFavorite(_ id: String) {
        if favoriteMenuItemIds.contains(id) {
            favoriteMenuItemIds.remove(id)
        } else {
            favoriteMenuItemIds.insert(id)
        }
        saveFavorites()
    }
    
    // MARK: - Save
    private func saveFavorites() {
        UserDefaults.standard.set(Array(favoriteRestaurantIds), forKey: restaurantKey)
        UserDefaults.standard.set(Array(favoriteMenuItemIds), forKey: menuItemKey)
    }
    
    // MARK: - Clear All
    func clearAllFavorites() {
        favoriteRestaurantIds.removeAll()
        favoriteMenuItemIds.removeAll()
        saveFavorites()
    }
}
