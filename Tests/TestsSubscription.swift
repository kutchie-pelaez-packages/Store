import Subscription

enum TestsSubscription: String, SubscriptionProduct, CaseIterable {
    case week
    case month
    case year

    var fallbackInfo: SubscriptionInfo {
        switch self {
        case .week:
            return SubscriptionInfo(price: 0.99, duration: .week)

        case .month:
            return SubscriptionInfo(price: 2.99, duration: .month)

        case .year:
            return SubscriptionInfo(price: 39.99, duration: .year)
        }
    }
}
