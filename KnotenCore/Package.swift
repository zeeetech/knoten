// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "KnotenCore",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "KnotenCore", targets: ["KnotenCore"])
    ],
    targets: [
        .target(name: "KnotenCore"),
        .testTarget(name: "KnotenCoreTests", dependencies: ["KnotenCore"]),
    ]
)
