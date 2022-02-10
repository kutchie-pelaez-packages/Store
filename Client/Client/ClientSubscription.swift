import Store

enum ClientSubscription: String, CaseIterable, StoreProduct {
    case week = "com.kulikovia.client.store.week"
    case month = "com.kulikovia.client.store.month"
    case twoMonths = "com.kulikovia.client.store.two_months"
    case year = "com.kulikovia.client.store.year"
}
