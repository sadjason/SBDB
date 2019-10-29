//
//  SelectTests.swift
//  SQLiteTests
//
//  Created by zhangwei on 2019/10/28.
//  Copyright © 2019 ByteDance. All rights reserved.
//

import XCTest
@testable import SQLite

class SelectTests: XCTestCase {

    var db: Database!

    override func setUp() {
        db = try? openDatabase()
    }

    override func tearDown() {

    }

    func testSelectOne() throws {
        let students = try Student.fetchRows(from: db)
        print(students.count)
//        for s in students {
//            print(s)
//        }
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
