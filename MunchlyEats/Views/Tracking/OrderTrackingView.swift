import SwiftUI
import MapKit

struct OrderTrackingView: View {
    let order: Order
    @StateObject private var viewModel: TrackingViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showContactDriver = false
    
    init(order: Order) {
        self.order = order
        self._viewModel = StateObject(wrappedValue: TrackingViewModel(order: order))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Map
                TrackingMapView(
                    restaurantCoordinate: viewModel.restaurantCoordinate,
                    deliveryCoordinate: viewModel.deliveryCoordinate,
                    driverCoordinate: viewModel.driverCoordinate,
                    routeCoordinates: viewModel.routeCoordinates,
                    driverProgress: viewModel.driverProgress
                )
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)
                
                // Status Card
                VStack(spacing: 16) {
                    // Status Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(viewModel.statusTitle)
                                .font(.title3)
                                .fontWeight(.bold)
                            Text(viewModel.statusSubtitle)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // ETA Badge
                        VStack {
                            Text(viewModel.etaMinutes)
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("min")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.primary.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    // Progress Steps
                    OrderProgressView(currentStatus: viewModel.currentStatus)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(16)
                .padding(.horizontal)
                
                // Driver Info (if assigned)
                if let driver = viewModel.driver {
                    HStack(spacing: 12) {
                        AsyncImageView(url: driver.profileImageURL ?? "")
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(driver.fullName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text(driver.vehicleInfo)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button {
                            showContactDriver = true
                        } label: {
                            Image(systemName: "phone.fill")
                                .font(.body)
                                .foregroundColor(.primary)
                                .padding(12)
                                .background(Color.primary.opacity(0.1))
                                .clipShape(Circle())
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)
                    .padding(.horizontal)
                }
                
                // Order Details & Price Breakdown
                VStack(alignment: .leading, spacing: 16) {
                    Text("Order Details")
                        .font(.headline)
                    
                    // Items
                    VStack(spacing: 12) {
                        ForEach(order.items, id: \.id) { item in
                            HStack {
                                Text("\(item.quantity)x")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .frame(width: 28, alignment: .leading)
                                Text(item.name)
                                    .font(.subheadline)
                                Spacer()
                                Text(item.totalPrice.asCurrency)
                                    .font(.subheadline)
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Price Breakdown
                    VStack(spacing: 8) {
                        HStack {
                            Text("Subtotal")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(order.subtotal.asCurrency)
                        }
                        .font(.subheadline)
                        
                        HStack {
                            Text("Delivery Fee")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(order.deliveryFee.asCurrency)
                        }
                        .font(.subheadline)
                        
                        HStack {
                            Text("Service Fee")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(order.serviceFee.asCurrency)
                        }
                        .font(.subheadline)
                        
                        HStack {
                            Text("Tax")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(order.tax.asCurrency)
                        }
                        .font(.subheadline)
                        
                        if order.tipAmount > 0 {
                            HStack {
                                Text("Tip")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(order.tipAmount.asCurrency)
                            }
                            .font(.subheadline)
                        }
                        
                        if order.discount > 0 {
                            HStack {
                                Text("Discount")
                                    .foregroundColor(.green)
                                Spacer()
                                Text("-\(order.discount.asCurrency)")
                                    .foregroundColor(.green)
                            }
                            .font(.subheadline)
                        }
                    }
                    
                    Divider()
                    
                    // Total
                    HStack {
                        Text("Total")
                            .fontWeight(.semibold)
                        Spacer()
                        Text(order.total.asCurrency)
                            .fontWeight(.semibold)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(16)
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Order Tracking")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    viewModel.recenterMap()
                } label: {
                    Image(systemName: "location.fill")
                        .foregroundColor(.primary)
                }
            }
        }
        .sheet(isPresented: $showContactDriver) {
            ContactDriverSheet(driver: viewModel.driver)
        }
        .onAppear {
            viewModel.startTracking()
        }
        .onDisappear {
            viewModel.stopTracking()
        }
    }
}

// MARK: - Tracking Map View
struct TrackingMapView: View {
    let restaurantCoordinate: CLLocationCoordinate2D?
    let deliveryCoordinate: CLLocationCoordinate2D?
    let driverCoordinate: CLLocationCoordinate2D?
    let routeCoordinates: [CLLocationCoordinate2D]
    let driverProgress: Double
    
    var body: some View {
        Map {
            // Route polyline (full route - dashed)
            if routeCoordinates.count >= 2 {
                MapPolyline(coordinates: routeCoordinates)
                    .stroke(.primary.opacity(0.3), style: StrokeStyle(lineWidth: 5, dash: [10, 6]))
            }
            
            // Traveled path (solid primary, animated)
            if routeCoordinates.count >= 2, driverProgress > 0 {
                let traveledCount = max(2, Int(Double(routeCoordinates.count) * driverProgress))
                let traveledCoords = Array(routeCoordinates.prefix(traveledCount))
                MapPolyline(coordinates: traveledCoords)
                    .stroke(.primary, lineWidth: 5)
            }
            
            // Restaurant marker
            if let restaurant = restaurantCoordinate {
                Annotation("Restaurant", coordinate: restaurant) {
                    TrackingAnnotationView(type: .restaurant)
                }
            }
            
            // Delivery location marker
            if let delivery = deliveryCoordinate {
                Annotation("Delivery", coordinate: delivery) {
                    TrackingAnnotationView(type: .delivery)
                }
            }
            
            // Driver marker with animation
            if let driver = driverCoordinate {
                Annotation("Driver", coordinate: driver) {
                    DriverMarkerView()
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic))
    }
}

// MARK: - Driver Marker View (animated)
struct DriverMarkerView: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Pulse animation
            Circle()
                .fill(Color.primary.opacity(0.3))
                .frame(width: isAnimating ? 60 : 40, height: isAnimating ? 60 : 40)
                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isAnimating)
            
            // Driver icon background
            Circle()
                .fill(Color.primary)
                .frame(width: 44, height: 44)
                .shadow(color: .primary.opacity(0.5), radius: 8)
            
            // Driver icon
            Image(systemName: "car.fill")
                .font(.title3)
                .foregroundColor(Color(.systemBackground))
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Tracking Annotation
struct TrackingAnnotation: Identifiable {
    let id = UUID()
    let type: AnnotationType
    let coordinate: CLLocationCoordinate2D
    
    enum AnnotationType {
        case restaurant
        case delivery
    }
}

// MARK: - Tracking Annotation View
struct TrackingAnnotationView: View {
    let type: TrackingAnnotation.AnnotationType
    
    var body: some View {
        ZStack {
            Circle()
                .fill(backgroundColor)
                .frame(width: 44, height: 44)
                .shadow(color: backgroundColor.opacity(0.5), radius: 6)
            
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(.white)
        }
    }
    
    private var icon: String {
        switch type {
        case .restaurant: return "fork.knife"
        case .delivery: return "house.fill"
        }
    }
    
    private var backgroundColor: Color {
        switch type {
        case .restaurant: return .primary
        case .delivery: return .secondary
        }
    }
}

// MARK: - Order Progress View
struct OrderProgressView: View {
    let currentStatus: OrderStatus
    
    private let displayStatuses: [OrderStatus] = [.confirmed, .preparing, .readyForPickup, .onTheWay, .delivered]
    
    // Full order of statuses for comparison
    private let allStatuses: [OrderStatus] = [.pending, .confirmed, .preparing, .readyForPickup, .driverAssigned, .pickedUp, .onTheWay, .arriving, .delivered]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(displayStatuses.enumerated()), id: \.offset) { index, status in
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(isCompleted(status) ? Color.primary : Color(.systemGray4))
                            .frame(width: 32, height: 32)
                        
                        if isCompleted(status) {
                            Image(systemName: "checkmark")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(Color(.systemBackground))
                        } else if isCurrent(status) {
                            Circle()
                                .fill(Color.primary)
                                .frame(width: 12, height: 12)
                        }
                    }
                    
                    Text(status.shortTitle)
                        .font(.caption2)
                        .foregroundColor(isCompleted(status) || isCurrent(status) ? .primary : .secondary)
                        .multilineTextAlignment(.center)
                        .frame(width: 60)
                }
                
                if index < displayStatuses.count - 1 {
                    Rectangle()
                        .fill(isCompleted(displayStatuses[index + 1]) || isCurrent(displayStatuses[index + 1]) ? Color.primary : Color(.systemGray4))
                        .frame(height: 3)
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 24)
                }
            }
        }
    }
    
    private func isCompleted(_ status: OrderStatus) -> Bool {
        guard let currentIndex = allStatuses.firstIndex(of: currentStatus),
              let statusIndex = allStatuses.firstIndex(of: status) else {
            return false
        }
        return statusIndex < currentIndex
    }
    
    private func isCurrent(_ status: OrderStatus) -> Bool {
        // Map intermediate statuses to their display equivalent
        let mappedCurrent = mapToDisplayStatus(currentStatus)
        return status == mappedCurrent
    }
    
    private func mapToDisplayStatus(_ status: OrderStatus) -> OrderStatus {
        switch status {
        case .driverAssigned, .pickedUp:
            return .readyForPickup
        case .arriving:
            return .onTheWay
        default:
            return status
        }
    }
}

extension OrderStatus {
    var shortTitle: String {
        switch self {
        case .pending: return "Pending"
        case .confirmed: return "Confirmed"
        case .preparing: return "Preparing"
        case .readyForPickup: return "Ready"
        case .driverAssigned: return "Assigned"
        case .pickedUp: return "Picked Up"
        case .onTheWay: return "On Way"
        case .arriving: return "Arriving"
        case .delivered: return "Delivered"
        case .cancelled: return "Cancelled"
        case .refunded: return "Refunded"
        }
    }
}

// MARK: - Driver Info Card
struct DriverInfoCard: View {
    let driver: Driver
    let onContact: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Driver Photo
            AsyncImageView(url: driver.profileImageURL ?? "")
                .frame(width: 60, height: 60)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(driver.fullName)
                    .fontWeight(.semibold)
                
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.primary)
                        .font(.caption)
                    Text(String(format: "%.1f", driver.rating))
                        .font(.subheadline)
                    Text("•")
                        .foregroundColor(.secondary)
                    Text(driver.vehicleInfo)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button(action: onContact) {
                Image(systemName: "phone.fill")
                    .foregroundColor(Color(.systemBackground))
                    .padding(12)
                    .background(Color.primary)
                    .clipShape(Circle())
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Order Details Card
struct OrderDetailsCard: View {
    let order: Order
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 12) {
            Button {
                withAnimation {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Text("Order Details")
                        .fontWeight(.medium)
                    Spacer()
                    Text("\(order.items.count) items • \(order.total.asCurrency)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .foregroundColor(.primary)
            
            if isExpanded {
                VStack(spacing: 8) {
                    ForEach(order.items, id: \.id) { item in
                        HStack {
                            Text("\(item.quantity)x")
                                .foregroundColor(.secondary)
                                .frame(width: 30, alignment: .leading)
                            Text(item.name)
                                .font(.subheadline)
                            Spacer()
                            Text(item.totalPrice.asCurrency)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Contact Driver Sheet
struct ContactDriverSheet: View {
    let driver: Driver?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if let driver = driver {
                    // Driver Photo
                    AsyncImageView(url: driver.profileImageURL ?? "")
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                    
                    Text(driver.fullName)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    VStack(spacing: 16) {
                        ContactOptionButton(
                            icon: "phone.fill",
                            title: "Call Driver",
                            color: .primary
                        ) {
                            // Call driver
                            if let url = URL(string: "tel://\(driver.phone)") {
                                UIApplication.shared.open(url)
                            }
                        }
                        
                        ContactOptionButton(
                            icon: "message.fill",
                            title: "Send Message",
                            color: .secondary
                        ) {
                            // Open messages
                            if let url = URL(string: "sms://\(driver.phone)") {
                                UIApplication.shared.open(url)
                            }
                        }
                    }
                    .padding()
                } else {
                    Text("Driver information not available")
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.top, 32)
            .navigationTitle("Contact Driver")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Contact Option Button
struct ContactOptionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(Color(.systemBackground))
                    .frame(width: 44, height: 44)
                    .background(color)
                    .cornerRadius(12)
                
                Text(title)
                    .fontWeight(.medium)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
        .foregroundColor(.primary)
    }
}

#Preview {
    OrderTrackingView(
        order: Order(
            id: UUID().uuidString,
            orderNumber: "MUN-2024-001234",
            userId: UUID().uuidString,
            restaurantId: UUID().uuidString,
            restaurantName: "Burger Palace",
            restaurantImageURL: "https://images.unsplash.com/photo-1568901346375-23c9450c58cd",
            items: [],
            status: .onTheWay,
            subtotal: 25.98,
            deliveryFee: 2.99,
            serviceFee: 2.50,
            tax: 2.60,
            discount: 0,
            total: 35.47,
            deliveryAddress: "123 Main Street, San Francisco, CA 94102",
            deliveryLatitude: 37.7849,
            deliveryLongitude: -122.4094,
            deliveryInstructions: nil,
            paymentMethodId: UUID().uuidString,
            paymentMethodLast4: "4242",
            driverId: UUID().uuidString,
            driverName: "Alex Johnson",
            driverPhone: "+1234567890",
            driverImageURL: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d",
            driverLatitude: 37.7799,
            driverLongitude: -122.4144,
            driverVehicleInfo: "White Toyota Camry",
            estimatedDeliveryTime: Date().addingTimeInterval(1200),
            tipAmount: 4.00
        )
    )
}
