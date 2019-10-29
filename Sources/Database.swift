//
//  Database.swift
//  SQLite
//
//  Created by zhangwei on 2019/10/20.
//  Copyright © 2019 ByteDance. All rights reserved.
//

import Foundation
import SQLite3

public class Database {

    var db: OpaquePointer! = nil

    lazy var statementLock = UnfairLock()
    var inTransaction: Bool = false
    lazy var transactionLock = UnfairLock()
    private var cachedStatements = [String: RawStatement]()

    /// TODO: 暂时不支持 tempory 数据库的建立，也不支持 flags

    // https://www.sqlite.org/c3ref/open.html
    init(path: String) throws {
        let ret = sqlite3_open(path, &db)
        if ret == SQLITE_OK {
            print("database is opened successfully, path: \(path)")
        } else {
            // calling `sqlite3_close` with a NULL pointer argument is a harmless no-op.
            sqlite3_close(db)
            throw SQLiteError.ConnectionError.openFailed("Open database at \(path) failed: \(lastErrorMessage(of: db))", ret)
        }
    }

    deinit {
        sqlite3_close(db)
    }

    @discardableResult
    func exec(
        sql: String,
        withParams params: [BaseValueConvertible]?)
        throws -> SQLiteExecuteCode
    {
        let stmt: RawStatement
        if let s = popStatement(forKey: sql) {
            try s.reset()
            stmt = s
        } else {
            stmt = try RawStatement(sql: sql, database: db)
        }

        defer {
            pushStatement(stmt, forKey: sql)
        }

        try params?.enumerated().forEach { (index, param) in
            try stmt.bind(param.baseValue, to: Base.ColumnIndex(index + 1))
        }

        return try stmt.step()
    }
}

// MARK: Manage Statements

extension Database {
    func pushStatement( _ statement: RawStatement, forKey key: String) {
        statementLock.protect {
            guard cachedStatements[key] == nil else {
                return
            }
            cachedStatements[key] = statement
        }
    }

    func popStatement(forKey key: String) -> RawStatement? {
        statementLock.protect { () -> RawStatement? in
            if let ret = cachedStatements[key] {
                cachedStatements.removeValue(forKey: key)
                return ret
            }
            return nil
        }
    }
}

// MARK: Transaction

extension Database {

    public struct Transaction {

        let database: Database
        let mode: Base.TransactionMode

        init(database: Database, mode: Base.TransactionMode) throws {
            try database.exec(sql: "begin transaction \(mode.sql)", withParams: nil)

            self.database = database
            self.mode = mode
        }

        func commit() {
            let _ = try? database.exec(sql: "commit transaction", withParams: nil)
        }

        func rollback() {
            let _ = try? database.exec(sql: "rollback transaction", withParams: nil)
        }
    }

    // TODO: 如何正确开启 transaction
    func transaction() -> Void {
        // TODO: 如何避免嵌套
        // 避免 transaction begin 了两次
        // 避免 transaction commit 了两次
    }
}
