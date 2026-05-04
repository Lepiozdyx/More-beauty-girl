import SwiftUI
import SwiftData

struct More_beauty_girlApp: View {
    var body: some View {
        LoadingScreen()
            .preferredColorScheme(.light)
            .modelContainer(for: [
                SessionModel.self,
                InventoryProductModel.self,
            ])
    }
}
