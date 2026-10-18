// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Snap",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/VedAtal/swift-app-kit.git", branch: "main")
    ],
    targets: [
        .executableTarget(
            name: "Snap",
            dependencies: [.product(name: "SwiftAppKit", package: "swift-app-kit")],
            path: "Sources/Snap"
        )
    ]
)
