import SwiftUI
import Combine

struct NotificationsView: View {
    @StateObject private var viewModel = NotificationsViewModel()
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.notifications.isEmpty {
                EmptyStateView(
                    icon: "bell.slash",
                    title: "No Notifications",
                    message: "You're all caught up!"
                )
            } else {
                List {
                    if !viewModel.todayNotifications.isEmpty {
                        Section("Today") {
                            ForEach(viewModel.todayNotifications) { notification in
                                NotificationRow(notification: notification) {
                                    viewModel.markAsRead(notification)
                                }
                            }
                        }
                    }
                    
                    if !viewModel.earlierNotifications.isEmpty {
                        Section("Earlier") {
                            ForEach(viewModel.earlierNotifications) { notification in
                                NotificationRow(notification: notification) {
                                    viewModel.markAsRead(notification)
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if !viewModel.notifications.isEmpty {
                    Button("Mark All Read") {
                        viewModel.markAllAsRead()
                    }
                    .font(.subheadline)
                }
            }
        }
        .task {
            await viewModel.loadNotifications()
        }
    }
}

// MARK: - Notification Row
struct NotificationRow: View {
    let notification: AppNotification
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(notification.type.color.opacity(0.2))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: notification.type.icon)
                        .foregroundColor(notification.type.color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(notification.title)
                            .fontWeight(notification.isRead ? .regular : .semibold)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if !notification.isRead {
                            Circle()
                                .fill(Color.primary)
                                .frame(width: 8, height: 8)
                        }
                    }
                    
                    Text(notification.message)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    Text(notification.timestamp.toRelativeString())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
    }
}

// MARK: - App Notification Model
struct AppNotification: Identifiable {
    let id: UUID
    let type: NotificationType
    let title: String
    let message: String
    let timestamp: Date
    var isRead: Bool
    let actionURL: String?
    
    enum NotificationType: String {
        case orderUpdate
        case promotion
        case delivery
        case reward
        case system
        
        var icon: String {
            switch self {
            case .orderUpdate: return "bag.fill"
            case .promotion: return "tag.fill"
            case .delivery: return "bicycle"
            case .reward: return "star.fill"
            case .system: return "bell.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .orderUpdate: return .primary
            case .promotion: return .secondary
            case .delivery: return .primary
            case .reward: return .primary
            case .system: return .secondary
            }
        }
    }
}

// MARK: - Notifications ViewModel
@MainActor
class NotificationsViewModel: ObservableObject {
    @Published var notifications: [AppNotification] = []
    @Published var isLoading = false
    
    var todayNotifications: [AppNotification] {
        notifications.filter { Calendar.current.isDateInToday($0.timestamp) }
    }
    
    var earlierNotifications: [AppNotification] {
        notifications.filter { !Calendar.current.isDateInToday($0.timestamp) }
    }
    
    func loadNotifications() async {
        isLoading = true
        
        // Simulate loading
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        notifications = [
            AppNotification(
                id: UUID(),
                type: .delivery,
                title: "Order Delivered!",
                message: "Your order from Burger Palace has been delivered. Enjoy your meal!",
                timestamp: Date().addingTimeInterval(-3600),
                isRead: false,
                actionURL: nil
            ),
            AppNotification(
                id: UUID(),
                type: .promotion,
                title: "50% Off Your Next Order",
                message: "Use code MUNCHLY50 for 50% off your next order. Valid until midnight!",
                timestamp: Date().addingTimeInterval(-7200),
                isRead: false,
                actionURL: nil
            ),
            AppNotification(
                id: UUID(),
                type: .orderUpdate,
                title: "Order Confirmed",
                message: "Your order #1234 has been confirmed and is being prepared.",
                timestamp: Date().addingTimeInterval(-86400),
                isRead: true,
                actionURL: nil
            ),
            AppNotification(
                id: UUID(),
                type: .reward,
                title: "You Earned 50 Points!",
                message: "Thanks for your recent order. You now have 350 points.",
                timestamp: Date().addingTimeInterval(-172800),
                isRead: true,
                actionURL: nil
            ),
            AppNotification(
                id: UUID(),
                type: .system,
                title: "New Restaurants Near You",
                message: "Check out 5 new restaurants that just joined MunchlyEats in your area!",
                timestamp: Date().addingTimeInterval(-259200),
                isRead: true,
                actionURL: nil
            )
        ]
        
        isLoading = false
    }
    
    func markAsRead(_ notification: AppNotification) {
        if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
            notifications[index].isRead = true
        }
    }
    
    func markAllAsRead() {
        for index in notifications.indices {
            notifications[index].isRead = true
        }
    }
}

#Preview {
    NotificationsView()
}
