// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "Sync",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "Sync",
            targets: ["Sync"]
        )
    ],
    dependencies: [
        .package(path: "../Tracking"),
        .package(path: "../Measurements")
    ],
    targets: [
        .target(
            name: "Sync",
            dependencies: [
                "Tracking",
                "Measurements"
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "SyncTests",
            dependencies: ["Sync"],
            path: "Tests/Sync"
        )
    ]
)
