import ProjectDescription

let appName = "BabyTrack"
let bundlePrefix = "com.example"
let teamID = "ABCDE12345"

let project = Project(
    name: appName,
    organizationName: "BabyTrack",
    options: [.textSettings(defaultIndentation: .spaces(4))],
    packages: [
        .package(path: "Packages/DesignSystem"),
        .package(path: "Packages/Content"),
        .package(path: "Packages/Tracking"),
        .package(path: "Packages/Measurements"),
        .package(path: "Packages/Timeline"),
        .package(path: "Packages/Paywall"),
        .package(path: "Packages/Sync"),
        .package(path: "Packages/Widgets"),
        .package(path: "Packages/WatchApp"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.12.0")
    ],
    settings: Settings(
        base: [
            "DEVELOPMENT_TEAM": .string(teamID),
            "CODE_SIGN_STYLE": "Automatic",
            "SWIFT_VERSION": "5.10"
        ]
    ),
    targets: [
        Target(
            name: appName,
            platform: .iOS,
            product: .app,
            bundleId: "\(bundlePrefix).babytrack",
            deploymentTarget: .iOS(targetVersion: "17.0", devices: [.iphone, .ipad]),
            infoPlist: .extendingDefault(with: [
                "UILaunchScreen": [:],
                "UIBackgroundModes": ["fetch"]
            ]),
            sources: ["App/Sources/**"],
            resources: ["App/Resources/**", "App/CoreData/**"],
            entitlements: "App/Resources/BabyTrack.entitlements",
            dependencies: [
                .package(product: "DesignSystem"),
                .package(product: "Content"),
                .package(product: "Tracking"),
                .package(product: "Measurements"),
                .package(product: "Timeline"),
                .package(product: "Paywall"),
                .package(product: "Sync"),
                .package(product: "Widgets"),
                .package(product: "WatchApp")
            ]
        ),
        Target(
            name: "BabyTrackTests",
            platform: .iOS,
            product: .unitTests,
            bundleId: "\(bundlePrefix).babytrack.tests",
            infoPlist: .default,
            sources: ["Tests/**"],
            dependencies: [
                .target(name: appName),
                .package(product: "SnapshotTesting")
            ]
        ),
        Target(
            name: "BabyTrackWidgets",
            platform: .iOS,
            product: .appExtension,
            bundleId: "\(bundlePrefix).babytrack.widgets",
            deploymentTarget: .iOS(targetVersion: "17.0", devices: [.iphone, .ipad]),
            infoPlist: .default,
            sources: ["Targets/BabyTrackWidgets/Sources/**"],
            entitlements: "Targets/BabyTrackWidgets/BabyTrackWidgets.entitlements",
            dependencies: [
                .package(product: "Widgets")
            ]
        ),
        Target(
            name: "BabyTrackWatch",
            platform: .watchOS,
            product: .app,
            bundleId: "\(bundlePrefix).babytrack.watchapp",
            deploymentTarget: .watchOS(targetVersion: "10.0"),
            infoPlist: .default,
            sources: ["Targets/BabyTrackWatch/Sources/**"],
            dependencies: [
                .target(name: "BabyTrackWatchExtension")
            ]
        ),
        Target(
            name: "BabyTrackWatchExtension",
            platform: .watchOS,
            product: .appExtension,
            bundleId: "\(bundlePrefix).babytrack.watchkitextension",
            deploymentTarget: .watchOS(targetVersion: "10.0"),
            infoPlist: .default,
            sources: ["Targets/BabyTrackWatchExtension/Sources/**"],
            entitlements: "Targets/BabyTrackWatchExtension/BabyTrackWatchExtension.entitlements",
            dependencies: [
                .package(product: "WatchApp"),
                .package(product: "Tracking")
            ]
        )
    ],
    schemes: [
        Scheme(
            name: appName,
            shared: true,
            buildAction: BuildAction(targets: [appName, "BabyTrackWidgets", "BabyTrackWatch", "BabyTrackWatchExtension"]),
            testAction: TestAction(targets: ["BabyTrackTests"])
        ),
        Scheme(
            name: "BabyTrackTests",
            shared: true,
            buildAction: BuildAction(targets: ["BabyTrackTests"]),
            testAction: TestAction(targets: ["BabyTrackTests"])
        )
    ]
)
