import Foundation

public struct StoreProductInfo {
    public enum Duration {
        case week
        case months(amount: Int)
        case year
    }

    public let price: Decimal
    public let duration: Duration
}
