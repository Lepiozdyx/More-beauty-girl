import SwiftData
import Foundation

@Model
class SessionModel {
    var id = UUID()
    var date = Date()
    var timeInterval: TimeInterval
    var category: SessionCategory
    var products: [UUID]
    
    init(id: UUID = UUID(), date: Date = Date(), timeInterval: TimeInterval, category: SessionCategory, products: [UUID]) {
        self.id = id
        self.date = date
        self.timeInterval = timeInterval
        self.category = category
        self.products = products
    }
}

enum SessionCategory: String, CaseIterable, Codable {
    case work, date, party, express, relax, custom
}

@Model
class InventoryProductModel {
    var id = UUID()
    
    var photo: Data?
    var systemAsset: String? // тут просто смайлик
    
    var name: String
    var brand: String?
    var category: InventoryCategory
    var price: Int?
    var quantity: Int? // ml
    
    init(id: UUID = UUID(), photo: Data? = nil, name: String, brand: String? = nil, category: InventoryCategory, price: Int? = nil, quantity: Int? = nil) {
        self.id = id
        self.photo = photo
        self.name = name
        self.brand = brand
        self.category = category
        self.price = price
        self.quantity = quantity
    }
}

enum InventoryCategory: String, CaseIterable, Codable {
    case base, eyes, lips, face, brows, special
}
