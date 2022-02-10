public enum SubscriptionStatus: CaseIterable, CustomStringConvertible, Equatable {
    case unknown
    case subscribed
    case notSubscribed(wasSubscribed: Bool)

    public static var allCases: [SubscriptionStatus] {
        [
            .unknown,
            .subscribed,
            .notSubscribed(wasSubscribed: false),
            .notSubscribed(wasSubscribed: true)
        ]
    }

    public var isSubscribed: Bool {
        if case .subscribed = self {
            return true
        }

        return false
    }

    // MARK: - CustomStringConvertible

    public var description: String {
        switch self {
        case .unknown:
            return "unknown"

        case .subscribed:
            return "subscribed"

        case let .notSubscribed(wasSubscribed):
            if wasSubscribed {
                return "expired"
            } else {
                return "notSubscribed"
            }
        }
    }
}
