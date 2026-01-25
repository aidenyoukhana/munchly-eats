import SwiftUI
import Combine
import Speech

// MARK: - Quick Order View
struct QuickOrderView: View {
    @StateObject private var speechService = SpeechRecognitionService.shared
    @StateObject private var quickOrderService = QuickOrderService.shared
    @StateObject private var synthesizer = SpeechSynthesizerService.shared
    @StateObject private var restaurantService = RestaurantService.shared
    @EnvironmentObject var cartViewModel: CartViewModel
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var conversationState: ConversationState = .idle
    @State private var quickOrderResponse: String = ""
    @State private var parsedIntent: ParsedOrderIntent?
    @State private var pulseAnimation = false
    @State private var silenceTimer: Timer?
    @State private var showCheckout = false
    @State private var selectedSuggestion: QuickOrderSuggestion?
    
    // Auto-stop after silence
    private let silenceThreshold: TimeInterval = 2.0
    
    enum ConversationState {
        case idle
        case listening
        case processing
        case confirming
        case completed
        case error
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Mic Button and Status Area
                    VStack(spacing: 16) {
                        micButton
                        
                        // Status text
                        if conversationState == .processing {
                            HStack(spacing: 8) {
                                ProgressView()
                                Text("Understanding your order...")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        } else if conversationState == .listening {
                            Text("Listening...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Tap to start ordering")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        // Live transcription
                        if !speechService.transcribedText.isEmpty {
                            Text(speechService.transcribedText)
                                .font(.body)
                                .fontWeight(.medium)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(12)
                                .padding(.horizontal)
                                .transition(.scale.combined(with: .opacity))
                        }
                        
                        // Quick Order Response
                        if !quickOrderResponse.isEmpty && (conversationState == .confirming || conversationState == .completed) {
                            quickOrderResponseCard
                        }
                        
                        // Error message
                        if conversationState == .error {
                            errorCard
                        }
                    }
                    .padding(.top, 20)
                    
                    // Quick Order Suggestions
                    quickOrderSuggestions
                    
                    // Popular Items Section
                    popularItemsSection
                }
                .padding(.bottom, 24)
            }
            .animation(.spring(response: 0.3), value: speechService.transcribedText)
            .animation(.spring(response: 0.3), value: conversationState)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Quick Order")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        cleanup()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
                
                if !cartViewModel.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showCheckout = true
                        } label: {
                            Image(systemName: "cart")
                        }
                    }
                }
            }
            .sheet(isPresented: $showCheckout) {
                NavigationStack {
                    CheckoutView()
                }
            }
            .onAppear {
                if speechService.authorizationStatus == .notDetermined {
                    speechService.checkAuthorization()
                }
                // Auto-start listening when view appears
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if speechService.isAuthorized {
                        startListening()
                    }
                }
            }
            .onDisappear {
                cleanup()
            }
            .onChange(of: speechService.transcribedText) { _, newValue in
                // Reset silence timer when text changes
                resetSilenceTimer()
            }
        }
    }
    
    // MARK: - Quick Order Response Card
    private var quickOrderResponseCard: some View {
        VStack(spacing: 16) {
            Text(quickOrderResponse)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal)
            
            if conversationState == .confirming {
                HStack(spacing: 12) {
                    Button {
                        resetAndListen()
                    } label: {
                        Text("Cancel")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(10)
                    }
                    
                    Button {
                        confirmOrder()
                    } label: {
                        Text("Add to Cart")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                }
            } else if conversationState == .completed {
                HStack(spacing: 12) {
                    Button {
                        resetAndListen()
                    } label: {
                        Text("Order More")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(10)
                    }
                    
                    Button {
                        showCheckout = true
                    } label: {
                        Text("Checkout")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.green)
                            .cornerRadius(10)
                    }
                }
            }
        }
    }
    
    // MARK: - Error Card
    private var errorCard: some View {
        VStack(spacing: 12) {
            Text(speechService.errorMessage ?? "Couldn't understand that. Try saying something like \"Order two pizzas from Tony's\"")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button {
                resetAndListen()
            } label: {
                HStack {
                    Image(systemName: "mic.fill")
                    Text("Try Again")
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.blue)
                .cornerRadius(10)
            }
        }
    }
    
    // MARK: - Idle State View
    private var idleStateView: some View {
        VStack(spacing: 24) {
            // Hero Section
            VStack(spacing: 16) {
                // Mic Button
                micButton
                
                Text("Tap to start ordering")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 40)
            .padding(.bottom, 24)
            
            // Quick Order Suggestions
            quickOrderSuggestions
            
            // Popular Items Section
            popularItemsSection
        }
    }
    
    // MARK: - Mic Button
    private var micButton: some View {
        Button {
            toggleListening()
        } label: {
            ZStack {
                // Outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.white.opacity(0.3), Color.clear],
                            center: .center,
                            startRadius: 40,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                    .opacity(conversationState == .listening ? 1 : 0)
                    .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                
                // Main circle
                Circle()
                    .fill(
                        conversationState == .listening 
                            ? Color.white
                            : Color(.systemGray5)
                    )
                    .frame(width: 100, height: 100)
                    .shadow(color: Color.black.opacity(0.1), radius: 10)
                
                // Icon
                Image(systemName: "mic.fill")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundColor(conversationState == .listening ? .red : .primary)
            }
        }
        .buttonStyle(.plain)
        .disabled(!speechService.isAuthorized)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulseAnimation = true
            }
        }
    }
    
    // MARK: - Quick Order Suggestions
    private var quickOrderSuggestions: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.purple)
                Text("Quick Commands")
                    .font(.headline)
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(quickSuggestions) { suggestion in
                        QuickSuggestionCard(suggestion: suggestion) {
                            // Simulate voice input with this suggestion
                            speechService.transcribedText = suggestion.command
                            processVoiceInput()
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Popular Items Section
    private var popularItemsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                Text("Popular Right Now")
                    .font(.headline)
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(popularOrderItems) { item in
                        PopularItemCard(item: item) {
                            // Set command and process
                            speechService.transcribedText = "Order \(item.itemName) from \(item.restaurantName)"
                            processVoiceInput()
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            // Restaurants Section
            VStack(alignment: .leading, spacing: 12) {
                Text("Say a restaurant name...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(restaurantService.restaurants.prefix(5)) { restaurant in
                            RestaurantChip(restaurant: restaurant) {
                                speechService.transcribedText = "Order from \(restaurant.name)"
                                processVoiceInput()
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.top, 8)
        }
        .padding(.vertical)
    }
    
    // MARK: - Listening State View
    private var listeningStateView: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Animated Mic
            micButton
            
            // Live transcription
            VStack(spacing: 12) {
                Text("Listening...")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                if !speechService.transcribedText.isEmpty {
                    Text(speechService.transcribedText)
                        .font(.title3)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(16)
                        .padding(.horizontal)
                        .transition(.scale.combined(with: .opacity))
                }
                
                Text("Tap mic when done or pause to auto-submit")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            Spacer()
        }
        .frame(minHeight: 500)
        .animation(.spring(response: 0.3), value: speechService.transcribedText)
    }
    
    // MARK: - Processing State View
    private var processingStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Processing animation
            ZStack {
                Circle()
                    .stroke(Color.purple.opacity(0.2), lineWidth: 4)
                    .frame(width: 100, height: 100)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(pulseAnimation ? 360 : 0))
                    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: pulseAnimation)
                
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 36))
                    .foregroundStyle(
                        LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing)
                    )
            }
            
            VStack(spacing: 8) {
                Text("Understanding your order...")
                    .font(.headline)
                
                Text("\"\(speechService.transcribedText)\"")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
            Spacer()
        }
        .frame(minHeight: 500)
    }
    
    // MARK: - Confirming State View
    private var confirmingStateView: some View {
        VStack(spacing: 0) {
            // Success header
            if conversationState == .completed {
                completedHeader
            }
            
            // Order Summary Card
            if let intent = parsedIntent {
                orderSummaryCard(intent: intent)
            }
            
            // Quick Order Response
            if !quickOrderResponse.isEmpty && conversationState == .confirming {
                quickOrderResponseCard
            }
            
            // Action Buttons
            actionButtonsSection
            
            Spacer(minLength: 100)
        }
    }
    
    private var completedHeader: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.green)
            }
            
            Text("Added to Cart!")
                .font(.title2)
                .fontWeight(.bold)
        }
        .padding(.vertical, 24)
    }
    
    private func orderSummaryCard(intent: ParsedOrderIntent) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Image(systemName: "bag.fill")
                    .foregroundColor(.primary)
                Text("Your Order")
                    .font(.headline)
                Spacer()
                if let restaurant = intent.items.first?.matchedRestaurant {
                    Text(restaurant.name)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            
            // Items
            VStack(spacing: 0) {
                ForEach(intent.items) { item in
                    orderItemRow(item: item)
                    
                    if item.id != intent.items.last?.id {
                        Divider()
                            .padding(.leading, 80)
                    }
                }
            }
            .background(Color(.systemBackground))
            
            // Total
            if let total = calculateTotal(intent: intent) {
                Divider()
                HStack {
                    Text("Subtotal")
                        .font(.headline)
                    Spacer()
                    Text("$\(String(format: "%.2f", total))")
                        .font(.title3)
                        .fontWeight(.bold)
                }
                .padding()
                .background(Color(.systemBackground))
            }
        }
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 10)
        .padding()
    }
    
    private func orderItemRow(item: ParsedOrderItem) -> some View {
        HStack(spacing: 12) {
            // Item Image
            AsyncImage(url: URL(string: item.matchedMenuItem?.imageURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.tertiarySystemBackground))
                    .overlay(
                        Image(systemName: "fork.knife")
                            .foregroundColor(.secondary)
                    )
            }
            .frame(width: 60, height: 60)
            .cornerRadius(8)
            
            // Item Details
            VStack(alignment: .leading, spacing: 4) {
                Text(item.matchedMenuItem?.name ?? item.itemName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if !item.customizations.isEmpty {
                    Text(item.customizations.joined(separator: ", "))
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                
                if let menuItem = item.matchedMenuItem {
                    Text("$\(String(format: "%.2f", menuItem.price))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Quantity & Price
            VStack(alignment: .trailing, spacing: 4) {
                Text("×\(item.quantity)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let menuItem = item.matchedMenuItem {
                    Text("$\(String(format: "%.2f", menuItem.price * Double(item.quantity)))")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }
        }
        .padding()
    }
    
    // MARK: - Action Buttons
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            if conversationState == .confirming {
                // Add to Cart Button
                Button {
                    confirmOrder()
                } label: {
                    HStack {
                        Image(systemName: "cart.badge.plus")
                        Text("Add to Cart")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(14)
                }
                
                // Checkout Now Button
                Button {
                    confirmOrder()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showCheckout = true
                    }
                } label: {
                    HStack {
                        Image(systemName: "creditcard.fill")
                        Text("Add & Checkout")
                    }
                    .font(.headline)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(14)
                }
                
                // Try Again
                Button {
                    resetAndListen()
                } label: {
                    HStack {
                        Image(systemName: "mic.fill")
                        Text("Say Something Else")
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                }
                .padding(.top, 8)
                
            } else if conversationState == .completed {
                // Checkout Button
                Button {
                    showCheckout = true
                } label: {
                    HStack {
                        Image(systemName: "creditcard.fill")
                        Text("Proceed to Checkout")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(14)
                }
                
                // Order More
                Button {
                    resetAndListen()
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Order More Items")
                    }
                    .font(.headline)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(14)
                }
                
                // Done
                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
            }
        }
        .padding()
    }
    
    // MARK: - Error State View
    private var errorStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 44))
                    .foregroundColor(.red)
            }
            
            VStack(spacing: 8) {
                Text("Couldn't understand that")
                    .font(.headline)
                
                Text(speechService.errorMessage ?? "Try saying something like \"Order two pizzas from Tony's\"")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Button {
                resetAndListen()
            } label: {
                HStack {
                    Image(systemName: "mic.fill")
                    Text("Try Again")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(Color.blue)
                .cornerRadius(12)
            }
            
            Spacer()
            Spacer()
        }
        .frame(minHeight: 500)
    }
    
    // MARK: - Data
    private var quickSuggestions: [QuickOrderSuggestion] {
        [
            QuickOrderSuggestion(
                title: "Pizza Night",
                command: "Order two pepperoni pizzas",
                imageURL: "https://images.unsplash.com/photo-1513104890138-7c749659a591?w=400"
            ),
            QuickOrderSuggestion(
                title: "Burger Combo",
                command: "Order a burger with fries",
                imageURL: "https://images.unsplash.com/photo-1571091718767-18b5b1457add?w=400"
            ),
            QuickOrderSuggestion(
                title: "Sushi for Two",
                command: "Order sushi rolls",
                imageURL: "https://images.unsplash.com/photo-1579871494447-9811cf80d66c?w=400"
            ),
            QuickOrderSuggestion(
                title: "Healthy",
                command: "Order something healthy",
                imageURL: "https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400"
            )
        ]
    }
    
    private var popularOrderItems: [PopularOrderItem] {
        [
            PopularOrderItem(
                itemName: "Pepperoni Pizza",
                restaurantName: "Tony's Pizzeria",
                price: 18.99,
                imageURL: "https://images.unsplash.com/photo-1628840042765-356cda07504e?w=400"
            ),
            PopularOrderItem(
                itemName: "Double Smash Burger",
                restaurantName: "Burger Joint",
                price: 14.99,
                imageURL: "https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=400"
            ),
            PopularOrderItem(
                itemName: "California Roll",
                restaurantName: "Sakura Sushi",
                price: 12.99,
                imageURL: "https://images.unsplash.com/photo-1579871494447-9811cf80d66c?w=400"
            )
        ]
    }
    
    // MARK: - Helper Functions
    private func calculateTotal(intent: ParsedOrderIntent) -> Double? {
        let total = intent.items.reduce(0.0) { sum, item in
            if let menuItem = item.matchedMenuItem {
                return sum + (menuItem.price * Double(item.quantity))
            }
            return sum
        }
        return total > 0 ? total : nil
    }
    
    // MARK: - Actions
    private func toggleListening() {
        if conversationState == .listening {
            stopAndProcess()
        } else {
            startListening()
        }
    }
    
    private func startListening() {
        conversationState = .listening
        quickOrderResponse = ""
        parsedIntent = nil
        speechService.startListening()
    }
    
    private func stopAndProcess() {
        silenceTimer?.invalidate()
        speechService.stopListening()
        conversationState = .idle
        
        if !speechService.transcribedText.isEmpty {
            processVoiceInput()
        }
    }
    
    private func resetSilenceTimer() {
        silenceTimer?.invalidate()
        silenceTimer = Timer.scheduledTimer(withTimeInterval: silenceThreshold, repeats: false) { _ in
            Task { @MainActor in
                if conversationState == .listening && !speechService.transcribedText.isEmpty {
                    stopAndProcess()
                }
            }
        }
    }
    
    private func processVoiceInput() {
        guard !speechService.transcribedText.isEmpty else {
            conversationState = .error
            return
        }
        
        conversationState = .processing
        
        Task {
            let intent = await quickOrderService.parseVoiceInput(speechService.transcribedText)
            parsedIntent = intent
            
            let response = quickOrderService.generateConfirmationMessage(for: intent)
            
            await MainActor.run {
                quickOrderResponse = response
                
                if intent.items.isEmpty || intent.items.allSatisfy({ $0.matchedMenuItem == nil }) {
                    conversationState = .error
                } else {
                    conversationState = .confirming
                    synthesizer.speak(response)
                }
            }
        }
    }
    
    private func confirmOrder() {
        guard let intent = parsedIntent else { return }
        
        for item in intent.items {
            if let menuItem = item.matchedMenuItem, let restaurant = item.matchedRestaurant {
                cartViewModel.addItem(
                    menuItem: menuItem,
                    restaurant: restaurant,
                    quantity: item.quantity,
                    specialInstructions: item.customizations.isEmpty ? nil : item.customizations.joined(separator: ", ")
                )
            }
        }
        
        conversationState = .completed
        synthesizer.speak("Added to your cart!")
    }
    
    private func resetAndListen() {
        speechService.reset()
        quickOrderResponse = ""
        parsedIntent = nil
        conversationState = .idle
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            startListening()
        }
    }
    
    private func cleanup() {
        silenceTimer?.invalidate()
        speechService.stopListening()
        synthesizer.stopSpeaking()
    }
}

// MARK: - Supporting Models
struct QuickOrderSuggestion: Identifiable {
    let id = UUID()
    let title: String
    let command: String
    let imageURL: String
}

struct PopularOrderItem: Identifiable {
    let id = UUID()
    let itemName: String
    let restaurantName: String
    let price: Double
    let imageURL: String
}

// MARK: - Quick Suggestion Card
struct QuickSuggestionCard: View {
    let suggestion: QuickOrderSuggestion
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                // Image
                AsyncImage(url: URL(string: suggestion.imageURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color(.tertiarySystemBackground))
                        .overlay(
                            ProgressView()
                        )
                }
                .frame(width: 160, height: 100)
                .clipped()
                
                // Details
                VStack(alignment: .leading, spacing: 4) {
                    Text(suggestion.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text("\"\(suggestion.command)\"")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    HStack {
                        Spacer()
                        
                        Image(systemName: "mic.circle.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                .padding(10)
            }
            .frame(width: 160)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.08), radius: 8, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Popular Item Card
struct PopularItemCard: View {
    let item: PopularOrderItem
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                // Image
                AsyncImage(url: URL(string: item.imageURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color(.tertiarySystemBackground))
                        .overlay(
                            ProgressView()
                        )
                }
                .frame(width: 160, height: 100)
                .clipped()
                
                // Details
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.itemName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(item.restaurantName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text("$\(String(format: "%.2f", item.price))")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Image(systemName: "mic.circle.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                .padding(10)
            }
            .frame(width: 160)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.08), radius: 8, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Restaurant Chip
struct RestaurantChip: View {
    let restaurant: RestaurantDTO
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                AsyncImage(url: URL(string: restaurant.imageURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color(.tertiarySystemBackground))
                }
                .frame(width: 32, height: 32)
                .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(restaurant.name)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 8))
                            .foregroundColor(.orange)
                        Text(String(format: "%.1f", restaurant.rating))
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Quick Order Button (for SearchView)
struct QuickOrderButton: View {
    @State private var showQuickOrder = false
    
    var body: some View {
        Button {
            showQuickOrder = true
        } label: {
            Image(systemName: "sparkles")
                .font(.title2)
                .foregroundStyle(.white)
        }
        .sheet(isPresented: $showQuickOrder) {
            QuickOrderView()
        }
    }
}

#Preview {
    QuickOrderView()
        .environmentObject(CartViewModel())
}
