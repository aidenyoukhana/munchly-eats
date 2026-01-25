import Foundation
import Combine

// MARK: - Menu Service
@MainActor
class MenuService: ObservableObject {
    static let shared = MenuService()
    
    @Published var menuItems: [String: [MenuItemDTO]] = [:] // restaurantId -> items
    @Published var isLoading = false
    @Published var error: Error?
    
    private init() {}
    
    // MARK: - Load Menu for Restaurant
    func loadMenu(for restaurantId: String) async throws -> [MenuItemDTO] {
        if let cachedItems = menuItems[restaurantId] {
            return cachedItems
        }
        
        isLoading = true
        defer { isLoading = false }
        
        // Simulate API call
        try await Task.sleep(nanoseconds: 500_000_000)
        
        let items = generateMenuItems(for: restaurantId)
        menuItems[restaurantId] = items
        
        return items
    }
    
    // MARK: - Get Menu Item by ID
    func getMenuItem(id: String, restaurantId: String) -> MenuItemDTO? {
        return menuItems[restaurantId]?.first { $0.id == id }
    }
    
    // MARK: - Generate Menu Items (Mock Data)
    private func generateMenuItems(for restaurantId: String) -> [MenuItemDTO] {
        switch restaurantId {
        case "rest_1": // Tony's Pizzeria
            return [
                MenuItemDTO(
                    id: "item_1_1",
                    restaurantId: restaurantId,
                    name: "Margherita Pizza",
                    description: "Classic tomato sauce, fresh mozzarella, basil, and olive oil on our signature crust.",
                    price: 16.99,
                    imageURL: "https://images.unsplash.com/photo-1574071318508-1cdbab80d002?w=400",
                    category: "Pizzas",
                    isPopular: true,
                    isAvailable: true,
                    calories: 850,
                    preparationTime: "15-20 min",
                    ingredients: ["Tomato sauce", "Fresh mozzarella", "Basil", "Olive oil"],
                    allergens: ["Gluten", "Dairy"],
                    customizationOptions: pizzaCustomizations
                ),
                MenuItemDTO(
                    id: "item_1_2",
                    restaurantId: restaurantId,
                    name: "Pepperoni Pizza",
                    description: "Loaded with premium pepperoni, mozzarella cheese, and our house tomato sauce.",
                    price: 18.99,
                    imageURL: "https://images.unsplash.com/photo-1628840042765-356cda07504e?w=400",
                    category: "Pizzas",
                    isPopular: true,
                    isAvailable: true,
                    calories: 980,
                    preparationTime: "15-20 min",
                    ingredients: ["Tomato sauce", "Mozzarella", "Pepperoni"],
                    allergens: ["Gluten", "Dairy"],
                    customizationOptions: pizzaCustomizations
                ),
                MenuItemDTO(
                    id: "item_1_3",
                    restaurantId: restaurantId,
                    name: "BBQ Chicken Pizza",
                    description: "Grilled chicken, red onions, cilantro, and tangy BBQ sauce with mozzarella.",
                    price: 20.99,
                    imageURL: "https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=400",
                    category: "Pizzas",
                    isPopular: false,
                    isAvailable: true,
                    calories: 920,
                    preparationTime: "18-25 min",
                    ingredients: ["BBQ sauce", "Grilled chicken", "Red onions", "Cilantro", "Mozzarella"],
                    allergens: ["Gluten", "Dairy"],
                    customizationOptions: pizzaCustomizations
                ),
                MenuItemDTO(
                    id: "item_1_4",
                    restaurantId: restaurantId,
                    name: "Garlic Knots",
                    description: "Fresh baked knots brushed with garlic butter and parmesan. Served with marinara.",
                    price: 6.99,
                    imageURL: "https://images.unsplash.com/photo-1509722747041-616f39b57569?w=400",
                    category: "Appetizers",
                    isPopular: true,
                    isAvailable: true,
                    calories: 380,
                    preparationTime: "10-12 min",
                    ingredients: ["Flour", "Garlic butter", "Parmesan", "Herbs"],
                    allergens: ["Gluten", "Dairy"],
                    customizationOptions: []
                ),
                MenuItemDTO(
                    id: "item_1_5",
                    restaurantId: restaurantId,
                    name: "Caesar Salad",
                    description: "Crisp romaine, parmesan, croutons, and our house Caesar dressing.",
                    price: 9.99,
                    imageURL: "https://images.unsplash.com/photo-1546793665-c74683f339c1?w=400",
                    category: "Salads",
                    isPopular: false,
                    isAvailable: true,
                    calories: 320,
                    preparationTime: "5-8 min",
                    ingredients: ["Romaine lettuce", "Parmesan", "Croutons", "Caesar dressing"],
                    allergens: ["Gluten", "Dairy", "Eggs"],
                    customizationOptions: saladCustomizations
                ),
                MenuItemDTO(
                    id: "item_1_6",
                    restaurantId: restaurantId,
                    name: "Tiramisu",
                    description: "Classic Italian dessert with layers of espresso-soaked ladyfingers and mascarpone cream.",
                    price: 8.99,
                    imageURL: "https://images.unsplash.com/photo-1571877227200-a0d98ea607e9?w=400",
                    category: "Desserts",
                    isPopular: true,
                    isAvailable: true,
                    calories: 450,
                    preparationTime: "5 min",
                    ingredients: ["Ladyfingers", "Mascarpone", "Espresso", "Cocoa"],
                    allergens: ["Gluten", "Dairy", "Eggs"],
                    customizationOptions: []
                )
            ]
            
        case "rest_2": // Burger Joint
            return [
                MenuItemDTO(
                    id: "item_2_1",
                    restaurantId: restaurantId,
                    name: "Classic Smash Burger",
                    description: "Double smashed beef patties, American cheese, lettuce, tomato, pickles, and special sauce.",
                    price: 12.99,
                    imageURL: "https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=400",
                    category: "Burgers",
                    isPopular: true,
                    isAvailable: true,
                    calories: 780,
                    preparationTime: "12-15 min",
                    ingredients: ["Beef patties", "American cheese", "Lettuce", "Tomato", "Pickles", "Special sauce"],
                    allergens: ["Gluten", "Dairy"],
                    customizationOptions: burgerCustomizations
                ),
                MenuItemDTO(
                    id: "item_2_2",
                    restaurantId: restaurantId,
                    name: "Bacon BBQ Burger",
                    description: "Juicy beef patty, crispy bacon, cheddar cheese, onion rings, and smoky BBQ sauce.",
                    price: 14.99,
                    imageURL: "https://images.unsplash.com/photo-1553979459-d2229ba7433b?w=400",
                    category: "Burgers",
                    isPopular: true,
                    isAvailable: true,
                    calories: 920,
                    preparationTime: "15-18 min",
                    ingredients: ["Beef patty", "Bacon", "Cheddar", "Onion rings", "BBQ sauce"],
                    allergens: ["Gluten", "Dairy"],
                    customizationOptions: burgerCustomizations
                ),
                MenuItemDTO(
                    id: "item_2_3",
                    restaurantId: restaurantId,
                    name: "Mushroom Swiss Burger",
                    description: "Beef patty topped with sautéed mushrooms and melted Swiss cheese.",
                    price: 13.99,
                    imageURL: "https://images.unsplash.com/photo-1572802419224-296b0aeee0d9?w=400",
                    category: "Burgers",
                    isPopular: false,
                    isAvailable: true,
                    calories: 750,
                    preparationTime: "12-15 min",
                    ingredients: ["Beef patty", "Mushrooms", "Swiss cheese"],
                    allergens: ["Gluten", "Dairy"],
                    customizationOptions: burgerCustomizations
                ),
                MenuItemDTO(
                    id: "item_2_4",
                    restaurantId: restaurantId,
                    name: "Crispy Chicken Sandwich",
                    description: "Crispy fried chicken breast, pickles, and spicy mayo on a brioche bun.",
                    price: 11.99,
                    imageURL: "https://images.unsplash.com/photo-1606755962773-d324e0a13086?w=400",
                    category: "Sandwiches",
                    isPopular: true,
                    isAvailable: true,
                    calories: 680,
                    preparationTime: "10-15 min",
                    ingredients: ["Fried chicken", "Pickles", "Spicy mayo", "Brioche bun"],
                    allergens: ["Gluten", "Eggs"],
                    customizationOptions: []
                ),
                MenuItemDTO(
                    id: "item_2_5",
                    restaurantId: restaurantId,
                    name: "Loaded Fries",
                    description: "Crispy fries topped with cheese sauce, bacon bits, jalapeños, and sour cream.",
                    price: 8.99,
                    imageURL: "https://images.unsplash.com/photo-1630384060421-cb20d0e0649d?w=400",
                    category: "Sides",
                    isPopular: true,
                    isAvailable: true,
                    calories: 520,
                    preparationTime: "8-10 min",
                    ingredients: ["Fries", "Cheese sauce", "Bacon", "Jalapeños", "Sour cream"],
                    allergens: ["Dairy"],
                    customizationOptions: []
                ),
                MenuItemDTO(
                    id: "item_2_6",
                    restaurantId: restaurantId,
                    name: "Milkshake",
                    description: "Thick and creamy milkshake made with real ice cream. Choose your flavor.",
                    price: 6.99,
                    imageURL: "https://images.unsplash.com/photo-1572490122747-3968b75cc699?w=400",
                    category: "Drinks",
                    isPopular: false,
                    isAvailable: true,
                    calories: 480,
                    preparationTime: "3-5 min",
                    ingredients: ["Ice cream", "Milk", "Whipped cream"],
                    allergens: ["Dairy"],
                    customizationOptions: milkshakeCustomizations
                )
            ]
            
        case "rest_3": // Sakura Sushi
            return [
                MenuItemDTO(
                    id: "item_3_1",
                    restaurantId: restaurantId,
                    name: "Dragon Roll",
                    description: "Shrimp tempura, cucumber inside, topped with eel, avocado, and eel sauce.",
                    price: 16.99,
                    imageURL: "https://images.unsplash.com/photo-1579871494447-9811cf80d66c?w=400",
                    category: "Specialty Rolls",
                    isPopular: true,
                    isAvailable: true,
                    calories: 450,
                    preparationTime: "15-20 min",
                    ingredients: ["Shrimp tempura", "Cucumber", "Eel", "Avocado", "Eel sauce"],
                    allergens: ["Shellfish", "Gluten", "Soy"],
                    customizationOptions: sushiCustomizations
                ),
                MenuItemDTO(
                    id: "item_3_2",
                    restaurantId: restaurantId,
                    name: "Rainbow Roll",
                    description: "California roll topped with assorted fresh sashimi including tuna, salmon, and yellowtail.",
                    price: 18.99,
                    imageURL: "https://images.unsplash.com/photo-1617196034796-73dfa7b1fd56?w=400",
                    category: "Specialty Rolls",
                    isPopular: true,
                    isAvailable: true,
                    calories: 380,
                    preparationTime: "15-20 min",
                    ingredients: ["Crab", "Avocado", "Cucumber", "Tuna", "Salmon", "Yellowtail"],
                    allergens: ["Shellfish", "Fish", "Soy"],
                    customizationOptions: sushiCustomizations
                ),
                MenuItemDTO(
                    id: "item_3_3",
                    restaurantId: restaurantId,
                    name: "Salmon Sashimi",
                    description: "8 pieces of premium fresh salmon, expertly sliced.",
                    price: 14.99,
                    imageURL: "https://images.unsplash.com/photo-1534482421-64566f976cfa?w=400",
                    category: "Sashimi",
                    isPopular: true,
                    isAvailable: true,
                    calories: 180,
                    preparationTime: "10-12 min",
                    ingredients: ["Fresh salmon"],
                    allergens: ["Fish"],
                    customizationOptions: []
                ),
                MenuItemDTO(
                    id: "item_3_4",
                    restaurantId: restaurantId,
                    name: "Miso Soup",
                    description: "Traditional Japanese soup with tofu, wakame seaweed, and green onions.",
                    price: 4.99,
                    imageURL: "https://images.unsplash.com/photo-1547592166-23ac45744acd?w=400",
                    category: "Soups",
                    isPopular: false,
                    isAvailable: true,
                    calories: 60,
                    preparationTime: "5 min",
                    ingredients: ["Miso paste", "Tofu", "Wakame", "Green onions"],
                    allergens: ["Soy"],
                    customizationOptions: []
                ),
                MenuItemDTO(
                    id: "item_3_5",
                    restaurantId: restaurantId,
                    name: "Edamame",
                    description: "Steamed young soybeans lightly salted. A perfect healthy starter.",
                    price: 5.99,
                    imageURL: "https://images.unsplash.com/photo-1564894809611-1742fc40ed80?w=400",
                    category: "Appetizers",
                    isPopular: true,
                    isAvailable: true,
                    calories: 120,
                    preparationTime: "5 min",
                    ingredients: ["Edamame", "Sea salt"],
                    allergens: ["Soy"],
                    customizationOptions: []
                )
            ]
            
        case "rest_5": // Taco Fiesta
            return [
                MenuItemDTO(
                    id: "item_5_1",
                    restaurantId: restaurantId,
                    name: "Street Tacos (3)",
                    description: "Three authentic street-style tacos with your choice of meat, onions, cilantro, and salsa verde.",
                    price: 9.99,
                    imageURL: "https://images.unsplash.com/photo-1565299585323-38d6b0865b47?w=400",
                    category: "Tacos",
                    isPopular: true,
                    isAvailable: true,
                    calories: 450,
                    preparationTime: "10-12 min",
                    ingredients: ["Corn tortillas", "Meat", "Onions", "Cilantro", "Salsa verde"],
                    allergens: [],
                    customizationOptions: tacoCustomizations
                ),
                MenuItemDTO(
                    id: "item_5_2",
                    restaurantId: restaurantId,
                    name: "Loaded Burrito",
                    description: "Large flour tortilla stuffed with rice, beans, meat, cheese, sour cream, and guacamole.",
                    price: 12.99,
                    imageURL: "https://images.unsplash.com/photo-1626700051175-6818013e1d4f?w=400",
                    category: "Burritos",
                    isPopular: true,
                    isAvailable: true,
                    calories: 780,
                    preparationTime: "12-15 min",
                    ingredients: ["Flour tortilla", "Rice", "Beans", "Meat", "Cheese", "Sour cream", "Guacamole"],
                    allergens: ["Gluten", "Dairy"],
                    customizationOptions: burritoCustomizations
                ),
                MenuItemDTO(
                    id: "item_5_3",
                    restaurantId: restaurantId,
                    name: "Quesadilla",
                    description: "Grilled flour tortilla filled with melted cheese and your choice of protein.",
                    price: 10.99,
                    imageURL: "https://images.unsplash.com/photo-1618040996337-56904b7850b9?w=400",
                    category: "Quesadillas",
                    isPopular: false,
                    isAvailable: true,
                    calories: 580,
                    preparationTime: "10-12 min",
                    ingredients: ["Flour tortilla", "Cheese blend", "Protein"],
                    allergens: ["Gluten", "Dairy"],
                    customizationOptions: tacoCustomizations
                ),
                MenuItemDTO(
                    id: "item_5_4",
                    restaurantId: restaurantId,
                    name: "Nachos Supreme",
                    description: "Crispy tortilla chips loaded with cheese, meat, beans, jalapeños, sour cream, and guacamole.",
                    price: 11.99,
                    imageURL: "https://images.unsplash.com/photo-1513456852971-30c0b8199d4d?w=400",
                    category: "Appetizers",
                    isPopular: true,
                    isAvailable: true,
                    calories: 680,
                    preparationTime: "12-15 min",
                    ingredients: ["Tortilla chips", "Cheese", "Meat", "Beans", "Jalapeños", "Sour cream", "Guacamole"],
                    allergens: ["Dairy"],
                    customizationOptions: []
                ),
                MenuItemDTO(
                    id: "item_5_5",
                    restaurantId: restaurantId,
                    name: "Churros",
                    description: "Crispy fried dough coated in cinnamon sugar, served with chocolate dipping sauce.",
                    price: 6.99,
                    imageURL: "https://images.unsplash.com/photo-1624371414361-e670edf4898b?w=400",
                    category: "Desserts",
                    isPopular: true,
                    isAvailable: true,
                    calories: 320,
                    preparationTime: "8-10 min",
                    ingredients: ["Dough", "Cinnamon sugar", "Chocolate sauce"],
                    allergens: ["Gluten", "Dairy"],
                    customizationOptions: []
                )
            ]
            
        default:
            return generateGenericMenu(for: restaurantId)
        }
    }
    
    private func generateGenericMenu(for restaurantId: String) -> [MenuItemDTO] {
        return [
            MenuItemDTO(
                id: "\(restaurantId)_item_1",
                restaurantId: restaurantId,
                name: "House Special",
                description: "Our signature dish made with fresh ingredients and chef's special recipe.",
                price: 15.99,
                imageURL: "https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=400",
                category: "Specials",
                isPopular: true,
                isAvailable: true,
                calories: 650,
                preparationTime: "15-20 min",
                ingredients: ["Fresh ingredients", "House sauce"],
                allergens: [],
                customizationOptions: []
            ),
            MenuItemDTO(
                id: "\(restaurantId)_item_2",
                restaurantId: restaurantId,
                name: "Classic Combo",
                description: "A perfect combination of our most popular items.",
                price: 18.99,
                imageURL: "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400",
                category: "Combos",
                isPopular: true,
                isAvailable: true,
                calories: 820,
                preparationTime: "18-25 min",
                ingredients: ["Various ingredients"],
                allergens: [],
                customizationOptions: []
            ),
            MenuItemDTO(
                id: "\(restaurantId)_item_3",
                restaurantId: restaurantId,
                name: "Light Bites",
                description: "Perfect for a lighter meal or as a starter.",
                price: 9.99,
                imageURL: "https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400",
                category: "Appetizers",
                isPopular: false,
                isAvailable: true,
                calories: 320,
                preparationTime: "8-10 min",
                ingredients: ["Fresh vegetables", "Light dressing"],
                allergens: [],
                customizationOptions: []
            ),
            MenuItemDTO(
                id: "\(restaurantId)_item_4",
                restaurantId: restaurantId,
                name: "Sweet Finish",
                description: "End your meal on a sweet note with our signature dessert.",
                price: 7.99,
                imageURL: "https://images.unsplash.com/photo-1551024601-bec78aea704b?w=400",
                category: "Desserts",
                isPopular: false,
                isAvailable: true,
                calories: 380,
                preparationTime: "5 min",
                ingredients: ["Sweet ingredients"],
                allergens: ["Dairy"],
                customizationOptions: []
            )
        ]
    }
    
    // MARK: - Customization Options
    private var pizzaCustomizations: [CustomizationGroup] {
        [
            CustomizationGroup(
                id: "pizza_size",
                name: "Size",
                isRequired: true,
                maxSelections: 1,
                options: [
                    CustomizationOption(id: "small", name: "Small (10\")", price: 0),
                    CustomizationOption(id: "medium", name: "Medium (12\")", price: 3.00),
                    CustomizationOption(id: "large", name: "Large (14\")", price: 6.00),
                    CustomizationOption(id: "xlarge", name: "X-Large (16\")", price: 9.00)
                ]
            ),
            CustomizationGroup(
                id: "pizza_crust",
                name: "Crust",
                isRequired: true,
                maxSelections: 1,
                options: [
                    CustomizationOption(id: "regular", name: "Regular", price: 0),
                    CustomizationOption(id: "thin", name: "Thin Crust", price: 0),
                    CustomizationOption(id: "thick", name: "Thick Crust", price: 1.50),
                    CustomizationOption(id: "stuffed", name: "Stuffed Crust", price: 3.00)
                ]
            ),
            CustomizationGroup(
                id: "pizza_toppings",
                name: "Extra Toppings",
                isRequired: false,
                maxSelections: 10,
                options: [
                    CustomizationOption(id: "pepperoni", name: "Pepperoni", price: 1.50),
                    CustomizationOption(id: "sausage", name: "Italian Sausage", price: 1.50),
                    CustomizationOption(id: "mushrooms", name: "Mushrooms", price: 1.00),
                    CustomizationOption(id: "onions", name: "Onions", price: 0.75),
                    CustomizationOption(id: "peppers", name: "Bell Peppers", price: 0.75),
                    CustomizationOption(id: "olives", name: "Black Olives", price: 1.00),
                    CustomizationOption(id: "bacon", name: "Bacon", price: 2.00),
                    CustomizationOption(id: "extra_cheese", name: "Extra Cheese", price: 2.00)
                ]
            )
        ]
    }
    
    private var burgerCustomizations: [CustomizationGroup] {
        [
            CustomizationGroup(
                id: "burger_cook",
                name: "How would you like it cooked?",
                isRequired: true,
                maxSelections: 1,
                options: [
                    CustomizationOption(id: "medium_rare", name: "Medium Rare", price: 0),
                    CustomizationOption(id: "medium", name: "Medium", price: 0),
                    CustomizationOption(id: "medium_well", name: "Medium Well", price: 0),
                    CustomizationOption(id: "well_done", name: "Well Done", price: 0)
                ]
            ),
            CustomizationGroup(
                id: "burger_extras",
                name: "Add Extras",
                isRequired: false,
                maxSelections: 5,
                options: [
                    CustomizationOption(id: "bacon", name: "Bacon", price: 2.00),
                    CustomizationOption(id: "avocado", name: "Avocado", price: 1.50),
                    CustomizationOption(id: "egg", name: "Fried Egg", price: 1.50),
                    CustomizationOption(id: "jalapenos", name: "Jalapeños", price: 0.75),
                    CustomizationOption(id: "extra_patty", name: "Extra Patty", price: 4.00)
                ]
            ),
            CustomizationGroup(
                id: "burger_sides",
                name: "Choose a Side",
                isRequired: true,
                maxSelections: 1,
                options: [
                    CustomizationOption(id: "fries", name: "French Fries", price: 0),
                    CustomizationOption(id: "onion_rings", name: "Onion Rings", price: 1.50),
                    CustomizationOption(id: "side_salad", name: "Side Salad", price: 1.00),
                    CustomizationOption(id: "sweet_potato", name: "Sweet Potato Fries", price: 2.00)
                ]
            )
        ]
    }
    
    private var sushiCustomizations: [CustomizationGroup] {
        [
            CustomizationGroup(
                id: "sushi_spice",
                name: "Spice Level",
                isRequired: false,
                maxSelections: 1,
                options: [
                    CustomizationOption(id: "mild", name: "Mild", price: 0),
                    CustomizationOption(id: "medium_spice", name: "Medium", price: 0),
                    CustomizationOption(id: "hot", name: "Hot", price: 0),
                    CustomizationOption(id: "extra_hot", name: "Extra Hot", price: 0)
                ]
            ),
            CustomizationGroup(
                id: "sushi_extras",
                name: "Add Extras",
                isRequired: false,
                maxSelections: 3,
                options: [
                    CustomizationOption(id: "extra_ginger", name: "Extra Ginger", price: 0.50),
                    CustomizationOption(id: "extra_wasabi", name: "Extra Wasabi", price: 0.50),
                    CustomizationOption(id: "spicy_mayo", name: "Spicy Mayo", price: 0.75),
                    CustomizationOption(id: "eel_sauce", name: "Extra Eel Sauce", price: 0.75)
                ]
            )
        ]
    }
    
    private var saladCustomizations: [CustomizationGroup] {
        [
            CustomizationGroup(
                id: "salad_protein",
                name: "Add Protein",
                isRequired: false,
                maxSelections: 1,
                options: [
                    CustomizationOption(id: "grilled_chicken", name: "Grilled Chicken", price: 4.00),
                    CustomizationOption(id: "grilled_shrimp", name: "Grilled Shrimp", price: 5.00),
                    CustomizationOption(id: "salmon", name: "Grilled Salmon", price: 6.00)
                ]
            ),
            CustomizationGroup(
                id: "salad_dressing",
                name: "Dressing",
                isRequired: true,
                maxSelections: 1,
                options: [
                    CustomizationOption(id: "caesar", name: "Caesar", price: 0),
                    CustomizationOption(id: "ranch", name: "Ranch", price: 0),
                    CustomizationOption(id: "balsamic", name: "Balsamic Vinaigrette", price: 0),
                    CustomizationOption(id: "on_side", name: "On the Side", price: 0)
                ]
            )
        ]
    }
    
    private var milkshakeCustomizations: [CustomizationGroup] {
        [
            CustomizationGroup(
                id: "shake_flavor",
                name: "Flavor",
                isRequired: true,
                maxSelections: 1,
                options: [
                    CustomizationOption(id: "vanilla", name: "Vanilla", price: 0),
                    CustomizationOption(id: "chocolate", name: "Chocolate", price: 0),
                    CustomizationOption(id: "strawberry", name: "Strawberry", price: 0),
                    CustomizationOption(id: "oreo", name: "Oreo", price: 1.00),
                    CustomizationOption(id: "peanut_butter", name: "Peanut Butter", price: 1.00)
                ]
            )
        ]
    }
    
    private var tacoCustomizations: [CustomizationGroup] {
        [
            CustomizationGroup(
                id: "taco_meat",
                name: "Choose Meat",
                isRequired: true,
                maxSelections: 1,
                options: [
                    CustomizationOption(id: "carne_asada", name: "Carne Asada (Steak)", price: 0),
                    CustomizationOption(id: "carnitas", name: "Carnitas (Pork)", price: 0),
                    CustomizationOption(id: "pollo", name: "Pollo (Chicken)", price: 0),
                    CustomizationOption(id: "pastor", name: "Al Pastor", price: 0),
                    CustomizationOption(id: "chorizo", name: "Chorizo", price: 0.50),
                    CustomizationOption(id: "veggie", name: "Grilled Veggies", price: 0)
                ]
            ),
            CustomizationGroup(
                id: "taco_salsa",
                name: "Salsa",
                isRequired: false,
                maxSelections: 2,
                options: [
                    CustomizationOption(id: "verde", name: "Salsa Verde", price: 0),
                    CustomizationOption(id: "roja", name: "Salsa Roja", price: 0),
                    CustomizationOption(id: "habanero", name: "Habanero (Very Hot)", price: 0)
                ]
            )
        ]
    }
    
    private var burritoCustomizations: [CustomizationGroup] {
        [
            CustomizationGroup(
                id: "burrito_meat",
                name: "Choose Protein",
                isRequired: true,
                maxSelections: 1,
                options: [
                    CustomizationOption(id: "carne_asada", name: "Carne Asada", price: 0),
                    CustomizationOption(id: "carnitas", name: "Carnitas", price: 0),
                    CustomizationOption(id: "pollo", name: "Chicken", price: 0),
                    CustomizationOption(id: "barbacoa", name: "Barbacoa", price: 1.00),
                    CustomizationOption(id: "veggie", name: "Grilled Veggies", price: 0)
                ]
            ),
            CustomizationGroup(
                id: "burrito_beans",
                name: "Beans",
                isRequired: true,
                maxSelections: 1,
                options: [
                    CustomizationOption(id: "black_beans", name: "Black Beans", price: 0),
                    CustomizationOption(id: "pinto_beans", name: "Pinto Beans", price: 0),
                    CustomizationOption(id: "no_beans", name: "No Beans", price: 0)
                ]
            ),
            CustomizationGroup(
                id: "burrito_extras",
                name: "Add Extras",
                isRequired: false,
                maxSelections: 5,
                options: [
                    CustomizationOption(id: "extra_guac", name: "Extra Guacamole", price: 2.00),
                    CustomizationOption(id: "extra_cheese", name: "Extra Cheese", price: 1.00),
                    CustomizationOption(id: "queso", name: "Queso", price: 1.50),
                    CustomizationOption(id: "jalapenos", name: "Jalapeños", price: 0.50)
                ]
            )
        ]
    }
}
