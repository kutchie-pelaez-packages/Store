import Subscription

enum ClientSubscription: String, SubscriptionProduct, CaseIterable {
    case week = "com.kulikovia.client.store.week"
    case month = "com.kulikovia.client.store.month"
    case year = "com.kulikovia.client.store.year"
}
