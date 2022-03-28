import Core
import Foundation
import Yams

@propertyWrapper
public struct SubscriptionStatusUserDefault {
    public init(_ key: String) {
        self._subscriptionStatus = UserDefault(
            key,
            default: nil
        )
    }

    @UserDefault
    private var subscriptionStatus: Data?

    private let decoder = YAMLDecoder()
    private let encoder = YAMLEncoder()

    public var wrappedValue: SubscriptionStatus {
        get {
            if
                let userDefaultsSubscriptionStatus = subscriptionStatus,
                let subscriptionStatus: SubscriptionStatus = try? decoder.decode(from: userDefaultsSubscriptionStatus)
            {
                return subscriptionStatus
            } else {
                return .notSubscribed
            }
        } set {
            do {
                let data = try encoder.encode(newValue).data
                subscriptionStatus = data
            } catch {
                safeCrash()
            }
        }
    }
}

