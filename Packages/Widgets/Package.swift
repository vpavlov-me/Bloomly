// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "Widgets",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "Widgets",
            targets: ["Widgets"]
        )
    ],
    dependencies: [
        .package(path: "../Timeline"),
        .package(path: "../Tracking"),
        .package(path: "../Measurements"),
        .package(path: "../DesignSystem"),
        .package(path: "../Content")
    ],
    targets: [
        .target(
            name: "Widgets",
            dependencies: [
                "Timeline",
                "Tracking",
                "Measurements",
                "DesignSystem",
                "Content"
            ],
            resources: [
                .process("Resources")
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "WidgetsTests",
            dependencies: ["Widgets"],
            path: "Tests/Widgets"
        )
    ]
)
