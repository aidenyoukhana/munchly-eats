import Foundation
import Combine

@MainActor
class RestaurantViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var restaurant: RestaurantDTO?
    @Published var menuItems: [MenuItemDTO] = []
    @Published var menuCategories: [String] = []
    @Published var selectedCategory: String = ""
    
    @Published var isLoading = false
    @Published var error: Error?
    
    // MARK: - Services
    private let menuService = MenuService.shared
    private let restaurantService = RestaurantService.shared
    
    // MARK: - Restaurant for initialization
    private let restaurantModel: Restaurant?
    
    init() {
        self.restaurantModel = nil
    }
    
    init(restaurant: Restaurant) {
        self.restaurantModel = restaurant
    }
    
    // MARK: - Computed Properties
    var categories: [String] {
        menuCategories
    }
    
    var filteredMenuItems: [MenuItemDTO] {
        if selectedCategory.isEmpty || selectedCategory == "All" {
            return menuItems
        }
        return menuItems.filter { $0.category == selectedCategory }
    }
    
    var popularItems: [MenuItemDTO] {
        menuItems.filter { $0.isPopular }
    }
    
    var groupedMenuItems: [String: [MenuItemDTO]] {
        Dictionary(grouping: menuItems, by: { $0.category })
    }
    
    // MARK: - Load Menu
    func loadMenu() async {
        guard let restaurantId = restaurantModel?.id else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            menuItems = try await menuService.loadMenu(for: restaurantId)
            
            // Extract unique categories
            var categories = ["All"]
            categories.append(contentsOf: Set(menuItems.map { $0.category }).sorted())
            menuCategories = categories
            
            if selectedCategory.isEmpty {
                selectedCategory = "All"
            }
        } catch {
            self.error = error
        }
    }
    
    // MARK: - Load Restaurant
    func loadRestaurant(id: String) {
        Task {
            isLoading = true
            defer { isLoading = false }
            
            // Get restaurant from service
            restaurant = restaurantService.getRestaurant(id: id)
            
            // Load menu
            do {
                menuItems = try await menuService.loadMenu(for: id)
                
                // Extract unique categories
                var categories = ["All"]
                categories.append(contentsOf: Set(menuItems.map { $0.category }).sorted())
                menuCategories = categories
                
                if selectedCategory.isEmpty {
                    selectedCategory = "All"
                }
            } catch {
                self.error = error
            }
        }
    }
    
    // MARK: - Get Menu Item
    func getMenuItem(id: String) -> MenuItemDTO? {
        menuItems.first { $0.id == id }
    }
    
    // MARK: - Select Category
    func selectCategory(_ category: String) {
        selectedCategory = category
    }
}
