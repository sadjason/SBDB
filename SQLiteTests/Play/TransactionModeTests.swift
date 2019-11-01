//
//  TransactionModeTests.swift
//  SQLiteTests
//
//  Created by zhangwei on 2019/10/31.
//  Copyright © 2019 ByteDance. All rights reserved.
//

import XCTest
@testable import SQLite
import SQLite3

/// 研究非 WAL 模式下各个 transaction mode
///     WAL 模式下 exclusive 和 immediate 等价
/// See also: https://www.sqlite.org/lang_transaction.html

class TransactionModeTests: XCTestCase {

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

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    struct Transaction {
        var mode: TransactionMode
        var type: `Type`
        var delay: TimeInterval
        var sleep: TimeInterval?
        enum `Type` {
            case empty
            case read
            case write
        }
        init(mode: TransactionMode, type: Type, delay: TimeInterval = 0.0, sleep: TimeInterval? = nil) {
            self.type = type
            self.mode = mode
            self.delay = delay
            self.sleep = sleep
        }
        init(mode: TransactionMode, type: Type, delay: TimeInterval = 0.0) {
            self.type = type
            self.mode = mode
            self.delay = delay
            self.sleep = nil
        }
    }
    
    func runTransaction(_ transaction: Transaction, errorHandler: ((Error) -> Void)?) {
        DispatchQueue.global().asyncAfter(deadline: .now() + transaction.delay) {
            let queue = Util.createDatabaseQueue()
            try? Util.setJournalMode("delete", for: queue)
            do {
                try queue.inTransaction(mode: transaction.mode, execute: { (db, _) in
                    do {
                        switch transaction.type {
                        case .empty:
                            break
                        case .read:
                            let _ = try Student.fetchObject(from: db)
                        case .write:
                            try generateStudent().save(in: db)
                        }
                        if let s = transaction.sleep {
                            Thread.sleep(forTimeInterval: s)
                        }
                    } catch {
                        errorHandler?(error)
                    }
                })
            } catch {
                errorHandler?(error)
            }
        }
    }

    // MARK: deferred 读事务对其他事务的影响
    func testDeferredReadTransactionIsActive() {
        let activeTransaction = Transaction(mode: .deferred, type: .read, delay: 0.0, sleep: 1.8)
        runTransaction(activeTransaction, errorHandler: nil)
        
        // 对 deferred 读事务没有影响
        let deferredReadTransactions = [
            Transaction(mode: .deferred, type: .read, delay: 0.1),
            Transaction(mode: .deferred, type: .empty, delay: 0.2, sleep: 0.1),
        ]
        deferredReadTransactions.forEach { (transaction) in
            runTransaction(transaction) { (_) in
                XCTFail()
            }
        }
        
        // 对 deferred 写事务有影响：commit 时报错 SQLITE_BUSY
        let deferredWriteTransaction = Transaction(mode: .deferred, type: .write, delay: 0.4)
        runTransaction(deferredWriteTransaction) { (error) in
            do {
                throw error
            } catch let SQLiteError.TransactionError.commit(_, code) {
                XCTAssert(code == SQLITE_BUSY)
            } catch {
                XCTFail()
            }
        }
        
        // 对 immediate 事务有影响：commit 时报错 SQLITE_BUSY：
        let immediateTransactions = [
            Transaction(mode: .immediate, type: .read, delay: 0.5),
            Transaction(mode: .immediate, type: .write, delay: 0.6),
            Transaction(mode: .immediate, type: .empty, delay: 0.7, sleep: 0.1),
        ]
        immediateTransactions.forEach { (transaction) in
            runTransaction(transaction) { (error) in
                do {
                    throw error
                } catch let SQLiteError.TransactionError.commit(_, code) {
                    XCTAssert(code == SQLITE_BUSY)
                } catch {
                    XCTFail()
                }
            }
        }
        
        // 对 immediate 事务有影响：begin 时报错 SQLITE_BUSY：
        let exclusiveTransactions = [
            Transaction(mode: .exclusive, type: .read, delay: 0.9),
            Transaction(mode: .exclusive, type: .write, delay: 1.0),
            Transaction(mode: .exclusive, type: .empty, delay: 1.1, sleep: 0.1)
        ]
        exclusiveTransactions.forEach { (transaction) in
            runTransaction(transaction) { (error) in
                do {
                    throw error
                } catch let SQLiteError.TransactionError.begin(_, code) {
                    XCTAssert(code == SQLITE_BUSY)
                } catch {
                    XCTFail()
                }
            }
        }

        Thread.sleep(forTimeInterval: 2.0)
    }
    
    // MARK: deferred 写事务对其他事务的影响
    
    func testDeferredWriteTransactionIsActive() {
        let activeTransaction = Transaction(mode: .deferred, type: .write, delay: 0.0, sleep: 1.8)
        runTransaction(activeTransaction, errorHandler: nil)
        
        // 对 deferred 读事务没有影响
        let deferredReadTransactions = [
            Transaction(mode: .deferred, type: .read, delay: 0.1),
            Transaction(mode: .deferred, type: .empty, delay: 0.2, sleep: 0.1),
        ]
        deferredReadTransactions.forEach { (transaction) in
            runTransaction(transaction) { (_) in
                XCTFail()
            }
        }
        
        // 对 deferred 写事务有影响：执行时报错 SQLITE_BUSY
        let deferredWriteTransaction = Transaction(mode: .deferred, type: .write, delay: 0.4)
        runTransaction(deferredWriteTransaction) { (error) in
            do {
                throw error
            } catch let SQLiteError.ExecuteError.stepFailed(_, code) {
                XCTAssert(code == SQLITE_BUSY)
            } catch {
                XCTFail()
            }
        }
        
        // 对 immediate 事务有影响：begin 时报错 SQLITE_BUSY：
        let immediateTransactions = [
            Transaction(mode: .immediate, type: .read, delay: 0.5),
            Transaction(mode: .immediate, type: .write, delay: 0.6),
            Transaction(mode: .immediate, type: .empty, delay: 0.7, sleep: 0.1),
        ]
        immediateTransactions.forEach { (transaction) in
            runTransaction(transaction) { (error) in
                do {
                    throw error
                } catch let SQLiteError.TransactionError.begin(_, code) {
                    XCTAssert(code == SQLITE_BUSY)
                } catch {
                    XCTFail()
                }
            }
        }
        
        // 对 immediate 事务有影响：begin 时报错 SQLITE_BUSY：
        let exclusiveTransactions = [
            Transaction(mode: .exclusive, type: .read, delay: 0.9),
            Transaction(mode: .exclusive, type: .write, delay: 1.0),
            Transaction(mode: .exclusive, type: .empty, delay: 1.1, sleep: 0.1)
        ]
        exclusiveTransactions.forEach { (transaction) in
            runTransaction(transaction) { (error) in
                do {
                    throw error
                } catch let SQLiteError.TransactionError.begin(_, code) {
                    XCTAssert(code == SQLITE_BUSY)
                } catch {
                    XCTFail()
                }
            }
        }

        Thread.sleep(forTimeInterval: 2.0)
    }

    // MAKR: immediate 事务对其他事务的影响
    
    func _immediateTransactionIsActive() {
        // 对 deferred 读事务没有影响
        let deferredReadTransactions = [
            Transaction(mode: .deferred, type: .read, delay: 0.1),
            Transaction(mode: .deferred, type: .empty, delay: 0.2, sleep: 0.1),
        ]
        deferredReadTransactions.forEach { (transaction) in
            runTransaction(transaction) { (_) in
                XCTFail()
            }
        }
        
        // 对 deferred 写事务有影响：执行时报错 SQLITE_BUSY
        let deferredWriteTransaction = Transaction(mode: .deferred, type: .write, delay: 0.4)
        runTransaction(deferredWriteTransaction) { (error) in
            do {
                throw error
            } catch let SQLiteError.ExecuteError.stepFailed(_, code) {
                XCTAssert(code == SQLITE_BUSY)
            } catch {
                XCTFail()
            }
        }
        
        // 对 immediate 事务有影响：begin 时报错 SQLITE_BUSY：
        let immediateTransactions = [
            Transaction(mode: .immediate, type: .read, delay: 0.5),
            Transaction(mode: .immediate, type: .write, delay: 0.6),
            Transaction(mode: .immediate, type: .empty, delay: 0.7, sleep: 0.1),
        ]
        immediateTransactions.forEach { (transaction) in
            runTransaction(transaction) { (error) in
                do {
                    throw error
                } catch let SQLiteError.TransactionError.begin(_, code) {
                    XCTAssert(code == SQLITE_BUSY)
                } catch {
                    XCTFail()
                }
            }
        }
        
        // 对 immediate 事务有影响：begin 时报错 SQLITE_BUSY：
        let exclusiveTransactions = [
            Transaction(mode: .exclusive, type: .read, delay: 0.9),
            Transaction(mode: .exclusive, type: .write, delay: 1.0),
            Transaction(mode: .exclusive, type: .empty, delay: 1.1, sleep: 0.1)
        ]
        exclusiveTransactions.forEach { (transaction) in
            runTransaction(transaction) { (error) in
                do {
                    throw error
                } catch let SQLiteError.TransactionError.begin(_, code) {
                    XCTAssert(code == SQLITE_BUSY)
                } catch {
                    XCTFail()
                }
            }
        }

        Thread.sleep(forTimeInterval: 2.0)
    }
    
    func testImmediateReadTransactionIsActive() {
        let activeTransaction = Transaction(mode: .immediate, type: .read, delay: 0.0, sleep: 1.8)
        runTransaction(activeTransaction, errorHandler: nil)
        _immediateTransactionIsActive()
    }
    
    func testImmediateWriteTransactionIsActive() {
        let activeTransaction = Transaction(mode: .immediate, type: .write, delay: 0.0, sleep: 1.8)
        runTransaction(activeTransaction, errorHandler: nil)
        _immediateTransactionIsActive()
    }
    
    func testImmediateEmptyTransactionIsActive() {
        let activeTransaction = Transaction(mode: .immediate, type: .empty, delay: 0.0, sleep: 1.8)
        runTransaction(activeTransaction, errorHandler: nil)
        _immediateTransactionIsActive()
    }
    
    // MAKR: immediate 事务对其他事务的影响
    
    func _exclusiveTransactionIsActive() {
        // 对 deferred 事务有影响: prepare statement 阶段报错 SQLITE_BUSY
        let deferredTransactions = [
            Transaction(mode: .deferred, type: .read, delay: 0.1),
            Transaction(mode: .deferred, type: .empty, delay: 0.2, sleep: 0.1),
            Transaction(mode: .deferred, type: .write, delay: 0.4)
        ]
        deferredTransactions.forEach { (transaction) in
            runTransaction(transaction) { (error) in
                do {
                    throw error
                } catch let SQLiteError.ExecuteError.prepareStmtFailed(_, code) {
                    XCTAssert(code == SQLITE_BUSY)
                } catch {
                    XCTFail()
                }
            }
        }
        
        // 对 immediate 事务和 exclusive 事务 有影响：begin 时报错 SQLITE_BUSY：
        let immediateAndExclusiveTransactions = [
            Transaction(mode: .immediate, type: .read, delay: 0.5),
            Transaction(mode: .immediate, type: .write, delay: 0.6),
            Transaction(mode: .immediate, type: .empty, delay: 0.7, sleep: 0.1),
        ]
        immediateAndExclusiveTransactions.forEach { (transaction) in
            runTransaction(transaction) { (error) in
                do {
                    throw error
                } catch let SQLiteError.TransactionError.begin(_, code) {
                    XCTAssert(code == SQLITE_BUSY)
                } catch {
                    XCTFail()
                }
            }
        }
        
        Thread.sleep(forTimeInterval: 2.0)
    }
    
    // MAKR: exclusive 事务对其他事务的影响
    
    func testExclusiveReadTransactionIsActive() {
        let activeTransaction = Transaction(mode: .exclusive, type: .read, delay: 0.0, sleep: 1.8)
        runTransaction(activeTransaction, errorHandler: nil)
        _exclusiveTransactionIsActive()
    }
    
    func testExclusiveWriteTransactionIsActive() {
        let activeTransaction = Transaction(mode: .exclusive, type: .write, delay: 0.0, sleep: 1.8)
        runTransaction(activeTransaction, errorHandler: nil)
        _exclusiveTransactionIsActive()
    }
    
    func testExclusiveEmptyTransactionIsActive() {
        let activeTransaction = Transaction(mode: .exclusive, type: .empty, delay: 0.0, sleep: 1.8)
        runTransaction(activeTransaction, errorHandler: nil)
        _exclusiveTransactionIsActive()
    }
}
