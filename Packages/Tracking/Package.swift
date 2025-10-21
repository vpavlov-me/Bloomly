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
    dependencies: [],
    targets: [
        .target(
            name: "Tracking",
            path: "Sources"
        ),
        .testTarget(
            name: "TrackingTests",
            dependencies: ["Tracking"],
            path: "Tests/Tracking"
        )
    ]
)
