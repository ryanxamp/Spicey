// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Spicey",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(name: "Spicey", path: "Sources/Spicey")
    ]
)
