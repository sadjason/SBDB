//
//  JournalModeTests.swift
//  SBDBTests
//
//  Created by zhangwei on 2019/11/1.
//  Copyright © 2019 ByteDance. All rights reserved.
//

import XCTest

/// 分析 Journal Model
///
/// - See also: https://www.sqlite.org/pragma.html
class JournalModeTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    /// The `DELETE` journaling mode is the normal behavior. In the `DELETE` mode, the rollback journal is deleted at
    /// the conclusion of each transaction. Indeed, the delete operation is the action that causes the transaction to
    /// commit.
    
    /// The `TRUNCATE` journaling mode commits transactions by truncating the rollback journal to zero-length instead
    /// of deleting it. On many systems, truncating a file is much faster than deleting the file since the containing
    /// directory does not need to be changed.
    
    /// The `PERSIST` journaling mode prevents the rollback journal from being deleted at the end of each transaction.
    /// Instead, the header of the journal is overwritten with zeros. This will prevent other database connections from
    /// rolling the journal back. The `PERSIST` journaling mode is useful as an optimization on platforms where deleting
    /// or truncating a file is much more expensive than overwriting the first block of a file with zeros.
    
    /// The MEMORY journaling mode stores the rollback journal in volatile RAM. This saves disk I/O but at the expense
    /// of database safety and integrity. If the application using SQLite crashes in the middle of a transaction when
    /// the MEMORY journaling mode is set, then the database file will very likely go corrupt.

    /// The WAL journaling mode uses a write-ahead log instead of a rollback journal to implement transactions. The WAL
    /// journaling mode is persistent; after being set it stays in effect across multiple database connections and after
    /// closing and reopening the database. A database in WAL journaling mode can only be accessed by SQLite version
    /// 3.7.0 (2010-07-21) or later.


    /// The OFF journaling mode disables the rollback journal completely. No rollback journal is ever created and hence
    /// there is never a rollback journal to delete. The OFF journaling mode disables the atomic commit and rollback
    /// capabilities of SQLite. The ROLLBACK command no longer works; it behaves in an undefined way. Applications must
    /// avoid using the ROLLBACK command when the journal mode is OFF. If the application crashes in the middle of a
    /// transaction when the OFF journaling mode is set, then the database file will very likely go corrupt. Without a
    /// journal, there is no way for a statement to unwind partially completed operations following a constraint error.
    /// This might also leave the database in a corrupted state. For example, if a duplicate entry causes a CREATE
    /// UNIQUE INDEX statement to fail half-way through, it will leave behind a partially created, and hence corrupt,
    /// index. Because OFF journaling mode allows the database file to be corrupted using ordinary SQL, it is disabled
    /// when SQLITE_DBCONFIG_DEFENSIVE is enabled.


    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
