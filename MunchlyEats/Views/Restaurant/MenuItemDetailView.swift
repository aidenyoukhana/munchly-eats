import SwiftUI

struct MenuItemDetailView: View {
    let menuItem: MenuItem
    let restaurant: Restaurant
    @EnvironmentObject var cartViewModel: CartViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var quantity: Int = 1
    @State private var selectedCustomizations: [String: [String]] = [:]
    @State private var specialInstructions: String = ""
    
    var totalPrice: Double {
        var price = menuItem.price
        for (groupId, selections) in selectedCustomizations {
            if let group = menuItem.customizationOptions.first(where: { $0.id == groupId }) {
                for selection in selections {
                    if let option = group.options.first(where: { $0.name == selection }) {
                        price += option.price
                    }
                }
            }
        }
        return price * Double(quantity)
    }
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Item Image
                    AsyncImageView(url: menuItem.imageURL)
                        .frame(height: 250)
                        .clipped()
                    
                    VStack(alignment: .leading, spacing: 16) {
                        // Item Info
                        VStack(alignment: .leading, spacing: 8) {
                            Text(menuItem.name)
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Text(menuItem.menuItemDescription)
                                .font(.body)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Text(menuItem.price.asCurrency)
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                
                                if let calories = menuItem.calories {
                                    Text("•")
                                        .foregroundColor(.secondary)
                                    Text("\(calories) cal")
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            // Dietary Tags
                            if !menuItem.allergens.isEmpty {
                                HStack(spacing: 8) {
                                    ForEach(menuItem.allergens, id: \.self) { info in
                                        DietaryTag(text: info)
                                    }
                                }
                            }
                        }
                        .padding()
                        
                        Divider()
                        
                        // Customizations
                        if !menuItem.customizationOptions.isEmpty {
                            ForEach(menuItem.customizationOptions) { group in
                                CustomizationGroupView(
                                    group: group,
                                    selections: Binding(
                                        get: { selectedCustomizations[group.id] ?? [] },
                                        set: { selectedCustomizations[group.id] = $0 }
                                    )
                                )
                            }
                        }
                        
                        // Special Instructions
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Special Instructions")
                                .font(.headline)
                            
                            TextField("Add a note (allergies, preferences, etc.)", text: $specialInstructions, axis: .vertical)
                                .lineLimit(3...5)
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(12)
                        }
                        .padding()
                        
                        // Quantity Selector
                        HStack {
                            Text("Quantity")
                                .font(.headline)
                            
                            Spacer()
                            
                            QuantitySelector(quantity: $quantity)
                        }
                        .padding()
                    }
                }
                .padding(.bottom, 120)
            }
            
            // Add to Cart Button
            VStack {
                Spacer()
                
                Button {
                    addToCart()
                } label: {
                    HStack {
                        Text("Add to Cart")
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Text(totalPrice.asCurrency)
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
        .navigationTitle(menuItem.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                CartToolbarButton()
            }
        }
    }
    
    private func addToCart() {
        var customizationsList: [SelectedCustomization] = []
        
        for (groupId, selections) in selectedCustomizations {
            if let group = menuItem.customizationOptions.first(where: { $0.id == groupId }) {
                for selection in selections {
                    if let option = group.options.first(where: { $0.name == selection }) {
                        customizationsList.append(SelectedCustomization(
                            id: option.id,
                            groupName: group.name,
                            optionName: option.name,
                            price: option.price
                        ))
                    }
                }
            }
        }
        
        cartViewModel.addItem(
            menuItem: menuItem.toDTO(),
            restaurant: restaurant.toDTO(),
            quantity: quantity,
            specialInstructions: specialInstructions.isEmpty ? nil : specialInstructions,
            selectedCustomizations: customizationsList
        )
        
        // Show toast and dismiss
        ToastManager.shared.showSuccess("Added to Cart", message: "\(quantity)x \(menuItem.name)")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            dismiss()
        }
    }
}

// MARK: - Dietary Tag
struct DietaryTag: View {
    let text: String
    
    var icon: String {
        switch text.lowercased() {
        case "vegetarian": return "leaf.fill"
        case "vegan": return "leaf.circle.fill"
        case "gluten-free": return "g.circle.fill"
        case "spicy": return "flame.fill"
        default: return "checkmark.circle.fill"
        }
    }
    
    var color: Color {
        switch text.lowercased() {
        case "vegetarian", "vegan": return .primary
        case "gluten-free": return .secondary
        case "spicy": return .secondary
        default: return .secondary
        }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .font(.caption)
        }
        .foregroundColor(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.15))
        .cornerRadius(8)
    }
}

// MARK: - Customization Group View
struct CustomizationGroupView: View {
    let group: CustomizationGroup
    @Binding var selections: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(group.name)
                    .font(.headline)
                
                if group.isRequired {
                    Text("Required")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if group.maxSelections > 1 {
                    Text("Select up to \(group.maxSelections)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            ForEach(group.options) { option in
                CustomizationOptionRow(
                    option: option,
                    isSelected: selections.contains(option.name),
                    isMultiSelect: group.maxSelections > 1
                ) {
                    toggleSelection(option.name)
                }
            }
        }
        .padding()
        
        Divider()
    }
    
    private func toggleSelection(_ name: String) {
        if group.maxSelections == 1 {
            // Single selection
            selections = [name]
        } else {
            // Multi selection
            if selections.contains(name) {
                selections.removeAll { $0 == name }
            } else if selections.count < group.maxSelections {
                selections.append(name)
            }
        }
    }
}

// MARK: - Customization Option Row
struct CustomizationOptionRow: View {
    let option: CustomizationOption
    let isSelected: Bool
    let isMultiSelect: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: isMultiSelect ?
                      (isSelected ? "checkmark.square.fill" : "square") :
                      (isSelected ? "largecircle.fill.circle" : "circle"))
                    .foregroundColor(isSelected ? .primary : .secondary)
                
                Text(option.name)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if option.price > 0 {
                    Text("+\(option.price.asCurrency)")
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Quantity Selector
struct QuantitySelector: View {
    @Binding var quantity: Int
    
    var body: some View {
        HStack(spacing: 20) {
            Button {
                if quantity > 1 {
                    quantity -= 1
                }
            } label: {
                Image(systemName: "minus")
                    .fontWeight(.semibold)
                    .foregroundColor(quantity > 1 ? .primary : .secondary)
                    .frame(width: 36, height: 36)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
            }
            .disabled(quantity <= 1)
            
            Text("\(quantity)")
                .font(.title3)
                .fontWeight(.semibold)
                .frame(width: 40)
            
            Button {
                if quantity < 99 {
                    quantity += 1
                }
            } label: {
                Image(systemName: "plus")
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .frame(width: 36, height: 36)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
            }
        }
    }
}

#Preview {
    MenuItemDetailView(
        menuItem: MenuItem(
            id: UUID().uuidString,
            restaurantId: UUID().uuidString,
            name: "Classic Cheeseburger",
            menuItemDescription: "Juicy beef patty with melted cheddar, lettuce, tomato, and our special sauce",
            price: 12.99,
            imageURL: "https://images.unsplash.com/photo-1568901346375-23c9450c58cd",
            category: "Burgers",
            isPopular: true,
            isAvailable: true,
            calories: 650,
            preparationTime: "15 min",
            ingredients: ["Beef", "Cheese", "Lettuce", "Tomato"],
            allergens: ["Gluten", "Dairy"],
            customizationOptions: [
                CustomizationGroup(
                    id: UUID().uuidString,
                    name: "Patty",
                    isRequired: true,
                    maxSelections: 1,
                    options: [
                        CustomizationOption(id: UUID().uuidString, name: "Single", price: 0),
                        CustomizationOption(id: UUID().uuidString, name: "Double", price: 4.0)
                    ]
                ),
                CustomizationGroup(
                    id: UUID().uuidString,
                    name: "Toppings",
                    isRequired: false,
                    maxSelections: 3,
                    options: [
                        CustomizationOption(id: UUID().uuidString, name: "Extra Cheese", price: 1.0),
                        CustomizationOption(id: UUID().uuidString, name: "Bacon", price: 2.0),
                        CustomizationOption(id: UUID().uuidString, name: "Avocado", price: 1.5)
                    ]
                )
            ]
        ),
        restaurant: Restaurant(
            id: UUID().uuidString,
            name: "Burger Palace",
            restaurantDescription: "The best burgers in town",
            imageURL: "https://images.unsplash.com/photo-1568901346375-23c9450c58cd",
            coverImageURL: "https://images.unsplash.com/photo-1568901346375-23c9450c58cd",
            rating: 4.7,
            reviewCount: 234,
            deliveryTime: "25-35 min",
            deliveryFee: 2.99,
            minimumOrder: 15.0,
            distance: 1.2,
            cuisineTypes: ["Burgers", "American"],
            address: "123 Main St",
            latitude: 37.7749,
            longitude: -122.4194,
            isOpen: true
        )
    )
    .environmentObject(CartViewModel())
}
