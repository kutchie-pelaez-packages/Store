public protocol StoreSubscription {
    var id: String { get }
}

extension StoreSubscription where Self: RawRepresentable, RawValue == String {
    public var id: String {
        rawValue
    }
}
