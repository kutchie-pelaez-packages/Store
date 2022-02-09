public enum StoreError: Error, Equatable {
    case purchaseCanceled
    case purchasePending
    case transactionUnverified
    case unknown(String)
}
