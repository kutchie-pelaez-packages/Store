import Subscription

enum ClientSubscription: String, CaseIterable, SubscriptionProduct {
    case week = "com.kulikovia.client.store.week"
    case month = "com.kulikovia.client.store.month"
    case year = "com.kulikovia.client.store.year"

    var fallbackInfo: SubscriptionInfo {
        switch self {
        case .week: return SubscriptionInfo(price: 0.99, duration: .week)
        case .month: return SubscriptionInfo(price: 2.99, duration: .week)
        case .year: return SubscriptionInfo(price: 39.99, duration: .week)
        }
    }
}
