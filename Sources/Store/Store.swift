import Core
import SubscriptionState

public protocol Store {
    var subscriptionStateSubject: ValueSubject<SubscriptionState> { get }
    var eventPublisher: ValuePublisher<StoreEvent> { get }
    func purchase(_ product: StoreProduct) async throws
    func restore() async throws
    func info(for product: StoreProduct, localized: Bool) -> StoreProductInfo
}
