// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "SnapshotGuard",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(name: "SnapshotGuard", targets: ["SnapshotGuard"])
    ],
    targets: [
        .target(name: "SnapshotGuard"),
        .testTarget(
            name: "SnapshotGuardTests",
            dependencies: ["SnapshotGuard"]
        )
    ]
)
