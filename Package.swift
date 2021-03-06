// swift-tools-version:5.3.0

import PackageDescription

let package = Package(
    name: "Store",
    platforms: [
        .iOS("15")
    ],
    products: [
        .library(
            name: "Store",
            targets: [
                "Store"
            ]
        ),
        .library(
            name: "Subscription",
            targets: [
                "Subscription"
            ]
        )
    ],
    dependencies: [
        .package(name: "Core", url: "https://github.com/kutchie-pelaez-packages/Core.git", .branch("master")),
        .package(name: "Logging", url: "https://github.com/kutchie-pelaez-packages/Logging.git", .branch("master")),
        .package(name: "Yams", url: "https://github.com/jpsim/Yams.git", from: "4.0.6")
    ],
    targets: [
        .target(
            name: "Store",
            dependencies: [
                .product(name: "Core", package: "Core"),
                .product(name: "Logger", package: "Logging"),
                .product(name: "Yams", package: "Yams"),
                .target(name: "Subscription")
            ]
        ),
        .target(
            name: "Subscription",
            dependencies: [
                .product(name: "Core", package: "Core"),
                .product(name: "Yams", package: "Yams")
            ]
        ),
        .testTarget(
            name: "StoreTests",
            dependencies: [
                .product(name: "Core", package: "Core"),
                .product(name: "Logger", package: "Logging"),
                .target(name: "Store"),
                .target(name: "Subscription")
            ],
            path: "Tests",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
