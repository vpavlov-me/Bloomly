// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "AppSupport",
    platforms: [
        .iOS(.v17),
        .watchOS(.v10)
    ],
    products: [
        .library(
            name: "AppSupport",
            targets: ["AppSupport"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/TelemetryDeck/SwiftSDK", from: "2.0.0")
    ],
    targets: [
        .target(
            name: "AppSupport",
            dependencies: [
                .product(name: "TelemetryDeck", package: "SwiftSDK")
            ],
            path: "Sources"
        )
    ]
)
