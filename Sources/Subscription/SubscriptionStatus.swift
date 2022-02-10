public enum SubscriptionStatus: CaseIterable, CustomStringConvertible, Equatable {
    case subscribed
    case notSubscribed(wasSubscribed: Bool)

    public init?(from string: String) {
        for status in Self.allCases {
            if status.description == string {
                self = status
            }
        }

        return nil
    }

    public static var allCases: [SubscriptionStatus] {
        [
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
