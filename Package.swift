// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WavesSDK",
    platforms: [
        .iOS(.v15),
        .macOS(.v13)
    ],
    products: [
        // Main SDK library
        .library(
            name: "WavesSDK",
            targets: ["WavesSDK"]
        ),
        // Crypto library
        .library(
            name: "WavesSDKCrypto",
            targets: ["WavesSDKCrypto"]
        ),
        // Extensions library
        .library(
            name: "WavesSDKExtensions",
            targets: ["WavesSDKExtensions"]
        ),
    ],
    dependencies: [
        // RxSwift - updated to latest SPM-compatible version
        .package(url: "https://github.com/ReactiveX/RxSwift.git", from: "6.5.0"),
        // Moya - updated to latest SPM-compatible version
        .package(url: "https://github.com/Moya/Moya.git", from: "15.0.0"),
        // Local WavesKeeperAuthenticator for waves.exchange authentication
        .package(path: "../WavesAuthentication"),
    ],
    targets: [
        // WavesSDK main target
        .target(
            name: "WavesSDK",
            dependencies: [
                "WavesSDKCrypto",
                "WavesSDKExtensions",
                .product(name: "RxSwift", package: "RxSwift"),
                .product(name: "Moya", package: "Moya"),
                .product(name: "RxMoya", package: "Moya"),
                .product(name: "WavesKeeperAuthenticator", package: "WavesAuthentication"),
            ],
            path: "Sources/WavesSDK"
        ),
        
        // WavesSDKCrypto target
        .target(
            name: "WavesSDKCrypto",
            dependencies: [
                "WavesSDKExtensions",
                "CBlake2",
                "CKeccak",
                "CCurve25519",
                "CBase58"
            ],
            path: "Sources/WavesSDKCrypto"
        ),
        
        // WavesSDKExtensions target
        .target(
            name: "WavesSDKExtensions",
            dependencies: [
                .product(name: "RxSwift", package: "RxSwift"),
            ],
            path: "Sources/WavesSDKExtensions"
        ),
        
        // C/ObjC targets for crypto libraries
        .target(
            name: "CBlake2",
            path: "Sources/CBlake2",
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("Sources"),
                .define("__SPM__"),
                .define("HAVE_EMMINTRIN_H", to: "0"),
                .define("HAVE_SMMINTRIN_H", to: "0"),
                .unsafeFlags(["-w"])  // Suppress warnings for vendor code
            ]
        ),
        
        .target(
            name: "CKeccak",
            path: "Sources/CKeccak",
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("Sources")
            ]
        ),
        
        .target(
            name: "CCurve25519",
            path: "Sources/CCurve25519",
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("Sources"),
                .headerSearchPath("Sources/ed25519"),
                .headerSearchPath("Sources/ed25519/additions"),
                .headerSearchPath("Sources/ed25519/nacl_includes"),
                .headerSearchPath("Sources/ed25519/nacl_sha512")
            ]
        ),
        
        .target(
            name: "CBase58",
            path: "Sources/CBase58",
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("Sources")
            ]
        ),
        
        // Test targets
        .testTarget(
            name: "WavesSDKTests",
            dependencies: [
                "WavesSDK",
                "WavesSDKCrypto",
                .product(name: "RxSwift", package: "RxSwift"),
            ],
            path: "Tests/WavesSDKTests"
        ),
    ],
    swiftLanguageVersions: [.v5]
)