// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "PongoKit",
    defaultLocalization: "en",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "PongoCore", targets: ["PongoCore"])
    ],
    targets: [
        // Everything that isn't UI: the API, the database, syncing, the
        // repositories and the player. It builds for iOS and macOS alike.
        .target(
            name: "PongoCore",
            linkerSettings: [.linkedLibrary("sqlite3")]
        ),
        .testTarget(name: "PongoCoreTests", dependencies: ["PongoCore"]),
    ]
)
