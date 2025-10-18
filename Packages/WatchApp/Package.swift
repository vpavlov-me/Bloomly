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
        .package(path: "../Tracking"),
        .package(path: "../DesignSystem"),
        .package(path: "../Content")
    ],
    targets: [
        .target(
            name: "WatchApp",
            dependencies: [
                "Tracking",
                "DesignSystem",
                "Content"
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
