import Foundation
import Combine
import SwiftData

@Model
final class PaymentMethod {
    @Attribute(.unique) var id: String
    var type: PaymentType
    var last4: String
    var brand: String
    var expiryMonth: Int
    var expiryYear: Int
    var holderName: String
    var isDefault: Bool
    var billingAddressId: String?
    
    var displayName: String {
        "\(brand) •••• \(last4)"
    }
    
    var expiryDisplay: String {
        String(format: "%02d/%02d", expiryMonth, expiryYear % 100)
    }
    
    init(
        id: String = UUID().uuidString,
        type: PaymentType,
        last4: String,
        brand: String,
        expiryMonth: Int,
        expiryYear: Int,
        holderName: String,
        isDefault: Bool = false,
        billingAddressId: String? = nil
    ) {
        self.id = id
        self.type = type
        self.last4 = last4
        self.brand = brand
        self.expiryMonth = expiryMonth
        self.expiryYear = expiryYear
        self.holderName = holderName
        self.isDefault = isDefault
        self.billingAddressId = billingAddressId
    }
}

enum PaymentType: String, Codable, CaseIterable {
    case creditCard = "Credit Card"
    case debitCard = "Debit Card"
    case applePay = "Apple Pay"
    case googlePay = "Google Pay"
    case paypal = "PayPal"
    case cash = "Cash"
    
    var icon: String {
        switch self {
        case .creditCard, .debitCard: return "creditcard.fill"
        case .applePay: return "apple.logo"
        case .googlePay: return "g.circle.fill"
        case .paypal: return "p.circle.fill"
        case .cash: return "banknote.fill"
        }
    }
}

// MARK: - Payment Method DTO
struct PaymentMethodDTO: Codable, Identifiable {
    let id: String
    let type: String
    let last4: String
    let brand: String
    let expiryMonth: Int
    let expiryYear: Int
    let holderName: String
    let isDefault: Bool
    
    func toPaymentMethod() -> PaymentMethod {
        PaymentMethod(
            id: id,
            type: PaymentType(rawValue: type) ?? .creditCard,
            last4: last4,
            brand: brand,
            expiryMonth: expiryMonth,
            expiryYear: expiryYear,
            holderName: holderName,
            isDefault: isDefault
        )
    }
}
