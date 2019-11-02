//
//  BatchReadTests.swift
//  SQLiteTests
//
//  Created by zhangwei on 2019/10/31.
//  Copyright © 2019 ByteDance. All rights reserved.
//

import XCTest
@testable import SQLite

class BatchReadTests: XCTestCase {

    override func setUp() {
        try? Util.createStudentTable()
        try? Util.createDatabaseQueue().inDatabasae{ (db) in
            try? Student.delete(in: db)
        }
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
