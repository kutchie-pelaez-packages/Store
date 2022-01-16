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
        .package(name: "CoreUtils", url: "https://github.com/kutchie-pelaez/CoreUtils", .branch("master"))
    ],
    targets: [
        .target(
            name: "Store",
            dependencies: [
                .product(name: "CoreUtils", package: "CoreUtils"),
                .target(name: "SubscriptionState")
            ]
        ),
        .target(name: "SubscriptionState")
    ]
)
