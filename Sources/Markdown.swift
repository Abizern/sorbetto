import Foundation
import Markdown
import PathKit

func markdown() -> Plugin {
  return { filesMap, sorbetto in
    var filesMap = filesMap
    for (path, file) in filesMap where path.`extension`?.lowercaseString == "md" {
      if let string = String(data: file.contents, encoding: NSUTF8StringEncoding),
        parser = try? Markdown(string: string),
        document = try? parser.document(),
        contents = document.dataUsingEncoding(NSUTF8StringEncoding)
      {
        filesMap[path] = File(contents: contents, context: file.context)
      }
    }

    return (filesMap, sorbetto)
  }
}
