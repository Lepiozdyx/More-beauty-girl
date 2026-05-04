import SwiftUI
import SwiftData

// MARK: - Session Active View (Screen 2)
struct SessionActiveView: View {
    let category: SessionCategory
    let productIDs: [UUID]
    let onComplete: (TimeInterval) -> Void

    @Environment(\.dismiss) private var dismiss
    @Query var allInventory: [InventoryProductModel]

    // Filter to only the selected products — same context, no cross-context issue
    var products: [InventoryProductModel] {
        let all = productIDs + extraProductIDs.filter { !productIDs.contains($0) }
        return allInventory.filter { all.contains($0.id) }
    }

    @State private var elapsedSeconds: Int = 0
    @State private var timer: Timer? = nil
    @State private var isPaused = false
    @State private var checkedItems: Set<UUID> = []
    @State private var showResult = false
    @State private var finalInterval: TimeInterval = 0
    @State private var extraProductIDs: [UUID] = []
    @State private var showInventoryAdd = false

    var timeString: String {
        let h = elapsedSeconds / 3600
        let m = (elapsedSeconds % 3600) / 60
        let s = elapsedSeconds % 60
        if h > 0 {
            return String(format: "%02d:%02d:%02d", h, m, s)
        }
        return String(format: "%02d:%02d", m, s)
    }

    var body: some View {
        ZStack {
            // Dark atmospheric background
            Color(red: 0.18, green: 0.08, blue: 0.22).ignoresSafeArea()

            // Subtle radial glow
            RadialGradient(
                colors: [Color(red: 0.45, green: 0.20, blue: 0.55).opacity(0.4), .clear],
                center: .center,
                startRadius: 10,
                endRadius: 300
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Timer display
                Text(timeString)
                    .font(.system(size: 72, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(.bottom, 8)

                Text("Track Progress")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.bottom, 24)

                // Product checklist — only products passed in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 8) {
                        ForEach(products) { product in
                            ChecklistRow(
                                name: product.name,
                                isChecked: checkedItems.contains(product.id)
                            ) {
                                toggle(product.id)
                            }
                        }
                    }
                    .padding(.horizontal, 40)
                }
                .frame(maxHeight: 340)

                Spacer()

                // Add / Skip row
                HStack(spacing: 32) {
                    Spacer()
                    Button(action: { showInventoryAdd = true }) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                                .font(.system(size: 13, weight: .semibold))
                            Text("Add")
                                .font(.system(size: 15, weight: .medium))
                        }
                        .foregroundColor(.white.opacity(0.7))
                    }
                    Button(action: finishSession) {
                        HStack(spacing: 6) {
                            Image(systemName: "forward.end")
                                .font(.system(size: 13, weight: .semibold))
                            Text("Skip")
                                .font(.system(size: 15, weight: .medium))
                        }
                        .foregroundColor(.white.opacity(0.7))
                    }
                    Spacer()
                }
                .padding(.bottom, 16)

                // Pause button
                Button(action: togglePause) {
                    HStack(spacing: 10) {
                        Image(systemName: isPaused ? "play.fill" : "pause")
                            .font(.system(size: 16, weight: .semibold))
                        Text(isPaused ? "Resume" : "Pause")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color.white.opacity(0.12))
                    )
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 12)

                // Stop button
                Button(action: finishSession) {
                    HStack(spacing: 10) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 14))
                        Text("STOP")
                            .font(.system(size: 17, weight: .bold))
                            .tracking(1.5)
                    }
                    .foregroundColor(Color(red: 0.20, green: 0.10, blue: 0.26))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color(red: 0.90, green: 0.73, blue: 0.45))
                    )
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .navigationBarHidden(true)
        .onAppear { startTimer() }
        .onDisappear { stopTimer() }
        .fullScreenCover(isPresented: $showResult) {
            SessionResultView(
                interval: finalInterval,
                category: category,
                productIDs: productIDs + extraProductIDs.filter { !productIDs.contains($0) },
                onClose: { dismiss() }
            )
        }
        .sheet(isPresented: $showInventoryAdd) {
            InventoryView(onSelect: { product in
                if !extraProductIDs.contains(product.id) && !productIDs.contains(product.id) {
                    extraProductIDs.append(product.id)
                }
            })
        }
    }

    private func toggle(_ id: UUID) {
        if checkedItems.contains(id) {
            checkedItems.remove(id)
        } else {
            checkedItems.insert(id)
        }
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if !isPaused { elapsedSeconds += 1 }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func togglePause() {
        isPaused.toggle()
    }

    private func finishSession() {
        stopTimer()
        finalInterval = TimeInterval(elapsedSeconds)
        onComplete(finalInterval)
        showResult = true
    }
}

// MARK: - Checklist Row
struct ChecklistRow: View {
    let name: String
    let isChecked: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(isChecked ? 0 : 0.35), lineWidth: 1.5)
                        .frame(width: 26, height: 26)
                    if isChecked {
                        Circle()
                            .fill(Color(red: 0.90, green: 0.73, blue: 0.45))
                            .frame(width: 26, height: 26)
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                Text(name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isChecked ? .white.opacity(0.45) : .white)
                    .strikethrough(isChecked, color: .white.opacity(0.45))
                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.08))
            )
        }
    }
}

#Preview {
    SessionActiveView(
        category: .work,
        productIDs: [],
        onComplete: { _ in }
    )
}
