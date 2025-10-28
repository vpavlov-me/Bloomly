// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "Tracking",
    platforms: [
        .iOS(.v17),
        .watchOS(.v10)
    ],
    products: [
        .library(
            name: "Tracking",
            targets: ["Tracking"]
        )
    ],
    dependencies: [
        .package(path: "../AppSupport"),
        .package(path: "../Content"),
        .package(path: "../DesignSystem"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.12.0")
    ],
    targets: [
        .target(
            name: "Tracking",
            dependencies: [
                "AppSupport",
                "Content",
                "DesignSystem"
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "TrackingTests",
            dependencies: [
                "Tracking",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
            ],
            path: "Tests/Tracking"
        )
    ]
)
