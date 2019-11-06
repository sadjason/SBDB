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
///
/// - See also:
///   - https://www.sqlite.org/atomiccommit.html
///   - https://www.sqlite.org/lang_transaction.html
///   - https://www.sqlite.org/lockingv3.html
///
/// - TODO:
///   * Response To Errors Within A Transaction 还没理解清楚
///   * Busy 处理机制
class TransactionTests: XCTestCase {

    override func setUp() {
        // 禁用 statement 缓存
        Database.disableStatementCache = true
        
        try? Util.createStudentTable()
    }
    
    // MARK: 隐式事务的结束时机
    
    /// 有些隐式事务会自动结束，不需要调用 reset 或者 finalize
    func testSomeStatementWillAutoFinishTransaction() {
        let db = try! Util.openDatabase()
        try? Student.delete(in: db)
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
                    } catch { self.neverExecute() }
                }
            } catch { self.deadCode() }
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
                    } catch { self.noError() }
                }
            } catch SQLiteError.TransactionError.commit(_, let code) {
                XCTAssert(code == SQLITE_BUSY)
                flag = true
            } catch { self.neverExecute() }
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
                    } catch { self.neverExecute() }
                }
            } catch { self.neverExecute() }
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
                    } catch { self.neverExecute() }
                }
            } catch SQLiteError.TransactionError.commit(_, let code) {
                flag = code == SQLITE_BUSY
                XCTAssert(code == SQLITE_BUSY)
            } catch { self.neverExecute() }
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
                    } catch { self.neverExecute() }
                }
            } catch { self.neverExecute() }
        }
        
        Thread.sleep(forTimeInterval: 2.0)
    }
    
    // MARK: 
    
    /// 当文件锁处于 pending 状态下，读失败
    func testObtainSharedLockInPending() throws {
        
        DispatchQueue.global().async {
            Thread.sleep(forTimeInterval: 0.1)
            let db = try! Util.openDatabase()
            try! db.beginTransaction()
            let _ = try! Student.fetchObjects(from: db)
            Thread.sleep(forTimeInterval: 0.5)
            try! db.endTransaction()
        }
        
        DispatchQueue.global().async {
            let db = try! Util.openDatabase()
            try? db.beginTransaction()
            try! Util.generateStudent().save(in: db)
            
            Thread.sleep(forTimeInterval: 0.2)
            
            try? db.endTransaction()
            
            // commit failed, 处于 pending 状态
            
            Thread.sleep(forTimeInterval: 1.2)
        }
        
        let db = try Util.openDatabase()
        try? db.beginTransaction()
        Thread.sleep(forTimeInterval: 1.0)
        do {
            let _ = try Student.fetchObject(from: db)
            neverExecute()
        } catch let SQLiteError.ExecuteError.prepareStmtFailed(desc, code) {
            print("read failed. desc: \(desc), code: \(code)")
            XCTAssert(code == SQLITE_BUSY)
        } catch {
            XCTFail()
        }
        try? db.endTransaction()
        
        Thread.sleep(forTimeInterval: 2.0)
    }
}
