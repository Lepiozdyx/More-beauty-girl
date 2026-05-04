import SwiftUI
import SwiftData

// MARK: - Inventory List View
struct InventoryView: View {
    @Query private var products: [InventoryProductModel]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var onSelect: ((InventoryProductModel) -> Void)? = nil

    @State private var selectedCategory: InventoryCategory? = nil
    @State private var showAddSheet = false
    @State private var productToEdit: InventoryProductModel? = nil

    var filteredProducts: [InventoryProductModel] {
        guard let cat = selectedCategory else { return products }
        return products.filter { $0.category == cat }
    }

    var isPickerMode: Bool { onSelect != nil }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color(red: 0.18, green: 0.10, blue: 0.26).ignoresSafeArea()

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
                    Text("My Inventory")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 16)

                // Category tabs
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        CategoryChip(title: "All", selected: selectedCategory == nil) {
                            selectedCategory = nil
                        }
                        ForEach(InventoryCategory.allCases, id: \.self) { cat in
                            CategoryChip(
                                title: cat.rawValue.capitalized,
                                selected: selectedCategory == cat
                            ) {
                                selectedCategory = cat
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 16)

                // List
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 10) {
                        ForEach(filteredProducts) { product in
                            ProductRow(product: product)
                                .onTapGesture {
                                    if isPickerMode {
                                        onSelect?(product)
                                        dismiss()
                                    } else {
                                        productToEdit = product
                                    }
                                }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
            }

            // FAB — only in default mode
            if !isPickerMode {
                Button(action: { showAddSheet = true }) {
                    ZStack {
                        Circle()
                            .fill(Color(red: 0.90, green: 0.73, blue: 0.45))
                            .frame(width: 56, height: 56)
                            .shadow(color: Color(red: 0.90, green: 0.73, blue: 0.45).opacity(0.5), radius: 12, x: 0, y: 4)
                        Image(systemName: "plus")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(Color(red: 0.18, green: 0.10, blue: 0.26))
                    }
                }
                .padding(.trailing, 20)
                .padding(.bottom, 32)
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showAddSheet) {
            AddEditProductView()
        }
        .sheet(item: $productToEdit) { product in
            AddEditProductView(product: product)
        }
    }
}

// MARK: - Category Chip
struct CategoryChip: View {
    let title: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: selected ? .semibold : .regular))
                .foregroundColor(selected ? Color(red: 0.18, green: 0.10, blue: 0.26) : .white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(selected
                              ? Color(red: 0.90, green: 0.73, blue: 0.45)
                              : Color.white.opacity(0.12))
                )
        }
    }
}

// MARK: - Product Row
struct ProductRow: View {
    let product: InventoryProductModel

    var categoryEmoji: String {
        switch product.category {
        case .base:    return "🧴"
        case .eyes:    return "👁️"
        case .lips:    return "💄"
        case .face:    return "✨"
        case .brows:   return "✏️"
        case .special: return "⭐"
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            // Photo or emoji fallback
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.10))
                    .frame(width: 56, height: 56)

                if let data = product.photo, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 56, height: 56)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                } else {
                    Text(categoryEmoji)
                        .font(.system(size: 26))
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                if let brand = product.brand {
                    Text(brand)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.55))
                }
                HStack(spacing: 12) {
                    if let price = product.price {
                        Text("$\(price)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(red: 0.90, green: 0.73, blue: 0.45))
                    }
                    if let qty = product.quantity {
                        Text("\(qty) ml")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.45))
                    }
                }
            }

            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.08))
        )
    }
}

#Preview {
    InventoryView()
        .modelContainer(for: InventoryProductModel.self, inMemory: true)
}
