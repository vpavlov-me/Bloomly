// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "Content",
    platforms: [
        .iOS(.v17),
        .watchOS(.v10)
    ],
    products: [
        .library(
            name: "Content",
            targets: ["Content"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Content",
            dependencies: [],
            resources: [
                .process("Resources")
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "ContentTests",
            dependencies: ["Content"],
            path: "Tests/Content"
        )
    ]
)
