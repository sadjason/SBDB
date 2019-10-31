//
//  WAL.swift
//  SQLiteTests
//
//  Created by zhangwei on 2019/10/31.
//  Copyright © 2019 ByteDance. All rights reserved.
//

import XCTest
@testable import SQLite
import SQLite3

class WAL: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testConfiguringWalMode() throws {
        let database: Database = try Util.openDatabase(options: [.readwrite, .create, .noMutex])
        try database.exec(sql: "pragma journal_mode=wal;", withParams: nil) { (index, row, _) in
            print("index = \(index)")
            if let mode = row["journal_mode"] {
                print("mode = \(mode)")
            }
        }
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
