import Core
import Subscription

public protocol Store {
    var subscriptionStatusSubject: ValueSubject<SubscriptionStatus> { get }
    var eventPublisher: ValuePublisher<StoreEvent> { get }
    func subscribe(for subscription: SubscriptionProduct) async throws
    func restore() async throws
    func info(for subscription: SubscriptionProduct) -> SubscriptionInfo
}

extension Store {
    public var activeSubscriptionId: String? {
        if case let .subscribed(subscribedInfo) = subscriptionStatusSubject.value {
            return subscribedInfo.id
        }

        return nil
    }
}
