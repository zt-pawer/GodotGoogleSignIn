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
    package: "SwiftGodotBinary"
)

let package = Package(
    name: "GodotGoogleSignIn",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "GodotGoogleSignIn", type: .dynamic, targets: ["GodotGoogleSignIn"]),
    ],
    dependencies: [
        .package(url: "https://github.com/migueldeicaza/SwiftGodotBinary", revision: "bf7cd9cb51b30039199c47811c486976923af93e"),
        .package(url: "https://github.com/google/GoogleSignIn-iOS", from: "10.0.0"),
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
