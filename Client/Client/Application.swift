import Logger
import Store
import UIKit

final class Application: UIApplication, UIApplicationDelegate, LoggerProvider {
    var window: UIWindow?

    private lazy var logger: Logger = {
        LoggerFactory().produce(
            environment: .dev,
            provider: self
        )
    }()

    private lazy var store: Store = {
        StoreFactory().produce(
            logger: logger
        )
    }()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = RootViewController(
            logger: logger,
            store: store
        )
        window?.makeKeyAndVisible()

        return true
    }
}
