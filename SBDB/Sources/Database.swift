//
//  Database.swift
//  SBDB
//
//  Created by SadJason on 2019/10/22.
//  Copyright © 2019 SadJason. All rights reserved.
//

import Foundation
import SQLite3

/// https://www.sqlite.org/c3ref/c_abort.html
typealias SQLiteCode = Int32

/// - See Also: https://www.sqlite.org/c3ref/stmt.html
final class _RawStatement {

    private let sql: String
    private let dbPointer: OpaquePointer
    private let stmtPointer: OpaquePointer

    init(sql: String, database: OpaquePointer) throws {

        /// prepare:
        /// - See Also: https://www.sqlite.org/c3ref/prepare.html
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
    
    /// - See Also: https://www.sqlite.org/c3ref/finalize.html
    // 需要手动 finalize，不能靠析构，否则存在线程问题：
    // [logging] BUG IN CLIENT OF libsqlite3.dylib: illegal multi-threaded access to database connection
    func finalize() {
        // Invoking sqlite3_finalize() on a NULL pointer is a harmless no-op.
        sqlite3_finalize(stmtPointer)
    }

    /// - See Also: https://www.sqlite.org/c3ref/step.html
    @discardableResult
    func step() -> SQLiteCode {
        sqlite3_step(stmtPointer)
    }

    /// - See Also: https://www.sqlite.org/c3ref/reset.html
    @discardableResult
    func reset() -> SQLiteCode {
        sqlite3_reset(stmtPointer)
    }
}

// MARK: Binding Parameters

let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

extension _RawStatement {

    /// - See Also: https://www.sqlite.org/c3ref/bind_blob.html
    func bind(_ value: ColumnValue, to index: ColumnIndex) throws {
        let ret: Int32
        switch value.storage {
        case .integer(let num):
            ret = sqlite3_bind_int64(stmtPointer, index, num)
        case .text(let str):
            ret = sqlite3_bind_text(stmtPointer,
                                    index,
                                    str,
                                    Int32(str.utf8.count),
                                    SQLITE_TRANSIENT)
        case .real(let real):
            ret = sqlite3_bind_double(stmtPointer, index, real)
        case .null:
            ret = sqlite3_bind_null(stmtPointer, index)
        case .blob(let data):
            ret = data.withUnsafeBytes {
                sqlite3_bind_blob(stmtPointer,
                                  index,
                                  $0.baseAddress,
                                  Int32($0.count),
                                  SQLITE_TRANSIENT)
            }
        }
        guard ret == SQLITE_OK else {
            throw SQLiteError.LibraryError.bindParameterFailed
        }
    }
}

// MARK: Return Result

/// - See Also: https://www.sqlite.org/c3ref/column_blob.html
extension _RawStatement {

    /// - See Also: https://www.sqlite.org/c3ref/column_blob.html
    private func _columnValue(at index: ColumnIndex) throws -> ColumnValueConvertible {
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
        case SQLITE_NULL: return ColumnValue.null
        default: throw SQLiteError.ResultError.unknownType(type)
        }
    }

    /// https://www.sqlite.org/c3ref/column_count.html
    func columnCount() -> Int {
        Int(sqlite3_column_count(stmtPointer))
    }

    func readRow() -> RowStorage {
        let colCount = columnCount()
        guard colCount > 0 else {
            return [:]
        }
        var storage = RowStorage()
        (0..<colCount).forEach { (index) in
            let colName = String(cString: sqlite3_column_name(stmtPointer, Int32(index)))
            let colValue: ColumnValueConvertible
            do {
                colValue = try _columnValue(at: Int32(index))
            } catch {
                print("readRow failed: \(error)")
                colValue = ColumnValue.null
            }
            storage[colName] = colValue
        }
        return storage
    }
}

public class Database: Identifiable {

    private var cachedStatements = [String: _RawStatement]()
    private lazy var statementLock = UnfairLock()
    private var inExplicitTransaction = false
    
    var pointer: OpaquePointer! = nil
    
    public static var disableStatementCache: Bool = false

    public var id = UUID.init().uuidString
    
    static let stepSucceedCodes: Set<SQLiteCode> = [SQLITE_OK, SQLITE_DONE, SQLITE_ROW]

    /// - See Also: https://www.sqlite.org/c3ref/open.html
    init(path: String, options: OpenOptions? = nil) throws {
        let ret = options != nil ? sqlite3_open_v2(path, &pointer, options!.rawValue, nil) : sqlite3_open(path, &pointer)
        guard ret == SQLITE_OK else {
            // calling `sqlite3_close` with a NULL pointer argument is a harmless no-op.
            sqlite3_close(pointer)
            throw SQLiteError.SetUpError.openFailed
        }
    }
    
    func close() {
        sqlite3_close(pointer)
    }
    
    private var lastErrorMessage: String {
        // `sqlite3_errmsg(nil)` return "out of memory", so there is not need to worry about `db`
        String(cString: sqlite3_errmsg(pointer))
    }
    
    private var lastErrorCode: SQLiteCode {
        sqlite3_errcode(pointer)
    }
    
    @discardableResult
    private func _checkStep(_ stmt: _RawStatement) throws -> SQLiteCode {
        let ret = stmt.step()
        guard Database.stepSucceedCodes.contains(ret) else {
            throw SQLiteError.ExecuteError.stepFailed(lastErrorMessage, lastErrorCode)
        }
        return ret
    }
    
    private func _exec(
        sql: String,
        withParams params: [ColumnValueConvertible]?,
        forEach rowIterator: RowIterator?
    ) throws
    {
        let stmt: _RawStatement
        if let s = Database.disableStatementCache ? nil : popStatement(forKey: sql) {
            stmt = s
        } else {
            do {
                stmt = try _RawStatement(sql: sql, database: pointer)
            } catch {
                throw SQLiteError.ExecuteError.prepareStmtFailed(lastErrorMessage, lastErrorCode)
            }
        }

        defer {
            if Database.disableStatementCache || stmt.reset() != SQLITE_OK {
                stmt.finalize()
            } else {
                DispatchQueue.global().async {
                    self.pushStatement(stmt, forKey: sql)
                }
            }
        }
        
        do {
            try params?.enumerated().forEach { (index, param) in
                try stmt.bind(param.columnValue, to: ColumnIndex(index + 1))
            }
        } catch {
            throw SQLiteError.ExecuteError.bindParamFailed(lastErrorMessage, lastErrorCode)
        }
        
        if rowIterator == nil {
            try _checkStep(stmt)
            return
        }
        
        do {
            var index: Int = 0
            var stop = !(try _checkStep(stmt) == SQLITE_ROW)
            while !stop {
                rowIterator!(index, stmt.readRow(), &stop)
                index += 1
                stop = try stop || !(_checkStep(stmt) == SQLITE_ROW)
            }
        } catch {
            throw SQLiteError.ExecuteError.stepFailed(lastErrorMessage, lastErrorCode)
        }
    }

    func exec(sql: String, withParams params: [ColumnValueConvertible]?) throws {
        try _exec(sql: sql, withParams: params, forEach: nil)
    }

    /// 遍历 sql 的执行结果（前提是正确执行了）
    ///
    /// - Parameter .0: index, starting from `0`
    /// - Parameter .1: row
    /// - Parameter .2: 指示是否结束遍历 
    public typealias RowIterator = (Int, RowStorage, inout Bool) -> Void

    func exec(
        sql: String,
        withParams params: [ColumnValueConvertible]?,
        forEach rowIterator: @escaping RowIterator
    ) throws {
        try _exec(sql: sql, withParams: params, forEach: rowIterator)
    }
}

extension Database: Hashable {
    public func hash(into hasher: inout Hasher) {
        id.hash(into: &hasher)
    }

    public var hashValue: Int { id.hashValue }

    public static func == (lhs: Database, rhs: Database) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: Manage Statements

extension Database {
    func pushStatement( _ statement: _RawStatement, forKey key: String) {
        statementLock.protect {
            guard cachedStatements[key] == nil else {
                return
            }
            cachedStatements[key] = statement
        }
    }

    func popStatement(forKey key: String) -> _RawStatement? {
        return statementLock.protect { () -> _RawStatement? in
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

    func _beginTransaction(withMode mode: Expr.TransactionMode = .deferred) throws {
        do {
            try exec(sql: "begin \(mode.sql) transaction", withParams: nil)
        } catch {
            throw SQLiteError.TransactionError.begin(lastErrorMessage, lastErrorCode)
        }
    }
    
    func _endTransaction() throws {
        do {
            try exec(sql: "commit transaction", withParams: nil)
        } catch {
            throw SQLiteError.TransactionError.commit(lastErrorMessage, lastErrorCode)
        }
    }
    
    func _rollbackTransaction() throws {
        do {
            try exec(sql: "rollback transaction", withParams: nil)
        } catch {
            throw SQLiteError.TransactionError.rollback(lastErrorMessage, lastErrorCode)
        }
    }
    
    public func beginTransaction(withMode mode: Expr.TransactionMode = .deferred) throws {
        guard !inExplicitTransaction else {
            // 避免 transaction 嵌套
            assert(false, "in transaction now")
            return
        }
        if inExplicitTransaction {
            return
        }
        try _beginTransaction(withMode: mode)
        inExplicitTransaction = true
    }

    public func endTransaction() throws {
        if sqlite3_get_autocommit(pointer) == 0 {
            try _endTransaction()
            inExplicitTransaction = false
        }
    }
    
    public func commitTransaction() throws {
        try endTransaction()
    }

    public func rollbackTransaction() throws {
        if sqlite3_get_autocommit(pointer) == 0 {
            try _rollbackTransaction()
            inExplicitTransaction = false
        }
    }
}

// MARK: DatabaseOpenOptions

extension Database {

    /// https://www3.sqlite.org/c3ref/open.html
    public struct OpenOptions: OptionSet {
        public let rawValue: Int32

        public init(rawValue: Int32) {
            self.rawValue = rawValue
        }

        /// The database is opened in read-only mode.
        /// If the database does not already exist, an error is returned.
        static let readonly = OpenOptions(rawValue: SQLITE_OPEN_READONLY)

        /// The database is opened for reading and writing if possible,
        /// or reading only if the file is write protected by the operating system.
        /// In either case the database must already exist, otherwise an error is returned.
        ///
        /// If the `create` option is set, the database is created if it does not already exist.
        static let readwrite = OpenOptions(rawValue: SQLITE_OPEN_READWRITE)
        static let createIfNotExists = OpenOptions(rawValue: SQLITE_OPEN_CREATE)

        /// If the `noMutex` option is set, then the database connection opens
        /// in the multi-thread threading mode as long as the single-thread mode
        /// has not been set at compile-time or start-time.
        ///
        /// If the `fullMutex` option is set then the database connection opens
        /// in the serialized threading mode unless single-thread was previously
        /// selected at compile-time or start-time.
        static let noMutex = OpenOptions(rawValue: SQLITE_OPEN_NOMUTEX)
        static let fullMutex = OpenOptions(rawValue: SQLITE_OPEN_FULLMUTEX)

        // static let sharedCache = OpenOptions(rawValue: SQLITE_OPEN_SHAREDCACHE)
        // static let privateCache = OpenOptions(rawValue: SQLITE_OPEN_PRIVATECACHE)
        // static let uri = OpenOptions(rawValue: SQLITE_OPEN_URI)
        // static let memory = OpenOptions(rawValue: SQLITE_OPEN_MEMORY)
    }
}

// MARK: Typealias

public typealias ColumnName = String
public typealias ColumnIndex = Int32
public typealias RowStorage = Dictionary<ColumnName, ColumnValueConvertible>
public typealias RowIterator = Database.RowIterator
public typealias OpenOptions = Database.OpenOptions

typealias DatabaseWorkItem = (Database) throws -> Void

/// About transaction
typealias Rollback = () -> Void
typealias TransactionWorkItem = (Database, Rollback) throws -> Void
