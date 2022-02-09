import Logger

public struct StoreFactory {
    public init() { }
    
    public func produce(logger: Logger) -> Store {
        StoreImpl(logger: logger)
    }
}
