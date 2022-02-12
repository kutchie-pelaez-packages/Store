import Logger
import Subscription

public struct StoreFactory {
    public init() { }
    
    public func produce(
        provider: StoreProvider,
        logger: Logger
    ) -> Store {
        StoreImpl(
            provider: provider,
            logger: logger
        )
    }
}
