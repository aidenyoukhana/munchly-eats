import Foundation
import Combine
import UserNotifications

// MARK: - Service Notification Model (to avoid conflict with Views AppNotification)
struct ServiceNotification: Identifiable, Codable {
    let id: String
    let userId: String
    let title: String
    let body: String
    let type: ServiceNotificationType
    let data: [String: String]?
    var isRead: Bool
    let createdAt: Date
}

enum ServiceNotificationType: String, Codable {
    case orderUpdate = "order_update"
    case promotion = "promotion"
    case driverUpdate = "driver_update"
    case general = "general"
    case rating = "rating"
    case newRestaurant = "new_restaurant"
}

// MARK: - Notification Service
@MainActor
class NotificationService: ObservableObject {
    static let shared = NotificationService()
    
    @Published var isAuthorized = false
    @Published var notifications: [ServiceNotification] = []
    @Published var unreadCount: Int = 0
    
    private init() {
        checkAuthorizationStatus()
        loadNotifications()
    }
    
    // MARK: - Check Authorization
    private func checkAuthorizationStatus() {
        Task {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            await MainActor.run {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // MARK: - Request Permission
    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
            )
            await MainActor.run {
                self.isAuthorized = granted
            }
            return granted
        } catch {
            print("Notification permission error: \(error)")
            return false
        }
    }
    
    // MARK: - Load Notifications
    private func loadNotifications() {
        // Mock notifications
        notifications = [
            ServiceNotification(
                id: "notif_1",
                userId: "user_1",
                title: "Your order is on the way! 🚗",
                body: "Michael is picking up your order from Burger Joint",
                type: .orderUpdate,
                data: ["orderId": "order_123"],
                isRead: false,
                createdAt: Date().addingTimeInterval(-300)
            ),
            ServiceNotification(
                id: "notif_2",
                userId: "user_1",
                title: "50% Off Your First Order!",
                body: "Use code WELCOME50 at checkout. Limited time offer!",
                type: .promotion,
                data: ["promoCode": "WELCOME50"],
                isRead: true,
                createdAt: Date().addingTimeInterval(-86400)
            ),
            ServiceNotification(
                id: "notif_3",
                userId: "user_1",
                title: "Order Delivered! 🎉",
                body: "Enjoy your meal! Don't forget to rate your experience.",
                type: .orderUpdate,
                data: ["orderId": "order_122"],
                isRead: true,
                createdAt: Date().addingTimeInterval(-86400 * 2)
            )
        ]
        
        updateUnreadCount()
    }
    
    // MARK: - Update Unread Count
    private func updateUnreadCount() {
        unreadCount = notifications.filter { !$0.isRead }.count
        UNUserNotificationCenter.current().setBadgeCount(unreadCount)
    }
    
    // MARK: - Mark as Read
    func markAsRead(_ notificationId: String) {
        if let index = notifications.firstIndex(where: { $0.id == notificationId }) {
            notifications[index].isRead = true
            updateUnreadCount()
        }
    }
    
    // MARK: - Mark All as Read
    func markAllAsRead() {
        for index in notifications.indices {
            notifications[index].isRead = true
        }
        updateUnreadCount()
    }
    
    // MARK: - Delete Notification
    func deleteNotification(_ notificationId: String) {
        notifications.removeAll { $0.id == notificationId }
        updateUnreadCount()
    }
    
    // MARK: - Clear All
    func clearAll() {
        notifications.removeAll()
        updateUnreadCount()
    }
    
    // MARK: - Schedule Local Notification
    func scheduleLocalNotification(
        title: String,
        body: String,
        timeInterval: TimeInterval,
        identifier: String
    ) {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Schedule Order Update Notifications
    func scheduleOrderUpdateNotifications(orderId: String, restaurantName: String) {
        // Preparing notification (after 2 minutes)
        scheduleLocalNotification(
            title: "Your order is being prepared! 👨‍🍳",
            body: "\(restaurantName) has started preparing your order",
            timeInterval: 120,
            identifier: "\(orderId)_preparing"
        )
        
        // Driver assigned notification (after 5 minutes)
        scheduleLocalNotification(
            title: "Driver on the way! 🚗",
            body: "A driver has been assigned to pick up your order",
            timeInterval: 300,
            identifier: "\(orderId)_driver"
        )
        
        // Arriving soon notification (after 15 minutes)
        scheduleLocalNotification(
            title: "Almost there! 📍",
            body: "Your order will arrive in about 5 minutes",
            timeInterval: 900,
            identifier: "\(orderId)_arriving"
        )
    }
    
    // MARK: - Cancel Order Notifications
    func cancelOrderNotifications(orderId: String) {
        let identifiers = [
            "\(orderId)_preparing",
            "\(orderId)_driver",
            "\(orderId)_arriving"
        ]
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }
}
