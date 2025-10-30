import ProjectDescription

let appName = "Bloomly"
let bundlePrefix = "com.vibecoding"
let teamID = "ABCDE12345"

let project = Project(
    name: appName,
    organizationName: "Bloomly",
    options: .options(
        textSettings: .textSettings(
            usesTabs: false,
            indentWidth: 4,
            tabWidth: 4
        )
    ),
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
    settings: .settings(
        base: [
            "DEVELOPMENT_TEAM": .string(teamID),
            "CODE_SIGN_STYLE": "Automatic",
            "SWIFT_VERSION": "5.10",
            "OTHER_SWIFT_FLAGS": "-warnings-as-errors"
        ]
    ),
    targets: [
        .target(
            name: appName,
            destinations: .iOS,
            product: .app,
            bundleId: "\(bundlePrefix).bloomly",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(with: [
                "UILaunchScreen": [:],
                "UIBackgroundModes": ["fetch"]
            ]),
            sources: ["App/**/*.swift"],
            resources: ["App/Resources/**"],
            entitlements: "App/Resources/Bloomly.entitlements",
            scripts: [
                .pre(
                    script: """
                    if which swiftlint >/dev/null; then
                        swiftlint
                    else
                        echo "warning: SwiftLint not installed, download from https://github.com/realm/SwiftLint"
                    fi
                    """,
                    name: "SwiftLint",
                    basedOnDependencyAnalysis: false
                )
            ],
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
                .package(product: "WatchApp"),
                .target(name: "BloomlyWidgets")
            ],
            coreDataModels: [.coreDataModel("App/CoreData/BloomlyModel.xcdatamodeld")]
        ),
        .target(
            name: "BloomlyWidgets",
            destinations: .iOS,
            product: .appExtension,
            bundleId: "\(bundlePrefix).bloomly.widgets",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["Targets/BloomlyWidgets/Sources/**"],
            entitlements: "Targets/BloomlyWidgets/BloomlyWidgets.entitlements",
            dependencies: [
                .package(product: "Widgets")
            ]
        ),
        .target(
            name: "BloomlyWatchExtension",
            destinations: .watchOS,
            product: .watch2Extension,
            bundleId: "\(bundlePrefix).bloomly.watchkitextension",
            deploymentTargets: .watchOS("10.0"),
            infoPlist: .default,
            sources: ["Targets/BloomlyWatchExtension/Sources/**"],
            entitlements: "Targets/BloomlyWatchExtension/BloomlyWatchExtension.entitlements",
            dependencies: [
                .package(product: "WatchApp"),
                .package(product: "Tracking")
            ]
        ),
        .target(
            name: "BloomlyWatch",
            destinations: .watchOS,
            product: .watch2App,
            bundleId: "\(bundlePrefix).bloomly.watchapp",
            deploymentTargets: .watchOS("10.0"),
            infoPlist: .default,
            sources: ["Targets/BloomlyWatch/Sources/**"],
            dependencies: [
                .target(name: "BloomlyWatchExtension")
            ]
        ),
        .target(
            name: "BloomlyTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "\(bundlePrefix).bloomly.tests",
            infoPlist: .default,
            sources: ["Tests/Unit/**"],
            dependencies: [
                .target(name: appName)
            ]
        ),
        .target(
            name: "BloomlyUITests",
            destinations: .iOS,
            product: .uiTests,
            bundleId: "\(bundlePrefix).bloomly.uitests",
            infoPlist: .default,
            sources: ["Tests/UI/**"],
            dependencies: [
                .target(name: appName)
            ]
        ),
        .target(
            name: "DesignSystemTestsTarget",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "\(bundlePrefix).bloomly.designsystemtests",
            infoPlist: .default,
            sources: ["Packages/DesignSystem/Tests/**"],
            dependencies: [
                .package(product: "DesignSystem"),
                .package(product: "SnapshotTesting")
            ]
        ),
        .target(
            name: "ContentTestsTarget",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "\(bundlePrefix).bloomly.contenttests",
            infoPlist: .default,
            sources: ["Packages/Content/Tests/**"],
            dependencies: [
                .package(product: "Content")
            ]
        ),
        .target(
            name: "TrackingTestsTarget",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "\(bundlePrefix).bloomly.trackingtests",
            infoPlist: .default,
            sources: ["Packages/Tracking/Tests/**"],
            dependencies: [
                .package(product: "Tracking")
            ]
        ),
        .target(
            name: "MeasurementsTestsTarget",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "\(bundlePrefix).bloomly.measurementstests",
            infoPlist: .default,
            sources: ["Packages/Measurements/Tests/**"],
            dependencies: [
                .package(product: "Measurements"),
                .package(product: "SnapshotTesting")
            ]
        ),
        .target(
            name: "TimelineTestsTarget",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "\(bundlePrefix).bloomly.timelinetests",
            infoPlist: .default,
            sources: ["Packages/Timeline/Tests/**"],
            dependencies: [
                .package(product: "Timeline"),
                .package(product: "Tracking"),
                .package(product: "Measurements"),
                .package(product: "SnapshotTesting")
            ]
        ),
        .target(
            name: "PaywallTestsTarget",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "\(bundlePrefix).bloomly.paywalltests",
            infoPlist: .default,
            sources: ["Packages/Paywall/Tests/**"],
            dependencies: [
                .package(product: "Paywall"),
                .package(product: "SnapshotTesting")
            ]
        ),
        .target(
            name: "SyncTestsTarget",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "\(bundlePrefix).bloomly.synctests",
            infoPlist: .default,
            sources: ["Packages/Sync/Tests/**"],
            dependencies: [
                .package(product: "Sync"),
                .package(product: "Tracking"),
                .package(product: "Measurements")
            ]
        ),
        .target(
            name: "WidgetsTestsTarget",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "\(bundlePrefix).bloomly.widgetstests",
            infoPlist: .default,
            sources: ["Packages/Widgets/Tests/**"],
            dependencies: [
                .package(product: "Widgets")
            ]
        ),
        .target(
            name: "WatchAppTestsTarget",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "\(bundlePrefix).bloomly.watchapptests",
            infoPlist: .default,
            sources: ["Packages/WatchApp/Tests/**"],
            dependencies: [
                .package(product: "WatchApp"),
                .package(product: "Tracking")
            ]
        )
    ]
)
