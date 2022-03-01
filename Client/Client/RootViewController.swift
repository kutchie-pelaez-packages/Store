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

    private var tableView: System.TableView!

    override func configureViews() {
        view.backgroundColor = System.Colors.Background.primary

        tableView = System.TableView()
        view.addSubviews(tableView)
    }

    override func configureNavigationBar() {
        navigationItem.title = "Store"
    }

    override func constraintViews() {
        tableView.snp.makeConstraints { make in
            make.directionalEdges.equalToSuperview()
        }
    }

    override func postSetup() {
        syncState()
    }

    // MARK: -

    override func subscribeToEvents() {
        store.eventPublisher
            .sink { [weak self] event in
                switch event {
                case .subscriptionsInitiallyLoaded:
                    self?.syncState()
                }
            }
            .store(in: &cancellables)

        store.subscriptionStatusSubject
            .sink { [weak self] status in
                self?.logger.log("Received new status: \(status)", domain: .storeClient)
                self?.syncState()
            }
            .store(in: &cancellables)
    }

    private func syncState() {
        tableView.state = System.TableView.State(
            sections: [
                System.TableView.Section(
                    rows: ClientSubscription.allCases.map { subscription in
                        System.TableView.Row(
                            content: System.TableView.SystemContent(
                                title: System.TableView.SystemContent.Title(
                                    text: store.info(for: subscription).price.description
                                ),
                                subtitle: System.TableView.SystemContent.Subtitle(
                                    text: subscription.id
                                )
                            ),
                            trailingContent: store.activeSubscriptionId == subscription.id ? .checkmark : nil,
                            action: {
                                Task { [weak self] in
                                    do {
                                        try await self?.store.subscribe(for: subscription)
                                    } catch {

                                    }
                                }
                            }
                        )
                    },
                    header: System.TableView.SystemHeader(
                        text: "Subscriptions"
                    )
                ),
                System.TableView.Section(
                    rows: {
                        switch store.subscriptionStatusSubject.value {
                        case let .subscribed(info):
                            return [
                                System.TableView.Row(
                                    content: System.TableView.SystemContent(
                                        title: System.TableView.SystemContent.Title(
                                            text: "Subscribed"
                                        )
                                    )
                                ),
                                System.TableView.Row(
                                    content: System.TableView.SystemContent(
                                        title: System.TableView.SystemContent.Title(
                                            text: "id: \(info.id)"
                                        )
                                    )
                                ),
                                System.TableView.Row(
                                    content: System.TableView.SystemContent(
                                        title: System.TableView.SystemContent.Title(
                                            text: "willAutoRenew: \(info.willAutoRenew)"
                                        )
                                    )
                                ),
                            ]

                        case .notSubscribed:
                            return [
                                System.TableView.Row(
                                    content: System.TableView.SystemContent(
                                        title: System.TableView.SystemContent.Title(
                                            text: "Not subscribed"
                                        )
                                    )
                                )
                            ]

                        case let .expired(info):
                            return [
                                [
                                    System.TableView.Row(
                                        content: System.TableView.SystemContent(
                                            title: System.TableView.SystemContent.Title(
                                                text: "Expired"
                                            )
                                        )
                                    ),
                                ],
                                info.expiredSubscriptions.map { expiredSubscription in
                                    System.TableView.Row(
                                        content: System.TableView.SystemContent(
                                            title: System.TableView.SystemContent.Title(
                                                text: "id: \(expiredSubscription.id), \(expiredSubscription.reason)"
                                            )
                                        )
                                    )
                                }
                            ].flatMap { $0 }
                        }
                    }(),
                    header: System.TableView.SystemHeader(
                        text: "Status"
                    )
                )
            ]
        )
    }
}

extension LogDomain {
    fileprivate static let storeClient: Self = "storeClient"
}
