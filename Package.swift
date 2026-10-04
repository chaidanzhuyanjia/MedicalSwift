// swift-tools-version: 6.0
import PackageDescription
let package = Package(
  name: "MedicalSwift",
  platforms: [.iOS(.v17), .macOS(.v14)],
  products: [
    .library(name:"MedicalSwiftCore",targets:["MedicalSwiftCore"]),
    .executable(name:"MedicalSwiftRunner",targets:["MedicalSwiftRunner"])
  ],
  dependencies:[.package(url:"https://github.com/swiftlang/swift-syntax.git",from:"600.0.0")],
  targets:[
    .target(name:"MedicalSwiftCore",dependencies:[
      .product(name:"SwiftSyntax",package:"swift-syntax"),
      .product(name:"SwiftParser",package:"swift-syntax")
    ]),
    .executableTarget(name:"MedicalSwiftRunner",dependencies:["MedicalSwiftCore"]),
    .testTarget(name:"MedicalSwiftCoreTests",dependencies:["MedicalSwiftCore"])
  ])
