import Foundation

enum SubscriptionsConfig {
    struct Subscription: Decodable {
        let id: String
        let price: Decimal
        let duration: String
    }
}
