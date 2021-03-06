//
//  SerializedTests.swift
//  SBDBTests
//
//  Created by SadJason on 2019/11/18.
//  Copyright © 2019 SadJason. All rights reserved.
//

import XCTest
@testable import SBDB
import SQLite3

/// 分析 serialized 线程模型下的情况
class SerializedTests: XCTestCase {

    override func setUp() {
        let db = try! Util.openDatabase()
        try! Util.setJournalMode("delete", for: db)
        try! Util.createStudentTable()
        try! db.delete(from: Student.self)
    }

    /// jounalMode = rollback/delete, threadSafeMode = serialized
    func prepareSerializedDatabase() throws -> Database {
        let db = try Util.openDatabase(options: [.readwrite, .createIfNotExists, .fullMutex])
        try Util.setJournalMode("delete", for: db)
        return db
    }
    
    /// jounalMode = rollback/delete, threadSafeMode = multi-thread
    func prepareMultiThreadDatabase() throws -> Database {
        let db = try Util.openDatabase(options: [.readwrite, .createIfNotExists, .noMutex])
        try Util.setJournalMode("delete", for: db)
        return db
    }
    
    func testBatchInsertWithSerializedMode() throws {
        let db = try prepareSerializedDatabase()
        self.measure {
            try! db.beginTransaction()
            try! (0..<5000).forEach { _ in try db.insert(Util.generateStudent()) }
            try! db.endTransaction()
        }
    }
    
    func testBatchInsertWithMultiThreadMode() throws {
        let db = try prepareMultiThreadDatabase()
        self.measure {
            try! db.beginTransaction()
            try! (0..<5000).forEach { _ in try db.insert(Util.generateStudent()) }
            try! db.endTransaction()
        }
    }
    
    func testBatchSelectWithSerializedMode() throws {
        let db = try prepareMultiThreadDatabase()
        self.measure {
            try? (0..<10000).forEach { _ in try db.insert(Util.generateStudent()) }
        }
    }

    func testBatchSelectWithMultiThreadMode() throws {
        let db = try prepareMultiThreadDatabase()
        self.measure {
            try? (0..<10000).forEach { _ in try db.insert(Util.generateStudent()) }
        }
    }
}
