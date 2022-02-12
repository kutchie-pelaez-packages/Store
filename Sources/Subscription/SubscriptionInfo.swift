import Foundation

public struct SubscriptionInfo {
    public enum Duration: String {
        case week
        case month
        case year
    }

    public init(
        price: Decimal,
        duration: Duration
    ) {
        self.price = price
        self.duration = duration
    }

    public let price: Decimal
    public let duration: Duration
}
