// swift-tools-version:5.3.0

import PackageDescription

let package = Package(
    name: "Store",
    platforms: [
        .iOS("15")
    ],
    products: [
        .library(name: "Store", targets: ["Store"]),
        .library(name: "SubscriptionState", targets: ["SubscriptionState"])
    ],
    dependencies: [
        .package(name: "Core", url: "https://github.com/kutchie-pelaez-packages/Core.git", .branch("master"))
    ],
    targets: [
        .target(
            name: "Store",
            dependencies: [
                .product(name: "Core", package: "Core"),
                .target(name: "SubscriptionState")
            ]
        ),
        .target(name: "SubscriptionState")
    ]
)
