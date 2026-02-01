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
        .library(
            name: "HealthQLParser",
            targets: ["HealthQLParser"]
        ),
    ],
    targets: [
        .target(
            name: "HealthQL",
            linkerSettings: [
                .linkedFramework("HealthKit")
            ]
        ),
        .target(
            name: "HealthQLParser",
            dependencies: ["HealthQL"]
        ),
        .testTarget(
            name: "HealthQLTests",
            dependencies: ["HealthQL"]
        ),
        .testTarget(
            name: "HealthQLParserTests",
            dependencies: ["HealthQLParser"]
        ),
    ]
)
