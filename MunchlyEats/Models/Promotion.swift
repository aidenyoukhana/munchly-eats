import Foundation
import Combine

// MARK: - Promotion
struct Promotion: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let imageURL: String
    let promoCode: String?
    let discountPercentage: Double?
    let restaurantId: String?
    let validFrom: Date
    let validUntil: Date
    let termsAndConditions: String
    
    var isActive: Bool {
        let now = Date()
        return now >= validFrom && now <= validUntil
    }
}

struct PromotionDTO: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let imageURL: String
    let promoCode: String?
    let discountPercentage: Double?
    let restaurantId: String?
    let validFrom: String
    let validUntil: String
    let termsAndConditions: String
    
    func toPromotion() -> Promotion {
        let formatter = ISO8601DateFormatter()
        return Promotion(
            id: id,
            title: title,
            description: description,
            imageURL: imageURL,
            promoCode: promoCode,
            discountPercentage: discountPercentage,
            restaurantId: restaurantId,
            validFrom: formatter.date(from: validFrom) ?? Date(),
            validUntil: formatter.date(from: validUntil) ?? Date(),
            termsAndConditions: termsAndConditions
        )
    }
}

// MARK: - Review
struct Review: Codable, Identifiable {
    let id: String
    let userId: String
    let userName: String
    let userImageURL: String?
    let restaurantId: String?
    let orderId: String?
    let driverId: String?
    let rating: Int
    let comment: String
    let images: [String]
    let createdAt: Date
    let response: String?
    let responseDate: Date?
}

struct ReviewDTO: Codable, Identifiable {
    let id: String
    let userId: String
    let userName: String
    let userImageURL: String?
    let restaurantId: String?
    let orderId: String?
    let driverId: String?
    let rating: Int
    let comment: String
    let images: [String]
    let createdAt: String
    let response: String?
    let responseDate: String?
    
    func toReview() -> Review {
        let formatter = ISO8601DateFormatter()
        return Review(
            id: id,
            userId: userId,
            userName: userName,
            userImageURL: userImageURL,
            restaurantId: restaurantId,
            orderId: orderId,
            driverId: driverId,
            rating: rating,
            comment: comment,
            images: images,
            createdAt: formatter.date(from: createdAt) ?? Date(),
            response: response,
            responseDate: responseDate.flatMap { formatter.date(from: $0) }
        )
    }
}

// MARK: - Notification DTO (for API responses)
struct NotificationDTO: Codable, Identifiable {
    let id: String
    let userId: String
    let title: String
    let body: String
    let type: String
    let data: [String: String]?
    let isRead: Bool
    let createdAt: String
}
