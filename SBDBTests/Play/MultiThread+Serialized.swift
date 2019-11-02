//
//  MultiThread.swift
//  SBDBTests
//
//  Created by zhangwei on 2019/10/30.
//  Copyright © 2019 ByteDance. All rights reserved.
//

import XCTest
@testable import SBDB
import SQLite3

/// 如果使用系统的 SQLite3 库，multi-thread 是默认模式
/// https://www3.sqlite.org/threadsafe.html
class MultiThread: XCTestCase {


    func createTableIfNeeded(in db: Database) throws {
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
    }

    func insertStudentsConcurrently(in db: Database) throws {
        let queue1 = DispatchQueue.global(qos: .default)

        queue1.async {
            let s = Student(name: "Jason", age: 27, address: nil,
                            grade: 12, married: true, isBoy: true,
                            gpa: 4.5, extra: nil)
            (0..<1000).forEach { _ in
                try? s.save(in: db)
            }
        }

        let queue2 = DispatchQueue.global(qos: .utility)

        queue2.async {
            let s = Student(name: "Jack", age: 27, address: nil,
                            grade: 12, married: true, isBoy: true,
                            gpa: 4.5, extra: nil)
            (0..<1000).forEach { _ in
                try? s.save(in: db)
            }
        }
    }

    func insertStudents(in db: Database) throws {
        let s = Student(name: "Jason", age: 27, address: nil,
                        grade: 12, married: true, isBoy: true,
                        gpa: 4.5, extra: nil)
        (0..<1000).forEach { _ in
            try? s.save(in: db)
        }
    }

    // MARK: Single Connection

    // Multi-Thread 模式下多线程访问一个 connection，会 crash:
    //   > [logging] BUG IN CLIENT OF libsqlite3.dylib: illegal multi-threaded access to database connection
    func testConcurrentInsertingInMultiThreadMode() throws {
        let db: Database = try Util.openDatabase(options: [.readwrite, .create, .noMutex])
        try createTableIfNeeded(in: db)
        try Student.delete(in: db)
        try insertStudentsConcurrently(in: db)
        Thread.sleep(forTimeInterval: 2.0)
    }

    // Serialized 模式下多线程访问一个 connection，没毛病
    func testConcurrentInsertingInSerializedMode() throws {
        let db: Database = try Util.openDatabase(options: [.readwrite, .create, .fullMutex])
        try createTableIfNeeded(in: db)
        try Student.delete(in: db)
        try insertStudentsConcurrently(in: db)
        Thread.sleep(forTimeInterval: 2.0)
    }

    // 测试结果证明，单线程下，multi-thread 和 serialized 性能差不多，甚至 serialized 还要稍微好一些

    func testInsertingPerformanceInMultiThreadMode() throws {
        let db: Database = try Util.openDatabase(options: [.readwrite, .create, .noMutex])
        try createTableIfNeeded(in: db)
        try Student.delete(in: db)
        measure {
            try? insertStudents(in: db)
        }
    }

    func testInsertingPerformanceInSerializedMode() throws {
        let db: Database = try Util.openDatabase(options: [.readwrite, .create, .fullMutex])
        try createTableIfNeeded(in: db)
        try Student.delete(in: db)
        measure {
            try? insertStudents(in: db)
        }
    }

    // MARK: Multi Connection
}
