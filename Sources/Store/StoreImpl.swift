import Combine
import Core
import Logger
import StoreKit
import SubscriptionStatus

final class StoreImpl: Store {
    init(
        products: [StoreProduct],
        logger: Logger
    ) {
        self.products = products
        self.logger = logger
    }

    private let products: [StoreProduct]
    private let logger: Logger

    private let eventPassthroughSubject = ValuePassthroughSubject<StoreEvent>()

    // MARK: -

    // MARK: - Store

    lazy var subscriptionStatusSubject: ValueSubject<SubscriptionStatus> = MutableValueSubject(.unknown)

    var eventPublisher: ValuePublisher<StoreEvent> {
        eventPassthroughSubject.eraseToAnyPublisher()
    }

    func purchase(_ product: StoreProduct) async throws {
        fatalError()
    }

    func restore() async throws {
        fatalError()
    }

    func info(for product: StoreProduct, localized: Bool) -> StoreProductInfo {
        fatalError()
    }
}

extension LogDomain {
    fileprivate static let store: Self = "store"
}
