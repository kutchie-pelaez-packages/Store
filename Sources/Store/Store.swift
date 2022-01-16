import CoreUtils
import SubscriptionState

public protocol Store {
    var subscriptionState: SubscriptionState { get }
    var subscriptionStatePublisher: ValuePublisher<SubscriptionState> { get }
    var eventPublisher: ValuePublisher<StoreEvent> { get }
    func purchase(_ product: StoreProduct) async throws
    func restore() async throws
    func info(for product: StoreProduct) -> StoreProductInfo
    func localizedInfo(for product: StoreProduct) -> StoreProductInfo
}
