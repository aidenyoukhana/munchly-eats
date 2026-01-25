import SwiftUI
import Combine

struct OrdersView: View {
    @EnvironmentObject var orderViewModel: OrderViewModel
    @EnvironmentObject var cartViewModel: CartViewModel
    @State private var selectedOrder: Order?
    @State private var navigateToOrder: Order?
    
    var allOrders: [Order] {
        // Combine and sort by date, most recent first
        (orderViewModel.activeOrders + orderViewModel.pastOrders)
            .sorted { $0.createdAt > $1.createdAt }
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            if allOrders.isEmpty {
                EmptyStateView(
                    icon: "bag",
                    title: "No Orders Yet",
                    message: "Your orders will appear here once you place one"
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(allOrders) { order in
                            OrderCard(order: order)
                                .onTapGesture {
                                    selectedOrder = order
                                }
                        }
                    }
                    .padding()
                    .padding(.bottom, cartViewModel.items.isEmpty ? 20 : 100)
                }
            }
            
            FloatingCartBanner()
        }
        .navigationTitle("Orders")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                CartToolbarButton()
            }
        }
        .navigationDestination(item: $selectedOrder) { order in
            if order.status.isActive {
                OrderTrackingView(order: order)
            } else {
                OrderDetailsView(order: order, orderViewModel: orderViewModel)
            }
        }
        .navigationDestination(item: $navigateToOrder) { order in
            OrderTrackingView(order: order)
        }
        .sheet(isPresented: $orderViewModel.showRatingSheet) {
            if let order = orderViewModel.ratingOrder {
                RatingSheet(
                    order: order,
                    rating: $orderViewModel.ratingValue,
                    reviewText: $orderViewModel.reviewText,
                    onSubmit: {
                        Task {
                            await orderViewModel.rateOrder(
                                order.id,
                                rating: orderViewModel.ratingValue,
                                review: orderViewModel.reviewText.isEmpty ? nil : orderViewModel.reviewText
                            )
                        }
                    }
                )
                .presentationDetents([.medium])
            }
        }
        .onAppear {
            orderViewModel.refreshOrders()
        }
        .onReceive(TabSelectionManager.shared.$orderToTrack) { order in
            if let order = order {
                // Small delay to ensure the view is ready
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    navigateToOrder = order
                    // Clear the order so it doesn't re-trigger
                    TabSelectionManager.shared.orderToTrack = nil
                }
            }
        }
    }
}

// MARK: - Order Card (Similar to RestaurantCard style)
struct OrderCard: View {
    let order: Order
    
    var isActive: Bool {
        order.status.isActive
    }
    
    var body: some View {
        HStack(spacing: 12) {
            AsyncImageView(url: order.restaurantImageURL)
                .frame(width: 100, height: 100)
                .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(order.restaurantName)
                    .font(.headline)
                    .lineLimit(1)
                
                Text("#\(order.orderNumber)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: order.status.icon)
                            .foregroundColor(isActive ? .orange : .primary)
                        Text(order.status.rawValue)
                            .fontWeight(.medium)
                            .foregroundColor(isActive ? .orange : .primary)
                    }
                    
                    if isActive, let eta = order.estimatedDeliveryTime {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .foregroundColor(.secondary)
                            Text(eta.toTimeString())
                        }
                    }
                }
                .font(.caption)
                
                HStack {
                    Text("\(order.items.count) item\(order.items.count > 1 ? "s" : "") • \(order.total.toCurrency())")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(order.createdAt.toOrderDateString())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
}

// MARK: - Order Details View (Navigation, not Sheet)
struct OrderDetailsView: View {
    let order: Order
    @ObservedObject var orderViewModel: OrderViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Restaurant Info
                HStack(spacing: 12) {
                    AsyncImageView(url: order.restaurantImageURL)
                        .frame(width: 60, height: 60)
                        .cornerRadius(12)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(order.restaurantName)
                            .font(.headline)
                        
                        Text(order.createdAt.toOrderDateString())
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    StatusBadge(status: order.status)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                
                // Order Number
                HStack {
                    Text("Order Number")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("#\(order.orderNumber)")
                        .fontWeight(.medium)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                
                // Items
                VStack(alignment: .leading, spacing: 12) {
                    Text("Items")
                        .font(.headline)
                    
                    ForEach(order.items) { item in
                        HStack {
                            Text("\(item.quantity)x")
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            
                            Text(item.name)
                            
                            Spacer()
                            
                            Text(item.totalPrice.toCurrency())
                                .foregroundColor(.secondary)
                        }
                        
                        if item.id != order.items.last?.id {
                            Divider()
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                
                // Price Breakdown
                VStack(spacing: 12) {
                    PriceRow(label: "Subtotal", value: order.subtotal)
                    PriceRow(label: "Delivery Fee", value: order.deliveryFee)
                    PriceRow(label: "Service Fee", value: order.serviceFee)
                    PriceRow(label: "Tax", value: order.tax)
                    
                    if order.discount > 0 {
                        PriceRow(label: "Discount", value: -order.discount, isDiscount: true)
                    }
                    
                    if order.tipAmount > 0 {
                        PriceRow(label: "Tip", value: order.tipAmount)
                    }
                    
                    Divider()
                    
                    HStack {
                        Text("Total")
                            .fontWeight(.bold)
                        Spacer()
                        Text(order.total.toCurrency())
                            .fontWeight(.bold)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                
                // Delivery Address
                VStack(alignment: .leading, spacing: 8) {
                    Text("Delivered To")
                        .font(.headline)
                    
                    HStack(alignment: .top) {
                        Image(systemName: "location.fill")
                            .foregroundColor(.primary)
                        
                        Text(order.deliveryAddress)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                
                // Rating
                if let rating = order.rating {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Rating")
                            .font(.headline)
                        
                        HStack(spacing: 4) {
                            ForEach(1...5, id: \.self) { index in
                                Image(systemName: index <= rating ? "star.fill" : "star")
                                    .foregroundColor(.primary)
                            }
                        }
                        
                        if let review = order.review, !review.isEmpty {
                            Text(review)
                                .foregroundColor(.secondary)
                                .padding(.top, 4)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                }
                
                // Rate Order Button (only if not rated)
                if order.rating == nil {
                    Button {
                        orderViewModel.startRating(order: order)
                    } label: {
                        Text("Rate Order")
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.primary.opacity(0.1))
                            .cornerRadius(12)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Order Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task {
                        await orderViewModel.reorder(order.id)
                    }
                    dismiss()
                } label: {
                    Text("Reorder")
                        .fontWeight(.medium)
                }
            }
        }
    }
}

// MARK: - Price Row
struct PriceRow: View {
    let label: String
    let value: Double
    var isDiscount: Bool = false
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value.toCurrency())
                .foregroundColor(isDiscount ? .green : .primary)
        }
    }
}

// MARK: - Status Badge
struct StatusBadge: View {
    let status: OrderStatus
    
    var body: some View {
        Text(status.rawValue)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(statusColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.1))
            .cornerRadius(8)
    }
    
    private var statusColor: Color {
        switch status {
        case .delivered: return .primary
        case .cancelled, .refunded: return .secondary
        default: return .primary
        }
    }
}

// MARK: - Rating Sheet
struct RatingSheet: View {
    let order: Order
    @Binding var rating: Int
    @Binding var reviewText: String
    let onSubmit: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Restaurant Info
                HStack {
                    AsyncImageView(url: order.restaurantImageURL)
                        .frame(width: 60, height: 60)
                        .cornerRadius(12)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Rate your order from")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text(order.restaurantName)
                            .font(.headline)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                
                // Star Rating
                HStack(spacing: 16) {
                    ForEach(1...5, id: \.self) { index in
                        Button {
                            rating = index
                        } label: {
                            Image(systemName: index <= rating ? "star.fill" : "star")
                                .font(.system(size: 40))
                                .foregroundColor(.primary)
                        }
                    }
                }
                
                // Review Text
                VStack(alignment: .leading, spacing: 8) {
                    Text("Leave a review (optional)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    TextEditor(text: $reviewText)
                        .frame(height: 100)
                        .padding(8)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                }
                
                Spacer()
                
                // Submit Button
                Button(action: onSubmit) {
                    Text("Submit Rating")
                        .primaryButtonStyle()
                }
            }
            .padding()
            .navigationTitle("Rate Order")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    OrdersView()
        .environmentObject(OrderViewModel())
        .environmentObject(CartViewModel())
}
