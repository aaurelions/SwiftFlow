// swift-tools-version: 6.1
import PackageDescription

let package = Package(
  name: "SwiftFlow",
  defaultLocalization: "en",
  platforms: [
    .iOS(.v17),
    .macOS(.v13),
  ],
  products: [
    .library(
      name: "SwiftFlow",
      targets: ["SwiftFlow"]
    )
  ],
  targets: [
    .target(
      name: "SwiftFlow",
      path: "Sources/SwiftFlow",
      resources: [.process("Resources")]
    ),
    .testTarget(
      name: "SwiftFlowTests",
      dependencies: ["SwiftFlow"],
      path: "Tests/SwiftFlowTests"
    ),
  ]
)
