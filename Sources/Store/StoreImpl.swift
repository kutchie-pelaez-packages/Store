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
    }

    private let subscriptions: [SubscriptionProduct]
    private let logger: Logger

    private var unfinishedTransactionsListener: Task<Void, Error>?

    @SubscriptionStatusUserDefault("subscription_status")
    private var storedSubscriptionStatus
    private lazy var _subscriptionStatusSubject = MutableValueSubject<SubscriptionStatus>(
        storedSubscriptionStatus
    )

    private let eventPassthroughSubject = ValuePassthroughSubject<StoreEvent>()
    private var storeProducts = [Product]()
    private var subscriptionIdToInfo = [String: SubscriptionInfo]()

    // MARK: -

    private func setup() {
        setupUnfinishedTransactionsListener()

        Task {
            do {
                try await retreiveStoreProducts()
                try await syncSubscriptionStatus()
            } catch {
                logger.error("Failed to retreive store products", domain: .store)
            }
        }
    }

    private func setupUnfinishedTransactionsListener() {
        unfinishedTransactionsListener = Task.detached {
            for await unfinishedTransaction in Transaction.unfinished {
                do {
                    let transaction = try self.verefied(unfinishedTransaction)
                    try await self.syncSubscriptionStatus()
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
                subscriptionIdToInfo[storeProduct.id] = SubscriptionInfo(
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

    private func syncSubscriptionStatus() async throws {
        guard
            let storeProduct = storeProducts.first,
            let statuses = try await storeProduct.subscription?.status
        else {
            return
        }

        var subscriptionStatus: SubscriptionStatus = .notSubscribed
        defer {
            _subscriptionStatusSubject.value = subscriptionStatus
            storedSubscriptionStatus = subscriptionStatus
        }

        var expiredSubscriptions = [SubscriptionStatus.ExpiredInfo.ExpiredSubscription]()

        for status in statuses {
            let renewalInfo = try verefied(status.renewalInfo)

            switch status.state {
            case .revoked, .expired:
                let reason: SubscriptionStatus.ExpiredInfo.ExpiredSubscription.Reason
                if status.state == .revoked {
                    reason = .revoked
                } else if let expirationReason = renewalInfo.expirationReason {
                    switch expirationReason {
                    case .autoRenewDisabled:
                        reason = .didNotAutoRenew

                    case .billingError:
                        reason = .billingError

                    case .didNotConsentToPriceIncrease:
                        reason = .didNotConsentToPriceIncrease

                    case .productUnavailable:
                        reason = .productUnavailable

                    default:
                        reason = .unknown
                    }
                } else {
                    reason = .unknown
                }

                expiredSubscriptions.append(
                    SubscriptionStatus.ExpiredInfo.ExpiredSubscription(
                        id: renewalInfo.currentProductID,
                        reason: reason
                    )
                )

                subscriptionStatus = .expired(
                    SubscriptionStatus.ExpiredInfo(
                        expiredSubscriptions: expiredSubscriptions
                    )
                )

            case .subscribed, .inBillingRetryPeriod, .inGracePeriod:
                let autoRenew: SubscriptionStatus.SubscribedInfo.AutoRenew
                if renewalInfo.willAutoRenew {
                    autoRenew = .enabled
                } else if let expirationReason = renewalInfo.expirationReason {
                    switch expirationReason {
                    case .autoRenewDisabled:
                        autoRenew = .disabled

                    default:
                        autoRenew = .failed
                    }
                } else {
                    autoRenew = .failed
                }

                subscriptionStatus = .subscribed(
                    SubscriptionStatus.SubscribedInfo(
                        id: renewalInfo.currentProductID,
                        autoRenew: autoRenew
                    )
                )
                return

            default:
                continue
            }
        }
    }

    private func verefied<T>(_ verificationResult: VerificationResult<T>) throws -> T {
        switch verificationResult {
        case let .verified(transaction):
            return transaction

        case .unverified:
            throw StoreError.unverifiedTransaction
        }
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

    // MARK: - Store

    var subscriptionStatusSubject: ValueSubject<SubscriptionStatus> {
        _subscriptionStatusSubject
    }

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
            let transaction = try verefied(verificationResult)
            try await syncSubscriptionStatus()
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
