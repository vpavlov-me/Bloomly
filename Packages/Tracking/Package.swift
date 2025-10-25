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
        .package(path: "../DesignSystem")
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
            dependencies: ["Tracking"],
            path: "Tests/Tracking"
        )
    ]
)
