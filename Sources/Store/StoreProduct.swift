public protocol StoreProduct {
    var id: String { get }
}

extension StoreProduct where Self: RawRepresentable, RawValue == String {
    public var id: String {
        rawValue
    }
}
