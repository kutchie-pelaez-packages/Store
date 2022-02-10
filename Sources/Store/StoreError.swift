public enum StoreError: Error {
    case pendingPurchase
    case unknownPurchaseResult
    case unknownProduct
    case unverifiedTransaction
    case userCancelledPurchase
}
