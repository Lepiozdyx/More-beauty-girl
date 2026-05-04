import Foundation

enum InventoryProductFactory {
    static let defaults: [(name: String, brand: String?, category: InventoryCategory, systemAsset: String)] = [
        ("Foundation",  "Generic",  .base,    "🧴"),
        ("Concealer",   "Generic",  .base,    "💄"),
        ("Mascara",     "Generic",  .eyes,    "👁️"),
        ("Eyeliner",    "Generic",  .eyes,    "✏️"),
        ("Lipstick",    "Generic",  .lips,    "💋"),
        ("Blush",       "Generic",  .face,    "🌸"),
        ("Eyeshadow",   "Generic",  .eyes,    "🎨"),
        ("Bronzer",     "Generic",  .face,    "✨"),
        ("Highlighter", "Generic",  .face,    "💫"),
        ("Lip Liner",   "Generic",  .lips,    "🖊️"),
        ("Brow Pencil", "Generic",  .brows,   "🪄"),
        ("Setting Spray","Generic", .special, "💧")
    ]

    static func seedIfNeeded(existing: [InventoryProductModel], insert: (InventoryProductModel) -> Void) {
        guard existing.isEmpty else { return }
        for item in defaults {
            let model = InventoryProductModel(
                name: item.name,
                brand: item.brand,
                category: item.category
            )
            model.systemAsset = item.systemAsset
            insert(model)
        }
    }
}
