import SwiftUI
import SwiftData
import PhotosUI

// MARK: - Add / Edit Product View
struct AddEditProductView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    /// Pass a product to edit it; nil = create new
    var product: InventoryProductModel? = nil

    // Form state
    @State private var name: String = ""
    @State private var brand: String = ""
    @State private var category: InventoryCategory = .base
    @State private var priceText: String = ""
    @State private var quantityText: String = ""
    @State private var photoData: Data? = nil
    @State private var pickerItem: PhotosPickerItem? = nil

    var isEditing: Bool { product != nil }

    var title: String { isEditing ? "Edit Product" : "Add Product" }

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.18, green: 0.10, blue: 0.26),
                    Color(red: 0.24, green: 0.12, blue: 0.34)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Nav
                    HStack(spacing: 12) {
                        Button(action: { dismiss() }) {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.12))
                                    .frame(width: 36, height: 36)
                                Image(systemName: "arrow.left")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        Text(title)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 28)

                    // Photo picker
                    PhotosPicker(selection: $pickerItem, matching: .images) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white.opacity(0.08))
                                .frame(width: 140, height: 140)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .strokeBorder(
                                            Color(red: 0.90, green: 0.73, blue: 0.45).opacity(0.5),
                                            style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                                        )
                                )

                            if let data = photoData, let uiImage = UIImage(data: data) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 140, height: 140)
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                            } else {
                                VStack(spacing: 10) {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 26, weight: .light))
                                        .foregroundColor(Color(red: 0.90, green: 0.73, blue: 0.45))
                                    Text("Upload Image")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                            }
                        }
                    }
                    .onChange(of: pickerItem) { _, newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                photoData = data
                            }
                        }
                    }
                    .padding(.bottom, 32)

                    // Form fields
                    VStack(spacing: 14) {
                        InventoryField(label: "Product Name", placeholder: "Enter product name", text: $name)

                        InventoryField(label: "Brand", placeholder: "Enter brand name", text: $brand)

                        // Category picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Category")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.85))

                            Menu {
                                ForEach(InventoryCategory.allCases, id: \.self) { cat in
                                    Button(cat.rawValue.capitalized) { category = cat }
                                }
                            } label: {
                                HStack {
                                    Text(category.rawValue.capitalized)
                                        .font(.system(size: 16))
                                        .foregroundColor(.white.opacity(0.85))
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 13))
                                        .foregroundColor(.white.opacity(0.4))
                                }
                                .padding(.horizontal, 18)
                                .padding(.vertical, 16)
                                .background(
                                    Capsule()
                                        .fill(Color.white.opacity(0.10))
                                )
                            }
                        }

                        // Price + Quantity row
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Price ($)")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.85))
                                TextField("0", text: $priceText)
                                    .keyboardType(.numberPad)
                                    .font(.system(size: 16))
                                    .foregroundColor(.white.opacity(0.85))
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 16)
                                    .background(Capsule().fill(Color.white.opacity(0.10)))
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Quantity (ml)")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.85))
                                TextField("0", text: $quantityText)
                                    .keyboardType(.numberPad)
                                    .font(.system(size: 16))
                                    .foregroundColor(.white.opacity(0.85))
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 16)
                                    .background(Capsule().fill(Color.white.opacity(0.10)))
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    // Save button
                    Button(action: save) {
                        Text("Save Product")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(Color(red: 0.18, green: 0.10, blue: 0.26))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                Capsule()
                                    .fill(Color(red: 0.90, green: 0.73, blue: 0.45))
                            )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 32)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear { populateIfEditing() }
    }

    private func populateIfEditing() {
        guard let p = product else { return }
        name         = p.name
        brand        = p.brand ?? ""
        category     = p.category
        priceText    = p.price.map { "\($0)" } ?? ""
        quantityText = p.quantity.map { "\($0)" } ?? ""
        photoData    = p.photo
    }

    private func save() {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        if let existing = product {
            existing.name     = name
            existing.brand    = brand.isEmpty ? nil : brand
            existing.category = category
            existing.price    = Int(priceText)
            existing.quantity = Int(quantityText)
            existing.photo    = photoData
        } else {
            let new = InventoryProductModel(
                photo:    photoData,
                name:     name,
                brand:    brand.isEmpty ? nil : brand,
                category: category,
                price:    Int(priceText),
                quantity: Int(quantityText)
            )
            modelContext.insert(new)
        }

        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Field Component
struct InventoryField: View {
    let label: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.85))
            TextField(placeholder, text: $text)
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.85))
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .background(Capsule().fill(Color.white.opacity(0.10)))
        }
    }
}

#Preview {
    AddEditProductView()
        .modelContainer(for: InventoryProductModel.self, inMemory: true)
}
