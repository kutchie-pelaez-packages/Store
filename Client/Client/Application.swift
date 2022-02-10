import Logger
import Store
import UIKit

final class Application: UIApplication, UIApplicationDelegate, LoggerProvider, StoreProvider {
    var window: UIWindow?

    private lazy var logger: Logger = {
        LoggerFactory().produce(
            environment: .dev,
            provider: self
        )
    }()

    private lazy var store: Store = {
        StoreFactory().produce(
            subscriptions: ClientSubscription.allCases,
            provider: self,
            logger: logger
        )
    }()

    // MARK: - UIApplicationDelegate

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        let rootViewController = RootViewController(
            logger: logger,
            store: store
        )
        let navigationController = UINavigationController(
            rootViewController: rootViewController
        )
        navigationController.navigationBar.prefersLargeTitles = true

        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()

        return true
    }

    // MARK: - StoreProvider

    var windowScene: UIWindowScene {
        connectedScenes.randomElement() as! UIWindowScene
    }
}
