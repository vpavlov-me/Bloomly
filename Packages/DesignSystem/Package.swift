// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "DesignSystem",
    platforms: [
        .iOS(.v17),
        .watchOS(.v10)
    ],
    products: [
        .library(
            name: "DesignSystem",
            targets: ["DesignSystem"]
        )
    ],
    dependencies: [
        .package(path: "../AppSupport"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.12.0")
    ],
    targets: [
        .target(
            name: "DesignSystem",
            dependencies: [
                "AppSupport"
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "DesignSystemTests",
            dependencies: [
                "DesignSystem",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
            ],
            path: "Tests/DesignSystem"
        )
    ]
)
