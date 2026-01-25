//
//  MunchlyEatsApp.swift
//  MunchlyEats
//
//  Created by Aiden Youkhana on 1/18/26.
//

import SwiftUI
import SwiftData
import Combine

@main
struct MunchlyEatsApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var cartViewModel = CartViewModel()
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            User.self,
            Restaurant.self,
            MenuItem.self,
            CartItem.self,
            Order.self,
            Address.self,
            PaymentMethod.self,
            Driver.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authViewModel)
                .environmentObject(cartViewModel)
        }
        .modelContainer(sharedModelContainer)
    }
}

// MARK: - Root View
struct RootView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var siriHandler = SiriIntentHandler.shared
    @State private var showSplash = true
    @State private var showQuickOrderFromSiri = false
    @State private var navigateToSearch = false
    @State private var navigateToOrders = false
    
    var body: some View {
        ZStack {
            if showSplash {
                SplashView()
                    .transition(.opacity)
            } else {
                if authViewModel.isAuthenticated {
                    MainTabView()
                        .transition(.opacity)
                        .sheet(isPresented: $showQuickOrderFromSiri) {
                            QuickOrderView()
                        }
                } else {
                    LoginView()
                        .transition(.opacity)
                }
            }
        }
        .withToastContainer()
        .animation(.easeInOut(duration: 0.3), value: showSplash)
        .animation(.easeInOut(duration: 0.3), value: authViewModel.isAuthenticated)
        .onAppear {
            // Show splash for 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    showSplash = false
                }
                
                // Check for Siri actions after splash
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    handleSiriActions()
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            handleSiriActions()
        }
    }
    
    private func handleSiriActions() {
        siriHandler.checkForPendingActions()
        
        if siriHandler.hasPendingAction {
            if siriHandler.pendingOrder != nil {
                // Show quick order view with pre-filled data
                showQuickOrderFromSiri = true
            } else if siriHandler.pendingSearch != nil {
                // Navigate to search tab
                navigateToSearch = true
            } else if siriHandler.shouldCheckOrder {
                // Navigate to orders tab
                navigateToOrders = true
            } else if siriHandler.shouldReorder {
                // Handle reorder - would need last order data
                showQuickOrderFromSiri = true
            }
            
            siriHandler.clearPendingActions()
        }
    }
}

// MARK: - Splash View
struct SplashView: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            Color.primary
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // App Icon
                ZStack {
                    Circle()
                        .fill(Color(.systemBackground))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "fork.knife")
                        .font(.system(size: 50))
                        .foregroundColor(.primary)
                }
                .scaleEffect(isAnimating ? 1.0 : 0.5)
                .opacity(isAnimating ? 1.0 : 0)
                
                Text("MunchlyEats")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Color(.systemBackground))
                    .opacity(isAnimating ? 1.0 : 0)
                
                Text("Delicious food, delivered fast")
                    .font(.subheadline)
                    .foregroundColor(Color(.systemBackground).opacity(0.8))
                    .opacity(isAnimating ? 1.0 : 0)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                isAnimating = true
            }
        }
    }
}
