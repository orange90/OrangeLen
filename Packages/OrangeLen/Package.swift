// swift-tools-version: 5.10
import PackageDescription
let package = Package(name: "OrangeLen", platforms: [.macOS(.v14)], products: [
    .library(name: "OrangeLenCore", targets: ["OrangeLenCore"]),
    .library(name: "OrangeLenUI", targets: ["OrangeLenUI"])
], dependencies: [.package(url: "https://github.com/swiftlang/swift-markdown.git", exact: "0.8.0")], targets: [
    .target(name: "OrangeLenCore", dependencies: [.product(name: "Markdown", package: "swift-markdown")]),
    .target(name: "OrangeLenUI", dependencies: ["OrangeLenCore"], resources: [.process("Resources")]),
    .testTarget(name: "OrangeLenCoreTests", dependencies: ["OrangeLenCore"]),
    .testTarget(name: "OrangeLenUITests", dependencies: ["OrangeLenUI", "OrangeLenCore"])
])
