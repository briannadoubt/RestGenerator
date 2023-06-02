// swift-tools-version: 5.8

import PackageDescription

let package = Package(
    name: "RestGenerator",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .tvOS(.v15),
        .watchOS(.v8)
    ],
    products: [
        .plugin(name: "RestGenerator", targets: ["RestGenerator"]),
        .plugin(name: "RestBuilder", targets: ["RestBuilder"]),
        .executable(name: "RestGeneration", targets: ["RestGeneration"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", .upToNextMajor(from: "1.2.2")),
        .package(url: "https://github.com/apple/swift-syntax.git", .upToNextMajor(from: "508.0.0")),
        .package(url: "https://github.com/yonaskolb/SwagGen.git", .upToNextMajor(from: "4.7.0")),
    ],
    targets: [
        .executableTarget(
            name: "RestGeneration",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
                .product(name: "Swagger", package: "SwagGen"),
                .product(name: "SwagGenKit", package: "SwagGen"),
            ]
        ),
        .testTarget(
            name: "RestGenerationTests",
            dependencies: ["RestGeneration"]
        ),
        .plugin(
            name: "RestGenerator",
            capability: .command(
                intent: .custom(
                    verb: "generate",
                    description: "Generate Rest Client"
                ),
                permissions: [
                    .writeToPackageDirectory(reason: "Generate Rest Client")
                ]
            ),
            dependencies: ["RestGeneration"]
        ),
        .plugin(
            name: "RestBuilder",
            capability: .buildTool(),
            dependencies: ["RestGeneration"]
        ),
        .testTarget(
            name: "RestGeneratorTests",
            dependencies: ["RestGenerator"]
        ),
    ]
)
