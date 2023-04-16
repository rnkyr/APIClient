// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "APIClient",
    platforms: [.iOS(.v11)],
    products: [
        .library(name: "APIClient", targets: ["APIClient"]),
        .library(name: "APIClientAlamofire", targets: ["APIClientAlamofire"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire", exact: "5.2.1")
    ],
    targets: [
        .target(name: "APIClient"),
        .target(name: "APIClientAlamofire", dependencies: ["APIClient", "Alamofire"])
    ],
    swiftLanguageVersions: [.v5]
)
