// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "geofence_foreground_service",
  platforms: [
    .iOS("12.0")
  ],
  products: [
    .library(name: "geofence-foreground-service", targets: ["geofence_foreground_service"])
  ],
  dependencies: [],
  targets: [
    .target(
      name: "geofence_foreground_service",
      dependencies: []
    )
  ]
)
