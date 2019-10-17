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

    private var db: OpaquePointer! = nil
    private var cachedStatements = [String: Statement]()

    /// TODO: 暂时不支持 tempory 数据库的建立，也不支持 flags

    // https://www.sqlite.org/c3ref/open.html
    init(path: String) throws {
        let ret = sqlite3_open(path, &db)
        if ret == SQLITE_OK {
            print("database is opened successfully, path: \(path)")
        } else {
            defer {
                // calling `sqlite3_close` with a NULL pointer argument is a harmless no-op.
                sqlite3_close(db)
            }

            throw SQLiteError.openFailed("Open database in \(path) failed: \(lastErrorMessage)", ret)
        }
    }

    deinit {
        sqlite3_close(db)
    }

    private var lastErrorMessage: String {
        // `sqlite3_errmsg(nil)` return "out of memory", so do not worry about `db`
        String(cString: sqlite3_errmsg(db))
    }

    func exec(sql: String) throws {
        var stmt = cachedStatements[sql]
        if stmt == nil {
            stmt = try Statement(sql: sql, db: db!)
            if stmt != nil {
                cachedStatements[sql] = stmt
            } else {
                return
            }
        }

        try stmt!.step()

        print("exec sql succeed: \(sql)")
    }

    public enum TransactionMode: String {
        case defered    = "DEFERRED"
        case immediate  = "IMMEDIATE"
        case exclusive  = "EXCLUSIVE"
    }
}

extension Database {
    func beginTransactiton(with mode: TransactionMode = .exclusive) throws {
        try exec(sql: "BEGIN TRANSACTION \(mode.rawValue)")
    }

    func commitTransaction() throws {
        try exec(sql: "COMMIT TRANSACTION")
    }

    func rollbackTransaction() throws {
        try exec(sql: "ROLLBACK TRANSACTION")
    }
}
