import SwiftUI
import SwiftData

// MARK: - Achievement Definition
struct AchievementDef: Identifiable {
    let id: String
    let emoji: String
    let title: String
    let description: String
    let check: ([SessionModel], [InventoryProductModel]) -> Bool
}

// MARK: - Rank Definition
struct RankDef: Identifiable {
    let id: String
    let emoji: String
    let title: String
    let description: String
    let gradient: [Color]
    let check: ([SessionModel], [InventoryProductModel]) -> Bool
}

// MARK: - Achievements View
struct AchievementsView: View {
    @Query private var sessions: [SessionModel]
    @Query private var inventory: [InventoryProductModel]
    @Environment(\.dismiss) private var dismiss

    // MARK: Ranks
    let ranks: [RankDef] = [
        RankDef(
            id: "lightning",
            emoji: "⚡",
            title: "Lightning",
            description: "Complete a session in under 5 minutes",
            gradient: [Color(red: 0.95, green: 0.80, blue: 0.45), Color(red: 0.85, green: 0.60, blue: 0.30)],
            check: { sessions, _ in sessions.contains { $0.timeInterval < 300 } }
        ),
        RankDef(
            id: "smart",
            emoji: "🌸",
            title: "Smart",
            description: "Maintain 5–10 min average for a week",
            gradient: [Color(red: 0.95, green: 0.65, blue: 0.65), Color(red: 0.80, green: 0.50, blue: 0.60)],
            check: { sessions, _ in
                let week = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
                let recent = sessions.filter { $0.date >= week }
                guard recent.count >= 3 else { return false }
                let avg = recent.map(\.timeInterval).reduce(0,+) / Double(recent.count)
                return avg >= 300 && avg <= 600
            }
        ),
        RankDef(
            id: "beauty",
            emoji: "💄",
            title: "Beauty",
            description: "Complete 20 sessions",
            gradient: [Color(red: 0.85, green: 0.55, blue: 0.75), Color(red: 0.70, green: 0.40, blue: 0.65)],
            check: { sessions, _ in sessions.count >= 20 }
        ),
        RankDef(
            id: "goddess",
            emoji: "👑",
            title: "Goddess",
            description: "Perfect your routine (20–35 min)",
            gradient: [Color(red: 0.80, green: 0.65, blue: 0.85), Color(red: 0.60, green: 0.45, blue: 0.75)],
            check: { sessions, _ in sessions.contains { $0.timeInterval >= 1200 && $0.timeInterval <= 2100 } }
        ),
        RankDef(
            id: "artist",
            emoji: "🎨",
            title: "Artist",
            description: "Create a masterpiece (35+ min)",
            gradient: [Color(red: 0.65, green: 0.55, blue: 0.90), Color(red: 0.45, green: 0.35, blue: 0.80)],
            check: { sessions, _ in sessions.contains { $0.timeInterval >= 2100 } }
        )
    ]

    // MARK: Achievements
    let achievements: [AchievementDef] = [
        AchievementDef(id: "streak7", emoji: "🔥", title: "7 Day Streak", description: "Log sessions 7 days in a row",
            check: { sessions, _ in
                let calendar = Calendar.current
                var streak = 0
                for i in 0..<7 {
                    let day = calendar.date(byAdding: .day, value: -i, to: Date())!
                    let start = calendar.startOfDay(for: day)
                    let end = calendar.date(byAdding: .day, value: 1, to: start)!
                    if sessions.contains(where: { $0.date >= start && $0.date < end }) { streak += 1 } else { break }
                }
                return streak >= 7
            }),
        AchievementDef(id: "earlybird", emoji: "⭐", title: "Early Bird", description: "Complete a session before 8 AM",
            check: { sessions, _ in
                sessions.contains { Calendar.current.component(.hour, from: $0.date) < 8 }
            }),
        AchievementDef(id: "nightowl", emoji: "🌙", title: "Night Owl", description: "Complete a session after 10 PM",
            check: { sessions, _ in
                sessions.contains { Calendar.current.component(.hour, from: $0.date) >= 22 }
            }),
        AchievementDef(id: "perfectionist", emoji: "💯", title: "Perfectionist", description: "Use 6+ products in one session",
            check: { sessions, _ in sessions.contains { $0.products.count >= 6 } }),
        AchievementDef(id: "consistent", emoji: "🎯", title: "Consistent", description: "Complete 5 sessions in one week",
            check: { sessions, _ in
                let week = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
                return sessions.filter { $0.date >= week }.count >= 5
            }),
        AchievementDef(id: "premium", emoji: "💎", title: "Premium", description: "Add 10+ products to inventory",
            check: { _, inventory in inventory.count >= 10 }),
        AchievementDef(id: "speeddemon", emoji: "⚡", title: "Speed Demon", description: "Complete 3 sessions under 5 min",
            check: { sessions, _ in sessions.filter { $0.timeInterval < 300 }.count >= 3 }),
        AchievementDef(id: "variety", emoji: "🌈", title: "Variety", description: "Use all 6 session categories",
            check: { sessions, _ in
                Set(sessions.map(\.category)).count == SessionCategory.allCases.count
            }),
        AchievementDef(id: "collector", emoji: "💎", title: "Collector", description: "Add 20+ products to inventory",
            check: { _, inventory in inventory.count >= 20 }),
        AchievementDef(id: "master", emoji: "🏆", title: "Master", description: "Unlock all other achievements",
            check: { _, _ in false }) // computed dynamically below
    ]

    // MARK: Unlock checks
    func isRankUnlocked(_ rank: RankDef) -> Bool {
        rank.check(sessions, inventory)
    }

    func isAchievementUnlocked(_ ach: AchievementDef) -> Bool {
        if ach.id == "master" {
            // Master unlocks when all other achievements are unlocked
            let others = achievements.filter { $0.id != "master" }
            return others.allSatisfy { isAchievementUnlocked($0) }
        }
        return ach.check(sessions, inventory)
    }

    var unlockedCount: Int {
        let r = ranks.filter { isRankUnlocked($0) }.count
        let a = achievements.filter { isAchievementUnlocked($0) }.count
        return r + a
    }

    var totalCount: Int { ranks.count + achievements.count }

    var body: some View {
        ZStack {
            Color(red: 0.16, green: 0.07, blue: 0.24).ignoresSafeArea()
            RadialGradient(
                colors: [Color(red: 0.40, green: 0.15, blue: 0.55).opacity(0.4), .clear],
                center: .top, startRadius: 0, endRadius: 500
            )
            .ignoresSafeArea()

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
                    Text("Achievements")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 16)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Progress card
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Progress")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.6))
                                Spacer()
                                Text("\(unlockedCount)/\(totalCount) unlocked")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Color.white.opacity(0.10))
                                        .frame(height: 8)
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: [Color(red: 0.90, green: 0.73, blue: 0.45), Color(red: 0.80, green: 0.55, blue: 0.30)],
                                                startPoint: .leading, endPoint: .trailing
                                            )
                                        )
                                        .frame(width: geo.size.width * CGFloat(unlockedCount) / CGFloat(max(totalCount, 1)), height: 8)
                                        .animation(.easeOut(duration: 0.6), value: unlockedCount)
                                }
                            }
                            .frame(height: 8)
                        }
                        .padding(18)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(Color.white.opacity(0.07))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18)
                                        .strokeBorder(Color(red: 0.90, green: 0.73, blue: 0.45).opacity(0.25), lineWidth: 1)
                                )
                        )
                        .padding(.horizontal, 20)

                        // Ranks section
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Ranks")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.horizontal, 20)

                            VStack(spacing: 10) {
                                ForEach(ranks) { rank in
                                    RankRow(rank: rank, unlocked: isRankUnlocked(rank))
                                }
                            }
                            .padding(.horizontal, 20)
                        }

                        // Achievements section
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Achievements")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.horizontal, 20)

                            LazyVGrid(
                                columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                                spacing: 10
                            ) {
                                ForEach(achievements) { ach in
                                    AchievementCell(achievement: ach, unlocked: isAchievementUnlocked(ach))
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Rank Row
struct RankRow: View {
    let rank: RankDef
    let unlocked: Bool

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(unlocked
                          ? LinearGradient(colors: rank.gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                          : LinearGradient(colors: [Color.white.opacity(0.06), Color.white.opacity(0.06)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 48, height: 48)
                if unlocked {
                    Text(rank.emoji)
                        .font(.system(size: 24))
                } else {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.25))
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(rank.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(unlocked ? .white : .white.opacity(0.35))
                Text(rank.description)
                    .font(.system(size: 12))
                    .foregroundColor(unlocked ? .white.opacity(0.65) : .white.opacity(0.25))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            if unlocked {
                Image(systemName: "sparkles")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(unlocked
                      ? LinearGradient(
                            colors: rank.gradient.map { $0.opacity(0.22) },
                            startPoint: .topLeading, endPoint: .bottomTrailing)
                      : LinearGradient(
                            colors: [Color.white.opacity(0.06), Color.white.opacity(0.06)],
                            startPoint: .topLeading, endPoint: .bottomTrailing))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(
                    unlocked
                        ? LinearGradient(colors: rank.gradient.map { $0.opacity(0.5) }, startPoint: .topLeading, endPoint: .bottomTrailing)
                        : LinearGradient(colors: [Color.clear], startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 1
                )
        )
    }
}

// MARK: - Achievement Cell
struct AchievementCell: View {
    let achievement: AchievementDef
    let unlocked: Bool

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(unlocked
                          ? Color(red: 0.35, green: 0.20, blue: 0.45).opacity(0.6)
                          : Color.white.opacity(0.05))
                    .frame(width: 50, height: 50)
                if unlocked {
                    Text(achievement.emoji)
                        .font(.system(size: 28))
                } else {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.20))
                }
            }
            Text(achievement.title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(unlocked ? .white.opacity(0.85) : .white.opacity(0.25))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(unlocked
                      ? Color(red: 0.30, green: 0.15, blue: 0.42).opacity(0.55)
                      : Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(
                    unlocked ? Color(red: 0.70, green: 0.50, blue: 0.85).opacity(0.35) : Color.clear,
                    lineWidth: 1
                )
        )
    }
}

#Preview {
    AchievementsView()
        .modelContainer(for: [SessionModel.self, InventoryProductModel.self], inMemory: true)
}
