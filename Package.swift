// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "MpzReader",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "MpzReader",
            targets: ["MpzReader"]),
    ],
    dependencies: [
        .package(url: "https://github.com/readium/swift-toolkit.git", exact: "3.6.0"),
        .package(url: "https://github.com/stephencelis/SQLite.swift.git", from: "0.14.0"),
        .package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", from: "5.0.0"),
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", from: "0.9.0"),
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", from: "1.0.0"),
        .package(url: "https://github.com/cezheng/Fuzi.git", from: "3.0.0"),
        .package(url: "https://github.com/hyperoslo/Lightbox", branch: "master"), 
        // Note: Minizip and ScreenShield are removed/commented. 
        // Verify if standard Minizip is needed (usually replaced by ZIPFoundation) 
        // and add ScreenShield manually if you have the URL.
        // .package(url: "URL_TO_SCREENSHIELD", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "MpzReader",
            dependencies: [
                .product(name: "ReadiumShared", package: "swift-toolkit"),
                .product(name: "ReadiumStreamer", package: "swift-toolkit"),
                .product(name: "ReadiumNavigator", package: "swift-toolkit"),
                .product(name: "SQLite", package: "SQLite.swift"),
                "SwiftyJSON",
                "ZIPFoundation",
                "CryptoSwift",
                "Fuzi",
                .product(name: "Lightbox", package: "Lightbox"),
            ],
            path: "MpzReader",
            exclude: ["Info.plist"], // Exclude Info.plist if present in source root
            resources: [
                .process("Assets"),
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "MpzReaderTests",
            dependencies: ["MpzReader"],
            path: "Example/Tests"
        ),
    ]
)
