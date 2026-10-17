// swift-tools-version: 5.10
import PackageDescription
let package = Package(name: "OrangeLen", defaultLocalization: "en", platforms: [.macOS(.v14)], products: [
    .library(name: "OrangeLenCore", targets: ["OrangeLenCore"]),
    .library(name: "OrangeLenUI", targets: ["OrangeLenUI"])
], dependencies: [.package(url: "https://github.com/swiftlang/swift-markdown.git", exact: "0.8.0"), .package(url: "https://github.com/jpsim/Yams.git", exact: "5.1.3")], targets: [
    .systemLibrary(name: "CSQLite"),
    .systemLibrary(name: "CZlib"),
    .systemLibrary(name: "CArchive"),
    .target(name: "CZstd"),
    .target(name: "OrangeLenCore", dependencies: ["CSQLite", "CZlib", "CArchive", "CZstd", .product(name: "Yams", package: "Yams"), .product(name: "Markdown", package: "swift-markdown")], resources: [.process("Resources")]),
    .target(name: "OrangeLenUI", dependencies: ["OrangeLenCore"], resources: [.process("Resources")]),
    .testTarget(name: "OrangeLenCoreTests", dependencies: ["OrangeLenCore"]),
    .testTarget(name: "OrangeLenUITests", dependencies: ["OrangeLenUI", "OrangeLenCore"])
])
