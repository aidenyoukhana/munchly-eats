import Foundation
import Combine
import UIKit
import SwiftUI

@MainActor
class ProfileViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var user: User?
    @Published var savedAddresses: [Address] = []
    @Published var paymentMethods: [PaymentMethod] = []
    @Published var notifications: [ServiceNotification] = []
    
    @Published var isLoading = false
    @Published var error: Error?
    @Published var showError = false
    @Published var errorMessage = ""
    
    // Edit Profile
    @Published var editFullName = ""
    @Published var editPhoneNumber = ""
    @Published var isEditingProfile = false
    
    // Settings
    @Published var notificationsEnabled = true
    @Published var locationEnabled = true
    @Published var orderUpdates = true
    @Published var promotionalNotifications = true
    
    // MARK: - Services
    private let authService = AuthService.shared
    private let locationService = LocationService.shared
    private let notificationService = NotificationService.shared
    
    // MARK: - Computed Properties
    var isAuthenticated: Bool {
        authService.isAuthenticated
    }
    
    var unreadNotificationCount: Int {
        notificationService.unreadCount
    }
    
    // MARK: - Initialization
    init() {
        loadProfile()
    }
    
    // MARK: - Load Profile
    func loadProfile() {
        user = authService.currentUser
        savedAddresses = locationService.savedAddresses
        notifications = notificationService.notifications
        
        // Load mock payment methods
        paymentMethods = [
            PaymentMethod(
                id: "pm_1",
                type: .creditCard,
                last4: "4242",
                brand: "Visa",
                expiryMonth: 12,
                expiryYear: 2027,
                holderName: user?.fullName ?? "Card Holder",
                isDefault: true
            ),
            PaymentMethod(
                id: "pm_2",
                type: .creditCard,
                last4: "5555",
                brand: "Mastercard",
                expiryMonth: 6,
                expiryYear: 2026,
                holderName: user?.fullName ?? "Card Holder",
                isDefault: false
            )
        ]
        
        // Populate edit fields
        if let user = user {
            editFullName = user.fullName
            editPhoneNumber = user.phoneNumber ?? ""
        }
    }
    
    // MARK: - Update Profile
    func updateProfile() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await authService.updateProfile(
                fullName: editFullName,
                phoneNumber: editPhoneNumber.isEmpty ? nil : editPhoneNumber,
                profileImageURL: nil
            )
            user = authService.currentUser
            isEditingProfile = false
            ToastManager.shared.showSuccess("Profile Updated")
        } catch {
            showError(message: error.localizedDescription)
            ToastManager.shared.showError("Update Failed", message: error.localizedDescription)
        }
    }
    
    // MARK: - Address Management
    func addAddress(_ address: Address) {
        locationService.addAddress(address)
        savedAddresses = locationService.savedAddresses
        ToastManager.shared.showSuccess("Address Added")
    }
    
    func updateAddress(_ address: Address) {
        locationService.updateAddress(address)
        savedAddresses = locationService.savedAddresses
        ToastManager.shared.showSuccess("Address Updated")
    }
    
    func deleteAddress(_ addressId: String) {
        locationService.deleteAddress(addressId)
        savedAddresses = locationService.savedAddresses
        ToastManager.shared.showInfo("Address Deleted")
    }
    
    func setDefaultAddress(_ addressId: String) {
        locationService.setDefaultAddress(addressId)
        savedAddresses = locationService.savedAddresses
        ToastManager.shared.showSuccess("Default Address Updated")
    }
    
    // MARK: - Payment Method Management
    func addPaymentMethod(_ method: PaymentMethod) {
        paymentMethods.append(method)
        ToastManager.shared.showSuccess("Payment Method Added")
    }
    
    func deletePaymentMethod(_ methodId: String) {
        paymentMethods.removeAll { $0.id == methodId }
        ToastManager.shared.showInfo("Payment Method Removed")
    }
    
    func setDefaultPaymentMethod(_ methodId: String) {
        for i in paymentMethods.indices {
            paymentMethods[i].isDefault = paymentMethods[i].id == methodId
        }
        ToastManager.shared.showSuccess("Default Payment Updated")
    }
    
    func getDefaultPaymentMethod() -> PaymentMethod? {
        paymentMethods.first { $0.isDefault } ?? paymentMethods.first
    }
    
    // MARK: - Notification Management
    func markNotificationAsRead(_ notificationId: String) {
        notificationService.markAsRead(notificationId)
        notifications = notificationService.notifications
    }
    
    func markAllNotificationsAsRead() {
        notificationService.markAllAsRead()
        notifications = notificationService.notifications
    }
    
    func deleteNotification(_ notificationId: String) {
        notificationService.deleteNotification(notificationId)
        notifications = notificationService.notifications
    }
    
    func clearAllNotifications() {
        notificationService.clearAll()
        notifications = notificationService.notifications
    }
    
    // MARK: - Settings
    func toggleNotifications() {
        Task {
            if !notificationsEnabled {
                let granted = await notificationService.requestPermission()
                notificationsEnabled = granted
            } else {
                // Open settings
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    await UIApplication.shared.open(url)
                }
            }
        }
    }
    
    func toggleLocation() {
        if !locationEnabled {
            locationService.requestPermission()
        } else {
            // Open settings
            if let url = URL(string: UIApplication.openSettingsURLString) {
                Task {
                    await UIApplication.shared.open(url)
                }
            }
        }
    }
    
    // MARK: - Sign Out
    func signOut() {
        authService.signOut()
        // Reset local state
        user = nil
        savedAddresses = []
        paymentMethods = []
        notifications = []
    }
    
    // MARK: - Delete Account
    func deleteAccount() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await authService.deleteAccount()
            signOut()
        } catch {
            showError(message: error.localizedDescription)
        }
    }
    
    // MARK: - Private Helpers
    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
}
