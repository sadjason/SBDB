//
//  SingleDatabasePerformance.swift
//  SQLiteTests
//
//  Created by zhangwei on 2019/10/30.
//  Copyright © 2019 ByteDance. All rights reserved.
//

import XCTest
@testable import SQLite
import SQLite3

class SingleDatabasePerformance: XCTestCase {

    var db: Database!

    override func setUp() {
        db = try? Util.openDatabase()
        try? Student.create(in: db) { (tb) in
            tb.ifNotExists = true

            tb.column("name", type: .text).notNull()
            tb.column("age", type: .integer).notNull()
            tb.column("address", type: .text)
            tb.column("grade", type: .integer)
            tb.column("married", type: .integer)
            tb.column("isBoy", type: .integer)
            tb.column("gpa", type: .real)
            tb.column("extra", type: .blob)
        }
        print("setUp 1")

        print("sqlite safe mode = \(sqlite3_threadsafe())")
    }

    override func tearDown() {
        try? Student.drop(from: db)
    }

    /// Insert 性能测试（单线程，不使用 statement 缓存）
    func testInsertPerformanceWithoutCachingStatement() {
        Database.disableStatementCache = true
        try? Student.delete(in: db)
        let s = Student(name: "Jason", age: 27, address: nil,
                        grade: 12, married: true, isBoy: true,
                        gpa: 4.5, extra: nil)
        self.measure {
            (0..<1000).forEach { _ in
                try? s.save(in: db)
            }
        }
    }

    /// Insert 性能测试（单线程，使用 statement 缓存）
    func testInsertPerformanceWithCachingStatement() {
        Database.disableStatementCache = false
        try? Student.delete(in: db)
        let s = Student(name: "Jason", age: 27, address: nil,
                        grade: 12, married: true, isBoy: true,
                        gpa: 4.5, extra: nil)
        self.measure {
            (0..<1000).forEach { _ in
                try? s.save(in: db)
            }
        }
    }

    func testConflict() throws {
        let queue1 = DispatchQueue.global(qos: .default)

        print("testConflict")

        queue1.async {
            print("queue1.async")
            let s = Student(name: "Jason", age: 27, address: nil,
                            grade: 12, married: true, isBoy: true,
                            gpa: 4.5, extra: nil)
            self.measure {
                (0..<1000).forEach { _ in
                    do {
                        try s.save(in: self.db)
                    } catch {
                        print("save error \(error)")
                    }
                }
            }
        }

//        queue1.async {
//            let s = Student(name: "Jason", age: 27, address: nil,
//                            grade: 12, married: true, isBoy: true,
//                            gpa: 4.5, extra: nil)
//            self.measure {
//                (0..<1000).forEach { _ in
//                    do {
//                        try s.save(in: self.db)
//                    } catch {
//                        print("save error \(error)")
//                    }
//                }
//            }
//        }

//        let queue2 = DispatchQueue.global(qos: .utility)
//        queue2.async {
//            let s = Student(name: "Jack", age: 27, address: nil,
//                            grade: 23, married: true, isBoy: true,
//                            gpa: 4.0, extra: nil)
//            self.measure {
//                (0..<1000).forEach { _ in
//                    do {
//                        try s.save(in: self.db)
//                    } catch {
//                        print("save error \(error)")
//                    }
//                }
//            }
//        }
    }
}
