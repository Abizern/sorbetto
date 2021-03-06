import Foundation
import PathKit

public typealias IgnoreFilter = (Path) -> Bool

public struct Sorbetto {
    var absoluteSource: Path

    var absoluteDestination: Path

    public var directory: Path {
        didSet {
            assert(directory.isAbsolute)
            absoluteSource = source.absolute(relativeTo: directory)
            absoluteDestination = destination.absolute(relativeTo: directory)
        }
    }

    public var source: Path {
        didSet {
            absoluteSource = source.absolute(relativeTo: directory)
        }
    }

    public var destination: Path {
        didSet {
            absoluteDestination = destination.absolute(relativeTo: directory)
        }
    }

    public var plugins = [Plugin]()

    public var metadata = Metadata()

    public var parsesFrontmatter = true

    public var ignoreFilters = [IgnoreFilter]()

    public init(directory: Path = Path.current, source: Path = "./src", destination: Path = "./build") {
        self.directory = directory

        self.source = source
        self.absoluteSource = source.absolute(relativeTo: directory)

        self.destination = destination
        self.absoluteDestination = destination.absolute(relativeTo: directory)
    }

    public mutating func use(_ plugin: Plugin) {
        plugins.append(plugin)
    }

    public mutating func ignore(_ path: Path) {
        let relativePath: Path
        if path.isAbsolute {
            relativePath = path.relative(from: absoluteSource)
        } else {
            relativePath = path
        }

        ignoreFilters.append { $0 == relativePath }
    }

    public mutating func ignore(pattern: String) {
        let paths = absoluteSource.glob(pattern)
        ignoreFilters.append { path in paths.contains(path) }
    }

    public mutating func ignore(_ filter: @escaping IgnoreFilter) {
        ignoreFilters.append(filter)
    }

    @discardableResult
    public func process() throws -> Site {
        var plugins = self.plugins
        if parsesFrontmatter {
            plugins.insert(FrontmatterParser(), at: 0)
        }

        let site = Site(source: absoluteSource, paths: loadPaths())
        try site.run(plugins: plugins)
        return site
    }

    @discardableResult
    public func build(shouldClean: Bool = true) throws -> Site {
        let site = try process()

        if shouldClean {
            try removeDestination()
        }

        for path in site.paths {
            try write(path: path, file: site.memoizedFiles[path])
        }

        return site
    }

    func shouldIgnore(_ path: Path) -> Bool {
        if path.isDirectory {
            // Ignore directories - Directories are created in write() as necessary
            return true
        }

        for shouldIgnore in ignoreFilters {
            if shouldIgnore(path) {
                return true
            }
        }

        return false
    }

    func loadPaths() -> Set<Path> {
        do {
            let children = try absoluteSource.recursiveChildren()
                .filter { path in !shouldIgnore(path) }
                .map { path in path.relative(from: absoluteSource) }
            return Set(children)
        } catch {
            return []
        }
    }

    func write(path: Path, file: File?) throws {
        let destinationPath = path.absolute(relativeTo: absoluteDestination)

        let destinationParent = destinationPath.parent()
        if !destinationParent.exists {
            try destinationParent.mkpath()
        }

        if let data = file?.contentsIfLoaded {
            try destinationPath.write(data)
        } else {
            let sourcePath = path.absolute(relativeTo: absoluteSource)
            try sourcePath.copy(destinationPath)
        }
    }

    func removeDestination() throws {
        try absoluteDestination.delete()
    }
}

extension Sorbetto {
    public func using(_ plugin: Plugin) -> Sorbetto {
        var copy = self
        copy.use(plugin)
        return copy
    }

    public func ignoring(_ path: Path) -> Sorbetto {
        var copy = self
        copy.ignore(path)
        return copy
    }

    public func ignoring(pattern: String) -> Sorbetto {
        var copy = self
        copy.ignore(pattern: pattern)
        return copy
    }

    public func ignoring(_ filter: @escaping IgnoreFilter) -> Sorbetto {
        var copy = self
        copy.ignore(filter)
        return copy
    }

    public func parsingFrontmatter(_ shouldParse: Bool) -> Sorbetto {
        var copy = self
        copy.parsesFrontmatter = shouldParse
        return copy
    }
}
