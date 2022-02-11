@testable import Store
import Combine
import Logger
import StoreKitTest
import XCTest

final class StoreTests: XCTestCase {
    private lazy var subject: Store = {
        StoreFactory().produce(
            subscriptions: TestsSubscription.allCases,
            logger: LoggerMock()
        )
    }()

    private let session: SKTestSession = {
        try! SKTestSession(
            contentsOf: Bundle.module.url(
                forResource: "Configuration",
                withExtension: "storekit"
            )!
        )
    }()

    private var cancellables = [AnyCancellable]()

    func test1_productsShouldBeLoaded() {
        StoreKitTest.SKTestSession.
        let expectation = expectation(description: "products loading")

        subject.eventPublisher
            .sink { event in
                guard case .subscriptionsInitiallyLoaded = event else { return }

                expectation.fulfill()
            }
            .store(in: &cancellables)

        waitForExpectations(timeout: 10)
    }

    func test2_shouldShangeSatusFromNotSubscribedToSubscribed() {
        let expectation = expectation(description: "purchase")

        guard case .notSubscribed = subject.subscriptionStatusSubject.value else {
            XCTAssert(false)
            return
        }

        Task {
            do {
                try await subject.subscribe(for: TestsSubscription.week)
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 0.3, handler: nil)

//        XCTAssertNoThrow(try session.buyProduct(productIdentifier: TestsSubscription.week.id))

        guard case .subscribed = subject.subscriptionStatusSubject.value else {
            XCTAssert(false)
            return
        }
    }
}

private struct LoggerMock: Logger {
    func log(_ entry: LogEntry) {  }
    func error(_ entry: LogEntry) { }
    func warning(_ entry: LogEntry) { }
}
