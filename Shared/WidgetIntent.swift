import Foundation

struct WidgetIntent: Codable {
    let id: String
    let createdAt: Date
}

extension WidgetIntent: Comparable {
    static func < (lhs: WidgetIntent, rhs: WidgetIntent) -> Bool {
        lhs.createdAt < rhs.createdAt
    }
}
