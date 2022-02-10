import Logger

public struct StoreFactory {
    public init() { }
    
    public func produce(
        products: [StoreProduct],
        logger: Logger
    ) -> Store {
        StoreImpl(
            products: products,
            logger: logger
        )
    }
}
