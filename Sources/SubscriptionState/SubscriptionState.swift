public enum SubscriptionState:
    String,
    CaseIterable,
    CustomStringConvertible,
    Equatable
{

    case unknown
    case subscribed
    case notSubscribed
    case expired

    // MARK: - CustomStringConvertible

    public var description: String {
        rawValue
    }
}
