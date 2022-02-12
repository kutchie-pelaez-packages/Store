import Subscription

enum TestsSubscription: String, SubscriptionProduct {
    case week = "store.tests.week"
    case month = "store.tests.month"
    case year = "store.tests.year"
}
