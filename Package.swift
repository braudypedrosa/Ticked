// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Ticked",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "EfficiencyCore", targets: ["EfficiencyCore"]),
        .executable(name: "Ticked", targets: ["Ticked"])
    ],
    dependencies: [
        .package(url: "https://github.com/supabase/supabase-swift.git", from: "2.0.0")
    ],
    targets: [
        .target(
            name: "EfficiencyCore",
            dependencies: []
        ),
        .executableTarget(
            name: "Ticked",
            dependencies: [
                "EfficiencyCore",
                .product(name: "Supabase", package: "supabase-swift")
            ],
            path: "Sources/Ticked"
        ),
        .testTarget(
            name: "EfficiencyCoreTests",
            dependencies: ["EfficiencyCore"]
        )
    ]
)
