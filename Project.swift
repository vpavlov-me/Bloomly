import ProjectDescription

let appName = "BabyTrack"
let bundlePrefix = "com.example"
let teamID = "ABCDE12345"

let project = Project(
    name: appName,
    organizationName: "BabyTrack",
    options: [.textSettings(defaultIndentation: .spaces(4))],
    packages: [
        .package(path: "Packages/AppSupport"),
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
            "SWIFT_VERSION": "5.10",
            "OTHER_SWIFT_FLAGS": "-warnings-as-errors"
        ]
    ),
    targets: targets,
    schemes: schemes
)

private let targets: [Target] = [
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
        sources: ["App/**/*.swift"],
        resources: ["App/Resources/**", "App/CoreData/**"],
        entitlements: "App/Resources/BabyTrack.entitlements",
        dependencies: [
            .package(product: "AppSupport"),
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
        name: "BabyTrackWidgets",
        platform: .iOS,
        product: .appExtension,
        bundleId: "\(bundlePrefix).babytrack.widgets",
        deploymentTarget: .iOS(targetVersion: "17.0", devices: [.iphone, .ipad]),
        infoPlist: .default,
        sources: ["Targets/BabyTrackWidgets/Sources/**"],
        entitlements: "Targets/BabyTrackWidgets/BabyTrackWidgets.entitlements",
        dependencies: [
            .package(product: "Widgets"),
            .target(name: appName, condition: .when(platforms: [.iOS]))
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
    ),
    Target(
        name: "BabyTrackTests",
        platform: .iOS,
        product: .unitTests,
        bundleId: "\(bundlePrefix).babytrack.tests",
        infoPlist: .default,
        sources: ["Tests/Unit/**"],
        dependencies: [
            .target(name: appName)
        ]
    ),
    Target(
        name: "BabyTrackUITests",
        platform: .iOS,
        product: .uiTests,
        bundleId: "\(bundlePrefix).babytrack.uitests",
        infoPlist: .default,
        sources: ["Tests/UI/**"],
        dependencies: [
            .target(name: appName)
        ]
    ),
    Target(
        name: "DesignSystemTestsTarget",
        platform: .iOS,
        product: .unitTests,
        bundleId: "\(bundlePrefix).babytrack.designsystemtests",
        infoPlist: .default,
        sources: ["Packages/DesignSystem/Tests/**"],
        dependencies: [
            .package(product: "DesignSystem"),
            .package(product: "SnapshotTesting")
        ]
    ),
    Target(
        name: "ContentTestsTarget",
        platform: .iOS,
        product: .unitTests,
        bundleId: "\(bundlePrefix).babytrack.contenttests",
        infoPlist: .default,
        sources: ["Packages/Content/Tests/**"],
        dependencies: [
            .package(product: "Content")
        ]
    ),
    Target(
        name: "TrackingTestsTarget",
        platform: .iOS,
        product: .unitTests,
        bundleId: "\(bundlePrefix).babytrack.trackingtests",
        infoPlist: .default,
        sources: ["Packages/Tracking/Tests/**"],
        dependencies: [
            .package(product: "Tracking")
        ]
    ),
    Target(
        name: "MeasurementsTestsTarget",
        platform: .iOS,
        product: .unitTests,
        bundleId: "\(bundlePrefix).babytrack.measurementstests",
        infoPlist: .default,
        sources: ["Packages/Measurements/Tests/**"],
        dependencies: [
            .package(product: "Measurements"),
            .package(product: "SnapshotTesting")
        ]
    ),
    Target(
        name: "TimelineTestsTarget",
        platform: .iOS,
        product: .unitTests,
        bundleId: "\(bundlePrefix).babytrack.timelinetests",
        infoPlist: .default,
        sources: ["Packages/Timeline/Tests/**"],
        dependencies: [
            .package(product: "Timeline"),
            .package(product: "Tracking"),
            .package(product: "Measurements"),
            .package(product: "SnapshotTesting")
        ]
    ),
    Target(
        name: "PaywallTestsTarget",
        platform: .iOS,
        product: .unitTests,
        bundleId: "\(bundlePrefix).babytrack.paywalltests",
        infoPlist: .default,
        sources: ["Packages/Paywall/Tests/**"],
        dependencies: [
            .package(product: "Paywall"),
            .package(product: "SnapshotTesting")
        ]
    ),
    Target(
        name: "SyncTestsTarget",
        platform: .iOS,
        product: .unitTests,
        bundleId: "\(bundlePrefix).babytrack.synctests",
        infoPlist: .default,
        sources: ["Packages/Sync/Tests/**"],
        dependencies: [
            .package(product: "Sync"),
            .package(product: "Tracking"),
            .package(product: "Measurements")
        ]
    ),
    Target(
        name: "WidgetsTestsTarget",
        platform: .iOS,
        product: .unitTests,
        bundleId: "\(bundlePrefix).babytrack.widgetstests",
        infoPlist: .default,
        sources: ["Packages/Widgets/Tests/**"],
        dependencies: [
            .package(product: "Widgets")
        ]
    ),
    Target(
        name: "WatchAppTestsTarget",
        platform: .iOS,
        product: .unitTests,
        bundleId: "\(bundlePrefix).babytrack.watchapptests",
        infoPlist: .default,
        sources: ["Packages/WatchApp/Tests/**"],
        dependencies: [
            .package(product: "WatchApp"),
            .package(product: "Tracking")
        ]
    )
]

private let schemes: [Scheme] = [
    Scheme(
        name: appName,
        shared: true,
        buildAction: BuildAction(targets: [appName, "BabyTrackWidgets", "BabyTrackWatch", "BabyTrackWatchExtension"]),
        testAction: TestAction(targets: [
            "BabyTrackTests",
            "BabyTrackUITests",
            "TrackingTestsTarget",
            "MeasurementsTestsTarget",
            "TimelineTestsTarget",
            "PaywallTestsTarget",
            "DesignSystemTestsTarget",
            "SyncTestsTarget",
            "WidgetsTestsTarget",
            "WatchAppTestsTarget"
        ])
    ),
    Scheme(
        name: "BabyTrackTests",
        shared: true,
        buildAction: BuildAction(targets: ["BabyTrackTests"]),
        testAction: TestAction(targets: ["BabyTrackTests"])
    ),
    Scheme(
        name: "BabyTrackWatch",
        shared: true,
        buildAction: BuildAction(targets: ["BabyTrackWatch", "BabyTrackWatchExtension"])
    )
]
