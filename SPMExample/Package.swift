// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "WavesSDKExample",
    platforms: [
        .iOS(.v11),
        .macOS(.v10_15)
    ],
    products: [
        .executable(
            name: "WavesSDKExample",
            targets: ["WavesSDKExample"]
        ),
    ],
    dependencies: [
        .package(name: "WavesSDK-iOS", path: "../")
    ],
    targets: [
        .executableTarget(
            name: "WavesSDKExample",
            dependencies: [
                .product(name: "WavesSDK", package: "WavesSDK-iOS"),
                .product(name: "WavesSDKCrypto", package: "WavesSDK-iOS"),
            ]
        ),
    ]
)