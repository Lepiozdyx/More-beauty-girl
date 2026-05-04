import SwiftUI
import SwiftData

// MARK: - Home View (Screen 1)
struct HomeView: View {
    @Query private var sessions: [SessionModel]
    @Query private var inventory: [InventoryProductModel]
    @Environment(\.modelContext) private var modelContext

    @State private var selectedCategory: SessionCategory = .work
    @State private var selectedProductIDs: Set<UUID> = []
    @State private var showSession = false
    @State private var showInventoryFull = false
    @State private var showAnalytics = false
    @State private var showAchievements = false

    var selectedProducts: [InventoryProductModel] {
        inventory.filter { selectedProductIDs.contains($0.id) }
    }

    var todaySessions: Int {
        let today = Calendar.current.startOfDay(for: Date())
        return sessions.filter { Calendar.current.startOfDay(for: $0.date) == today }.count
    }

    var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good morning, Beauty"
        case 12..<17: return "Good afternoon, Beauty"
        default: return "Good evening, Beauty"
        }
    }

    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text(greetingText)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    Text("\(todaySessions) sessions today")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(red: 0.90, green: 0.73, blue: 0.45))
                }
                .padding(.horizontal, 20)
                .padding(.top, 56)
                .padding(.bottom, 24)

                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Choose Category")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.horizontal, 20)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(SessionCategory.allCases, id: \.self) { cat in
                                    CategoryCard(category: cat, selected: selectedCategory == cat) {
                                        selectedCategory = cat
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.bottom, 28)

                    // Products section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Select Products")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                            Spacer()
                            Button(action: { showInventoryFull = true }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 12, weight: .semibold))
                                    Text("Add from inventory")
                                        .font(.system(size: 13, weight: .medium))
                                }
                                .foregroundColor(Color(red: 0.90, green: 0.73, blue: 0.45))
                            }
                        }
                        .padding(.horizontal, 20)

                        // 2-column grid from inventory with checkboxes
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            ForEach(inventory) { product in
                                let isSelected = selectedProductIDs.contains(product.id)
                                ProductGridCell(
                                    item: ProductGridItem(
                                        name: product.name,
                                        emoji: product.systemAsset ?? categoryEmoji(product.category),
                                        inventoryProduct: product
                                    ),
                                    isSelected: isSelected
                                ) {
                                    if isSelected {
                                        selectedProductIDs.remove(product.id)
                                    } else {
                                        selectedProductIDs.insert(product.id)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    Spacer()

                    // START button
                    Button(action: { showSession = true }) {
                        Text("START")
                            .font(.system(size: 18, weight: .bold))
                            .tracking(2)
                            .foregroundColor(selectedProducts.isEmpty ? .white.opacity(0.3) : .white.opacity(0.85))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(Color.white.opacity(selectedProducts.isEmpty ? 0.05 : 0.12))
                            )
                    }
                    .disabled(selectedProducts.isEmpty)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                }
            }

            // Bottom nav
            BottomNav(
                onAnalyticsTap: { showAnalytics = true },
                onAchievementsTap: { showAchievements = true },
                onInventoryTap: { showInventoryFull = true }
            )
        }
        .bg()
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $showSession) {
            SessionActiveView(
                category: selectedCategory,
                productIDs: Array(selectedProductIDs),
                onComplete: { interval in
                    saveSession(interval: interval)
                }
            )
        }
        .sheet(isPresented: $showAnalytics) {
            AnalyticsView()
        }
        .sheet(isPresented: $showAchievements) {
            AchievementsView()
        }
        .sheet(isPresented: $showInventoryFull) {
            InventoryView()
        }
        .onAppear {
            InventoryProductFactory.seedIfNeeded(existing: inventory) { model in
                modelContext.insert(model)
            }
            try? modelContext.save()
        }
    }

    private func categoryEmoji(_ cat: InventoryCategory) -> String {
        switch cat {
        case .base:    return "🧴"
        case .eyes:    return "👁️"
        case .lips:    return "💄"
        case .face:    return "🌸"
        case .brows:   return "✏️"
        case .special: return "⭐"
        }
    }

    private func saveSession(interval: TimeInterval) {
        let session = SessionModel(
            timeInterval: interval,
            category: selectedCategory,
            products: Array(selectedProductIDs)
        )
        modelContext.insert(session)
        try? modelContext.save()
    }
}

// MARK: - Product Grid Item (local model)
struct ProductGridItem: Identifiable {
    let id = UUID()
    let name: String
    let emoji: String
    let inventoryProduct: InventoryProductModel?
}

// MARK: - Product Grid Cell
struct ProductGridCell: View {
    let item: ProductGridItem
    var isSelected: Bool = false
    var onTap: (() -> Void)? = nil

    var body: some View {
        Button(action: { onTap?() }) {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 10) {
                    if let data = item.inventoryProduct?.photo, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 44, height: 44)
                            .clipShape(Circle())
                    } else {
                        Text(item.emoji)
                            .font(.system(size: 36))
                    }
                    Text(item.name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(isSelected
                              ? Color(red: 0.90, green: 0.73, blue: 0.45).opacity(0.18)
                              : Color.white.opacity(0.09))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .strokeBorder(
                            isSelected ? Color(red: 0.90, green: 0.73, blue: 0.45) : Color.clear,
                            lineWidth: 1.5
                        )
                )

                // Checkmark badge
                if isSelected {
                    ZStack {
                        Circle()
                            .fill(Color(red: 0.90, green: 0.73, blue: 0.45))
                            .frame(width: 20, height: 20)
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color(red: 0.18, green: 0.08, blue: 0.22))
                    }
                    .offset(x: -8, y: 8)
                }
            }
        }
    }
}

// MARK: - Category Card
struct CategoryCard: View {
    let category: SessionCategory
    let selected: Bool
    let action: () -> Void

    var emoji: String {
        switch category {
        case .work:    return "💼"
        case .date:    return "💕"
        case .party:   return "🎉"
        case .express: return "🏃"
        case .relax:   return "🧘"
        case .custom:  return "✨"
        }
    }

    var bgColor: Color {
        switch category {
        case .work:    return Color(red: 0.45, green: 0.35, blue: 0.55)
        case .date:    return Color(red: 0.75, green: 0.45, blue: 0.55)
        case .party:   return Color(red: 0.75, green: 0.50, blue: 0.40)
        case .express: return Color(red: 0.75, green: 0.62, blue: 0.35)
        case .relax:   return Color(red: 0.50, green: 0.40, blue: 0.65)
        case .custom:  return Color(red: 0.40, green: 0.45, blue: 0.70)
        }
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(emoji)
                    .font(.system(size: 28))
                Text(category.rawValue.capitalized)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
            }
            .frame(width: 80, height: 80)
            .background(bgColor)
            .cornerRadius(18)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(
                        selected ? Color(red: 0.90, green: 0.73, blue: 0.45) : Color.clear,
                        lineWidth: 2
                    )
            )
        }
    }
}

// MARK: - Bottom Nav
struct BottomNav: View {
    let onAnalyticsTap: () -> Void
    let onAchievementsTap: () -> Void
    let onInventoryTap: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            Spacer()
            NavButton(icon: "chart.bar", active: false, action: onAnalyticsTap)
            Spacer()
            NavButton(icon: "trophy", active: false, action: onAchievementsTap)
            Spacer()
            NavButton(icon: "shippingbox", active: false, action: onInventoryTap)
            Spacer()
        }
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(Color(red: 0.14, green: 0.08, blue: 0.22))
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 24)
    }
}

struct NavButton: View {
    let icon: String
    let active: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(active ? Color(red: 0.90, green: 0.73, blue: 0.45) : .white.opacity(0.35))
                .frame(width: 56, height: 40)
        }
    }
}
