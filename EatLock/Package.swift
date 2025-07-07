// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "EatLock",
    platforms: [
        .iOS(.v16) // iOS 16以上をサポート
    ],
    products: [
        .library(
            name: "EatLock",
            targets: ["EatLock"]
        ),
    ],
    dependencies: [
        // Google Mobile Ads SDK
        .package(
            url: "https://github.com/googleads/swift-package-manager-google-mobile-ads",
            from: "11.0.0"
        )
    ],
    targets: [
        .target(
            name: "EatLock",
            dependencies: [
                .product(name: "GoogleMobileAds", package: "swift-package-manager-google-mobile-ads")
            ]
        ),
        .testTarget(
            name: "EatLockTests",
            dependencies: ["EatLock"]
        ),
    ]
)