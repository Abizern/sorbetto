import PackageDescription

let package = Package(
  name: "Forge",
  dependencies: [
 //   .Package(url: "https://github.com/KyleF/PathKit.git", majorVersion: 0),
    .Package(url: "https://github.com/behrang/YamlSwift.git", majorVersion: 1)
  ],
  testDependencies: [
    .Package(url: "https://github.com/KyleF/spectre-build.git", majorVersion: 0)
  ])