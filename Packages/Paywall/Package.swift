// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "Paywall",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "Paywall",
            targets: ["Paywall"]
        )
    ],
    dependencies: [
        .package(path: "../DesignSystem"),
        .package(path: "../Content"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.12.0")
    ],
    targets: [
        .target(
            name: "Paywall",
            dependencies: [
                "DesignSystem",
                "Content"
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "PaywallTests",
            dependencies: [
                "Paywall",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
            ],
            path: "Tests/Paywall"
        )
    ]
)
