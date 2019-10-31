//
//  BatchWriteTests.swift
//  SQLiteTests
//
//  Created by zhangwei on 2019/10/31.
//  Copyright © 2019 ByteDance. All rights reserved.
//

import XCTest
@testable import SQLite

class BatchWriteTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    // SQLite.DB 批量写（without transaction）
    func testBatchWriteForSQLite_withoutTransaction() {
        
    }

    // FMDB 批量写（without transaction）
    func testBatchWriteForFMDB_withoutTransaction() {

    }

    // SQLite.DB 批量写（with transaction）
    func testBatchWriteForSQLite_withTransaction() {

    }

    // FMDB 批量写（with transaction）
    func testBatchWriteForFMDB_withTransaction() {

    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
