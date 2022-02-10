import Combine
import Core
import Logger
import StoreKit
import Subscription

final class StoreImpl: Store {
    init(
        subscriptions: [SubscriptionProduct],
        logger: Logger
    ) {
        self.subscriptions = subscriptions
        self.logger = logger
        setup()
    }

    deinit {
        unfinishedTransactionsListener?.cancel()
        unfinishedTransactionsListener = nil
    }

    private let subscriptions: [SubscriptionProduct]
    private let logger: Logger

    private var unfinishedTransactionsListener: Task<Void, Error>?

    private let eventPassthroughSubject = ValuePassthroughSubject<StoreEvent>()
    private var storeProducts = [Product]()
    private var productIdToInfo = [String: SubscriptionInfo]()

    // MARK: -

    private func setup() {
        listenForUnfinishedTransaction()

        Task {
            do {
                try await retreiveStoreProducts()
            } catch {
                logger.error("Failed to retreive store products", domain: .store)
            }
        }
    }

    private func listenForUnfinishedTransaction() {
        unfinishedTransactionsListener = Task.detached {
            for await unfinishedTransaction in Transaction.unfinished {
                do {
                    let transaction = try self.transaction(from: unfinishedTransaction)
                    // TODO: - update subscription state
                    await transaction.finish()
                } catch {
                    self.logger.error(
                        "Failed to verefy transaction for \(unfinishedTransaction) transaction",
                        domain: .store
                    )
                }
            }
        }
    }

    private func retreiveStoreProducts() async throws {
        let storeProducts = try await Product.products(for: subscriptions.map(\.id))

        for storeProduct in storeProducts {
            switch storeProduct.type {
            case .autoRenewable:
                productIdToInfo[storeProduct.id] = SubscriptionInfo(
                    price: storeProduct.price,
                    duration: duration(
                        from: storeProduct.subscription?.subscriptionPeriod
                    )
                )

            default:
                logger.log("\(storeProduct.type) product type is not supported", domain: .store)
                safeCrash()
            }
        }

        self.storeProducts = storeProducts
    }

    private func duration(from subscriptionPeriod: Product.SubscriptionPeriod?) -> SubscriptionInfo.Duration {
        guard let subscriptionPeriod = subscriptionPeriod else {
            logger.error("Subscription period is nil", domain: .store)
            crash()
        }

        switch subscriptionPeriod.unit {
        case .week:
            if subscriptionPeriod.value == 1 {
                return .week
            } else {
                logger.error("\(subscriptionPeriod.value) weeks duration is not supported", domain: .store)
                crash()
            }

        case .month:
            if subscriptionPeriod.value == 1 {
                return .month
            } else {
                logger.error("\(subscriptionPeriod.value) months duration is not supported", domain: .store)
                crash()
            }

        case .year:
            if subscriptionPeriod.value == 1 {
                return .year
            } else {
                logger.error("\(subscriptionPeriod.value) years duration is not supported", domain: .store)
                crash()
            }

        default:
            logger.error("\(subscriptionPeriod.unit) unit is not supported", domain: .store)
            crash()
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

    lazy var subscriptionStatusSubject: ValueSubject<SubscriptionStatus> = MutableValueSubject(
        .notSubscribed(
            wasSubscribed: false
        )
    )

    var eventPublisher: ValuePublisher<StoreEvent> {
        eventPassthroughSubject.eraseToAnyPublisher()
    }

    func subscribe(for subscription: SubscriptionProduct) async throws {
        guard let storeProduct = storeProducts.first(where: { $0.id == subscription.id }) else {
            logger.log("Unknown subscription \(subscription.id) received", domain: .store)
            safeCrash()
            throw StoreError.unknownProduct
        }

        let purchaseResult = try await storeProduct.purchase()

        switch purchaseResult {
        case let .success(verificationResult):
            let transaction = try transaction(from: verificationResult)
            // TODO: - update subscription state
            await transaction.finish()

        case .userCancelled:
            throw StoreError.userCancelledPurchase

        case .pending:
            logger.log("Pending \(subscription.id) subscription purchased", domain: .store)

        @unknown default:
            throw StoreError.unknownPurchaseResult
        }
    }

    func restore() async throws {
        fatalError()
    }

    func info(for subscription: SubscriptionProduct) -> SubscriptionInfo {
        fatalError()
    }
}

extension LogDomain {
    fileprivate static let store: Self = "store"
}
