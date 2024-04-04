// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "APIClient",
    platforms: [.iOS(.v13)],
    products: [
        .library(name: "APIClient", targets: ["APIClient"]),
        .library(name: "APIClientAlamofire", targets: ["APIClientAlamofire"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire", exact: "5.9.1")
    ],
    targets: [
        .target(name: "APIClient"),
        .target(name: "APIClientAlamofire", dependencies: ["APIClient", "Alamofire"])
    ],
    swiftLanguageVersions: [.v5]
)
