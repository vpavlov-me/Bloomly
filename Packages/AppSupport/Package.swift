// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "AppSupport",
    platforms: [
        .iOS(.v17),
        .watchOS(.v10)
    ],
    products: [
        .library(
            name: "AppSupport",
            targets: ["AppSupport"]
        )
    ],
    targets: [
        .target(
            name: "AppSupport",
            path: "Sources"
        )
    ]
)
