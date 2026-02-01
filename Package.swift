// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "HealthQL",
    platforms: [
        .iOS(.v15),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "HealthQL",
            targets: ["HealthQL"]
        ),
    ],
    targets: [
        .target(
            name: "HealthQL",
            linkerSettings: [
                .linkedFramework("HealthKit")
            ]
        ),
        .testTarget(
            name: "HealthQLTests",
            dependencies: ["HealthQL"]
        ),
    ]
)
