import Core
import Foundation
import Store

struct ClientStoreProvider: StoreProvider {
    var subscriptionsConfigURL: URL {
        undefinedIfNil(
            Bundle.main.url(
                forResource: "subscriptions_config",
                withExtension: "yml"
            )
        )
    }
}
