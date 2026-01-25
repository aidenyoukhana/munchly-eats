import SwiftUI

struct RestaurantDetailView: View {
    let restaurant: Restaurant
    @StateObject private var viewModel: RestaurantViewModel
    @StateObject private var favoritesService = FavoritesService.shared
    @EnvironmentObject var cartViewModel: CartViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategory: String? = nil
    @State private var navigateToCart = false
    
    init(restaurant: Restaurant) {
        self.restaurant = restaurant
        self._viewModel = StateObject(wrappedValue: RestaurantViewModel(restaurant: restaurant))
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            mainScrollView
            floatingCartButton
        }
        .navigationTitle(restaurant.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    Button {
                        withAnimation {
                            favoritesService.toggleRestaurantFavorite(restaurant.id)
                        }
                    } label: {
                        Image(systemName: favoritesService.isRestaurantFavorite(restaurant.id) ? "heart.fill" : "heart")
                            .foregroundColor(favoritesService.isRestaurantFavorite(restaurant.id) ? .red : .primary)
                    }
                    
                    CartToolbarButton()
                }
            }
        }
        .navigationDestination(isPresented: $navigateToCart) {
            CartView()
        }
        .task {
            await viewModel.loadMenu()
        }
    }
    
    // MARK: - Main Scroll View
    @ViewBuilder
    private var mainScrollView: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Restaurant Header Image
                AsyncImageView(url: restaurant.imageURL)
                    .frame(height: 200)
                    .clipped()
                
                // Restaurant Info
                RestaurantInfoSection(restaurant: restaurant)
                
                // Category Pills
                if !viewModel.categories.isEmpty {
                    CategoryPillsView(
                        categories: viewModel.categories,
                        selectedCategory: $selectedCategory
                    )
                }
                
                // Menu Items
                menuItemsList
            }
        }
    }
    
    // MARK: - Menu Items List
    @ViewBuilder
    private var menuItemsList: some View {
        LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
            ForEach(viewModel.groupedMenuItems.keys.sorted(), id: \.self) { category in
                Section {
                    ForEach(viewModel.groupedMenuItems[category, default: []]) { itemDTO in
                        let item = itemDTO.toMenuItem()
                        NavigationLink {
                            MenuItemDetailView(menuItem: item, restaurant: restaurant)
                                .environmentObject(cartViewModel)
                        } label: {
                            MenuItemRow(item: item)
                        }
                        .buttonStyle(.plain)
                        
                        if itemDTO.id != viewModel.groupedMenuItems[category]?.last?.id {
                            Divider()
                                .padding(.leading, 100)
                        }
                    }
                } header: {
                    MenuSectionHeader(title: category)
                }
            }
        }
        .padding(.bottom, cartViewModel.items.isEmpty ? 20 : 100)
    }
    
    // MARK: - Floating Cart Button
    @ViewBuilder
    private var floatingCartButton: some View {
        if !cartViewModel.items.isEmpty {
            VStack(spacing: 0) {
                Spacer()
                
                Button {
                    navigateToCart = true
                } label: {
                    HStack {
                        Text("View Cart")
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Text(cartViewModel.total.toCurrency())
                            .fontWeight(.bold)
                    }
                    .foregroundColor(Color(.systemBackground))
                    .padding()
                    .background(Color.primary)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}

// MARK: - Restaurant Info Section
struct RestaurantInfoSection: View {
    let restaurant: Restaurant
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(restaurant.name)
                .font(.title)
                .fontWeight(.bold)
            
            Text(restaurant.cuisineTypes.joined(separator: " • "))
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 16) {
                // Rating
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.primary)
                    Text(String(format: "%.1f", restaurant.rating))
                        .fontWeight(.medium)
                    Text("(\(restaurant.reviewCount)+)")
                        .foregroundColor(.secondary)
                }
                
                // Delivery Time
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .foregroundColor(.secondary)
                    Text(restaurant.deliveryTime)
                }
                
                // Delivery Fee
                HStack(spacing: 4) {
                    Image(systemName: "bicycle")
                        .foregroundColor(.secondary)
                    Text(restaurant.deliveryFee == 0 ? "Free" : restaurant.deliveryFee.toCurrency())
                }
            }
            .font(.subheadline)
            
            // Minimum Order
            if restaurant.minimumOrder > 0 {
                Text("Minimum order: \(restaurant.minimumOrder.toCurrency())")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
                .padding(.top, 8)
        }
        .padding()
    }
}

// MARK: - Category Pills View
struct CategoryPillsView: View {
    let categories: [String]
    @Binding var selectedCategory: String?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(categories, id: \.self) { category in
                    Button {
                        withAnimation {
                            selectedCategory = selectedCategory == category ? nil : category
                        }
                    } label: {
                        Text(category)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(selectedCategory == category ? Color(.systemBackground) : .primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selectedCategory == category ? Color.primary : Color(.secondarySystemBackground))
                            .cornerRadius(20)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.bottom, 8)
    }
}

// MARK: - Menu Section Header
struct MenuSectionHeader: View {
    let title: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.title3)
                .fontWeight(.bold)
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

// MARK: - Menu Item Row
struct MenuItemRow: View {
    let item: MenuItem
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(item.name)
                        .font(.headline)
                    
                    if item.isPopular {
                        Text("Popular")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(Color(.systemBackground))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.primary)
                            .cornerRadius(4)
                    }
                }
                
                Text(item.menuItemDescription)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    Text(item.price.toCurrency())
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    if let calories = item.calories {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text("\(calories) cal")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            AsyncImageView(url: item.imageURL)
                .frame(width: 80, height: 80)
                .cornerRadius(8)
        }
        .padding()
    }
}

#Preview {
    NavigationStack {
        RestaurantDetailView(
            restaurant: Restaurant(
                id: UUID().uuidString,
                name: "Burger Palace",
                restaurantDescription: "The best burgers in town",
                imageURL: "https://images.unsplash.com/photo-1568901346375-23c9450c58cd",
                coverImageURL: "https://images.unsplash.com/photo-1568901346375-23c9450c58cd",
                rating: 4.7,
                reviewCount: 234,
                deliveryTime: "25-35 min",
                deliveryFee: 2.99,
                minimumOrder: 15.0,
                distance: 1.2,
                cuisineTypes: ["Burgers", "American"],
                address: "123 Main St",
                latitude: 37.7749,
                longitude: -122.4194,
                isOpen: true
            )
        )
        .environmentObject(CartViewModel())
    }
}
