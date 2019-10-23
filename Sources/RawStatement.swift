//
//  RawStatement.swift
//  SQLite
//
//  Created by zhangwei on 2019/10/19.
//  Copyright © 2019 ByteDance. All rights reserved.
//

import Foundation
import SQLite3

/// https://www.sqlite.org/c3ref/stmt.html
struct RawStatement {

    typealias ColumnIndex = Int32

    private let sql: String
    fileprivate let db: OpaquePointer
    fileprivate let stmtPointer: OpaquePointer

    static let stepSucceedCodes: Set<Int32> = [SQLITE_OK, SQLITE_DONE, SQLITE_ROW]

    init?(sql: String, db: OpaquePointer) throws {
        self.sql = sql
        self.db = db

        /// prepare:
        /// https://www.sqlite.org/c3ref/prepare.html
        var stmt: OpaquePointer? = nil
        let ret = sqlite3_prepare_v2(db, sql, Int32(sql.utf8.count), &stmt, nil)
        guard ret == SQLITE_OK else {
            throw SQLiteError.prepareFailed(Base.lastErrorMessage(of: db), ret)
        }
        if stmt == nil {
            return nil
        }

        stmtPointer = stmt!
    }

    /// https://www.sqlite.org/c3ref/step.html
    @discardableResult
    func step() throws -> SQLiteResultCode {
        let ret = sqlite3_step(stmtPointer)
        guard RawStatement.stepSucceedCodes.contains(ret) else {
            throw SQLiteError.stepFailed(Base.lastErrorMessage(of: db), ret)
        }
        return ret
    }

    /// https://www.sqlite.org/c3ref/reset.html
    func reset() throws {
        let ret = sqlite3_reset(stmtPointer)
        guard ret == SQLITE_OK else {
            throw SQLiteError.resetFalied(Base.lastErrorMessage(of: db), ret)
        }
    }

    /// https://www.sqlite.org/c3ref/finalize.html
    mutating func finalize() {
        // Invoking sqlite3_finalize() on a NULL pointer is a harmless no-op.
        sqlite3_finalize(stmtPointer)
    }
}

// MARK: Binding Parameters

let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

extension RawStatement {

    /// https://www.sqlite.org/c3ref/bind_blob.html
    func bind(_ value: BaseValue, to index: ColumnIndex) throws {
        let ret: Int32
        switch value.storage {
        case .integer(let num):
            ret = sqlite3_bind_int64(stmtPointer, index, num)
        case .text(let str):
            ret = sqlite3_bind_text(stmtPointer, index, str, Int32(str.utf8.count), SQLITE_TRANSIENT)
        case .real(let real):
            ret = sqlite3_bind_double(stmtPointer, index, real)
        case .null:
            ret = sqlite3_bind_null(stmtPointer, index)
        case .blob(let data):
            ret = data.withUnsafeBytes {
                sqlite3_bind_blob(stmtPointer, index, $0.baseAddress, Int32($0.count), SQLITE_TRANSIENT)
            }
        }
        guard ret == SQLITE_OK else {
            throw SQLiteError.bindFalied(Base.lastErrorMessage(of: db), ret)
        }
    }
}
