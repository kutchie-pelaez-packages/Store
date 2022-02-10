import CoreUI
import Logger
import Store
import UIKit

final class RootViewController: ViewController {
    init(
        logger: Logger,
        store: Store
    ) {
        self.logger = logger
        self.store = store
        super.init()
    }

    private let logger: Logger
    private let store: Store

    // MARK: - UI

    override func configureViews() {
        view.backgroundColor = System.Colors.Background.primary
    }

    override func subscribeToEvents() {
        store.subscriptionStatusSubject
            .sink { [weak self] status in
                self?.logger.log("New status: \(status)", domain: .storeClient)
            }
            .store(in: &cancellables)
    }
}

extension LogDomain {
    fileprivate static let storeClient: Self = "storeClient"
}
