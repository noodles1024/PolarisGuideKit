// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "PolarisGuideKit",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        .library(
            name: "PolarisGuideKit",
            targets: ["PolarisGuideKit"]
        )
    ],
    targets: [
        .target(
            name: "PolarisGuideKit",
            path: "Sources"
        )
    ]
)


