import PathKit
import XCTest
import Yaml
@testable import Sorbetto

class SorbettoTests: XCTestCase {
    func makeTest(path: String, completionHandler: @escaping BuildCompletionHandler = { _ in }) throws {
        let destination = try Path.uniqueTemporary()

        //
        // Why three ".."?
        //        <-(1) <-(2)         <-(3)
        // Sorbetto/Tests/SorbettoTests/X.swift
        //
        let fileToRoot = "../../.."

        let repoRoot = (Path(#file) + fileToRoot).normalize()
        let directoryPath = repoRoot + path
        XCTAssertTrue(directoryPath.isDirectory)

        var builder = SiteBuilder(directory: directoryPath)
        builder.destination = destination
        builder.build { error, site in
            completionHandler(error, site)
            XCTAssertNil(error)
        }
    }

    func testFixture1() throws {
        try makeTest(path: "./Fixtures/Sites/01/") { error, site in

        }
    }

    func testFixture2() throws {
        try makeTest(path: "./Fixtures/Sites/02/") { error, site in
            guard let index = site["index.md"] else {
                XCTFail("index.md should exist")
                return
            }

            guard let frontmatter = index.metadata[.frontmatter] as? Yaml else {
                XCTFail("Frontmatter should have been parsed")
                return
            }

            XCTAssertEqual(frontmatter.dictionary?["title"], "An Example")
            XCTAssertEqual(frontmatter.dictionary?["date"], "2001-01-01")
            XCTAssertEqual(frontmatter.dictionary?["draft"], false)
        }
    }

    static var allTests: [(String, (SorbettoTests) -> () throws -> Void)] {
        return [
            ("testFixture1", testFixture1),
            ("testFixture2", testFixture2),
        ]
    }
}
