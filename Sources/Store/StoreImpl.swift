import Combine
import Core
import Logger
import StoreKit
import Subscription
import Yams

final class StoreImpl: Store {
    init(
        provider: StoreProvider,
        logger: Logger
    ) {
        self.provider = provider
        self.logger = logger
        setup()
    }

    deinit {
        updatesTransactionsListener?.cancel()
    }

    private let provider: StoreProvider
    private let logger: Logger

    private var updatesTransactionsListener: Task<Void, Error>?

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
        do {
            try retreiveConfigSubscriptions()
            setupTransactionsListener()

            Task {
                try await retreiveStoreProducts()
                dispatch {
                    self.eventPassthroughSubject.send(.subscriptionsInitiallyLoaded)
                }
                try await syncSubscriptionStatus()
            }
        } catch {
            logger.error("Failed to setup store, error: \(error)", domain: .store)
        }
    }

    private func retreiveConfigSubscriptions() throws {
        let decoder = YAMLDecoder()
        let configData = try Data(contentsOf: provider.subscriptionsConfigURL)
        let configSubscriptions = try decoder.decode([SubscriptionsConfig.Subscription].self, from: configData)

        configSubscriptions.forEach {
            guard let duration = SubscriptionInfo.Duration(rawValue: $0.duration) else {
                logger.error("Failed to get duration from \($0.duration)", domain: .store)
                safeCrash()
                return
            }

            subscriptionIdToInfo[$0.id] = SubscriptionInfo(
                price: $0.price,
                duration: duration
            )
        }
    }

    private func setupTransactionsListener() {
        updatesTransactionsListener = Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try self.verefied(result)
                    try await self.syncSubscriptionStatus()
                    await transaction.finish()
                } catch {
                    self.logger.error(
                        "Failed to verify \(result) transaction",
                        domain: .store
                    )
                }
            }
        }
    }

    private func retreiveStoreProducts() async throws {
        let storeProducts = try await Product.products(for: subscriptionIdToInfo.keys)

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
                logger.log("Failed to make subscription info for \(storeProduct.id), error: \(storeProduct.type) product type is not supported", domain: .store)
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
            dispatch {
                self._subscriptionStatusSubject.value = subscriptionStatus
            }
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
                subscriptionStatus = .subscribed(
                    SubscriptionStatus.SubscribedInfo(
                        id: renewalInfo.currentProductID,
                        willAutoRenew: renewalInfo.willAutoRenew
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
            logger.error("Failed to get duration from subscription period, error: Subscription period is nil", domain: .store)
            crash()
        }

        switch subscriptionPeriod.unit {
        case .week:
            if subscriptionPeriod.value == 1 {
                return .week
            } else {
                logger.error("Failed to get duration from subscription period, error: Multiple weeks duration is not supported", domain: .store)
                crash()
            }

        case .month:
            if subscriptionPeriod.value == 1 {
                return .month
            } else {
                logger.error("Failed to get duration from subscription period, error: Multiple months duration is not supported", domain: .store)
                crash()
            }

        case .year:
            if subscriptionPeriod.value == 1 {
                return .year
            } else {
                logger.error("Failed to get duration from subscription period, error: Multiple years duration is not supported", domain: .store)
                crash()
            }

        default:
            logger.error("Failed to get duration from subscription period, error: \(subscriptionPeriod.unit) duration unit is not supported", domain: .store)
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
            logger.log("Failed to subscribe for \(subscription.id) subscription, error: Unknown subscription id received", domain: .store)
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
            logger.log("Received pernding purchase result for \(subscription.id) subscription", domain: .store)
            throw StoreError.pendingProduct

        @unknown default:
            throw StoreError.unknownPurchaseResult
        }
    }

    func restore() async throws {
        try await AppStore.sync()
        try await syncSubscriptionStatus()
    }

    func info(for subscription: SubscriptionProduct) -> SubscriptionInfo {
        undefinedIfNil(
            subscriptionIdToInfo[subscription.id],
            "Failed to ger info for \(subscription.id) subscription"
        )
    }
}

extension LogDomain {
    fileprivate static let store: Self = "store"
}
