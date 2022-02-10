import Core
import SubscriptionStatus

public protocol Store {
    var subscriptionStatusSubject: ValueSubject<SubscriptionStatus> { get }
    var eventPublisher: ValuePublisher<StoreEvent> { get }
    func subscribe(for subscription: StoreSubscription) async throws
    func restore() async throws
    func info(for subscription: StoreSubscription) -> StoreSubscriptionInfo
}
