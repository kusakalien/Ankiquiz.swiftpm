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
            appIcon: .asset("AppIcon"),
            accentColor: .presetColor(.indigo),
            supportedDeviceFamilies: [.pad, .phone],
            supportedInterfaceOrientations: [
                .portrait,
                .portraitUpsideDown,
                .landscapeRight,
                .landscapeLeft
            ]
        )
    ],
    targets: [
        .executableTarget(
            name: "AppModule",
            path: "Sources",
            resources: [
                .process("Assets.xcassets")
            ]
        )
    ]
)
