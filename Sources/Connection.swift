//
//  Connection.swift
//  SQLite
//
//  Created by zhangwei on 2019/10/18.
//  Copyright © 2019 ByteDance. All rights reserved.
//

import Foundation
import SQLite3

enum SQLiteError : Error {

    public typealias Reason = String
    public typealias Code = Int32

    case openFailed(Reason, Code)
    case disconnecting
    case prepareFailed(Reason, Code)
    case stepFailed(Reason, Code)
    case resetFalied(Reason, Code)
    case bindFalied(Reason, Code)
}

enum SQLite { }

extension SQLite {
    static func lastErrorMessage(of db: OpaquePointer) -> String {
        // `sqlite3_errmsg(nil)` return "out of memory", so do not worry about `db`
        String(cString: sqlite3_errmsg(db))
    }
}

typealias SQLiteResultCode = Int32

class Connection {

    typealias Statement = OpaquePointer

    private var db: OpaquePointer? = nil

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
                db = nil
            }

            throw SQLiteError.openFailed("Open database in \(path) failed: \(lastErrorMessage)", ret)
        }
    }

    deinit {
        if db != nil {
            sqlite3_close(db)
            db = nil
        }
    }

    private var lastErrorMessage: String {
        // `sqlite3_errmsg(nil)` return "out of memory", so do not worry about `db`
        String(cString: sqlite3_errmsg(db))
    }

    private func check() throws {
        guard let _ = db else {
            throw SQLiteError.disconnecting
        }
    }

    // MARK:

    /// https://www.sqlite.org/c3ref/prepare.html
    func prepare(_ sql: String) throws -> Statement? {
        try check()

        var stmt: OpaquePointer? = nil
        let ret = sqlite3_prepare_v2(db, sql, Int32(sql.utf8.count), &stmt, nil)
        if ret == SQLITE_OK {
            return stmt
        } else {
            throw SQLiteError.prepareFailed(lastErrorMessage, ret)
        }
    }

    static let stepSucceedCodes: Set<Int32> = [SQLITE_OK, SQLITE_DONE, SQLITE_ROW]

    /// https://www.sqlite.org/c3ref/step.html
    @discardableResult
    func step(_ stmt: Statement) throws -> SQLiteResultCode {
        let ret = sqlite3_step(stmt)
        guard Connection.stepSucceedCodes.contains(ret) else {
            throw SQLiteError.stepFailed(lastErrorMessage, ret)
        }
        return ret
    }

    /// https://www.sqlite.org/c3ref/reset.html
    func reset() throws {

    }

    func exec(_ sql: String) throws {
        guard let stmt = try prepare(sql) else {
            return
        }

        defer {
            sqlite3_finalize(stmt)
        }

        try step(stmt)
        print("exec sql succeed: \(sql)")
    }
}
