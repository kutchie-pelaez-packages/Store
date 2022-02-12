import Core
import Foundation
import Store

struct TestsStoreProvider: StoreProvider {
    var subscriptionsConfigURL: URL {
        undefinedIfNil(
            Bundle.module.url(
                forResource: "subscriptions_config",
                withExtension: "yml"
            )
        )
    }
}
