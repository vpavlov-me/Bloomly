// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "WatchApp",
    platforms: [
        .watchOS(.v10)
    ],
    products: [
        .library(
            name: "WatchApp",
            targets: ["WatchApp"]
        )
    ],
    dependencies: [
        .package(path: "../AppSupport"),
        .package(path: "../Tracking"),
        .package(path: "../Content"),
        .package(path: "../Sync"),
        .package(path: "../Measurements")
    ],
    targets: [
        .target(
            name: "WatchApp",
            dependencies: [
                "AppSupport",
                "Tracking",
                "Content",
                "Sync",
                "Measurements"
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "WatchAppTests",
            dependencies: ["WatchApp"],
            path: "Tests/WatchApp"
        )
    ]
)
