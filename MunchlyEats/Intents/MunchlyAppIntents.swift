import AppIntents
import SwiftUI
import Combine

// MARK: - Order Food Intent (Siri)
@available(iOS 16.0, *)
struct OrderFoodIntent: AppIntent {
    static var title: LocalizedStringResource = "Order Food"
    static var description = IntentDescription("Order food from MunchlyEats")
    
    // Open the app when run
    static var openAppWhenRun: Bool = true
    
    @Parameter(title: "Food Item")
    var foodItem: String?
    
    @Parameter(title: "Restaurant")
    var restaurant: String?
    
    @Parameter(title: "Quantity", default: 1)
    var quantity: Int
    
    static var parameterSummary: some ParameterSummary {
        Summary("Order \(\.$quantity) \(\.$foodItem) from \(\.$restaurant)")
    }
    
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        // Store the intent data for the app to process
        let orderRequest = SiriOrderRequest(
            foodItem: foodItem ?? "",
            restaurant: restaurant ?? "",
            quantity: quantity
        )
        
        // Save to UserDefaults for the app to pick up
        if let encoded = try? JSONEncoder().encode(orderRequest) {
            UserDefaults.standard.set(encoded, forKey: "pendingSiriOrder")
        }
        
        let responseText = if let food = foodItem, !food.isEmpty {
            if let rest = restaurant, !rest.isEmpty {
                "Opening MunchlyEats to order \(quantity) \(food) from \(rest)"
            } else {
                "Opening MunchlyEats to order \(quantity) \(food)"
            }
        } else {
            "Opening MunchlyEats to place your order"
        }
        
        return .result(
            dialog: IntentDialog(stringLiteral: responseText)
        ) {
            SiriOrderSnippetView(
                foodItem: foodItem ?? "Your order",
                restaurant: restaurant ?? "MunchlyEats",
                quantity: quantity
            )
        }
    }
}

// MARK: - Reorder Last Order Intent
@available(iOS 16.0, *)
struct ReorderLastOrderIntent: AppIntent {
    static var title: LocalizedStringResource = "Reorder Last Order"
    static var description = IntentDescription("Reorder your last order from MunchlyEats")
    
    static var openAppWhenRun: Bool = true
    
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Mark that we want to reorder
        UserDefaults.standard.set(true, forKey: "pendingSiriReorder")
        
        return .result(
            dialog: "Opening MunchlyEats to reorder your last order"
        )
    }
}

// MARK: - Search Restaurant Intent
@available(iOS 16.0, *)
struct SearchRestaurantIntent: AppIntent {
    static var title: LocalizedStringResource = "Search Restaurants"
    static var description = IntentDescription("Search for restaurants on MunchlyEats")
    
    static var openAppWhenRun: Bool = true
    
    @Parameter(title: "Search Query")
    var query: String
    
    static var parameterSummary: some ParameterSummary {
        Summary("Search for \(\.$query)")
    }
    
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Store search query
        UserDefaults.standard.set(query, forKey: "pendingSiriSearch")
        
        return .result(
            dialog: "Searching for \(query) on MunchlyEats"
        )
    }
}

// MARK: - Check Order Status Intent
@available(iOS 16.0, *)
struct CheckOrderStatusIntent: AppIntent {
    static var title: LocalizedStringResource = "Check Order Status"
    static var description = IntentDescription("Check the status of your current order")
    
    static var openAppWhenRun: Bool = true
    
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        UserDefaults.standard.set(true, forKey: "pendingSiriCheckOrder")
        
        return .result(
            dialog: "Opening MunchlyEats to check your order status"
        )
    }
}

// MARK: - App Shortcuts Provider
@available(iOS 16.0, *)
struct MunchlyShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OrderFoodIntent(),
            phrases: [
                "Order food from \(.applicationName)",
                "Order dinner from \(.applicationName)",
                "Order lunch from \(.applicationName)",
                "Get food from \(.applicationName)",
                "I want food from \(.applicationName)"
            ],
            shortTitle: "Order Food",
            systemImageName: "bag.fill"
        )
        
        AppShortcut(
            intent: ReorderLastOrderIntent(),
            phrases: [
                "Reorder my last order from \(.applicationName)",
                "Order again from \(.applicationName)",
                "Repeat my last \(.applicationName) order",
                "Get my usual from \(.applicationName)"
            ],
            shortTitle: "Reorder",
            systemImageName: "arrow.clockwise"
        )
        
        AppShortcut(
            intent: SearchRestaurantIntent(),
            phrases: [
                "Find restaurants on \(.applicationName)",
                "Search restaurants on \(.applicationName)",
                "What's open on \(.applicationName)"
            ],
            shortTitle: "Search Restaurants",
            systemImageName: "magnifyingglass"
        )
        
        AppShortcut(
            intent: CheckOrderStatusIntent(),
            phrases: [
                "Check my \(.applicationName) order",
                "Where's my \(.applicationName) delivery",
                "Track my order on \(.applicationName)",
                "What's the status of my \(.applicationName) order"
            ],
            shortTitle: "Check Order",
            systemImageName: "shippingbox"
        )
    }
}

// MARK: - Siri Order Request Model
struct SiriOrderRequest: Codable {
    let foodItem: String
    let restaurant: String
    let quantity: Int
}

// MARK: - Siri Order Snippet View
@available(iOS 16.0, *)
struct SiriOrderSnippetView: View {
    let foodItem: String
    let restaurant: String
    let quantity: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bag.fill")
                    .font(.title2)
                    .foregroundColor(.orange)
                
                Text("MunchlyEats")
                    .font(.headline)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Ordering:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("\(quantity)x \(foodItem)")
                    .font(.body)
                    .fontWeight(.medium)
                
                if !restaurant.isEmpty && restaurant != "MunchlyEats" {
                    Text("from \(restaurant)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Siri Handler Service
@MainActor
class SiriIntentHandler: ObservableObject {
    static let shared = SiriIntentHandler()
    
    @Published var pendingOrder: SiriOrderRequest?
    @Published var pendingSearch: String?
    @Published var shouldReorder = false
    @Published var shouldCheckOrder = false
    @Published var hasPendingAction = false
    
    private init() {}
    
    func checkForPendingActions() {
        // Check for pending order
        if let data = UserDefaults.standard.data(forKey: "pendingSiriOrder"),
           let order = try? JSONDecoder().decode(SiriOrderRequest.self, from: data) {
            pendingOrder = order
            hasPendingAction = true
            UserDefaults.standard.removeObject(forKey: "pendingSiriOrder")
        }
        
        // Check for pending search
        if let query = UserDefaults.standard.string(forKey: "pendingSiriSearch") {
            pendingSearch = query
            hasPendingAction = true
            UserDefaults.standard.removeObject(forKey: "pendingSiriSearch")
        }
        
        // Check for reorder
        if UserDefaults.standard.bool(forKey: "pendingSiriReorder") {
            shouldReorder = true
            hasPendingAction = true
            UserDefaults.standard.removeObject(forKey: "pendingSiriReorder")
        }
        
        // Check for order status
        if UserDefaults.standard.bool(forKey: "pendingSiriCheckOrder") {
            shouldCheckOrder = true
            hasPendingAction = true
            UserDefaults.standard.removeObject(forKey: "pendingSiriCheckOrder")
        }
    }
    
    func clearPendingActions() {
        pendingOrder = nil
        pendingSearch = nil
        shouldReorder = false
        shouldCheckOrder = false
        hasPendingAction = false
    }
}
