import Core

@propertyWrapper
public struct SubscriptionStatusUserDefault {
    public init(_ key: String) {
        self._subscriptionStatus = UserDefault(
            key,
            default: SubscriptionStatus.notSubscribed(wasSubscribed: false).description
        )
    }

    @UserDefault
    private var subscriptionStatus: String

    public var wrappedValue: SubscriptionStatus {
        get {
            guard let status = SubscriptionStatus(from: subscriptionStatus) else {
                return .notSubscribed(wasSubscribed: false)
            }

            return status
        } set {
            subscriptionStatus = newValue.description
        }
    }
}

