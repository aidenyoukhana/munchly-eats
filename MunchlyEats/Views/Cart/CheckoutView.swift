import SwiftUI
import Combine

struct CheckoutView: View {
    @EnvironmentObject var cartViewModel: CartViewModel
    @StateObject private var viewModel = CheckoutViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var showAddressSelector = false
    @State private var showPaymentSelector = false
    @State private var navigateToConfirmation = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Delivery Address
                DeliveryAddressSection(
                    address: viewModel.selectedAddress,
                    onTap: { showAddressSelector = true }
                )
                
                // Delivery Time
                DeliveryTimeSection(
                    selectedOption: $viewModel.deliveryOption,
                    scheduledTime: $viewModel.scheduledTime
                )
                
                // Payment Method
                PaymentMethodSection(
                    method: viewModel.selectedPaymentMethod,
                    onTap: { showPaymentSelector = true }
                )
                
                // Driver Tip
                DriverTipSection(
                    selectedTip: $viewModel.selectedTip,
                    customTip: $viewModel.customTip
                )
                
                // Order Summary
                CheckoutSummarySection(
                    subtotal: cartViewModel.subtotal,
                    deliveryFee: cartViewModel.deliveryFee,
                    serviceFee: cartViewModel.serviceFee,
                    discount: cartViewModel.discount,
                    tip: viewModel.tipAmount,
                    total: cartViewModel.total + viewModel.tipAmount
                )
                
                // Terms
                Text("By placing your order, you agree to MunchlyEats' Terms of Service and Privacy Policy")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer(minLength: 100)
            }
            .padding(.top)
        }
        .navigationTitle("Checkout")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
        .safeAreaInset(edge: .bottom) {
            PlaceOrderButton(
                total: cartViewModel.total + viewModel.tipAmount,
                isLoading: viewModel.isPlacingOrder
            ) {
                placeOrder()
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .sheet(isPresented: $showAddressSelector) {
            AddressSelectorSheet(selectedAddress: $viewModel.selectedAddress)
        }
        .sheet(isPresented: $showPaymentSelector) {
            PaymentSelectorSheet(selectedMethod: $viewModel.selectedPaymentMethod)
        }
        .navigationDestination(isPresented: $navigateToConfirmation) {
            if let order = viewModel.placedOrder {
                OrderConfirmationView(order: order)
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
        .task {
            viewModel.loadDefaults()
        }
    }
    
    private func placeOrder() {
        Task {
            if await viewModel.placeOrder() != nil {
                cartViewModel.clearCart()
                navigateToConfirmation = true
            }
        }
    }
}

// MARK: - Delivery Address Section
struct DeliveryAddressSection: View {
    let address: Address?
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(.primary)
                    Text("Delivery Address")
                        .fontWeight(.semibold)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                
                if let address = address {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(address.label)
                            .fontWeight(.medium)
                        Text(address.fullAddress)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        if let instructions = address.instructions {
                            Text("Note: \(instructions)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    Text("Select delivery address")
                        .foregroundColor(.primary)
                }
            }
            .foregroundColor(.primary)
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
        .padding(.horizontal)
    }
}

// MARK: - Delivery Time Section
struct DeliveryTimeSection: View {
    @Binding var selectedOption: DeliveryOption
    @Binding var scheduledTime: Date
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(.primary)
                Text("Delivery Time")
                    .fontWeight(.semibold)
            }
            
            HStack(spacing: 12) {
                DeliveryOptionButton(
                    title: "Standard",
                    subtitle: "25-35 min",
                    isSelected: selectedOption == .standard
                ) {
                    selectedOption = .standard
                }
                
                DeliveryOptionButton(
                    title: "Priority",
                    subtitle: "15-25 min",
                    isSelected: selectedOption == .priority,
                    extraCost: "$2.99"
                ) {
                    selectedOption = .priority
                }
            }
            
            Button {
                selectedOption = .scheduled
            } label: {
                HStack {
                    Text("Schedule for later")
                    Spacer()
                    if selectedOption == .scheduled {
                        Image(systemName: "checkmark")
                            .foregroundColor(.primary)
                    }
                }
                .padding()
                .background(selectedOption == .scheduled ? Color.primary.opacity(0.1) : Color(.tertiarySystemBackground))
                .cornerRadius(8)
            }
            .foregroundColor(.primary)
            
            if selectedOption == .scheduled {
                DatePicker(
                    "Select time",
                    selection: $scheduledTime,
                    in: Date()...,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.compact)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// MARK: - Delivery Option Button
struct DeliveryOptionButton: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    var extraCost: String? = nil
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(title)
                    .fontWeight(.medium)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                if let cost = extraCost {
                    Text(cost)
                        .font(.caption)
                        .foregroundColor(.primary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? Color.primary.opacity(0.1) : Color(.tertiarySystemBackground))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.primary : Color.clear, lineWidth: 2)
            )
        }
        .foregroundColor(.primary)
    }
}

// MARK: - Payment Method Section
struct PaymentMethodSection: View {
    let method: PaymentMethod?
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "creditcard.fill")
                        .foregroundColor(.primary)
                    Text("Payment Method")
                        .fontWeight(.semibold)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                
                if let method = method {
                    HStack {
                        Image(systemName: method.type.icon)
                            .foregroundColor(method.type.color)
                        
                        VStack(alignment: .leading) {
                            Text(method.type.displayName)
                                .fontWeight(.medium)
                            Text("•••• \(method.last4)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    Text("Select payment method")
                        .foregroundColor(.primary)
                }
            }
            .foregroundColor(.primary)
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
        .padding(.horizontal)
    }
}

// MARK: - Driver Tip Section
struct DriverTipSection: View {
    @Binding var selectedTip: TipOption
    @Binding var customTip: String
    
    let tipOptions: [TipOption] = [.none, .fifteenPercent, .twentyPercent, .twentyFivePercent, .custom]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(.primary)
                Text("Driver Tip")
                    .fontWeight(.semibold)
            }
            
            Text("100% of your tip goes to your driver")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(spacing: 8) {
                ForEach(tipOptions, id: \.self) { option in
                    TipButton(
                        option: option,
                        isSelected: selectedTip == option
                    ) {
                        selectedTip = option
                    }
                }
            }
            
            if selectedTip == .custom {
                HStack {
                    Text("$")
                    TextField("Enter amount", text: $customTip)
                        .keyboardType(.decimalPad)
                }
                .padding()
                .background(Color(.tertiarySystemBackground))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// MARK: - Tip Button
struct TipButton: View {
    let option: TipOption
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(option.displayText)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? Color(.systemBackground) : .primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isSelected ? Color.primary : Color(.tertiarySystemBackground))
                .cornerRadius(8)
        }
    }
}

// MARK: - Checkout Summary Section
struct CheckoutSummarySection: View {
    let subtotal: Double
    let deliveryFee: Double
    let serviceFee: Double
    let discount: Double
    let tip: Double
    let total: Double
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Order Summary")
                    .fontWeight(.semibold)
                Spacer()
            }
            
            Group {
                SummaryRow(title: "Subtotal", value: subtotal.asCurrency)
                SummaryRow(title: "Delivery Fee", value: deliveryFee == 0 ? "Free" : deliveryFee.asCurrency, highlight: deliveryFee == 0)
                SummaryRow(title: "Service Fee", value: serviceFee.asCurrency)
                
                if discount > 0 {
                    SummaryRow(title: "Discount", value: "-\(discount.asCurrency)", highlight: true)
                }
                
                if tip > 0 {
                    SummaryRow(title: "Driver Tip", value: tip.asCurrency)
                }
            }
            
            Divider()
            
            HStack {
                Text("Total")
                    .fontWeight(.bold)
                Spacer()
                Text(total.asCurrency)
                    .fontWeight(.bold)
                    .font(.title3)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// MARK: - Summary Row
struct SummaryRow: View {
    let title: String
    let value: String
    var highlight: Bool = false
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .foregroundColor(highlight ? .primary : .primary)
        }
        .font(.subheadline)
    }
}

// MARK: - Place Order Button
struct PlaceOrderButton: View {
    let total: Double
    let isLoading: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .tint(Color(.systemBackground))
                    Spacer()
                    Text("Placing Order...")
                        .fontWeight(.semibold)
                    Spacer()
                } else {
                    Text("Place Order")
                        .fontWeight(.semibold)
                    Spacer()
                    Text(total.asCurrency)
                        .fontWeight(.bold)
                }
            }
            .foregroundColor(Color(.systemBackground))
            .padding()
            .background(Color.primary)
            .cornerRadius(12)
        }
        .disabled(isLoading)
    }
}

// MARK: - Address Selector Sheet
struct AddressSelectorSheet: View {
    @Binding var selectedAddress: Address?
    @Environment(\.dismiss) private var dismiss
    @StateObject private var profileViewModel = ProfileViewModel()
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(profileViewModel.savedAddresses) { address in
                    Button {
                        selectedAddress = address
                        dismiss()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(address.label)
                                    .fontWeight(.medium)
                                Text(address.fullAddress)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if selectedAddress?.id == address.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
            .navigationTitle("Select Address")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Payment Selector Sheet
struct PaymentSelectorSheet: View {
    @Binding var selectedMethod: PaymentMethod?
    @Environment(\.dismiss) private var dismiss
    @StateObject private var profileViewModel = ProfileViewModel()
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(profileViewModel.paymentMethods) { method in
                    Button {
                        selectedMethod = method
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: method.type.icon)
                                .foregroundColor(method.type.color)
                                .frame(width: 30)
                            
                            VStack(alignment: .leading) {
                                Text(method.type.displayName)
                                    .fontWeight(.medium)
                                Text("•••• \(method.last4)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if selectedMethod?.id == method.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                }
                
                // Apple Pay option
                Button {
                    // Handle Apple Pay selection
                } label: {
                    HStack {
                        Image(systemName: "apple.logo")
                            .frame(width: 30)
                        Text("Apple Pay")
                            .fontWeight(.medium)
                        Spacer()
                    }
                }
                .foregroundColor(.primary)
            }
            .navigationTitle("Payment Method")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    CheckoutView()
        .environmentObject(CartViewModel())
}
