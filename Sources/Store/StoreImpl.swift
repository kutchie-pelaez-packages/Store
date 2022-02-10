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
        setup()
    }

    private let products: [StoreProduct]
    private let logger: Logger

    private let eventPassthroughSubject = ValuePassthroughSubject<StoreEvent>()
    private var storeProducts = [Product]()
    private var productIdToInfo = [String: StoreProductInfo]()

    // MARK: -

    private func setup() {
        Task {
            do {
                try await retreiveProductsFromStore()
            }
        }
    }

    private func retreiveProductsFromStore() async throws {
        let storeProducts = try await Product.products(for: products.map(\.id))

        for storeProduct in storeProducts {
            switch storeProduct.type {
            case .autoRenewable:
                productIdToInfo[storeProduct.id] = StoreProductInfo(
                    price: storeProduct.price,
                    duration: duration(
                        from: storeProduct.subscription?.subscriptionPeriod
                    )
                )

            default:
                safeCrash("\(storeProduct.type) product type is not supported")
            }
        }

        self.storeProducts = storeProducts
    }

    private func duration(from subscriptionPeriod: Product.SubscriptionPeriod?) -> StoreProductDuration {
        guard let subscriptionPeriod = subscriptionPeriod else { crash() }

        switch subscriptionPeriod.unit {
        case .week:
            if subscriptionPeriod.value == 1 {
                return .week
            } else {
                crash("\(subscriptionPeriod.value) weeks duration is not supported")
            }

        case .month:
            return .months(amount: subscriptionPeriod.value)

        case .year:
            if subscriptionPeriod.value == 1 {
                return .year
            } else {
                crash("\(subscriptionPeriod.value) years duration is not supported")
            }

        default:
            crash("\(subscriptionPeriod.unit) unit is not supported")
        }
    }

    private func transaction<T>(from verificationResult: VerificationResult<T>) throws -> T {
        switch verificationResult {
        case let .verified(transaction):
            return transaction

        case .unverified:
            throw StoreError.unverifiedTransaction
        }
    }

    // MARK: - Store

    lazy var subscriptionStatusSubject: ValueSubject<SubscriptionStatus> = MutableValueSubject(.unknown)

    var eventPublisher: ValuePublisher<StoreEvent> {
        eventPassthroughSubject.eraseToAnyPublisher()
    }

    func purchase(_ product: StoreProduct) async throws {
        guard let storeProduct = storeProducts.first(where: { $0.id == product.id }) else {
            safeCrash("Unknown product \(product.id) received")
            throw StoreError.unknownProduct
        }

        let purchaseResult = try await storeProduct.purchase()

        switch purchaseResult {
        case let .success(verificationResult):
            let transaction = try transaction(from: verificationResult)
            await transaction.finish()

        case .userCancelled:
            throw StoreError.userCancelledPurchase

        case .pending:
            throw StoreError.pendingPurchase

        @unknown default:
            throw StoreError.unknownPurchaseResult
        }
    }

    func restore() async throws {
        fatalError()
    }

    func info(for product: StoreProduct) -> StoreProductInfo {
        fatalError()
    }
}

extension LogDomain {
    fileprivate static let store: Self = "store"
}
