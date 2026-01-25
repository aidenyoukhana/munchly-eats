import Foundation
import Combine

@MainActor
class HomeViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var categories: [Category] = []
    @Published var featuredRestaurants: [RestaurantDTO] = []
    @Published var nearbyRestaurants: [RestaurantDTO] = []
    @Published var promotions: [PromotionDTO] = []
    @Published var allRestaurants: [RestaurantDTO] = []
    
    @Published var selectedCategory: Category?
    @Published var filteredRestaurants: [RestaurantDTO] = []
    
    @Published var isLoading = false
    @Published var isRefreshing = false
    @Published var error: Error?
    
    // MARK: - Services
    private let restaurantService = RestaurantService.shared
    private let locationService = LocationService.shared
    
    // MARK: - Computed Properties
    var currentAddress: String {
        locationService.selectedAddress?.fullAddress ?? locationService.currentAddress
    }
    
    var hasActiveFilter: Bool {
        selectedCategory != nil
    }
    
    // MARK: - Initialization
    init() {
        loadData()
    }
    
    // MARK: - Load Data
    func loadData() {
        guard !isLoading else { return }
        
        Task {
            isLoading = true
            defer { isLoading = false }
            
            await restaurantService.loadInitialData()
            
            categories = restaurantService.categories
            featuredRestaurants = restaurantService.featuredRestaurants
            nearbyRestaurants = restaurantService.nearbyRestaurants
            promotions = restaurantService.promotions
            allRestaurants = restaurantService.restaurants
            filteredRestaurants = allRestaurants
            
            if let serviceError = restaurantService.error {
                error = serviceError
            }
        }
    }
    
    // MARK: - Refresh Data
    func refreshData() async {
        isRefreshing = true
        defer { isRefreshing = false }
        
        await restaurantService.loadInitialData()
        
        await MainActor.run {
            categories = restaurantService.categories
            featuredRestaurants = restaurantService.featuredRestaurants
            nearbyRestaurants = restaurantService.nearbyRestaurants
            promotions = restaurantService.promotions
            allRestaurants = restaurantService.restaurants
            
            if selectedCategory != nil {
                applyFilter()
            } else {
                filteredRestaurants = allRestaurants
            }
        }
    }
    
    // MARK: - Filter by Category
    func selectCategory(_ category: Category) {
        if selectedCategory?.id == category.id {
            // Deselect if same category tapped
            selectedCategory = nil
            filteredRestaurants = allRestaurants
        } else {
            selectedCategory = category
            applyFilter()
        }
    }
    
    func clearFilter() {
        selectedCategory = nil
        filteredRestaurants = allRestaurants
    }
    
    private func applyFilter() {
        guard let category = selectedCategory else {
            filteredRestaurants = allRestaurants
            return
        }
        
        filteredRestaurants = restaurantService.filterByCategory(category.name)
    }
    
    // MARK: - Get Restaurant
    func getRestaurant(id: String) -> RestaurantDTO? {
        restaurantService.getRestaurant(id: id)
    }
}
