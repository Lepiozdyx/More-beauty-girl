import SwiftUI
import SwiftData

// MARK: - Session Result View (Screen 3)
struct SessionResultView: View {
    let interval: TimeInterval
    let category: SessionCategory
    let productIDs: [UUID]
    @Query var allInventory: [InventoryProductModel]

    var products: [InventoryProductModel] { allInventory.filter { productIDs.contains($0.id) } }
    let onClose: () -> Void

    @State private var showAnalytics = false

    var timeString: String {
        let total = Int(interval)
        let m = total / 60
        let s = total % 60
        return String(format: "%d:%02d", m, s)
    }

    var badge: (emoji: String, title: String, subtitle: String, bg: Color) {
        switch interval {
        case 0..<300:
            return ("⚡", "Lightning", "< 5 min", Color(red: 0.82, green: 0.68, blue: 0.38))
        case 300..<600:
            return ("🌟", "Express", "5–10 min", Color(red: 0.55, green: 0.42, blue: 0.72))
        case 600..<1200:
            return ("✨", "Glam", "10–20 min", Color(red: 0.45, green: 0.55, blue: 0.75))
        default:
            return ("👑", "Full Glam", "20+ min", Color(red: 0.60, green: 0.38, blue: 0.65))
        }
    }

    var tip: String {
        switch category {
        case .work:    return "Perfect for work! Try prepping products beforehand next time."
        case .date:    return "Great date look! A setting spray will make it last all night."
        case .party:   return "Party ready! Don't forget to touch up lips after dinner."
        case .express: return "Speed run complete! Practice makes it even faster."
        case .relax:   return "Relaxed and refreshed. Great self-care session!"
        case .custom:  return "Custom session done. Save this routine for next time!"
        }
    }

    var body: some View {
        ZStack {
            Color(red: 0.18, green: 0.08, blue: 0.22).ignoresSafeArea()

            RadialGradient(
                colors: [Color(red: 0.50, green: 0.25, blue: 0.60).opacity(0.45), .clear],
                center: .top,
                startRadius: 0,
                endRadius: 400
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Session Complete asset
                    Image("sessionComplete")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 180)
                        .padding(.top, 50)
                        .padding(.bottom, 4)

                    // Time
                    Text(timeString)
                        .font(.system(size: 64, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(.bottom, 20)

                    // Badge card
                    let b = badge
                    VStack(spacing: 8) {
                        Text(b.emoji)
                            .font(.system(size: 40))
                        Text(b.title)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                        Text(b.subtitle)
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .frame(width: 130, height: 130)
                    .background(
                        RoundedRectangle(cornerRadius: 22)
                            .fill(b.bg)
                    )
                    .padding(.bottom, 20)

                    // Tip
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "lightbulb")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.top, 2)
                        Text(tip)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.leading)
                    }
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.08)))
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)

                    // Used Products
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Used Products")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.horizontal, 24)

                        VStack(spacing: 0) {
                            ForEach(Array(products.enumerated()), id: \.offset) { index, product in
                                HStack(spacing: 14) {
                                    if let data = product.photo, let uiImage = UIImage(data: data) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 32, height: 32)
                                            .clipShape(Circle())
                                    } else {
                                        Text(categoryEmoji(product.category))
                                            .font(.system(size: 22))
                                            .frame(width: 32, height: 32)
                                    }
                                    Text(product.name)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(.white)
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)

                                if index < products.count - 1 {
                                    Divider()
                                        .background(Color.white.opacity(0.08))
                                        .padding(.horizontal, 16)
                                }
                            }
                        }
                        .background(RoundedRectangle(cornerRadius: 18).fill(Color.white.opacity(0.08)))
                        .padding(.horizontal, 24)
                    }
                    .padding(.bottom, 24)

                    // Buttons
                    VStack(spacing: 10) {
                        Button(action: { showAnalytics = true }) {
                            Text("View Analytics")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.10)))
                        }

                        Button(action: onClose) {
                            Text("Close")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white.opacity(0.6))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.05)))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 50)
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showAnalytics) {
            AnalyticsView()
        }
    }

    private func categoryEmoji(_ cat: InventoryCategory) -> String {
        switch cat {
        case .base: return "🧴"
        case .eyes: return "👁️"
        case .lips: return "💄"
        case .face: return "🌸"
        case .brows: return "✏️"
        case .special: return "⭐"
        }
    }
}
