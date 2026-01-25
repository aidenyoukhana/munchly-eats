import SwiftUI

struct PaymentMethodsView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @State private var showAddCard = false
    
    var body: some View {
        Group {
            if viewModel.paymentMethods.isEmpty {
                EmptyStateView(
                    icon: "creditcard.trianglebadge.exclamationmark",
                    title: "No Payment Methods",
                    message: "Add a payment method for faster checkout"
                )
            } else {
                List {
                    ForEach(viewModel.paymentMethods) { method in
                        PaymentMethodRow(
                            method: method,
                            onSetDefault: {
                                Task {
                                    viewModel.setDefaultPaymentMethod(method.id)
                                }
                            }
                        )
                    }
                    .onDelete { indexSet in
                        Task {
                            for index in indexSet {
                                viewModel.deletePaymentMethod(viewModel.paymentMethods[index].id)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Payment Methods")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showAddCard = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddCard) {
            AddPaymentMethodView(viewModel: viewModel)
        }
    }
}

// MARK: - Payment Method Row
struct PaymentMethodRow: View {
    let method: PaymentMethod
    let onSetDefault: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: method.type.icon)
                .font(.title2)
                .foregroundColor(method.type.color)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(method.type.displayName)
                        .fontWeight(.medium)
                    
                    if method.isDefault {
                        Text("Default")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(Color(.systemBackground))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.primary)
                            .clipShape(Capsule())
                    }
                }
                
                Text("•••• \(method.last4)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("Expires \(method.expiryDisplay)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if !method.isDefault {
                Menu {
                    Button {
                        onSetDefault()
                    } label: {
                        Label("Set as Default", systemImage: "star")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Add Payment Method View
struct AddPaymentMethodView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedType: PaymentType = .creditCard
    @State private var cardNumber: String = ""
    @State private var cardholderName: String = ""
    @State private var expiryMonth: String = ""
    @State private var expiryYear: String = ""
    @State private var cvv: String = ""
    @State private var setAsDefault: Bool = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Payment Type") {
                    Picker("Type", selection: $selectedType) {
                        ForEach([PaymentType.creditCard, PaymentType.debitCard], id: \.self) { type in
                            Label(type.displayName, systemImage: type.icon)
                                .tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Card Details") {
                    TextField("Card Number", text: $cardNumber)
                        .keyboardType(.numberPad)
                        .onChange(of: cardNumber) { _, newValue in
                            cardNumber = formatCardNumber(newValue)
                        }
                    
                    TextField("Cardholder Name", text: $cardholderName)
                        .textContentType(.name)
                    
                    HStack {
                        TextField("MM", text: $expiryMonth)
                            .keyboardType(.numberPad)
                            .frame(width: 50)
                        
                        Text("/")
                            .foregroundColor(.secondary)
                        
                        TextField("YY", text: $expiryYear)
                            .keyboardType(.numberPad)
                            .frame(width: 50)
                        
                        Spacer()
                        
                        SecureField("CVV", text: $cvv)
                            .keyboardType(.numberPad)
                            .frame(width: 80)
                    }
                }
                
                Section {
                    Toggle("Set as default payment method", isOn: $setAsDefault)
                }
                
                Section {
                    HStack {
                        Image(systemName: "lock.shield.fill")
                            .foregroundColor(.primary)
                        Text("Your payment information is encrypted and secure")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Add Payment Method")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addPaymentMethod()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isValid)
                }
            }
        }
    }
    
    private var isValid: Bool {
        cardNumber.replacingOccurrences(of: " ", with: "").count >= 15 &&
        !cardholderName.isEmpty &&
        expiryMonth.count == 2 &&
        expiryYear.count == 2 &&
        cvv.count >= 3
    }
    
    private func formatCardNumber(_ number: String) -> String {
        let digits = number.filter { $0.isNumber }
        let limited = String(digits.prefix(16))
        
        var formatted = ""
        for (index, char) in limited.enumerated() {
            if index > 0 && index % 4 == 0 {
                formatted += " "
            }
            formatted.append(char)
        }
        return formatted
    }
    
    private func addPaymentMethod() {
        Task {
            let lastFour = String(cardNumber.replacingOccurrences(of: " ", with: "").suffix(4))
            let monthInt = Int(expiryMonth) ?? 1
            let yearInt = Int(expiryYear) ?? 25
            
            let method = PaymentMethod(
                type: selectedType,
                last4: lastFour,
                brand: selectedType == .creditCard ? "Visa" : "Debit",
                expiryMonth: monthInt,
                expiryYear: 2000 + yearInt,
                holderName: cardholderName,
                isDefault: setAsDefault
            )
            viewModel.addPaymentMethod(method)
            dismiss()
        }
    }
}

// MARK: - Payment Type Extensions
extension PaymentType {
    var displayName: String {
        switch self {
        case .creditCard: return "Credit Card"
        case .debitCard: return "Debit Card"
        case .applePay: return "Apple Pay"
        case .googlePay: return "Google Pay"
        case .paypal: return "PayPal"
        case .cash: return "Cash"
        }
    }
    
    var color: Color {
        switch self {
        case .creditCard: return .primary
        case .debitCard: return .primary
        case .applePay: return .primary
        case .googlePay: return .primary
        case .paypal: return .primary
        case .cash: return .primary
        }
    }
}

#Preview {
    PaymentMethodsView(viewModel: ProfileViewModel())
}
