import XCTest

import SQLite_dbTests

var tests = [XCTestCaseEntry]()
tests += SQLite_dbTests.allTests()
XCTMain(tests)
