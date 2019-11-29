//
//  BatchWriteTests.swift
//  SBDBTests
//
//  Created by SadJason on 2019/10/31.
//  Copyright © 2019 SadJason. All rights reserved.
//

import XCTest
@testable import SBDB

/// 批量写基准测试，得出如下结论：
///   * 使用事务和不使用事务，耗时差距非常大
///   * 是否使用 statement 缓存，差距不大
class BatchWriteTests: XCTestCase {

    override func setUp() {
        try? Util.createStudentTable()
        try? Util.createDatabaseQueue().inDatabasae{ (db) in
            try? db.delete(from: Student.self)
        }
    }

    /// SBDB 批量写（without transaction, with statementCache）
    // 5000 次写入，8 组采集，每组采集跑 10 次取平均数，数据如下（单位秒）：
    // 4.10, 3.86, 3.72, 3.74, 3.69, 3.73, 3.60, 3.86
    func testSBDBBatchWrite_withoutTransaction() throws {
        Database.disableStatementCache = true
        let dbQueue = Util.createDatabaseQueue()
        self.measure {
            try? dbQueue.inDatabasae { (db) in
                (0..<5000).forEach { (_) in
                    try? db.insert(Util.generateStudent())
                }
            }
        }
    }
    
    // SBDB 批量写（with transaction, without statementCache）
    // 5000 次写入，8 组采集，每组采集跑 10 次取平均数，数据如下（单位秒）：
    // 0.381, 0.386, 0.391, 0.383, 0.384, 0.392, 0.387, 0.379
    func testSBDBBatchWrite_withTransaction_withoutStatementCache() {
       Database.disableStatementCache = true
       let dbQueue = Util.createDatabaseQueue()
       self.measure {
           try? dbQueue.inTransaction(mode: .immediate, execute: { (db, rollback) in
               (0..<5000).forEach { (_) in
                   try? db.insert(Util.generateStudent())
               }
           })
       }
   }
    
    // SBDB 批量写（with transaction, with statementCache）
    // 5000 次写入，8 组采集，每组采集跑 10 次取平均数，数据如下（单位秒）：
    // 0.388, 0.389, 0.381, 0.388, 0.387, 0.387, 0.387, 383
    func testSBDBBatchWrite_withTransaction_withStatementCache() {
        Database.disableStatementCache = false
        let dbQueue = Util.createDatabaseQueue()
        self.measure {
            try? dbQueue.inTransaction(mode: .immediate, execute: { (db, rollback) in
                (0..<5000).forEach { (_) in
                    try? db.insert(Util.generateStudent())
                }
            })
        }
    }

    // FMDB 批量写（without transaction）
    func testFMDBBatchWrite_withoutTransaction() {
        
    }

    // FMDB 批量写（with transaction）
    func testFMDBBatchWrite_withTransaction() {

    }
}
