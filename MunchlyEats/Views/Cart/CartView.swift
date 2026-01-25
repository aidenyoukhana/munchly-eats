import SwiftUI

struct CartView: View {
    @EnvironmentObject var cartViewModel: CartViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showCheckout = false
    @State private var promoCode: String = ""
    @State private var showPromoField = false
    
    var body: some View {
        contentView
        .navigationTitle("Cart")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !cartViewModel.items.isEmpty {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear") {
                        cartViewModel.clearCart()
                        ToastManager.shared.showInfo("Cart Cleared")
                    }
                    .foregroundColor(.secondary)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if !cartViewModel.items.isEmpty {
                NavigationLink(destination: CheckoutView()) {
                    HStack {
                        Text("Proceed to Checkout")
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
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        if cartViewModel.items.isEmpty {
            EmptyCartView()
        } else {
            ScrollView {
                VStack(spacing: 16) {
                    // Restaurant Info
                    if let restaurantName = cartViewModel.restaurantName {
                        RestaurantNameHeader(name: restaurantName)
                    }
                    
                    // Cart Items
                    VStack(spacing: 0) {
                        ForEach(cartViewModel.items) { item in
                            CartItemRow(
                                item: item,
                                onUpdateQuantity: { newQuantity in
                                    cartViewModel.updateQuantity(for: item.id, quantity: newQuantity)
                                },
                                onRemove: {
                                    cartViewModel.removeItem(item.id)
                                }
                            )
                            
                            if item.id != cartViewModel.items.last?.id {
                                Divider()
                                    .padding(.horizontal)
                            }
                        }
                    }
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Add More Items Button
                    Button {
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add More Items")
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    }
                    
                    // Promo Code
                    PromoCodeSection(
                        promoCode: $cartViewModel.promoCodeInput,
                        showField: $showPromoField,
                        appliedPromo: cartViewModel.appliedPromoCode,
                        onApply: {
                            cartViewModel.applyPromoCode()
                        },
                        onRemove: {
                            cartViewModel.removePromoCode()
                        }
                    )
                    .padding(.horizontal)
                    
                    // Order Summary
                    OrderSummarySection(
                        subtotal: cartViewModel.subtotal,
                        deliveryFee: cartViewModel.deliveryFee,
                        serviceFee: cartViewModel.serviceFee,
                        discount: cartViewModel.discount,
                        total: cartViewModel.total
                    )
                    .padding(.horizontal)
                    
                    Spacer(minLength: 100)
                }
                .padding(.top)
            }
        }
    }
}

// MARK: - Empty Cart View
struct EmptyCartView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "cart")
                .font(.system(size: 80))
                .foregroundColor(.secondary)
            
            Text("Your cart is empty")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Add items from a restaurant to start your order")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// MARK: - Restaurant Name Header (Simple version when we only have name)
struct RestaurantNameHeader: View {
    let name: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "storefront.fill")
                .font(.title2)
                .foregroundColor(.primary)
                .frame(width: 50, height: 50)
                .background(Color.primary.opacity(0.1))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.headline)
                
                Text("Delivery")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// MARK: - Restaurant Cart Header
struct RestaurantCartHeader: View {
    let restaurant: Restaurant
    
    var body: some View {
        HStack(spacing: 12) {
            AsyncImageView(url: restaurant.imageURL)
                .frame(width: 50, height: 50)
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(restaurant.name)
                    .font(.headline)
                
                Text(restaurant.deliveryTime)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// MARK: - Cart Item Row
struct CartItemRow: View {
    let item: CartItem
    let onUpdateQuantity: (Int) -> Void
    let onRemove: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            AsyncImageView(url: item.menuItemImageURL)
                .frame(width: 60, height: 60)
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.menuItemName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                // Customizations
                if !item.selectedCustomizations.isEmpty {
                    ForEach(item.selectedCustomizations) { customization in
                        Text("\(customization.groupName): \(customization.optionName)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Special Instructions
                if let instructions = item.specialInstructions {
                    Text("Note: \(instructions)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                }
                
                Text(item.totalPrice.toCurrency())
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 8) {
                Button(action: onRemove) {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                CartQuantitySelector(
                    quantity: item.quantity,
                    onUpdate: onUpdateQuantity
                )
            }
        }
        .padding()
    }
}

// MARK: - Cart Quantity Selector
struct CartQuantitySelector: View {
    let quantity: Int
    let onUpdate: (Int) -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button {
                if quantity > 1 {
                    onUpdate(quantity - 1)
                }
            } label: {
                Image(systemName: "minus")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(quantity > 1 ? .primary : .secondary)
                    .frame(width: 28, height: 28)
                    .background(Color(.tertiarySystemBackground))
                    .cornerRadius(6)
            }
            
            Text("\(quantity)")
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(width: 24)
            
            Button {
                onUpdate(quantity + 1)
            } label: {
                Image(systemName: "plus")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .frame(width: 28, height: 28)
                    .background(Color(.tertiarySystemBackground))
                    .cornerRadius(6)
            }
        }
    }
}

// MARK: - Promo Code Section
struct PromoCodeSection: View {
    @Binding var promoCode: String
    @Binding var showField: Bool
    let appliedPromo: PromoCode?
    let onApply: () -> Void
    let onRemove: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            if let promo = appliedPromo {
                // Applied promo
                HStack {
                    Image(systemName: "tag.fill")
                        .foregroundColor(.primary)
                    
                    VStack(alignment: .leading) {
                        Text(promo.code)
                            .fontWeight(.medium)
                        Text(promo.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button("Remove") {
                        onRemove()
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.primary.opacity(0.1))
                .cornerRadius(12)
            } else if showField {
                HStack {
                    TextField("Enter promo code", text: $promoCode)
                        .textInputAutocapitalization(.characters)
                    
                    Button("Apply") {
                        onApply()
                    }
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .disabled(promoCode.isEmpty)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            } else {
                Button {
                    showField = true
                } label: {
                    HStack {
                        Image(systemName: "tag")
                        Text("Add Promo Code")
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .foregroundColor(.primary)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                }
            }
        }
    }
}

// MARK: - Order Summary Section
struct OrderSummarySection: View {
    let subtotal: Double
    let deliveryFee: Double
    let serviceFee: Double
    let discount: Double
    let total: Double
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Subtotal")
                Spacer()
                Text(subtotal.toCurrency())
            }
            
            HStack {
                Text("Delivery Fee")
                Spacer()
                Text(deliveryFee == 0 ? "Free" : deliveryFee.toCurrency())
                    .foregroundColor(deliveryFee == 0 ? .primary : .primary)
            }
            
            HStack {
                Text("Service Fee")
                Spacer()
                Text(serviceFee.toCurrency())
            }
            
            if discount > 0 {
                HStack {
                    Text("Discount")
                    Spacer()
                    Text("-\(discount.toCurrency())")
                        .foregroundColor(.primary)
                }
            }
            
            Divider()
            
            HStack {
                Text("Total")
                    .fontWeight(.bold)
                Spacer()
                Text(total.toCurrency())
                    .fontWeight(.bold)
            }
        }
        .font(.subheadline)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Checkout Button
struct CheckoutButton: View {
    let total: Double
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text("Proceed to Checkout")
                    .fontWeight(.semibold)
                Spacer()
                Text(total.toCurrency())
                    .fontWeight(.bold)
            }
            .foregroundColor(Color(.systemBackground))
            .padding()
            .background(Color.primary)
            .cornerRadius(12)
        }
    }
}

#Preview {
    CartView()
        .environmentObject(CartViewModel())
}
