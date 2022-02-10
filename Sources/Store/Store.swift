import Core
import SubscriptionStatus

public protocol Store {
    var subscriptionStatusSubject: ValueSubject<SubscriptionStatus> { get }
    var eventPublisher: ValuePublisher<StoreEvent> { get }
    func purchase(_ product: StoreProduct) async throws
    func restore() async throws
    func info(for product: StoreProduct) -> StoreProductInfo
}
