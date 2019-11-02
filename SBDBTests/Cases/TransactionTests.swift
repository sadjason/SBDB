//
//  TransactionTests.swift
//  SBDBTests
//
//  Created by zhangwei on 2019/11/1.
//  Copyright © 2019 ByteDance. All rights reserved.
//

import XCTest
@testable import SBDB
import SQLite3

/// 分析研究隐式、显式的 transaction
/// See also: https://www.sqlite.org/lang_transaction.html
/// TODO:
///   * Response To Errors Within A Transaction 还没理解清楚
///   * Busy 处理机制
class TransactionTests: XCTestCase {

    override func setUp() {
        // 禁用 statement 缓存
        Database.disableStatementCache = true
        
        let db: Database! = try? Util.openDatabase()
        
        try? Student.create(in: db!) { (tb) in
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
        try? Student.delete(in: db)
    }
    
    // MARK: 隐式事务的结束时机
    
    /// 有些隐式事务会自动结束，不需要调用 reset 或者 finalize
    func testSomeStatementWillAutoFinishTransaction() {
        let db = try! Util.openDatabase()
        try! Util.setJournalMode("delete", for: db)
        
        DispatchQueue.global().async {
            try? Student.delete(in: db)
            // student 表是空的，即便不手动调用 reset 或者 finalize，也会自动结束事务
            let stmt = try! RawStatement(sql: "select * from student", database: db.pointer)
            stmt.step()
            DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
                stmt.reset()
            }
        }
        
        // 写事务正常进行，因为上一个事务自动结束了
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.2) {
            let queue = Util.createDatabaseQueue()
            do {
                try queue.inTransaction(mode: .immediate) { (db, _) in
                    do {
                        try Util.generateStudent().save(in: db)
                    } catch {
                        XCTFail()
                    }
                }
            } catch {
                XCTFail()
            }
        }
        
        Thread.sleep(forTimeInterval: 2.0)
    }

    /// 调用 reset 结束事务
    func testEndImplicitTransactionByReset() {
        let db = try! Util.openDatabase()
        try! Util.setJournalMode("delete", for: db)
        
        // transaction 1
        DispatchQueue.global().async {
            // 插入两条数据，以防 select 语句自动结束事务
            try! Util.generateStudent().save(in: db)
            try! Util.generateStudent().save(in: db)
            let stmt = try! RawStatement(sql: "select * from student", database: db.pointer)
            stmt.step()
            DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
                stmt.reset()
            }
        }
        
        // transaction 2
        // 会在 commit 时报错，因为 transaction 1 的 statement 还没有 reset
        var flag = false
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.2) {
            let queue = Util.createDatabaseQueue()
            do {
                try queue.inTransaction(mode: .immediate) { (db, _) in
                    do {
                        try Util.generateStudent().save(in: db)
                    } catch {
                        XCTFail()
                    }
                }
            } catch SQLiteError.TransactionError.commit(_, let code) {
                XCTAssert(code == SQLITE_BUSY)
                flag = true
            } catch {
                XCTFail()
            }
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.3) {
            XCTAssert(flag)
        }
        
        // transaction 3
        // 正常执行，因为 transaction 1 和 transaction 2 已经结束了
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.2) {
            let queue = Util.createDatabaseQueue()
            do {
                try queue.inTransaction(mode: .immediate) { (db, _) in
                    do {
                        try Util.generateStudent().save(in: db)
                    } catch {
                        XCTFail()
                    }
                }
            } catch {
                XCTFail()
            }
        }
        
        Thread.sleep(forTimeInterval: 2.0)
    }
    
    /// 调用 finalize 结束事务
    func testEndImplicitTransactionByFinalize() {
        let db = try! Util.openDatabase()
        try! Util.setJournalMode("delete", for: db)
        
        // transaction 1
        DispatchQueue.global().async {
            // 插入两条数据，以防 select 语句自动结束事务
            try! Util.generateStudent().save(in: db)
            try! Util.generateStudent().save(in: db)
            let stmt = try! RawStatement(sql: "select * from student", database: db.pointer)
            stmt.step()
            DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
                stmt.finalize()
            }
        }
        
        // transaction 2
        // 会在 commit 时报错，因为 transaction 1 的 statement 还没有 reset
        var flag = false
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.2) {
            let queue = Util.createDatabaseQueue()
            do {
                try queue.inTransaction(mode: .immediate) { (db, _) in
                    do {
                        try Util.generateStudent().save(in: db)
                    } catch {
                        XCTFail()
                    }
                }
            } catch SQLiteError.TransactionError.commit(_, let code) {
                flag = code == SQLITE_BUSY
                XCTAssert(code == SQLITE_BUSY)
            } catch {
                XCTFail()
            }
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.3) {
            XCTAssert(flag)
        }
        
        // transaction 3
        // 正常执行，因为 transaction 1 和 transaction 2 已经结束了
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.2) {
            let queue = Util.createDatabaseQueue()
            do {
                try queue.inTransaction(mode: .immediate) { (db, _) in
                    do {
                        try Util.generateStudent().save(in: db)
                    } catch {
                        XCTFail()
                    }
                }
            } catch {
                XCTFail()
            }
        }
        
        Thread.sleep(forTimeInterval: 2.0)
    }
}
