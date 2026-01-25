import Foundation
import NaturalLanguage
import Combine

// MARK: - Parsed Order Intent
struct ParsedOrderIntent: Identifiable {
    let id = UUID()
    var items: [ParsedOrderItem]
    var restaurantHint: String?
    var cuisineHint: String?
    var priceHint: PriceRange?
    var dietaryRequirements: [String]
    var quantity: Int
    var confidence: Double
    
    enum PriceRange {
        case cheap      // under $10
        case moderate   // $10-20
        case expensive  // over $20
    }
}

struct ParsedOrderItem: Identifiable, Equatable {
    let id = UUID()
    var itemName: String
    var quantity: Int
    var customizations: [String]
    var matchedMenuItem: MenuItemDTO?
    var matchedRestaurant: RestaurantDTO?
    
    static func == (lhs: ParsedOrderItem, rhs: ParsedOrderItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Quick Order Service
@MainActor
class QuickOrderService: ObservableObject {
    static let shared = QuickOrderService()
    
    private let restaurantService = RestaurantService.shared
    private let menuService = MenuService.shared
    
    // MARK: - Keywords for NLP
    private let quantityWords: [String: Int] = [
        "one": 1, "a": 1, "an": 1, "single": 1,
        "two": 2, "couple": 2, "pair": 2,
        "three": 3, "triple": 3,
        "four": 4,
        "five": 5,
        "six": 6,
        "seven": 7,
        "eight": 8,
        "nine": 9,
        "ten": 10
    ]
    
    private let sizeWords = ["small", "medium", "large", "extra large", "xl", "regular"]
    private let dietaryWords = ["vegetarian", "vegan", "gluten-free", "gluten free", "halal", "kosher", "dairy-free", "dairy free", "nut-free", "nut free"]
    private let priceWords: [String: ParsedOrderIntent.PriceRange] = [
        "cheap": .cheap, "budget": .cheap, "affordable": .cheap, "inexpensive": .cheap,
        "moderate": .moderate, "mid-range": .moderate,
        "expensive": .expensive, "premium": .expensive, "fancy": .expensive
    ]
    
    private let cuisineTypes = ["pizza", "burger", "burgers", "sushi", "chinese", "mexican", "indian", "thai", "italian", "japanese", "korean", "vietnamese", "mediterranean", "american", "fast food", "healthy", "salad", "dessert", "coffee"]
    
    private let foodItems = [
        "pizza", "burger", "burgers", "fries", "sushi", "roll", "rolls", "taco", "tacos", "burrito",
        "noodles", "rice", "chicken", "beef", "pork", "fish", "shrimp", "pasta", "salad",
        "sandwich", "wrap", "wings", "nuggets", "soup", "curry", "pad thai", "fried rice",
        "steak", "ribs", "pulled pork", "nachos", "quesadilla", "enchiladas",
        "margherita", "pepperoni", "hawaiian", "veggie", "meat lovers",
        "california roll", "salmon", "tuna", "tempura", "gyoza", "ramen",
        "ice cream", "cake", "brownie", "cookie", "milkshake", "smoothie",
        "coffee", "latte", "cappuccino", "espresso", "tea"
    ]
    
    private init() {}
    
    // MARK: - Parse Voice Input
    func parseVoiceInput(_ input: String) async -> ParsedOrderIntent {
        let lowercased = input.lowercased()
        let tokens = tokenize(lowercased)
        
        // Extract quantity
        let quantity = extractQuantity(from: tokens)
        
        // Extract dietary requirements
        let dietary = extractDietaryRequirements(from: lowercased)
        
        // Extract price hints
        let priceHint = extractPriceHint(from: lowercased)
        
        // Extract cuisine hints
        let cuisineHint = extractCuisineHint(from: lowercased)
        
        // Extract restaurant hint
        let restaurantHint = extractRestaurantHint(from: lowercased)
        
        // Extract food items
        let parsedItems = await extractFoodItems(from: lowercased, defaultQuantity: quantity)
        
        // Calculate confidence based on matches
        let confidence = calculateConfidence(items: parsedItems, hasRestaurant: restaurantHint != nil, hasCuisine: cuisineHint != nil)
        
        return ParsedOrderIntent(
            items: parsedItems,
            restaurantHint: restaurantHint,
            cuisineHint: cuisineHint,
            priceHint: priceHint,
            dietaryRequirements: dietary,
            quantity: quantity,
            confidence: confidence
        )
    }
    
    // MARK: - Tokenization
    private func tokenize(_ text: String) -> [String] {
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = text
        
        var tokens: [String] = []
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lexicalClass) { _, range in
            let word = String(text[range])
            tokens.append(word)
            return true
        }
        return tokens
    }
    
    // MARK: - Extract Quantity
    private func extractQuantity(from tokens: [String]) -> Int {
        for token in tokens {
            if let qty = Int(token) {
                return qty
            }
            if let qty = quantityWords[token] {
                return qty
            }
        }
        return 1
    }
    
    // MARK: - Extract Dietary Requirements
    private func extractDietaryRequirements(from text: String) -> [String] {
        return dietaryWords.filter { text.contains($0) }
    }
    
    // MARK: - Extract Price Hint
    private func extractPriceHint(from text: String) -> ParsedOrderIntent.PriceRange? {
        for (word, range) in priceWords {
            if text.contains(word) {
                return range
            }
        }
        
        // Check for "under $X" pattern
        if let range = text.range(of: #"under \$?(\d+)"#, options: .regularExpression) {
            let match = String(text[range])
            if let amount = Int(match.filter { $0.isNumber }) {
                if amount <= 10 { return .cheap }
                if amount <= 20 { return .moderate }
                return .expensive
            }
        }
        
        return nil
    }
    
    // MARK: - Extract Cuisine Hint
    private func extractCuisineHint(from text: String) -> String? {
        for cuisine in cuisineTypes {
            if text.contains(cuisine) {
                return cuisine.capitalized
            }
        }
        return nil
    }
    
    // MARK: - Extract Restaurant Hint
    private func extractRestaurantHint(from text: String) -> String? {
        // Check for "from [restaurant]" pattern
        if let range = text.range(of: #"from\s+([a-zA-Z\s']+?)(?:\s+restaurant|\s+please|\s*$|,)"#, options: .regularExpression) {
            let match = String(text[range])
            let cleaned = match
                .replacingOccurrences(of: "from ", with: "")
                .replacingOccurrences(of: " restaurant", with: "")
                .replacingOccurrences(of: " please", with: "")
                .replacingOccurrences(of: ",", with: "")
                .trimmingCharacters(in: .whitespaces)
            
            if !cleaned.isEmpty && cleaned.count > 2 {
                return cleaned
            }
        }
        
        // Check against known restaurants
        for restaurant in restaurantService.restaurants {
            if text.contains(restaurant.name.lowercased()) {
                return restaurant.name
            }
        }
        
        return nil
    }
    
    // MARK: - Extract Food Items
    private func extractFoodItems(from text: String, defaultQuantity: Int) async -> [ParsedOrderItem] {
        var items: [ParsedOrderItem] = []
        var foundItems = Set<String>()
        
        // Match against known food items
        for food in foodItems {
            if text.contains(food) && !foundItems.contains(food) {
                foundItems.insert(food)
                
                // Try to find quantity specific to this item
                let itemQuantity = extractItemSpecificQuantity(for: food, in: text) ?? defaultQuantity
                
                // Extract customizations for this item
                let customizations = extractCustomizations(for: food, in: text)
                
                // Try to match with actual menu items
                let (matchedItem, matchedRestaurant) = await findMatchingMenuItem(for: food)
                
                items.append(ParsedOrderItem(
                    itemName: food.capitalized,
                    quantity: itemQuantity,
                    customizations: customizations,
                    matchedMenuItem: matchedItem,
                    matchedRestaurant: matchedRestaurant
                ))
            }
        }
        
        // If no items found, try NLP extraction
        if items.isEmpty {
            let nlpItems = extractItemsUsingNLP(from: text)
            for itemName in nlpItems {
                let (matchedItem, matchedRestaurant) = await findMatchingMenuItem(for: itemName)
                items.append(ParsedOrderItem(
                    itemName: itemName.capitalized,
                    quantity: defaultQuantity,
                    customizations: [],
                    matchedMenuItem: matchedItem,
                    matchedRestaurant: matchedRestaurant
                ))
            }
        }
        
        return items
    }
    
    // MARK: - Extract Item Specific Quantity
    private func extractItemSpecificQuantity(for item: String, in text: String) -> Int? {
        // Pattern: "[number/word] [item]"
        for (word, qty) in quantityWords {
            if text.contains("\(word) \(item)") || text.contains("\(word) \(item)s") {
                return qty
            }
        }
        
        // Check for numeric quantities
        let pattern = "(\(item))|(\\d+)\\s+\(item)"
        if let range = text.range(of: pattern, options: .regularExpression) {
            let match = String(text[range])
            if let num = Int(match.filter { $0.isNumber }), num > 0 {
                return num
            }
        }
        
        return nil
    }
    
    // MARK: - Extract Customizations
    private func extractCustomizations(for item: String, in text: String) -> [String] {
        var customizations: [String] = []
        
        // Size
        for size in sizeWords {
            if text.contains("\(size) \(item)") {
                customizations.append(size.capitalized)
                break
            }
        }
        
        // Common customizations
        let customizationKeywords = [
            "extra cheese", "no cheese", "light cheese",
            "extra sauce", "no sauce", "sauce on the side",
            "spicy", "mild", "hot",
            "no onions", "extra onions",
            "no tomato", "extra tomato",
            "well done", "medium rare", "rare",
            "with fries", "no fries",
            "with drink", "combo"
        ]
        
        for keyword in customizationKeywords {
            if text.contains(keyword) {
                customizations.append(keyword.capitalized)
            }
        }
        
        return customizations
    }
    
    // MARK: - Find Matching Menu Item
    private func findMatchingMenuItem(for itemName: String) async -> (MenuItemDTO?, RestaurantDTO?) {
        let searchTerm = itemName.lowercased()
        
        // Search through all restaurants and their menus
        for restaurant in restaurantService.restaurants {
            // Load menu if not already loaded
            if menuService.menuItems[restaurant.id] == nil {
                _ = try? await menuService.loadMenu(for: restaurant.id)
            }
            
            if let menuItems = menuService.menuItems[restaurant.id] {
                for menuItem in menuItems {
                    let itemNameLower = menuItem.name.lowercased()
                    
                    // Exact match
                    if itemNameLower == searchTerm {
                        return (menuItem, restaurant)
                    }
                    
                    // Contains match
                    if itemNameLower.contains(searchTerm) || searchTerm.contains(itemNameLower.components(separatedBy: " ").first ?? "") {
                        return (menuItem, restaurant)
                    }
                }
            }
        }
        
        return (nil, nil)
    }
    
    // MARK: - Extract Items Using NLP
    private func extractItemsUsingNLP(from text: String) -> [String] {
        let tagger = NLTagger(tagSchemes: [.nameType, .lexicalClass])
        tagger.string = text
        
        var nouns: [String] = []
        
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lexicalClass) { tag, range in
            if tag == .noun {
                let word = String(text[range])
                // Filter out common non-food words
                let skipWords = ["order", "want", "please", "need", "get", "me", "i", "from", "restaurant", "delivery"]
                if !skipWords.contains(word.lowercased()) && word.count > 2 {
                    nouns.append(word)
                }
            }
            return true
        }
        
        return nouns
    }
    
    // MARK: - Calculate Confidence
    private func calculateConfidence(items: [ParsedOrderItem], hasRestaurant: Bool, hasCuisine: Bool) -> Double {
        var confidence = 0.3 // Base confidence
        
        // Items found
        if !items.isEmpty {
            confidence += 0.3
        }
        
        // Items matched to menu
        let matchedItems = items.filter { $0.matchedMenuItem != nil }
        if !matchedItems.isEmpty {
            confidence += 0.2 * (Double(matchedItems.count) / Double(max(items.count, 1)))
        }
        
        // Restaurant hint
        if hasRestaurant {
            confidence += 0.1
        }
        
        // Cuisine hint
        if hasCuisine {
            confidence += 0.1
        }
        
        return min(confidence, 1.0)
    }
    
    // MARK: - Generate Confirmation Message
    func generateConfirmationMessage(for intent: ParsedOrderIntent) -> String {
        guard !intent.items.isEmpty else {
            return "I'm sorry, I couldn't understand your order. Could you please try again? For example, say 'Order two pepperoni pizzas from Tony's Pizzeria'."
        }
        
        var message = "I'll order "
        
        // List items
        let itemDescriptions = intent.items.map { item -> String in
            var desc = "\(item.quantity) \(item.itemName)"
            if let matched = item.matchedMenuItem {
                desc += " ($\(String(format: "%.2f", matched.price)) each)"
            }
            if !item.customizations.isEmpty {
                desc += " - \(item.customizations.joined(separator: ", "))"
            }
            return desc
        }
        
        message += itemDescriptions.joined(separator: ", and ")
        
        // Add restaurant info
        if let restaurant = intent.items.first?.matchedRestaurant {
            message += " from \(restaurant.name)"
        } else if let hint = intent.restaurantHint {
            message += " from \(hint)"
        } else if let cuisine = intent.cuisineHint {
            message += " (\(cuisine) cuisine)"
        }
        
        // Calculate total
        let total = intent.items.reduce(0.0) { sum, item in
            if let menuItem = item.matchedMenuItem {
                return sum + (menuItem.price * Double(item.quantity))
            }
            return sum
        }
        
        if total > 0 {
            message += ". Your subtotal will be $\(String(format: "%.2f", total))"
        }
        
        message += ". Would you like me to add this to your cart?"
        
        return message
    }
    
    // MARK: - Generate Search Response
    func generateSearchResponse(for query: String, results: [RestaurantDTO]) -> String {
        if results.isEmpty {
            return "I couldn't find any restaurants matching '\(query)'. Try searching for a different cuisine or restaurant name."
        }
        
        let topResults = Array(results.prefix(3))
        let names = topResults.map { "\($0.name) (\($0.rating)⭐)" }
        
        return "I found \(results.count) restaurant\(results.count == 1 ? "" : "s"). Top picks: \(names.joined(separator: ", "))"
    }
}

// MARK: - AI Search Extension for SearchViewModel
extension SearchViewModel {
    func aiSearch(_ query: String) async -> [RestaurantDTO] {
        let lowercased = query.lowercased()
        let service = RestaurantService.shared
        
        // Parse natural language query
        var filteredResults = service.restaurants
        
        // Price filters
        if lowercased.contains("cheap") || lowercased.contains("budget") || lowercased.contains("under $10") {
            filteredResults = filteredResults.filter { $0.minimumOrder < 15 }
        } else if lowercased.contains("under $15") {
            filteredResults = filteredResults.filter { $0.minimumOrder < 15 }
        } else if lowercased.contains("under $20") {
            filteredResults = filteredResults.filter { $0.minimumOrder < 20 }
        }
        
        // Delivery time filters
        if lowercased.contains("fast") || lowercased.contains("quick") || lowercased.contains("soon") {
            filteredResults = filteredResults.filter { restaurant in
                // Parse delivery time and filter for < 30 min
                let timeString = restaurant.deliveryTime.lowercased()
                if let range = timeString.range(of: "\\d+", options: .regularExpression) {
                    if let minTime = Int(timeString[range]) {
                        return minTime < 30
                    }
                }
                return true
            }
        }
        
        // Rating filters
        if lowercased.contains("best") || lowercased.contains("top rated") || lowercased.contains("highly rated") {
            filteredResults = filteredResults.filter { $0.rating >= 4.5 }
                .sorted { $0.rating > $1.rating }
        }
        
        // Distance filters
        if lowercased.contains("nearby") || lowercased.contains("close") || lowercased.contains("near me") {
            filteredResults = filteredResults.filter { $0.distance < 2.0 }
                .sorted { $0.distance < $1.distance }
        }
        
        // Cuisine type search
        let cuisines = ["pizza", "burger", "sushi", "chinese", "mexican", "indian", "thai", "italian", "japanese", "healthy", "salad", "fast food", "american"]
        for cuisine in cuisines {
            if lowercased.contains(cuisine) {
                filteredResults = filteredResults.filter { restaurant in
                    restaurant.cuisineTypes.contains { $0.lowercased().contains(cuisine) }
                }
                break
            }
        }
        
        // Keyword search (if no specific filters matched)
        if filteredResults.count == service.restaurants.count {
            filteredResults = service.searchRestaurants(query: query)
        }
        
        return filteredResults
    }
}
