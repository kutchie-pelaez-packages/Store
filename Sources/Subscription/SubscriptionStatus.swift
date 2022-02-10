public enum SubscriptionStatus: CustomStringConvertible, Codable {
    case subscribed(SubscribedInfo)
    case notSubscribed
    case expired(ExpiredInfo)

    public struct SubscribedInfo: Codable {
        public init(
            id: String,
            willAutoRenew: Bool
        ) {
            self.id = id
            self.willAutoRenew = willAutoRenew
        }

        public let id: String
        public let willAutoRenew: Bool
    }

    public struct ExpiredInfo: Codable {
        public init(expiredSubscriptions: [ExpiredSubscription]) {
            self.expiredSubscriptions = expiredSubscriptions
        }

        public let expiredSubscriptions: [ExpiredSubscription]

        public struct ExpiredSubscription: Codable {
            public init(
                id: String,
                reason: Reason
            ) {
                self.id = id
                self.reason = reason
            }

            public let id: String
            public let reason: Reason

            public enum Reason: Codable {
                case revoked
                case didNotAutoRenew
                case billingError
                case didNotConsentToPriceIncrease
                case productUnavailable
                case unknown
            }
        }
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

        case .notSubscribed:
            return "notSubscribed"

        case .expired:
            return "expired"
        }
    }
}
