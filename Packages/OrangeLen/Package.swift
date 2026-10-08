// swift-tools-version: 5.10
import PackageDescription
let package = Package(name: "OrangeLen", defaultLocalization: "en", platforms: [.macOS(.v14)], products: [
    .library(name: "OrangeLenCore", targets: ["OrangeLenCore"]),
    .library(name: "OrangeLenUI", targets: ["OrangeLenUI"])
], dependencies: [.package(url: "https://github.com/swiftlang/swift-markdown.git", exact: "0.8.0")], targets: [
    .systemLibrary(name: "CSQLite"),
    .systemLibrary(name: "CZlib"),
    .target(name: "OrangeLenCore", dependencies: ["CSQLite", "CZlib", .product(name: "Markdown", package: "swift-markdown")], resources: [.process("Resources")]),
    .target(name: "OrangeLenUI", dependencies: ["OrangeLenCore"], resources: [.process("Resources")]),
    .testTarget(name: "OrangeLenCoreTests", dependencies: ["OrangeLenCore"]),
    .testTarget(name: "OrangeLenUITests", dependencies: ["OrangeLenUI", "OrangeLenCore"])
])
