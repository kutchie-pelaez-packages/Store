import Logger
import Subscription

public struct StoreFactory {
    public init() { }
    
    public func produce(
        subscriptions: [SubscriptionProduct],
        provider: StoreProvider,
        logger: Logger
    ) -> Store {
        StoreImpl(
            subscriptions: subscriptions,
            provider: provider,
            logger: logger
        )
    }
}
