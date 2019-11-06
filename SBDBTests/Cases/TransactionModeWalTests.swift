//
//  TransactionModeWalTests.swift
//  SBDBTests
//
//  Created by zhangwei on 2019/11/6.
//  Copyright © 2019 zhangwei. All rights reserved.
//

import XCTest
@testable import SBDB
import SQLite3

/// 研究分析 WAL 日志模式下各个 transaction mode 之间互相的影响
/// - See also:
///   - https://www.sqlite.org/lang_transaction.html
class TransactionModeWalTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        try! Util.createStudentTable()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func prepareDatabase() throws -> Database {
        let db = try Util.openDatabase(options: [.readwrite, .create, .noMutex])
        try Util.setJournalMode("delete", for: db)
        return db
    }
    
    // MARK: DereferredRead is Active
    
    /// DereferredRead 对 DereferredRead 的影响：无影响
    func testDereferredRead_DereferredRead() throws {
        
        do {
            let db = try prepareDatabase()
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
                try! db.beginTransaction(withMode: .deferred)
                let _ = try! Student.fetchObject(from: db)
                Thread.sleep(forTimeInterval: 0.5)
                try! db.endTransaction()
            }
        }
        
        do {
            let db = try prepareDatabase()
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.2) {
                do {
                    try db.beginTransaction(withMode: .deferred)
                    let _ = try Student.fetchObject(from: db)
                    try db.endTransaction()
                } catch {
                    XCTFail()
                }
            }
        }
                
        Thread.sleep(forTimeInterval: 1.0)
    }
    
    /// DereferredRead 对 DereferredWrite 的影响：commit 时会出错
    func testDereferredRead_DereferredWrite() throws {
        do {
            let db = try prepareDatabase()
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
                try! db.beginTransaction(withMode: .deferred)
                let _ = try! Student.fetchObject(from: db)
                Thread.sleep(forTimeInterval: 0.5)
                try! db.endTransaction()
            }
        }
        
        do {
            let db = try prepareDatabase()
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.2) {
                do {
                    try db.beginTransaction(withMode: .deferred)
                    try Util.generateStudent().save(in: db)
                    try db.endTransaction()
                    self.neverExecute()
                } catch SQLiteError.TransactionError.commit(_, let code) {
                    XCTAssert(code == SQLITE_BUSY)
                } catch {
                    XCTFail()
                }
            }
        }
                
        Thread.sleep(forTimeInterval: 1.0)
    }
    
    /// DereferredRead 对 Immediate 事务的影响：commit 时会出错
    /// Immediate 事务被认为是写事务，commit 时尝试获取 exclusive 锁，即便这个 immediate 事务是空的
    func testDereferredRead_Immediate() throws {
        do {
            let db = try prepareDatabase()
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
                try! db.beginTransaction(withMode: .deferred)
                let _ = try! Student.fetchObject(from: db)
                Thread.sleep(forTimeInterval: 0.5)
                try! db.endTransaction()
            }
        }
        
        do {
            let db = try prepareDatabase()
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.2) {
                do {
                    try db.beginTransaction(withMode: .immediate)
                    // do nothing
                    try db.endTransaction()
                    self.neverExecute()
                } catch SQLiteError.TransactionError.commit(_, let code) {
                    XCTAssert(code == SQLITE_BUSY)
                } catch {
                    XCTFail()
                }
            }
        }
                
        Thread.sleep(forTimeInterval: 1.0)
    }
    
    /// DereferredRead 对 Exclusive 的影响：begin 时会出错
    func testDereferredRead_Exclusive() throws {
        do {
            let db = try prepareDatabase()
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
                try! db.beginTransaction(withMode: .deferred)
                let _ = try! Student.fetchObject(from: db)
                Thread.sleep(forTimeInterval: 0.5)
                try! db.endTransaction()
            }
        }
        
        do {
            let db = try prepareDatabase()
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.2) {
                do {
                    try db.beginTransaction(withMode: .exclusive)
                    // do nothing
                    try db.endTransaction()
                    self.neverExecute()
                } catch SQLiteError.TransactionError.begin(_, let code) {
                    XCTAssert(code == SQLITE_BUSY)
                } catch {
                    XCTFail()
                }
            }
        }
                
        Thread.sleep(forTimeInterval: 1.0)
    }

    // MARK: DereferredWrite is Active
    
    /// DereferredWrite 对 DereferredRead 的影响：无影响
    func testDereferredWrite_DereferredRead() throws {
        
        do {
            let db = try prepareDatabase()
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
                try! db.beginTransaction(withMode: .deferred)
                try! Util.generateStudent().save(in: db)
                Thread.sleep(forTimeInterval: 0.5)
                try! db.endTransaction()
            }
        }
        
        do {
            let db = try prepareDatabase()
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.2) {
                do {
                    try db.beginTransaction(withMode: .deferred)
                    let _ = try Student.fetchObject(from: db)
                    try db.endTransaction()
                } catch {
                    XCTFail()
                }
            }
        }
                
        Thread.sleep(forTimeInterval: 1.0)
    }
    
    /// DereferredWrite 对 DereferredWrite 的影响：execute 时会出错
    func testDereferredWrite_DereferredWrite() throws {
        do {
            let db = try prepareDatabase()
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
                try! db.beginTransaction(withMode: .deferred)
                try! Util.generateStudent().save(in: db)
                Thread.sleep(forTimeInterval: 0.5)
                try! db.endTransaction()
            }
        }

        do {
            let db = try prepareDatabase()
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.2) {
                do {
                    try db.beginTransaction(withMode: .deferred)
                    try Util.generateStudent().save(in: db)
                    try db.endTransaction()
                    self.neverExecute()
                } catch SQLiteError.ExecuteError.stepFailed(_, let code) {
                    XCTAssert(code == SQLITE_BUSY)
                } catch {
                    XCTFail()
                }
            }
        }

        Thread.sleep(forTimeInterval: 1.0)
    }

    /// DereferredWrite 对 Immediate 事务的影响：begin 时会出错
    /// Begin Immediate 执行时尝试获取 exclusive 锁，所以会失败
    func testDereferredWrite_Immediate() throws {
        do {
            let db = try prepareDatabase()
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
                try! db.beginTransaction(withMode: .deferred)
                try! Util.generateStudent().save(in: db)
                Thread.sleep(forTimeInterval: 0.5)
                try! db.endTransaction()
            }
        }

        do {
            let db = try prepareDatabase()
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.2) {
                do {
                    try db.beginTransaction(withMode: .immediate)
                    // do nothing
                    try db.endTransaction()
                    self.neverExecute()
                } catch SQLiteError.TransactionError.begin(_, let code) {
                    XCTAssert(code == SQLITE_BUSY)
                } catch {
                    XCTFail()
                }
            }
        }

        Thread.sleep(forTimeInterval: 1.0)
    }

    /// DereferredWrite 对 Exclusive 的影响：begin 时会出错
    func testDereferredWrite_Exclusive() throws {
        do {
            let db = try prepareDatabase()
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
                try! db.beginTransaction(withMode: .deferred)
                try! Util.generateStudent().save(in: db)
                Thread.sleep(forTimeInterval: 0.5)
                try! db.endTransaction()
            }
        }

        do {
            let db = try prepareDatabase()
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.2) {
                do {
                    try db.beginTransaction(withMode: .exclusive)
                    // do nothing
                    try db.endTransaction()
                    self.neverExecute()
                } catch SQLiteError.TransactionError.begin(_, let code) {
                    XCTAssert(code == SQLITE_BUSY)
                } catch {
                    XCTFail()
                }
            }
        }

        Thread.sleep(forTimeInterval: 1.0)
    }
    
    // MARK: Immediate is Active
    
    /// Immediate 对 DereferredRead 的影响：无影响
    func testImmediate_DereferredRead() throws {
        
        do {
            let db = try prepareDatabase()
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
                try! db.beginTransaction(withMode: .immediate)
                // do nothing
                Thread.sleep(forTimeInterval: 0.5)
                try! db.endTransaction()
            }
        }
        
        do {
            let db = try prepareDatabase()
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.2) {
                do {
                    try db.beginTransaction(withMode: .deferred)
                    let _ = try Student.fetchObject(from: db)
                    try db.endTransaction()
                } catch {
                    XCTFail()
                }
            }
        }
                
        Thread.sleep(forTimeInterval: 1.0)
    }
    
    /// Immediate 对 DereferredWrite 的影响：execute 时会出错
    func testImmediate_DereferredWrite() throws {
        do {
            let db = try prepareDatabase()
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
                try! db.beginTransaction(withMode: .immediate)
                // do nothing
                Thread.sleep(forTimeInterval: 0.5)
                try! db.endTransaction()
            }
        }

        do {
            let db = try prepareDatabase()
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.2) {
                do {
                    try db.beginTransaction(withMode: .deferred)
                    try Util.generateStudent().save(in: db)
                    try db.endTransaction()
                    self.neverExecute()
                } catch SQLiteError.ExecuteError.stepFailed(_, let code) {
                    XCTAssert(code == SQLITE_BUSY)
                } catch {
                    XCTFail()
                }
            }
        }

        Thread.sleep(forTimeInterval: 1.0)
    }

    /// Immediate 对 Immediate 事务的影响：begin 时会出错
    func testImmediate_Immediate() throws {
        do {
            let db = try prepareDatabase()
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
                try! db.beginTransaction(withMode: .immediate)
                // do nothing
                Thread.sleep(forTimeInterval: 0.5)
                try! db.endTransaction()
            }
        }

        do {
            let db = try prepareDatabase()
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.2) {
                do {
                    try db.beginTransaction(withMode: .immediate)
                    // do nothing
                    try db.endTransaction()
                    self.neverExecute()
                } catch SQLiteError.TransactionError.begin(_, let code) {
                    XCTAssert(code == SQLITE_BUSY)
                } catch {
                    XCTFail()
                }
            }
        }

        Thread.sleep(forTimeInterval: 1.0)
    }

    /// Immediate 对 Exclusive 的影响：begin 时会出错
    func testImmediate_Exclusive() throws {
        do {
            let db = try prepareDatabase()
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
                try! db.beginTransaction(withMode: .immediate)
                // do nothing
                Thread.sleep(forTimeInterval: 0.5)
                try! db.endTransaction()
            }
        }

        do {
            let db = try prepareDatabase()
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.2) {
                do {
                    try db.beginTransaction(withMode: .exclusive)
                    // do nothing
                    try db.endTransaction()
                    self.neverExecute()
                } catch SQLiteError.TransactionError.begin(_, let code) {
                    XCTAssert(code == SQLITE_BUSY)
                } catch {
                    XCTFail()
                }
            }
        }

        Thread.sleep(forTimeInterval: 1.0)
    }
    
    // MARK: Exclusive is Active
    
    /// Exclusive 对 DereferredRead 的影响：无影响
    func testExclusive_DereferredRead() throws {
        
        do {
            let db = try prepareDatabase()
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
                try! db.beginTransaction(withMode: .exclusive)
                // do nothing
                Thread.sleep(forTimeInterval: 0.5)
                try! db.endTransaction()
            }
        }
        
        do {
            let db = try prepareDatabase()
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.2) {
                do {
                    try db.beginTransaction(withMode: .deferred)
                    let _ = try Student.fetchObject(from: db)
                    try db.endTransaction()
                    self.neverExecute()
                } catch SQLiteError.ExecuteError.stepFailed(_, let code) {
                    XCTAssert(code == SQLITE_BUSY)
                } catch {
                    XCTFail()
                }
            }
        }
                
        Thread.sleep(forTimeInterval: 1.0)
    }
    
    /// Exclusive 对 DereferredWrite 的影响：execute 时会出错
    func testExclusive_DereferredWrite() throws {
        do {
            let db = try prepareDatabase()
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
                try! db.beginTransaction(withMode: .exclusive)
                // do nothing
                Thread.sleep(forTimeInterval: 0.5)
                try! db.endTransaction()
            }
        }

        do {
            let db = try prepareDatabase()
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.2) {
                do {
                    try db.beginTransaction(withMode: .deferred)
                    try Util.generateStudent().save(in: db)
                    try db.endTransaction()
                    self.neverExecute()
                } catch SQLiteError.ExecuteError.stepFailed(_, let code) {
                    XCTAssert(code == SQLITE_BUSY)
                } catch {
                    XCTFail()
                }
            }
        }

        Thread.sleep(forTimeInterval: 1.0)
    }

    /// Exclusive 对 Immediate 事务的影响：begin 时会出错
    func testExclusive_Immediate() throws {
        do {
            let db = try prepareDatabase()
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
                try! db.beginTransaction(withMode: .exclusive)
                // do nothing
                Thread.sleep(forTimeInterval: 0.5)
                try! db.endTransaction()
            }
        }

        do {
            let db = try prepareDatabase()
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.2) {
                do {
                    try db.beginTransaction(withMode: .immediate)
                    // do nothing
                    try db.endTransaction()
                    self.neverExecute()
                } catch SQLiteError.TransactionError.begin(_, let code) {
                    XCTAssert(code == SQLITE_BUSY)
                } catch {
                    XCTFail()
                }
            }
        }

        Thread.sleep(forTimeInterval: 1.0)
    }

    /// Exclusive 对 Exclusive 的影响：begin 时会出错
    func testExclusive_Exclusive() throws {
        do {
            let db = try prepareDatabase()
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
                try! db.beginTransaction(withMode: .exclusive)
                // do nothing
                Thread.sleep(forTimeInterval: 0.5)
                try! db.endTransaction()
            }
        }

        do {
            let db = try prepareDatabase()
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.2) {
                do {
                    try db.beginTransaction(withMode: .exclusive)
                    // do nothing
                    try db.endTransaction()
                    self.neverExecute()
                } catch SQLiteError.TransactionError.begin(_, let code) {
                    XCTAssert(code == SQLITE_BUSY)
                } catch {
                    XCTFail()
                }
            }
        }

        Thread.sleep(forTimeInterval: 1.0)
    }
    
}
