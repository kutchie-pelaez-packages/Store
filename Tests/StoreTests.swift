@testable import Store
import Combine
import Logger
import StoreKitTest
import XCTest

final class StoreTests: XCTestCase {
    private lazy var subject: Store = {
        StoreFactory().produce(
            provider: TestsStoreProvider(),
            logger: LoggerMock()
        )
    }()

    private let session: SKTestSession = {
        try! SKTestSession(
            contentsOf: Bundle.module.url(
                forResource: "Subscriptions",
                withExtension: "storekit"
            )!
        )
    }()

    private var cancellables = [AnyCancellable]()

    func test1_productsShouldBeLoaded() {
        let expectation = expectation(description: "products loading")

        subject.eventPublisher
            .sink { event in
                guard case .subscriptionsInitiallyLoaded = event else { return }

                expectation.fulfill()
            }
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1)
    }
}

private struct LoggerMock: Logger {
    func log(_ entry: LogEntry) {  }
    func error(_ entry: LogEntry) { }
    func warning(_ entry: LogEntry) { }
}
