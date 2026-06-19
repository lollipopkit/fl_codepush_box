// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "fcb_code_push",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "fcb-code-push", type: .static, targets: ["fcb_code_push"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .binaryTarget(
            name: "libfcb_updater",
            path: "libfcb_updater.xcframework"
        ),
        .target(
            name: "fcb_code_push",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
                "libfcb_updater"
            ],
            path: "Sources/fcb_code_push",
            publicHeadersPath: ".",
            linkerSettings: [
                .linkedFramework("Foundation"),
                .linkedFramework("UIKit")
            ]
        )
    ]
)
