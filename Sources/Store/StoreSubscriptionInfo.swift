import Foundation

public struct StoreSubscriptionInfo {
    public enum Duration {
        case week
        case month
        case year
    }

    public let price: Decimal
    public let duration: Duration
}
