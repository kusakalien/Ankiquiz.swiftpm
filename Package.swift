// swift-tools-version: 5.8

import PackageDescription
import AppleProductTypes

let package = Package(
    name: "AnkiQuiz",
    platforms: [
        .iOS("16.0")
    ],
    products: [
        .iOSApplication(
            name: "AnkiQuiz",
            targets: ["AppModule"],
            bundleIdentifier: "com.example.AnkiQuiz",
            displayVersion: "1.0",
            bundleVersion: "1",
            appIcon: .placeholder(icon: .book),
            accentColor: .presetColor(.indigo),
            supportedDeviceFamilies: [.pad, .phone],
            supportedInterfaceOrientations: [
                .portrait,
                .landscapeRight,
                .landscapeLeft
            ]
        )
    ],
    targets: [
        .executableTarget(
            name: "AppModule",
            path: "Sources"
        )
    ]
)
