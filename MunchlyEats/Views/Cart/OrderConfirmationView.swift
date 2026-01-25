import SwiftUI

struct OrderConfirmationView: View {
    let order: Order
    @Environment(\.dismiss) private var dismiss
    @State private var animateCheckmark = false
    @State private var animateContent = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Success Header
                VStack(spacing: 20) {
                    // Animated Checkmark
                    ZStack {
                        Circle()
                            .fill(Color.primary.opacity(0.15))
                            .frame(width: 100, height: 100)
                            .scaleEffect(animateCheckmark ? 1.0 : 0.5)
                        
                        Circle()
                            .fill(Color.primary)
                            .frame(width: 70, height: 70)
                            .scaleEffect(animateCheckmark ? 1.0 : 0.5)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(Color(.systemBackground))
                            .scaleEffect(animateCheckmark ? 1.0 : 0.0)
                    }
                    
                    VStack(spacing: 8) {
                        Text("Order Confirmed!")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Your order has been placed successfully")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 40)
                .opacity(animateContent ? 1.0 : 0.0)
                .offset(y: animateContent ? 0 : 20)
                
                // Order Info Card
                VStack(spacing: 16) {
                    // Order Number & ETA
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Order Number")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("#\(order.orderNumber)")
                                .font(.headline)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Estimated Arrival")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(order.estimatedDeliveryTime?.formatted(date: .omitted, time: .shortened) ?? "25-35 min")
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                    }
                    
                    Divider()
                    
                    // Restaurant
                    HStack(spacing: 12) {
                        AsyncImageView(url: order.restaurantImageURL)
                            .frame(width: 50, height: 50)
                            .cornerRadius(8)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(order.restaurantName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("\(order.items.count) item\(order.items.count > 1 ? "s" : "")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text(order.total.asCurrency)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    
                    Divider()
                    
                    // Delivery Address
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "location.fill")
                            .foregroundColor(.primary)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Delivery Address")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(order.deliveryAddress)
                                .font(.subheadline)
                        }
                        
                        Spacer()
                    }
                }
                .padding(20)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(16)
                .padding(.horizontal)
                .opacity(animateContent ? 1.0 : 0.0)
                .offset(y: animateContent ? 0 : 20)
                
                // Order Items
                VStack(alignment: .leading, spacing: 12) {
                    Text("Order Summary")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    VStack(spacing: 0) {
                        ForEach(order.items, id: \.id) { item in
                            HStack {
                                Text("\(item.quantity)x")
                                    .foregroundColor(.secondary)
                                    .frame(width: 30, alignment: .leading)
                                Text(item.name)
                                    .font(.subheadline)
                                Spacer()
                                Text(item.totalPrice.asCurrency)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            
                            if item.id != order.items.last?.id {
                                Divider()
                                    .padding(.leading, 50)
                            }
                        }
                    }
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                .opacity(animateContent ? 1.0 : 0.0)
                .offset(y: animateContent ? 0 : 20)
                
                Spacer(minLength: 120)
            }
        }
        .navigationTitle("Order Placed")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    navigateToHome()
                } label: {
                    Image(systemName: "xmark")
                        .font(.body.weight(.medium))
                        .foregroundColor(.primary)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                trackOrder()
            } label: {
                HStack {
                    Image(systemName: "location.fill")
                    Text("Track Order")
                        .fontWeight(.semibold)
                }
                .foregroundColor(Color(.systemBackground))
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.primary)
                .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                animateCheckmark = true
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                animateContent = true
            }
        }
    }
    
    private func navigateToHome() {
        // Pop to root and switch to home tab
        popToRootAndSwitchTab {
            TabSelectionManager.shared.switchToHomeTab()
        }
    }
    
    private func trackOrder() {
        // Pop to root and switch to orders tab with the order
        popToRootAndSwitchTab {
            TabSelectionManager.shared.switchToOrdersTab(with: order)
        }
    }
    
    private func popToRootAndSwitchTab(completion: @escaping () -> Void) {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            findNavigationController(in: rootVC)?.popToRootViewController(animated: false)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                completion()
            }
        }
    }
    
    private func findNavigationController(in viewController: UIViewController) -> UINavigationController? {
        if let nav = viewController as? UINavigationController {
            return nav
        }
        for child in viewController.children {
            if let nav = findNavigationController(in: child) {
                return nav
            }
        }
        return nil
    }
}

// MARK: - Corner Radius Extension
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    OrderConfirmationView(
        order: Order(
            id: UUID().uuidString,
            orderNumber: "MUN-2024-001234",
            userId: UUID().uuidString,
            restaurantId: UUID().uuidString,
            restaurantName: "Burger Palace",
            restaurantImageURL: "https://images.unsplash.com/photo-1568901346375-23c9450c58cd",
            items: [
                OrderItem(
                    id: UUID().uuidString,
                    menuItemId: UUID().uuidString,
                    name: "Classic Cheeseburger",
                    imageURL: "https://images.unsplash.com/photo-1568901346375-23c9450c58cd",
                    quantity: 2,
                    basePrice: 12.99,
                    customizations: [],
                    specialInstructions: nil
                )
            ],
            status: .confirmed,
            subtotal: 25.98,
            deliveryFee: 2.99,
            serviceFee: 2.50,
            tax: 2.60,
            discount: 0,
            total: 35.47,
            deliveryAddress: "123 Main Street, Apt 4B, San Francisco, CA 94102",
            deliveryLatitude: 37.7749,
            deliveryLongitude: -122.4194,
            deliveryInstructions: "Leave at door",
            paymentMethodId: UUID().uuidString,
            paymentMethodLast4: "4242",
            estimatedDeliveryTime: Date().addingTimeInterval(1800),
            tipAmount: 4.00
        )
    )
}
