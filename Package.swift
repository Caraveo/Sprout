// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Sprout",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "Sprout",
            targets: ["Sprout"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "Sprout",
            dependencies: [],
            resources: [
                .process("Resources"),
                .process("FerrofluidShader.metal")
            ]
        )
    ]
)


