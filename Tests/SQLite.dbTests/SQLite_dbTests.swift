import XCTest
@testable import SQLite_db

final class SQLite_dbTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(SQLite_db().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
