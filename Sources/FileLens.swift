import Foundation
import Yaml

public struct FileLens {
  public static let contents = Lens<File, NSData>(from: { $0.contents }, to: { contents, file -> File in
    return File(contents: contents, context: file.context)
  })

  public static let context = Lens<File, [Yaml : Yaml]>(from: { $0.context }, to: { context, file -> File in
    return File(contents: file.contents, context: context)
  })
}
