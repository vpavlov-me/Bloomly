// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "Timeline",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "Timeline",
            targets: ["Timeline"]
        )
    ],
    dependencies: [
        .package(path: "../AppSupport"),
        .package(path: "../Tracking"),
        .package(path: "../Measurements"),
        .package(path: "../DesignSystem"),
        .package(path: "../Content"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.12.0")
    ],
    targets: [
        .target(
            name: "Timeline",
            dependencies: [
                "AppSupport",
                "Tracking",
                "Measurements",
                "DesignSystem",
                "Content"
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "TimelineTests",
            dependencies: [
                "Timeline",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
            ],
            path: "Tests/Timeline"
        )
    ]
)
