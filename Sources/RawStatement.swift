//
//  RawStatement.swift
//  SQLite
//
//  Created by zhangwei on 2019/10/23.
//  Copyright © 2019 ByteDance. All rights reserved.
//

import Foundation
import SQLite3

/// https://www.sqlite.org/c3ref/stmt.html
final class RawStatement {

    private let sql: String
    private let dbPointer: OpaquePointer
    private let stmtPointer: OpaquePointer

    init(sql: String, database: OpaquePointer) throws {

        /// prepare:
        /// https://www.sqlite.org/c3ref/prepare.html
        var pStmt: OpaquePointer? = nil
        let ret = sqlite3_prepare_v2(database, sql, Int32(sql.utf8.count), &pStmt, nil)
        guard ret == SQLITE_OK else {
            throw SQLiteError.LibraryError.prepareStatementFailed
        }
        guard let stmt = pStmt else {
            fatalError("sql cannot be empty")
        }

        self.sql = sql
        self.dbPointer = database
        self.stmtPointer = stmt
    }
    
    /// https://www.sqlite.org/c3ref/finalize.html
    // 需要手动 finalize，不能靠析构，否则存在线程问题：
    // [logging] BUG IN CLIENT OF libsqlite3.dylib: illegal multi-threaded access to database connection
    func finalize() {
        // Invoking sqlite3_finalize() on a NULL pointer is a harmless no-op.
        sqlite3_finalize(stmtPointer)
    }

    /// https://www.sqlite.org/c3ref/step.html
    @discardableResult
    func step() -> SQLiteCode {
        sqlite3_step(stmtPointer)
    }

    /// https://www.sqlite.org/c3ref/reset.html
    @discardableResult
    func reset() -> SQLiteCode {
        sqlite3_reset(stmtPointer)
    }
}

// MARK: Binding Parameters

let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

extension RawStatement {

    /// https://www.sqlite.org/c3ref/bind_blob.html
    func bind(_ value: BaseValue, to index: Base.ColumnIndex) throws {
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
            throw SQLiteError.LibraryError.bindParameterFailed
        }
    }
}

// MARK: Return Result

/// https://www.sqlite.org/c3ref/column_blob.html
extension RawStatement {

    /// https://www.sqlite.org/c3ref/column_blob.html
    private func _columnValue(at index: Base.ColumnIndex) throws -> BaseValueConvertible {
        let type = sqlite3_column_type(stmtPointer, index)
        switch type {
        case SQLITE_INTEGER: return Int64(sqlite3_column_int64(stmtPointer, index))
        case SQLITE_FLOAT: return Double(sqlite3_column_double(stmtPointer, index))
        case SQLITE_BLOB:
            if let bytes = sqlite3_column_blob(stmtPointer, index) {
                let count = Int(sqlite3_column_bytes(stmtPointer, index))
                return Data(bytes: bytes, count: count)
            } else {
                return Data()
            }
        case SQLITE_TEXT: return String(cString:sqlite3_column_text(stmtPointer, index))
        case SQLITE_NULL: return Base.null
        default: throw SQLiteError.ResultError.unknownType(type)
        }
    }

    /// https://www.sqlite.org/c3ref/column_count.html
    func columnCount() -> Int {
        Int(sqlite3_column_count(stmtPointer))
    }

    func readRow() -> Base.RowStorage {
        let colCount = columnCount()
        guard colCount > 0 else {
            return [:]
        }
        var storage = Base.RowStorage()
        (0..<colCount).forEach { (index) in
            let colName = String(cString: sqlite3_column_name(stmtPointer, Int32(index)))
            let colValue: BaseValueConvertible
            do {
                colValue = try _columnValue(at: Int32(index))
            } catch {
                print("readRow failed: \(error)")
                colValue = Base.null
            }
            storage[colName] = colValue
        }
        return storage
    }
}

