//
//  SerializedTests.swift
//  SBDBTests
//
//  Created by zhangwei on 2019/11/18.
//  Copyright © 2019 ByteDance. All rights reserved.
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
        try! Student.delete(in: db);
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
            try! (0..<5000).forEach { _ in try Util.generateStudent().save(in: db) }
            try! db.endTransaction()
        }
    }
    
    func testBatchInsertWithMultiThreadMode() throws {
        let db = try prepareMultiThreadDatabase()
        self.measure {
            try! db.beginTransaction()
            try! (0..<5000).forEach { _ in try Util.generateStudent().save(in: db) }
            try! db.endTransaction()
        }
    }
    
    func testBatchSelectWithSerializedMode() throws {
        let db = try prepareMultiThreadDatabase()
        self.measure {
            try? (0..<10000).forEach { _ in try Util.generateStudent().save(in: db) }
        }
    }

    func testBatchSelectWithMultiThreadMode() throws {
        let db = try prepareMultiThreadDatabase()
        self.measure {
            try? (0..<10000).forEach { _ in try Util.generateStudent().save(in: db) }
        }
    }
}
