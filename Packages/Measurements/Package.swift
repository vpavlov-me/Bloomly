// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "Measurements",
    platforms: [
        .iOS(.v17),
        .watchOS(.v10)
    ],
    products: [
        .library(
            name: "Measurements",
            targets: ["Measurements"]
        )
    ],
    dependencies: [
        .package(path: "../DesignSystem"),
        .package(path: "../Content"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.12.0")
    ],
    targets: [
        .target(
            name: "Measurements",
            dependencies: [
                "DesignSystem",
                "Content"
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "MeasurementsTests",
            dependencies: [
                "Measurements",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
            ],
            path: "Tests/Measurements"
        )
    ]
)
