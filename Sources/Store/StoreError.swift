public enum StoreError: Error {
    case pendingProduct
    case unknownProduct
    case unknownPurchaseResult
    case unverifiedTransaction
    case userCancelledPurchase
}
