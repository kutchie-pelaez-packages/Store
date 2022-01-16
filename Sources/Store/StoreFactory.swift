public struct StoreFactory {
    public init() { }
    
    public func produce() -> Store {
        StoreImpl()
    }
}
