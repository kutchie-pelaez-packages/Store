import Logger
import Subscription

public struct StoreFactory {
    public init() { }
    
    public func produce(
        subscriptions: [SubscriptionProduct],
        logger: Logger
    ) -> Store {
        StoreImpl(
            subscriptions: subscriptions,
            logger: logger
        )
    }
}
