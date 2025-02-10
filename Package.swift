// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "miniCountdown",
    defaultLocalization: "zh-Hans",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "miniCountdown", targets: ["miniCountdown"])
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", .upToNextMajor(from: "5.10.0")),
        .package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", .upToNextMajor(from: "5.0.2"))
    ],
    targets: [
        .executableTarget(
            name: "miniCountdown",
            dependencies: [
                "Alamofire",
                "SwiftyJSON"
            ],
            path: "miniCountdown",
            resources: [
                .process("Data/WorkMind.xcdatamodeld")
            ]
        )
    ]
)
