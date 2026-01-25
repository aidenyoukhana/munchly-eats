import SwiftUI
import Combine

struct AddressListView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @State private var showAddAddress = false
    @State private var editingAddress: Address? = nil
    
    var body: some View {
        Group {
            if viewModel.savedAddresses.isEmpty {
                EmptyStateView(
                    icon: "location.slash",
                    title: "No Saved Addresses",
                    message: "Add your delivery addresses for faster checkout"
                )
            } else {
                List {
                    ForEach(viewModel.savedAddresses) { address in
                        AddressRow(
                            address: address,
                            isDefault: address.isDefault,
                            onEdit: {
                                editingAddress = address
                            },
                            onSetDefault: {
                                Task {
                                    viewModel.setDefaultAddress(address.id)
                                }
                            }
                        )
                    }
                    .onDelete { indexSet in
                        Task {
                            for index in indexSet {
                                viewModel.deleteAddress(viewModel.savedAddresses[index].id)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Saved Addresses")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showAddAddress = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddAddress) {
            AddEditAddressView(viewModel: viewModel, address: nil)
        }
        .sheet(item: $editingAddress) { address in
            AddEditAddressView(viewModel: viewModel, address: address)
        }
    }
}

// MARK: - Address Row
struct AddressRow: View {
    let address: Address
    let isDefault: Bool
    let onEdit: () -> Void
    let onSetDefault: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: address.addressType.icon)
                    .foregroundColor(.primary)
                
                Text(address.label)
                    .fontWeight(.semibold)
                
                if isDefault {
                    Text("Default")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(Color(.systemBackground))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.primary)
                        .clipShape(Capsule())
                }
                
                Spacer()
                
                Menu {
                    Button {
                        onEdit()
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    
                    if !isDefault {
                        Button {
                            onSetDefault()
                        } label: {
                            Label("Set as Default", systemImage: "star")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.secondary)
                }
            }
            
            Text(address.fullAddress)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if let instructions = address.instructions, !instructions.isEmpty {
                Text("Note: \(instructions)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Add/Edit Address View
struct AddEditAddressView: View {
    @ObservedObject var viewModel: ProfileViewModel
    let address: Address?
    @Environment(\.dismiss) private var dismiss
    
    @State private var label: String = ""
    @State private var street: String = ""
    @State private var apartment: String = ""
    @State private var city: String = ""
    @State private var state: String = ""
    @State private var zipCode: String = ""
    @State private var deliveryInstructions: String = ""
    @State private var selectedType: AddressType = .home
    @State private var isDefault: Bool = false
    
    private var isEditing: Bool { address != nil }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Address Type") {
                    Picker("Type", selection: $selectedType) {
                        ForEach(AddressType.allCases, id: \.self) { type in
                            Label(type.rawValue.capitalized, systemImage: type.icon)
                                .tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    TextField("Label (e.g., Home, Work)", text: $label)
                }
                
                Section("Address Details") {
                    TextField("Street Address", text: $street)
                    TextField("Apt, Suite, Floor (optional)", text: $apartment)
                    TextField("City", text: $city)
                    
                    HStack {
                        TextField("State", text: $state)
                        TextField("ZIP Code", text: $zipCode)
                            .keyboardType(.numberPad)
                    }
                }
                
                Section("Delivery Instructions") {
                    TextField("Instructions for driver (optional)", text: $deliveryInstructions, axis: .vertical)
                        .lineLimit(3...5)
                }
                
                Section {
                    Toggle("Set as default address", isOn: $isDefault)
                }
            }
            .navigationTitle(isEditing ? "Edit Address" : "Add Address")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveAddress()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isValid)
                }
            }
            .onAppear {
                if let address = address {
                    label = address.label
                    street = address.street
                    apartment = address.apartment ?? ""
                    city = address.city
                    state = address.state
                    zipCode = address.zipCode
                    deliveryInstructions = address.instructions ?? ""
                    selectedType = address.addressType
                    isDefault = address.isDefault
                }
            }
        }
    }
    
    private var isValid: Bool {
        !label.isEmpty && !street.isEmpty && !city.isEmpty && !state.isEmpty && !zipCode.isEmpty
    }
    
    private func saveAddress() {
        Task {
            if let existingAddress = address {
                // Update existing - modify the address properties
                existingAddress.label = label
                existingAddress.street = street
                existingAddress.apartment = apartment.isEmpty ? nil : apartment
                existingAddress.city = city
                existingAddress.state = state
                existingAddress.zipCode = zipCode
                existingAddress.instructions = deliveryInstructions.isEmpty ? nil : deliveryInstructions
                existingAddress.addressType = selectedType
                existingAddress.isDefault = isDefault
                viewModel.updateAddress(existingAddress)
            } else {
                // Create new
                let newAddress = Address(
                    label: label,
                    street: street,
                    apartment: apartment.isEmpty ? nil : apartment,
                    city: city,
                    state: state,
                    zipCode: zipCode,
                    latitude: 0, // Would need geocoding in real app
                    longitude: 0,
                    isDefault: isDefault,
                    instructions: deliveryInstructions.isEmpty ? nil : deliveryInstructions,
                    addressType: selectedType
                )
                viewModel.addAddress(newAddress)
            }
            dismiss()
        }
    }
}

#Preview {
    AddressListView(viewModel: ProfileViewModel())
}
