import CoreUI
import Store
import UIKit

final class RootViewController: ViewController {
    init(store: Store) {
        self.store = store
        super.init()
    }

    private let store: Store

    // MARK: - UI

    override func configureViews() {
        view.backgroundColor = System.Colors.Background.primary
    }
}
