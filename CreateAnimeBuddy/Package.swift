// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CreateAnimeBuddy",
    platforms: [.macOS("10.15")],
    products: [
        .executable(
            name: "createAnimeBuddy",
            targets: ["CreateAnimeBuddy"]
        )
    ],
    dependencies: [
        // other dependencies
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "12.3.0"),
        .package(url: "https://github.com/googleapis/google-auth-library-swift.git", from: "0.5.3" )
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "CreateAnimeBuddy",
            dependencies: [
                // other dependencies
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "OAuth2", package: "google-auth-library-swift")
            ]
        ),
    ]
)
