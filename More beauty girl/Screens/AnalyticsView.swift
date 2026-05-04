import SwiftUI
import SwiftData

// MARK: - Analytics View
struct AnalyticsView: View {
    @Query private var sessions: [SessionModel]
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPeriod: Period = .week

    enum Period: String, CaseIterable {
        case week = "week"
        case month = "month"
    }

    // MARK: - Computed Stats

    var filteredSessions: [SessionModel] {
        let now = Date()
        let calendar = Calendar.current
        switch selectedPeriod {
        case .week:
            let start = calendar.date(byAdding: .day, value: -7, to: now)!
            return sessions.filter { $0.date >= start }
        case .month:
            let start = calendar.date(byAdding: .month, value: -1, to: now)!
            return sessions.filter { $0.date >= start }
        }
    }

    var totalSessions: Int { filteredSessions.count }

    var avgTime: TimeInterval {
        guard !filteredSessions.isEmpty else { return 0 }
        return filteredSessions.map(\.timeInterval).reduce(0, +) / Double(filteredSessions.count)
    }

    var fastestTime: TimeInterval {
        filteredSessions.map(\.timeInterval).min() ?? 0
    }

    var longestTime: TimeInterval {
        filteredSessions.map(\.timeInterval).max() ?? 0
    }

    var favoriteCategory: SessionCategory? {
        let counts = Dictionary(grouping: filteredSessions, by: \.category)
            .mapValues(\.count)
        return counts.max(by: { $0.value < $1.value })?.key
    }

    // Days for line chart (last 7 days)
    var dailyData: [(label: String, minutes: Double)] {
        let calendar = Calendar.current
        let now = Date()
        return (0..<7).reversed().map { offset -> (String, Double) in
            let day = calendar.date(byAdding: .day, value: -offset, to: now)!
            let start = calendar.startOfDay(for: day)
            let end = calendar.date(byAdding: .day, value: 1, to: start)!
            let daySessions = filteredSessions.filter { $0.date >= start && $0.date < end }
            let totalMins = daySessions.map(\.timeInterval).reduce(0, +) / 60
            let weekday = calendar.component(.weekday, from: day)
            let labels = ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"]
            return (labels[weekday - 1], totalMins)
        }
    }

    // Category breakdown
    var categoryData: [(category: SessionCategory, count: Int, fraction: Double)] {
        guard totalSessions > 0 else { return [] }
        let counts = Dictionary(grouping: filteredSessions, by: \.category).mapValues(\.count)
        return SessionCategory.allCases.compactMap { cat -> (SessionCategory, Int, Double)? in
            guard let count = counts[cat], count > 0 else { return nil }
            return (cat, count, Double(count) / Double(totalSessions))
        }.sorted { $0.1 > $1.1 }
    }

    var body: some View {
        ZStack {
            Color(red: 0.16, green: 0.07, blue: 0.24).ignoresSafeArea()

            RadialGradient(
                colors: [Color(red: 0.40, green: 0.15, blue: 0.55).opacity(0.35), .clear],
                center: .top,
                startRadius: 0,
                endRadius: 450
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
                    Text("Analytics")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 16)

                // Period picker
                HStack(spacing: 0) {
                    ForEach(Period.allCases, id: \.self) { period in
                        Button(action: { withAnimation(.easeInOut(duration: 0.2)) { selectedPeriod = period } }) {
                            Text(period.rawValue)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(selectedPeriod == period ? .white : .white.opacity(0.45))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedPeriod == period
                                              ? Color(red: 0.60, green: 0.20, blue: 0.85)
                                              : Color.clear)
                                )
                        }
                    }
                }
                .padding(4)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.08)))
                .padding(.horizontal, 20)
                .padding(.bottom, 20)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        // Stats 2x2
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            StatCard(label: "Total Sessions", value: "\(totalSessions)", color: Color(red: 0.90, green: 0.73, blue: 0.45))
                            StatCard(label: "Avg Time", value: formatTime(avgTime), color: Color(red: 0.90, green: 0.73, blue: 0.45))
                            StatCard(label: "Fastest", value: formatTime(fastestTime), color: Color(red: 0.90, green: 0.45, blue: 0.55))
                            StatCard(label: "Longest", value: formatTime(longestTime), color: Color(red: 0.65, green: 0.55, blue: 0.90))
                        }
                        .padding(.horizontal, 20)

                        // Line chart
                        AnalyticsCard(title: "Time by Day (Last 7 Days)") {
                            LineChartView(data: dailyData)
                                .frame(height: 160)
                        }
                        .padding(.horizontal, 20)

                        // Donut chart
                        AnalyticsCard(title: "Sessions by Category") {
                            if categoryData.isEmpty {
                                Text("No sessions yet")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.4))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 40)
                            } else {
                                VStack(spacing: 16) {
                                    DonutChartView(data: categoryData)
                                        .frame(width: 180, height: 180)

                                    // Legend 2-col
                                    let columns = [GridItem(.flexible()), GridItem(.flexible())]
                                    LazyVGrid(columns: columns, spacing: 8) {
                                        ForEach(categoryData, id: \.category) { item in
                                            HStack(spacing: 8) {
                                                Circle()
                                                    .fill(categoryColor(item.category))
                                                    .frame(width: 10, height: 10)
                                                Text(item.category.rawValue.capitalized)
                                                    .font(.system(size: 13))
                                                    .foregroundColor(.white.opacity(0.8))
                                                Spacer()
                                                Text("\(Int(item.fraction * 100))%")
                                                    .font(.system(size: 13, weight: .semibold))
                                                    .foregroundColor(.white.opacity(0.6))
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)

                        // Favorite category
                        if let fav = favoriteCategory {
                            HStack(spacing: 16) {
                                Text("⭐")
                                    .font(.system(size: 36))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Favorite Category")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.55))
                                    Text("\(fav.rawValue.capitalized) Makeup")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                Spacer()
                            }
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(Color.white.opacity(0.08))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 18)
                                            .strokeBorder(Color(red: 0.90, green: 0.73, blue: 0.45).opacity(0.4), lineWidth: 1)
                                    )
                            )
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarHidden(true)
    }

    func formatTime(_ t: TimeInterval) -> String {
        let total = Int(t)
        let m = total / 60
        let s = total % 60
        return String(format: "%d:%02d", m, s)
    }

    func categoryColor(_ cat: SessionCategory) -> Color {
        switch cat {
        case .work:    return Color(red: 0.85, green: 0.40, blue: 0.50)
        case .date:    return Color(red: 0.90, green: 0.55, blue: 0.40)
        case .party:   return Color(red: 0.90, green: 0.73, blue: 0.45)
        case .express: return Color(red: 0.55, green: 0.45, blue: 0.85)
        case .relax:   return Color(red: 0.45, green: 0.65, blue: 0.85)
        case .custom:  return Color(red: 0.60, green: 0.85, blue: 0.65)
        }
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .monospaced))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.07)))
    }
}

// MARK: - Analytics Card wrapper
struct AnalyticsCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
            content()
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 18).fill(Color.white.opacity(0.07)))
    }
}

// MARK: - Line Chart
struct LineChartView: View {
    let data: [(label: String, minutes: Double)]

    var maxVal: Double { max(data.map(\.minutes).max() ?? 1, 1) }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let chartH = h - 24 // leave room for labels
            let stepX = w / CGFloat(max(data.count - 1, 1))
            let points: [CGPoint] = data.enumerated().map { i, item in
                CGPoint(
                    x: CGFloat(i) * stepX,
                    y: chartH - CGFloat(item.minutes / maxVal) * chartH * 0.85
                )
            }

            ZStack(alignment: .bottomLeading) {
                // Y axis guides
                ForEach([0, 1, 2, 3, 4], id: \.self) { i in
                    let y = chartH - chartH * 0.85 * CGFloat(i) / 4
                    Path { p in
                        p.move(to: CGPoint(x: 0, y: y))
                        p.addLine(to: CGPoint(x: w, y: y))
                    }
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)

                    Text("\(Int(maxVal * Double(i) / 4))")
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.3))
                        .position(x: 12, y: y)
                }

                // Fill gradient under line
                if points.count > 1 {
                    Path { p in
                        p.move(to: CGPoint(x: points[0].x, y: chartH))
                        for pt in points { p.addLine(to: pt) }
                        p.addLine(to: CGPoint(x: points.last!.x, y: chartH))
                        p.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.90, green: 0.73, blue: 0.45).opacity(0.25), .clear],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                }

                // Line
                if points.count > 1 {
                    Path { p in
                        p.move(to: points[0])
                        for pt in points.dropFirst() { p.addLine(to: pt) }
                    }
                    .stroke(Color(red: 0.90, green: 0.73, blue: 0.45), lineWidth: 2)
                }

                // Dots
                ForEach(Array(points.enumerated()), id: \.offset) { _, pt in
                    Circle()
                        .fill(Color(red: 0.90, green: 0.73, blue: 0.45))
                        .frame(width: 8, height: 8)
                        .position(pt)
                }

                // X labels
                ForEach(Array(data.enumerated()), id: \.offset) { i, item in
                    Text(item.label)
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.45))
                        .position(x: CGFloat(i) * stepX, y: chartH + 14)
                }
            }
        }
    }
}

// MARK: - Donut Chart
struct DonutChartView: View {
    let data: [(category: SessionCategory, count: Int, fraction: Double)]

    func categoryColor(_ cat: SessionCategory) -> Color {
        switch cat {
        case .work:    return Color(red: 0.85, green: 0.40, blue: 0.50)
        case .date:    return Color(red: 0.90, green: 0.55, blue: 0.40)
        case .party:   return Color(red: 0.90, green: 0.73, blue: 0.45)
        case .express: return Color(red: 0.55, green: 0.45, blue: 0.85)
        case .relax:   return Color(red: 0.45, green: 0.65, blue: 0.85)
        case .custom:  return Color(red: 0.60, green: 0.85, blue: 0.65)
        }
    }

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let outerR = size / 2
            let innerR = size / 2 * 0.55
            let gap: Double = 0.03

            ZStack {
                var startAngle = -Double.pi / 2
                ForEach(Array(data.enumerated()), id: \.offset) { _, item in
                    let sweep = item.fraction * (2 * Double.pi) - gap
                    let sa = startAngle
                    let _ = { startAngle += item.fraction * 2 * Double.pi }()

                    Path { p in
                        p.addArc(center: center, radius: outerR, startAngle: .radians(sa), endAngle: .radians(sa + sweep), clockwise: false)
                        p.addArc(center: center, radius: innerR, startAngle: .radians(sa + sweep), endAngle: .radians(sa), clockwise: true)
                        p.closeSubpath()
                    }
                    .fill(categoryColor(item.category))
                }
            }
        }
    }
}

#Preview {
    AnalyticsView()
        .modelContainer(for: SessionModel.self, inMemory: true)
}
