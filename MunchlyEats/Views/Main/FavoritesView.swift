import SwiftUI

struct FavoritesView: View {
    @StateObject private var favoritesService = FavoritesService.shared
    @StateObject private var restaurantService = RestaurantService.shared
    @EnvironmentObject var cartViewModel: CartViewModel
    @State private var selectedRestaurant: RestaurantDTO?
    
    var favoriteRestaurants: [RestaurantDTO] {
        restaurantService.restaurants.filter { favoritesService.favoriteRestaurantIds.contains($0.id) }
    }
    
    var body: some View {
        Group {
            if favoriteRestaurants.isEmpty {
                EmptyStateView(
                    icon: "heart.slash",
                    title: "No Favorites Yet",
                    message: "Start adding restaurants to your favorites by tapping the heart icon"
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(favoriteRestaurants) { restaurant in
                            FavoriteRestaurantCard(restaurant: restaurant)
                                .onTapGesture {
                                    selectedRestaurant = restaurant
                                }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Favorites")
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(item: $selectedRestaurant) { restaurant in
            RestaurantDetailView(restaurant: restaurant.toRestaurant())
        }
    }
}

// MARK: - Favorite Restaurant Card
struct FavoriteRestaurantCard: View {
    let restaurant: RestaurantDTO
    @StateObject private var favoritesService = FavoritesService.shared
    
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
                }
                .font(.caption)
                
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
            }
            
            Spacer()
            
            Button {
                withAnimation {
                    favoritesService.toggleRestaurantFavorite(restaurant.id)
                }
            } label: {
                Image(systemName: "heart.fill")
                    .font(.title2)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
}

#Preview {
    NavigationStack {
        FavoritesView()
            .environmentObject(CartViewModel())
    }
}
