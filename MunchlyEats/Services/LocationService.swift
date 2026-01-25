import Foundation
import Combine
import CoreLocation
import MapKit

// MARK: - Location Service
@MainActor
class LocationService: NSObject, ObservableObject {
    static let shared = LocationService()
    
    @Published var currentLocation: CLLocation?
    @Published var currentAddress: String = "Loading..."
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isLoading = false
    @Published var error: Error?
    @Published var savedAddresses: [Address] = []
    @Published var selectedAddress: Address?
    
    private let locationManager = CLLocationManager()
    
    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        loadSavedAddresses()
    }
    
    // MARK: - Request Permission
    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    // MARK: - Start Updating Location
    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }
    
    // MARK: - Stop Updating Location
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
    
    // MARK: - Reverse Geocode
    func reverseGeocode(location: CLLocation) async -> String? {
        guard let request = MKReverseGeocodingRequest(location: location) else {
            return nil
        }
        
        do {
            let mapItems = try await request.mapItems
            if let mapItem = mapItems.first,
               let addressRepresentations = mapItem.addressRepresentations {
                return addressRepresentations.fullAddress(includingRegion: false, singleLine: true)
            }
        } catch {
            print("Geocoding error: \(error)")
        }
        return nil
    }
    
    // MARK: - Search Address
    func searchAddress(_ query: String) async -> [MKMapItem] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        
        if let location = currentLocation {
            request.region = MKCoordinateRegion(
                center: location.coordinate,
                latitudinalMeters: 10000,
                longitudinalMeters: 10000
            )
        }
        
        do {
            let search = MKLocalSearch(request: request)
            let response = try await search.start()
            return response.mapItems
        } catch {
            print("Search error: \(error)")
            return []
        }
    }
    
    // MARK: - Load Saved Addresses
    private func loadSavedAddresses() {
        // Mock saved addresses
        savedAddresses = [
            Address(
                id: "addr_1",
                label: "Home",
                street: "123 Main Street",
                apartment: "4B",
                city: "San Francisco",
                state: "CA",
                zipCode: "94102",
                latitude: 37.7749,
                longitude: -122.4194,
                isDefault: true,
                instructions: "Ring doorbell twice",
                addressType: .home
            ),
            Address(
                id: "addr_2",
                label: "Work",
                street: "456 Market Street",
                apartment: "Suite 800",
                city: "San Francisco",
                state: "CA",
                zipCode: "94103",
                latitude: 37.7897,
                longitude: -122.4001,
                isDefault: false,
                instructions: "Leave at reception",
                addressType: .work
            )
        ]
        
        // Set default address as selected
        selectedAddress = savedAddresses.first { $0.isDefault } ?? savedAddresses.first
    }
    
    // MARK: - Add Address
    func addAddress(_ address: Address) {
        if address.isDefault {
            // Remove default from others
            for i in savedAddresses.indices {
                savedAddresses[i].isDefault = false
            }
        }
        savedAddresses.append(address)
        
        if address.isDefault || selectedAddress == nil {
            selectedAddress = address
        }
    }
    
    // MARK: - Update Address
    func updateAddress(_ address: Address) {
        if let index = savedAddresses.firstIndex(where: { $0.id == address.id }) {
            if address.isDefault {
                // Remove default from others
                for i in savedAddresses.indices {
                    savedAddresses[i].isDefault = false
                }
            }
            savedAddresses[index] = address
            
            if address.isDefault {
                selectedAddress = address
            }
        }
    }
    
    // MARK: - Delete Address
    func deleteAddress(_ addressId: String) {
        savedAddresses.removeAll { $0.id == addressId }
        
        if selectedAddress?.id == addressId {
            selectedAddress = savedAddresses.first
        }
    }
    
    // MARK: - Set Default Address
    func setDefaultAddress(_ addressId: String) {
        for i in savedAddresses.indices {
            savedAddresses[i].isDefault = savedAddresses[i].id == addressId
        }
        selectedAddress = savedAddresses.first { $0.id == addressId }
    }
    
    // MARK: - Calculate Distance
    func calculateDistance(to destination: CLLocationCoordinate2D) -> Double? {
        guard let currentLocation = currentLocation else { return nil }
        
        let destinationLocation = CLLocation(latitude: destination.latitude, longitude: destination.longitude)
        return currentLocation.distance(from: destinationLocation) / 1609.34 // Convert to miles
    }
    
    // MARK: - Calculate Route
    func calculateRoute(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) async -> MKRoute? {
        let request = MKDirections.Request()
        request.source = MKMapItem(location: CLLocation(latitude: source.latitude, longitude: source.longitude), address: nil)
        request.destination = MKMapItem(location: CLLocation(latitude: destination.latitude, longitude: destination.longitude), address: nil)
        request.transportType = .automobile
        
        do {
            let directions = MKDirections(request: request)
            let response = try await directions.calculate()
            return response.routes.first
        } catch {
            print("Route calculation error: \(error)")
            return nil
        }
    }
    
    // MARK: - Format Address
    private func formatAddress(from placemark: CLPlacemark) -> String {
        var components: [String] = []
        
        if let streetNumber = placemark.subThoroughfare,
           let street = placemark.thoroughfare {
            components.append("\(streetNumber) \(street)")
        } else if let street = placemark.thoroughfare {
            components.append(street)
        }
        
        if let city = placemark.locality {
            components.append(city)
        }
        
        if let state = placemark.administrativeArea {
            components.append(state)
        }
        
        return components.joined(separator: ", ")
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        Task { @MainActor in
            self.authorizationStatus = status
            
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                self.startUpdatingLocation()
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            guard let location = locations.last else { return }
            self.currentLocation = location
            
            if let address = await self.reverseGeocode(location: location) {
                self.currentAddress = address
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.error = error
            print("Location error: \(error.localizedDescription)")
        }
    }
}
