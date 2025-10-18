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
        .package(path: "../Content")
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
            dependencies: ["Measurements"],
            path: "Tests/Measurements"
        )
    ]
)
