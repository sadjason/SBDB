//
//  SingleDatabasePerformance.swift
//  SBDBTests
//
//  Created by zhangwei on 2019/10/30.
//  Copyright © 2019 ByteDance. All rights reserved.
//

import XCTest
@testable import SBDB
import SQLite3

class SingleDatabasePerformance: XCTestCase {

    var db: Database!

    override func setUp() {
        try! Util.createStudentTable()
        db = try! Util.openDatabase()
    }

    override func tearDown() {
        try? db.dropTable(Student.self)
    }

    /// Insert 性能测试（单线程，不使用 statement 缓存）
    func testInsertPerformanceWithoutCachingStatement() {
        Database.disableStatementCache = true
        try? db.delete(from: Student.self)
        let s = Student(name: "Jason", age: 27, address: nil,
                        grade: 12, married: true, isBoy: true,
                        gpa: 4.5, extra: nil)
        self.measure {
            (0..<1000).forEach { _ in
                try? db.insert(s)
            }
        }
    }

    /// Insert 性能测试（单线程，使用 statement 缓存）
    func testInsertPerformanceWithCachingStatement() {
        Database.disableStatementCache = false
        try? db.delete(from: Student.self)
        let s = Student(name: "Jason", age: 27, address: nil,
                        grade: 12, married: true, isBoy: true,
                        gpa: 4.5, extra: nil)
        self.measure {
            (0..<1000).forEach { _ in
                try? db.insert(s)
            }
        }
    }

//    func testConflict() throws {
//        let queue1 = DispatchQueue.global(qos: .default)
//
//        print("testConflict")
//
//        queue1.async {
//            print("queue1.async")
//            let s = Student(name: "Jason", age: 27, address: nil,
//                            grade: 12, married: true, isBoy: true,
//                            gpa: 4.5, extra: nil)
//            self.measure {
//                (0..<1000).forEach { _ in
//                    do {
//                        try self.db.insert(s)
//                    } catch {
//                        print("save error \(error)")
//                    }
//                }
//            }
//        }
//    }
}
