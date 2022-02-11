@testable import Store
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

    func test1_wip() {

    }
}

private struct LoggerMock: Logger {
    func log(_ entry: LogEntry) {  }
    func error(_ entry: LogEntry) { }
    func warning(_ entry: LogEntry) { }
}
