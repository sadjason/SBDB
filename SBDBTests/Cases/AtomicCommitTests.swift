//
//  AtomicCommitTests.swift
//  SBDBTests
//
//  Created by SadJason on 2019/11/3.
//  Copyright © 2019 SadJason. All rights reserved.
//

import XCTest
@testable import SBDB
import SQLite3

/// 分析研究 atomic commit 相关
///
/// - See Also:
///   - https://www.sqlite.org/atomiccommit.html
///   - https://www.sqlite.org/lang_transaction.html
///   - https://www.sqlite.org/lockingv3.html
class AtomicCommitTests: XCTestCase {

    // MARK: Begin/Commit/Rollback
    
    /// `begin` command 的作用是退出 auto commit 模式
    
    /// - Commit
    ///
    /// The SQL command "COMMIT" does not actually commit the changes to disk. It just turns autocommit back on. Then,
    /// at the conclusion of the command, the regular autocommit logic takes over and causes the actual commit to disk
    /// to occur.
    
    /// - Rollback
    ///
    /// The SQL command "ROLLBACK" also operates by turning autocommit back on, but it also sets a flag that tells the
    /// autocommit logic to rollback rather than commit.

    /// SQLite 不允许 transaction 嵌套：
    ///   - begin 后执行 begin，抛出错误：cannot start a transaction within a transaction
    ///   - commit/rollback 后执行 commit，抛出错误：cannot commit - no transaction is active
    ///   - commit/rollback 后执行 rollback，抛出错误：cannot rollback - no transaction is active
    /// commit/rollback 重复执行问题，可以通过 `sqlite3_get_autocommit()` 来规避
    ///   - See Also: https://www.sqlite.org/c3ref/get_autocommit.html
    /// begin 嵌套问题也可以通过 `sqlite3_get_autocommit()` 来规避？存疑，但可以通过弄一个标志位来解决
    func testNestTransaction() throws {
        let db = try! Util.openDatabase()
        
        // begin 后执行 begin
        do {
            try db._beginTransaction(withMode: .deferred)
            defer { try? db.endTransaction() }
            
            do {
                try db._beginTransaction(withMode: .deferred)
                deadCode()
            } catch let SQLiteError.TransactionError.begin(desc, code) {
                print("begin failed, code: \(code), desc: \(desc)")
                XCTAssert(code == SQLITE_ERROR)
            } catch {
                deadCode()
            }
        }
        
        // commit 后执行 commit
        do {
            try db._beginTransaction(withMode: .deferred)
            try db._endTransaction()
            do {
                try db._endTransaction()
                deadCode()
            } catch let SQLiteError.TransactionError.commit(desc, code) {
                print("commit failed, code: \(code), desc: \(desc)")
                XCTAssert(code == SQLITE_ERROR)
            } catch {
                deadCode()
            }
        }
        
        // rollback 后执行 commit
        do {
            try db._beginTransaction(withMode: .deferred)
            try db.rollbackTransaction()
            do {
                try db._endTransaction()
                deadCode()
            } catch let SQLiteError.TransactionError.commit(desc, code) {
                print("commit failed, code: \(code), desc: \(desc)")
                XCTAssert(code == SQLITE_ERROR)
            } catch {
                deadCode()
            }
        }
        
        // commit 后执行 rollback
        do {
            try db._beginTransaction(withMode: .deferred)
            try db._endTransaction()
            do {
                try db._rollbackTransaction()
                deadCode()
            } catch let SQLiteError.TransactionError.rollback(desc, code) {
                print("rollback failed, code: \(code), desc: \(desc)")
                XCTAssert(code == SQLITE_ERROR)
            } catch {
                deadCode()
            }
        }
        
        // rollback 后执行 rollback
        do {
            try db._beginTransaction(withMode: .deferred)
            try db._rollbackTransaction()
            do {
                try db._rollbackTransaction()
                deadCode()
            } catch let SQLiteError.TransactionError.rollback(desc, code) {
                print("rollback failed, code: \(code), desc: \(desc)")
                XCTAssert(code == SQLITE_ERROR)
            } catch {
                deadCode()
            }
        }
    }
    
    // MARK: Commit Busy
    
    /// 只有 begin，没有 commit 会如何
    func testWhenCommitFailed() throws {
        try Util.createStudentTable()
        let db = try! Util.openDatabase()
        try? db.delete(from: Student.self)
        
        try db.beginTransaction(withMode: .deferred)
    }
    
    /// `begin deferred` command 本身不尝试获取任何锁，直到遇到第一条语句时才获取 shared lock
    /// 本 case 尝试验证如下观点：
    ///   * `begin deferred` 命令重复执行是无害的
    ///   * `begin deferred` 命令的执行永远都不会返回 SQLITE_BUSY 错误（这一点应该比较难验证，case 只是进来复现）
    func testBeginDeferred() throws {
        DispatchQueue.global().async {
            try? Util.createDatabaseQueue().executeTransaction(mode: .immediate) { (db, _) in
                try? db.insert(Util.generateStudent())
                Thread.sleep(forTimeInterval: 1.0)
            }
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
            let db = try! Util.openDatabase()
            try! db.beginTransaction(withMode: .deferred)
            do {
                try db.beginTransaction(withMode: .deferred)
            } catch {
                print(error)
            }
//            (0..<10000).forEach { _ in
//                try! db.beginTransaction(withMode: .deferred)
//            }
        }
        
        // cannot start a transaction within a transaction
        
        Thread.sleep(forTimeInterval: 2.0)
    }
    
    func testBeginImmediate() throws {
        
    }
    
    func testBeginExclusive() throws {
        
    }
    
    // MARK: Commit Command
}
