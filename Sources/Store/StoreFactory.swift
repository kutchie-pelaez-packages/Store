import Logger

public struct StoreFactory {
    public init() { }
    
    public func produce(
        subscriptions: [StoreSubscription],
        logger: Logger
    ) -> Store {
        StoreImpl(
            subscriptions: subscriptions,
            logger: logger
        )
    }
}
