import Combine
import Core
import StoreKit
import SubscriptionState
import os

final class StoreImpl: Store {
    init() {
//        initiallyUpdateSubscriptionState()
//        initiallyLoadProducts()
//        startListeningForTransactions()
    }

    deinit {
        transactionListeningHandle?.cancel()
    }

    private var productInfos = [StoreProduct: StoreProductInfo]()
    private var storeKitProducts = [StoreProduct: StoreKit.Product]()

    private let stateValueSubject = CurrentValueSubject<SubscriptionState, Never>(.unknown)
    private let eventPassthroughSubject = PassthroughSubject<StoreEvent, Never>()

    private var transactionListeningHandle: Task<Void, Error>?

    // MARK: -

    private func initiallyUpdateSubscriptionState() {
        Task {
            try await updatePurchaseState()
            eventPassthroughSubject.send(.subscriptionStateInitiallySet)
        }
    }

    private func initiallyLoadProducts() {
        Task {
            try await loadProducts()
            self.eventPassthroughSubject.send(.productsInitiallyLoaded)
        }
    }

    private func startListeningForTransactions() {
        transactionListeningHandle = createTransactionListeningHandle()
    }

    private func createTransactionListeningHandle() -> Task<Void, Error> {
        Task {

        }
//        detach { [weak self] in
//            for await result in Transaction.listener {
//                let transaction = try self?.check(result)
//                try await self?.updatePurchaseState()
//                await transaction?.finish()
//            }
//        }
    }

    private func updatePurchaseState() async throws {
//        for await status in StoreKit.Product.SubscriptionInfo.Status.listener {
//            let state: PurchaseState
//
//            switch status.state {
//            case .subscribed:
//                state = .subscribed
//
//            case .expired:
//                state = .expired
//
//            case .inBillingRetryPeriod:
//                state = .subscribed
//
//            case .inGracePeriod:
//                state = .subscribed
//
//            case .revoked:
//                state = .notSubscribed
//
//            default:
//                state = .unknown
//            }
//
//            stateValueSubject.send(state)
//        }
    }

    private func loadProducts() async throws {
//        guard productInfos.isEmpty else { return }
//
//        let allIds = Set(Product.allCases.map { $0.rawValue })
//        let storeKitProducts = try await StoreKit.Product.request(with: allIds)
//
//        var productInfosResult = [Product: ProductInfo]()
//        var storeKitProductsResult = [Product: StoreKit.Product]()
//        for storeKitProduct in storeKitProducts {
//            guard let product = Product(rawValue: storeKitProduct.id),
//                  let subscription = storeKitProduct.subscription else {
//                continue
//            }
//
//            let duration: ProductInfo.Duration
//            let period = subscription.subscriptionPeriod
//            switch period.unit {
//            case .day:
//                appFatalError()
//
//            case .week:
//                guard period.value == 1 else {
//                    appFatalError()
//                }
//                duration = .week
//
//            case .month:
//                duration = .months(amount: period.value)
//
//            case .year:
//                duration = .year
//
//            @unknown default:
//                appFatalError()
//            }
//
//            let productInfo = ProductInfo(
//                value: storeKitProduct.price,
//                duration: duration
//            )
//
//            productInfosResult[product] = productInfo
//            storeKitProductsResult[product] = storeKitProduct
//        }
//
//        self.productInfos = productInfosResult
//        self.storeKitProducts = storeKitProductsResult
    }

    private func check<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.transactionUnverified

        case .verified(let t):
            return t
        }
    }

    // MARK: - Store

    var eventPublisher: ValuePublisher<StoreEvent> {
        eventPassthroughSubject
            .eraseToAnyPublisher()
    }

    var subscriptionStatePublisher: ValuePublisher<SubscriptionState> {
        stateValueSubject
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    var subscriptionState: SubscriptionState {
        stateValueSubject
            .value
    }

    func purchase(_ product: StoreProduct) async throws {
        guard let storeKitProduct = storeKitProducts[product] else { return }

        try await loadProducts()

        let result = try await storeKitProduct.purchase()

        switch result {
        case let .success(result):
            let transaction = try check(result)
            try await updatePurchaseState()
            await transaction.finish()

        case .userCancelled:
            throw StoreError.purchaseCanceled

        case .pending:
            throw StoreError.purchasePending

        @unknown default:
            throw StoreError.unknown("Unknown purchase error")
        }
    }

    func restore() async throws {
        try await AppStore.sync()
        try await updatePurchaseState()
    }

    func info(for product: StoreProduct) -> StoreProductInfo {
        StoreProductInfo(
            value: 0,
            duration: .week,
            locale: .current
        )
    }

    func localizedInfo(for product: StoreProduct) -> StoreProductInfo {
        StoreProductInfo(
            value: 0,
            duration: .week,
            locale: .current
        )
    }
}
