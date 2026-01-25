import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @StateObject private var searchViewModel = SearchViewModel()
    @ObservedObject private var favoritesService = FavoritesService.shared
    @EnvironmentObject var cartViewModel: CartViewModel
    @State private var showAddressSelector = false
    @State private var selectedRestaurant: RestaurantDTO?
    @State private var favoriteRestaurants: [RestaurantDTO] = []
    @State private var showQuickOrder = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 0) {
                    // Search Bar
                    searchBarSection
                    
                    if !searchViewModel.searchText.isEmpty {
                        // Search Results
                        searchResultsContent
                    } else {
                        mainContent
                    }
                }
            }
            .refreshable {
                await viewModel.refreshData()
            }
            
            FloatingCartBanner()
        }
        .navigationTitle("Home")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    Button {
                        showAddressSelector = true
                    } label: {
                        Image(systemName: "house.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.primary)
                    }
                    
                    CartToolbarButton()
                }
            }
        }
        .navigationDestination(item: $selectedRestaurant) { restaurant in
            RestaurantDetailView(restaurant: restaurant.toRestaurant())
        }
        .navigationDestination(isPresented: $showAddressSelector) {
            AddressListView(viewModel: ProfileViewModel())
        }
        .overlay {
            if viewModel.isLoading {
                LoadingOverlay(isLoading: true)
            }
        }
        .onChange(of: searchViewModel.searchText) { _, newValue in
            if !newValue.isEmpty {
                searchViewModel.search()
            }
        }
        .onChange(of: favoritesService.favoriteRestaurantIds) { _, newIds in
            updateFavoriteRestaurants(ids: newIds)
        }
        .onChange(of: viewModel.allRestaurants) { _, _ in
            updateFavoriteRestaurants(ids: favoritesService.favoriteRestaurantIds)
        }
        .onAppear {
            updateFavoriteRestaurants(ids: favoritesService.favoriteRestaurantIds)
        }
    }
    
    private func updateFavoriteRestaurants(ids: Set<String>) {
        let newFavorites = viewModel.allRestaurants.filter { ids.contains($0.id) }
        // Only update if the actual restaurant IDs changed, not just the array reference
        let currentIds = Set(favoriteRestaurants.map { $0.id })
        let newIds = Set(newFavorites.map { $0.id })
        if currentIds != newIds {
            favoriteRestaurants = newFavorites
        }
    }
    
    // MARK: - Search Bar Section
    @ViewBuilder
    private var searchBarSection: some View {
        HStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Try: 'cheap sushi nearby'...", text: $searchViewModel.searchText)
                    .autocapitalization(.none)
                    .submitLabel(.search)
                    .onSubmit {
                        searchViewModel.search()
                    }
                
                if !searchViewModel.searchText.isEmpty {
                    Button {
                        searchViewModel.clearSearch()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(12)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            
            // Quick Order Button
            Button {
                showQuickOrder = true
            } label: {
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundStyle(.white)
            }
            .accessibilityLabel("Quick Order")
        }
        .padding(.horizontal)
        .padding(.bottom, 16)
        .sheet(isPresented: $showQuickOrder) {
            QuickOrderView()
        }
    }
    
    // MARK: - Search Results Content
    @ViewBuilder
    private var searchResultsContent: some View {
        if searchViewModel.isSearching {
            VStack {
                Spacer()
                ProgressView()
                Spacer()
            }
            .frame(minHeight: 300)
        } else if searchViewModel.searchResults.isEmpty {
            EmptyStateView(
                icon: "magnifyingglass",
                title: "No Results",
                message: "We couldn't find any restaurants matching \"\(searchViewModel.searchText)\""
            )
            .padding(.top, 60)
        } else {
            LazyVStack(spacing: 16) {
                ForEach(searchViewModel.searchResults) { restaurant in
                    RestaurantCard(restaurant: restaurant)
                        .onTapGesture {
                            selectedRestaurant = restaurant
                        }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, cartViewModel.items.isEmpty ? 20 : 100)
        }
    }
    
    // MARK: - Main Content
    @ViewBuilder
    private var mainContent: some View {
        VStack(spacing: 24) {
            // Promotions Carousel
            if !viewModel.promotions.isEmpty {
                PromotionsCarousel(promotions: viewModel.promotions)
            }
            
            // Categories
            categoriesSection
            
            // Favorites
            if !favoriteRestaurants.isEmpty && !viewModel.hasActiveFilter {
                favoritesSection
            }
            
            // Featured Restaurants
            if !viewModel.featuredRestaurants.isEmpty && !viewModel.hasActiveFilter {
                featuredSection
            }
            
            // Nearby / All Restaurants
            nearbyRestaurantsSection
        }
        .padding(.bottom, cartViewModel.items.isEmpty ? 20 : 100)
    }
    
    // MARK: - Categories Section
    @ViewBuilder
    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Categories")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(viewModel.categories) { category in
                        CategoryCard(
                            category: category,
                            isSelected: viewModel.selectedCategory?.id == category.id
                        )
                        .onTapGesture {
                            withAnimation(.spring()) {
                                viewModel.selectCategory(category)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Favorites Section
    @ViewBuilder
    private var favoritesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Favorites")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                
                Spacer()
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(favoriteRestaurants) { restaurant in
                        FeaturedRestaurantCard(restaurant: restaurant)
                            .onTapGesture {
                                selectedRestaurant = restaurant
                            }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Featured Section
    @ViewBuilder
    private var featuredSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Featured")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Image(systemName: "star.fill")
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(viewModel.featuredRestaurants) { restaurant in
                        FeaturedRestaurantCard(restaurant: restaurant)
                            .onTapGesture {
                                selectedRestaurant = restaurant
                            }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Nearby Restaurants Section
    @ViewBuilder
    private var nearbyRestaurantsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(viewModel.hasActiveFilter ? "\(viewModel.selectedCategory?.name ?? "") Restaurants" : "Nearby Restaurants")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                if viewModel.hasActiveFilter {
                    Button("Clear") {
                        withAnimation {
                            viewModel.clearFilter()
                        }
                    }
                    .font(.subheadline)
                    .foregroundColor(.primary)
                }
            }
            .padding(.horizontal)
            
            LazyVStack(spacing: 16) {
                ForEach(viewModel.filteredRestaurants) { restaurant in
                    RestaurantCard(restaurant: restaurant)
                        .onTapGesture {
                            selectedRestaurant = restaurant
                        }
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Promotions Carousel
struct PromotionsCarousel: View {
    let promotions: [PromotionDTO]
    @State private var currentIndex = 0
    
    var body: some View {
        TabView(selection: $currentIndex) {
            ForEach(Array(promotions.enumerated()), id: \.element.id) { index, promotion in
                PromotionCard(promotion: promotion)
                    .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .automatic))
        .frame(height: 180)
    }
}

// MARK: - Promotion Card
struct PromotionCard: View {
    let promotion: PromotionDTO
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            AsyncImageView(url: promotion.imageURL)
                .frame(height: 180)
                .clipped()
            
            LinearGradient(
                colors: [.clear, .black.opacity(0.7)],
                startPoint: .top,
                endPoint: .bottom
            )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(promotion.title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(promotion.description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.9))
                
                if let code = promotion.promoCode {
                    Text("Use code: \(code)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
            }
            .padding()
        }
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

// MARK: - Category Card
struct CategoryCard: View {
    let category: Category
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Text(category.iconName)
                .font(.system(size: 32))
                .frame(width: 60, height: 60)
                .background(isSelected ? Color.primary : Color(.secondarySystemBackground))
                .cornerRadius(16)
            
            Text(category.name)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .primary : .secondary)
        }
    }
}

// MARK: - Featured Restaurant Card
struct FeaturedRestaurantCard: View {
    let restaurant: RestaurantDTO
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                AsyncImageView(url: restaurant.imageURL)
                    .frame(width: 200, height: 130)
                    .cornerRadius(12)
                
                if restaurant.isPromoted {
                    Text("Promoted")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(Color(.systemBackground))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.primary)
                        .cornerRadius(8)
                        .padding(8)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(restaurant.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.primary)
                        .font(.caption)
                    
                    Text(String(format: "%.1f", restaurant.rating))
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    Text("(\(restaurant.reviewCount))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text(restaurant.deliveryTime)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(width: 200)
    }
}

// MARK: - Restaurant Card
struct RestaurantCard: View {
    let restaurant: RestaurantDTO
    
    var body: some View {
        HStack(spacing: 12) {
            AsyncImageView(url: restaurant.imageURL)
                .frame(width: 100, height: 100)
                .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(restaurant.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(restaurant.cuisineTypes.joined(separator: " • "))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.primary)
                        Text(String(format: "%.1f", restaurant.rating))
                            .fontWeight(.medium)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .foregroundColor(.secondary)
                        Text(restaurant.deliveryTime)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "location")
                            .foregroundColor(.secondary)
                        Text(restaurant.distance.toDistance())
                    }
                }
                .font(.caption)
                
                HStack {
                    if restaurant.deliveryFee == 0 {
                        Text("Free Delivery")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    } else {
                        Text("\(restaurant.deliveryFee.toCurrency()) delivery")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if !restaurant.isOpen {
                        Text("Closed")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
}

#Preview {
    HomeView()
        .environmentObject(CartViewModel())
        .environmentObject(OrderViewModel())
}
