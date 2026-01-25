import SwiftUI
import Combine

// MARK: - Tab Selection Manager
class TabSelectionManager: ObservableObject {
    static let shared = TabSelectionManager()
    @Published var selectedTab = 0
    @Published var orderToTrack: Order?
    
    func switchToOrdersTab(with order: Order? = nil) {
        orderToTrack = order
        selectedTab = 1
    }
    
    func switchToHomeTab() {
        selectedTab = 0
    }
}

struct MainTabView: View {
    @StateObject private var tabManager = TabSelectionManager.shared
    @StateObject private var cartViewModel = CartViewModel()
    @StateObject private var orderViewModel = OrderViewModel()
    
    var body: some View {
        TabView(selection: $tabManager.selectedTab) {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(0)
            
            NavigationStack {
                OrdersView()
            }
            .tabItem {
                Label("Orders", systemImage: "bag.fill")
            }
            .tag(1)
            
            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Label("Profile", systemImage: "person.fill")
            }
            .tag(2)
        }
        .tint(.primary)
        .environmentObject(cartViewModel)
        .environmentObject(orderViewModel)
        .environmentObject(tabManager)
    }
}

// MARK: - Cart Toolbar Button
struct CartToolbarButton: View {
    @EnvironmentObject var cartViewModel: CartViewModel
    
    var body: some View {
        NavigationLink {
            CartView()
        } label: {
            Image(systemName: "cart.fill")
                .font(.system(size: 18))
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Floating Cart Banner
/// A consistent floating cart button that appears at the bottom of screens when cart has items
struct FloatingCartBanner: View {
    @EnvironmentObject var cartViewModel: CartViewModel
    @State private var navigateToCart = false
    
    var body: some View {
        if !cartViewModel.items.isEmpty {
            VStack(spacing: 0) {
                Spacer()
                
                NavigationLink(value: "cart") {
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
            .navigationDestination(for: String.self) { value in
                if value == "cart" {
                    CartView()
                }
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}

#Preview {
    MainTabView()
}
