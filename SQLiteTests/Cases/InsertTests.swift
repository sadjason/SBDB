//
//  InsertTests.swift
//  SQLiteTests
//
//  Created by zhangwei on 2019/10/26.
//  Copyright © 2019 ByteDance. All rights reserved.
//

import XCTest
@testable import SQLite

//struct Student: TableCodable, Equatable {
//    let name: String
//    let age: UInt8
//    let address: String?
//    let grade: Int?
//    let married: Bool
//    let isBoy: Bool?
//    let gpa: Float
//    let extra: Data?
//}

class InsertTests: XCTestCase {

    var db: Database!

    override func setUp() {
        db = try? Util.openDatabase()
        try? Student.create(in: db) { (tb) in
            tb.ifNotExists = true

            tb.column("id", type: .integer).primaryKey()
            tb.column("name", type: .text).notNull()
            tb.column("age", type: .integer).notNull()
            tb.column("address", type: .text)
            tb.column("grade", type: .integer)
            tb.column("married", type: .integer)
            tb.column("isBoy", type: .integer)
            tb.column("gpa", type: .real)
            tb.column("extra", type: .blob)
        }
    }

    override func tearDown() {
        // try? Student.drop(from: db)
    }

    func testInsertOne1() throws {
        try Student.save([Util.generateStudent()], in: db)
    }

    func testInsertOne2() throws {
        try Util.generateStudent().save(in: db)
    }

    func testInsertOneByOne() throws {
        for _ in 0..<100 {
            let s1 = Util.generateStudent()
            try Student.save([s1], in: db)
            let s2 = Util.generateStudent()
            try s2.save(in: db)
        }
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
