public protocol SubscriptionProduct {
    var id: String { get }
    var fallbackInfo: SubscriptionInfo { get }
}

extension SubscriptionProduct where Self: RawRepresentable, RawValue == String {
    public var id: String {
        rawValue
    }
}
