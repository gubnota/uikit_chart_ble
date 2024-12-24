import ProjectDescription

let project = Project(
    name: "iOSProject",
    targets: [
        .target(
            name: "iOSProject",
            destinations: .iOS,
            product: .app,
            bundleId: "net.fenki.default",
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ],
                    "NSBluetoothAlwaysUsageDescription": "This app requires Bluetooth to connect to BLE devices.",
                    "NSBluetoothPeripheralUsageDescription": "This app needs Bluetooth to scan and connect to BLE devices.",
                    "NSLocationWhenInUseUsageDescription": "Location is required to scan for nearby Bluetooth devices.",
                    "NSLocationAlwaysUsageDescription": "Location is required to detect Bluetooth devices in the background.",
                    "UIBackgroundModes": ["bluetooth-central", "location"],
                ]
            ),
            sources: ["App/**"],
            resources: ["Resources/**"],
            dependencies: [
                // .external(name: "Charts") // Add DGCharts dependency
            ],
            settings: .settings(
                base: [
                    "DEVELOPMENT_TEAM": "RSD67YH647", // Replace with your actual Team ID
                ]
            )
        ),
        // .target(
        //     name: "iOSProjectTests",
        //     destinations: .iOS,
        //     product: .unitTests,
        //     bundleId: "io.tuist.iOSProjectTests",
        //     infoPlist: .default,
        //     sources: ["iOSProject/Tests/**"],
        //     resources: [],
        //     dependencies: [.target(name: "iOSProject")]
        // ),
    ]
)

