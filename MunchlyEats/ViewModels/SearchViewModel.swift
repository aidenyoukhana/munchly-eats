import Foundation
import Combine

@MainActor
class SearchViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var searchText = ""
    @Published var searchResults: [RestaurantDTO] = []
    @Published var recentSearches: [String] = []
    @Published var isSearching = false
    
    // MARK: - Services
    private let restaurantService = RestaurantService.shared
    
    // MARK: - User Defaults Keys
    private let recentSearchesKey = "recentSearches"
    
    // MARK: - Initialization
    init() {
        loadRecentSearches()
    }
    
    // MARK: - Computed Properties
    var hasResults: Bool {
        !searchResults.isEmpty
    }
    
    var showRecentSearches: Bool {
        searchText.isEmpty && !recentSearches.isEmpty
    }
    
    var popularCategories: [String] {
        ["Pizza", "Burgers", "Sushi", "Mexican", "Chinese", "Healthy"]
    }
    
    // MARK: - Search
    func search() {
        guard !searchText.isEmpty else {
            searchResults = []
            return
        }
        
        isSearching = true
        
        // Debounce search
        Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            
            searchResults = restaurantService.searchRestaurants(query: searchText)
            isSearching = false
            
            // Save to recent searches
            saveRecentSearch(searchText)
        }
    }
    
    // MARK: - Search with Category
    func searchByCategory(_ category: String) {
        searchText = category
        searchResults = restaurantService.filterByCategory(category)
        saveRecentSearch(category)
    }
    
    // MARK: - Clear Search
    func clearSearch() {
        searchText = ""
        searchResults = []
    }
    
    // MARK: - Recent Searches
    private func loadRecentSearches() {
        recentSearches = UserDefaults.standard.stringArray(forKey: recentSearchesKey) ?? []
    }
    
    private func saveRecentSearch(_ search: String) {
        var searches = recentSearches
        
        // Remove if already exists
        searches.removeAll { $0.lowercased() == search.lowercased() }
        
        // Add to beginning
        searches.insert(search, at: 0)
        
        // Keep only last 10
        if searches.count > 10 {
            searches = Array(searches.prefix(10))
        }
        
        recentSearches = searches
        UserDefaults.standard.set(searches, forKey: recentSearchesKey)
    }
    
    func removeRecentSearch(_ search: String) {
        recentSearches.removeAll { $0 == search }
        UserDefaults.standard.set(recentSearches, forKey: recentSearchesKey)
    }
    
    func clearRecentSearches() {
        recentSearches = []
        UserDefaults.standard.removeObject(forKey: recentSearchesKey)
    }
    
    func selectRecentSearch(_ search: String) {
        searchText = search
        self.search()
    }
}
