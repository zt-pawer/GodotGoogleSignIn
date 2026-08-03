// swift-tools-version: 6.2

import PackageDescription

let swiftSettings: [SwiftSetting] = [
    .unsafeFlags([
        "-Xfrontend", "-internalize-at-link",
        "-Xfrontend", "-lto=llvm-full",
        "-Xfrontend", "-conditional-runtime-records"
    ])
]

let linkerSettings: [LinkerSetting] = [
    .unsafeFlags(["-Xlinker", "-dead_strip"])
]

let runtimeDependency: Target.Dependency = .product(
    name: "SwiftGodotRuntime",
    package: "SwiftGodot"
)

let package = Package(
    name: "GodotGoogleSignIn",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "GodotGoogleSignIn", type: .dynamic, targets: ["GodotGoogleSignIn"]),
    ],
    dependencies: [
        .package(url: "https://github.com/migueldeicaza/SwiftGodot", from: "0.79.0"),
        .package(url: "https://github.com/google/GoogleSignIn-iOS", from: "7.0.0"),
    ],
    targets: [
        .target(
            name: "GodotGoogleSignIn",
            dependencies: [
                runtimeDependency,
                .product(name: "GoogleSignIn", package: "GoogleSignIn-iOS", condition: .when(platforms: [.iOS])),
            ],
            swiftSettings: swiftSettings,
            linkerSettings: linkerSettings
        ),
    ]
)
