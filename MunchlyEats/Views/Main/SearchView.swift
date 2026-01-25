import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    @EnvironmentObject var cartViewModel: CartViewModel
    @State private var selectedRestaurant: RestaurantDTO?
    @State private var showQuickOrder = false
    @State private var isAISearchEnabled = true
    @State private var aiSearchHint: String?
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                // Search Bar with Voice Button
                HStack(spacing: 12) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        
                        TextField("Try: 'cheap sushi nearby'...", text: $viewModel.searchText)
                            .autocapitalization(.none)
                            .submitLabel(.search)
                            .onSubmit {
                                performSearch()
                            }
                        
                        if !viewModel.searchText.isEmpty {
                            Button {
                                viewModel.clearSearch()
                                aiSearchHint = nil
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    
                    // Quick Order Button
                    Button {
                        showQuickOrder = true
                    } label: {
                        Image(systemName: "sparkles")
                            .font(.title2)
                            .foregroundStyle(.white)
                    }
                    .accessibilityLabel("Quick Order")
                    
                    if !viewModel.searchText.isEmpty {
                        Button("Cancel") {
                            viewModel.clearSearch()
                            aiSearchHint = nil
                            hideKeyboard()
                        }
                        .foregroundColor(.primary)
                    }
                }
                .padding()
                
                // AI Search Hint
                if let hint = aiSearchHint {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.caption)
                            .foregroundColor(.purple)
                        Text(hint)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                if viewModel.searchText.isEmpty {
                    // No Search - Show Recent & Categories
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            // Recent Searches
                            if viewModel.showRecentSearches {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Text("Recent Searches")
                                            .font(.headline)
                                        
                                        Spacer()
                                        
                                        Button("Clear") {
                                            viewModel.clearRecentSearches()
                                        }
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                    }
                                    
                                    ForEach(viewModel.recentSearches, id: \.self) { search in
                                        HStack {
                                            Image(systemName: "clock.arrow.circlepath")
                                                .foregroundColor(.secondary)
                                            
                                            Text(search)
                                            
                                            Spacer()
                                            
                                            Button {
                                                viewModel.removeRecentSearch(search)
                                            } label: {
                                                Image(systemName: "xmark")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            viewModel.selectRecentSearch(search)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                            
                            // Popular Categories
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Popular Categories")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                LazyVGrid(columns: [
                                    GridItem(.flexible()),
                                        GridItem(.flexible())
                                    ], spacing: 12) {
                                        ForEach(viewModel.popularCategories, id: \.self) { category in
                                            Button {
                                                viewModel.searchByCategory(category)
                                            } label: {
                                                HStack {
                                                    Text(categoryEmoji(for: category))
                                                    Text(category)
                                                        .fontWeight(.medium)
                                                    Spacer()
                                                }
                                                .padding()
                                                .background(Color(.secondarySystemBackground))
                                                .cornerRadius(12)
                                                .foregroundColor(.primary)
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                                
                                // AI Search Tips
                                aiSearchTipsSection
                            }
                            .padding(.vertical)
                            .padding(.bottom, cartViewModel.items.isEmpty ? 0 : 80)
                        }
                    } else {
                        // Search Results
                        if viewModel.isSearching {
                            Spacer()
                            ProgressView()
                            Spacer()
                        } else if viewModel.searchResults.isEmpty {
                            EmptyStateView(
                                icon: "magnifyingglass",
                                title: "No Results",
                                message: "We couldn't find any restaurants matching \"\(viewModel.searchText)\""
                            )
                        } else {
                            ScrollView {
                                LazyVStack(spacing: 12) {
                                    ForEach(viewModel.searchResults) { restaurant in
                                        RestaurantCard(restaurant: restaurant)
                                            .onTapGesture {
                                                selectedRestaurant = restaurant
                                            }
                                    }
                                }
                                .padding()
                                .padding(.bottom, cartViewModel.items.isEmpty ? 0 : 80)
                            }
                        }
                    }
                }
            
            FloatingCartBanner()
        }
        .navigationTitle("Search")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                CartToolbarButton()
            }
        }
        .sheet(isPresented: $showQuickOrder) {
            QuickOrderView()
        }
        .navigationDestination(item: $selectedRestaurant) { restaurantDTO in
            RestaurantDetailView(restaurant: restaurantDTO.toRestaurant())
        }
        .onChange(of: viewModel.searchText) { _, newValue in
            if !newValue.isEmpty {
                performSearch()
            }
        }
    }
    
    // MARK: - AI Search Tips Section
    private var aiSearchTipsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.purple)
                Text("AI-Powered Search")
                    .font(.headline)
            }
            .padding(.horizontal)
            
            Text("Try natural language searches like:")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(aiSearchExamples, id: \.self) { example in
                        Button {
                            viewModel.searchText = example
                            performSearch()
                        } label: {
                            Text(example)
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.purple.opacity(0.1))
                                .foregroundColor(.purple)
                                .cornerRadius(16)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }
    
    private var aiSearchExamples: [String] {
        [
            "cheap pizza nearby",
            "best sushi in town",
            "fast delivery burgers",
            "healthy food under $15",
            "top rated Thai"
        ]
    }
    
    // MARK: - Perform AI Search
    private func performSearch() {
        Task {
            viewModel.isSearching = true
            let results = await viewModel.aiSearch(viewModel.searchText)
            
            await MainActor.run {
                viewModel.searchResults = results
                viewModel.isSearching = false
                
                // Generate AI hint
                aiSearchHint = generateSearchHint(for: viewModel.searchText, resultCount: results.count)
            }
        }
    }
    
    private func generateSearchHint(for query: String, resultCount: Int) -> String? {
        let lowercased = query.lowercased()
        
        if lowercased.contains("cheap") || lowercased.contains("budget") {
            return "🔍 Showing affordable options"
        } else if lowercased.contains("fast") || lowercased.contains("quick") {
            return "⚡ Filtered for quick delivery"
        } else if lowercased.contains("best") || lowercased.contains("top") {
            return "⭐ Sorted by highest ratings"
        } else if lowercased.contains("nearby") || lowercased.contains("close") {
            return "📍 Showing closest restaurants"
        } else if resultCount > 0 {
            return "Found \(resultCount) restaurant\(resultCount == 1 ? "" : "s")"
        }
        
        return nil
    }
    
    private func categoryEmoji(for category: String) -> String {
        switch category.lowercased() {
        case "pizza": return "🍕"
        case "burgers": return "🍔"
        case "sushi": return "🍣"
        case "mexican": return "🌮"
        case "chinese": return "🥡"
        case "healthy": return "🥗"
        default: return "🍽️"
        }
    }
}

#Preview {
    SearchView()
        .environmentObject(CartViewModel())
}
