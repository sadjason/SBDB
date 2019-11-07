//
//  Database.swift
//  SBDB
//
//  Created by zhangwei on 2019/10/22.
//  Copyright © 2019 ByteDance. All rights reserved.
//

import Foundation
import SQLite3

public class Database: Identifiable {

    private var cachedStatements = [String: RawStatement]()
    private lazy var statementLock = UnfairLock()
    private var inExplicitTransaction = false
    
    var pointer: OpaquePointer! = nil
    
    public static var disableStatementCache: Bool = false

    public var id = UUID.init().uuidString
    
    static let stepSucceedCodes: Set<SQLiteCode> = [SQLITE_OK, SQLITE_DONE, SQLITE_ROW]

    /// TODO: 暂时不支持 tempory 数据库的建立

    // https://www.sqlite.org/c3ref/open.html
    init(path: String, options: OpenOptions? = nil) throws {
        let ret = options != nil ? sqlite3_open_v2(path, &pointer, options!.rawValue, nil) : sqlite3_open(path, &pointer)
        guard ret == SQLITE_OK else {
            // calling `sqlite3_close` with a NULL pointer argument is a harmless no-op.
            sqlite3_close(pointer)
            throw SQLiteError.SetUpError.openFailed
        }
        // print("database is opened successfully, path: \(path)")
    }
    
    deinit {
        sqlite3_close(pointer)
    }
    
    private var lastErrorMessage: String {
        // `sqlite3_errmsg(nil)` return "out of memory", so do not worry about `db`
        String(cString: sqlite3_errmsg(pointer))
    }
    
    private var lastErrorCode: SQLiteCode {
        sqlite3_errcode(pointer)
    }
    
    @discardableResult
    private func _checkStep(_ stmt: RawStatement) throws -> SQLiteCode {
        let ret = stmt.step()
        guard Database.stepSucceedCodes.contains(ret) else {
            throw SQLiteError.ExecuteError.stepFailed(lastErrorMessage, lastErrorCode)
        }
        return ret
    }
    
    private func _exec(
        sql: String,
        withParams params: [BaseValueConvertible]?,
        forEach rowIterator: RowIterator?
    ) throws
    {
        let stmt: RawStatement
        if let s = Database.disableStatementCache ? nil : popStatement(forKey: sql) {
            stmt = s
        } else {
            do {
                stmt = try RawStatement(sql: sql, database: pointer)
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
                try stmt.bind(param.baseValue, to: Base.ColumnIndex(index + 1))
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

    func exec(sql: String, withParams params: [BaseValueConvertible]?) throws {
        try _exec(sql: sql, withParams: params, forEach: nil)
    }

    /// 遍历 sql 的执行结果（前提是正确执行了）
    ///
    /// - Parameter .0: index, starting from `0`
    /// - Parameter .1: row
    /// - Parameter .2: 指示是否结束遍历 
    public typealias RowIterator = (Int, Base.RowStorage, inout Bool) -> Void

    func exec(
        sql: String,
        withParams params: [BaseValueConvertible]?,
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
    func pushStatement( _ statement: RawStatement, forKey key: String) {
        statementLock.protect {
            guard cachedStatements[key] == nil else {
                return
            }
            cachedStatements[key] = statement
        }
    }

    func popStatement(forKey key: String) -> RawStatement? {
        return statementLock.protect { () -> RawStatement? in
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

    func _beginTransaction(withMode mode: Base.TransactionMode = .deferred) throws {
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
    
    public func beginTransaction(withMode mode: Base.TransactionMode = .deferred) throws {
        if inExplicitTransaction { // 避免 transaction 嵌套
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
        static let create = OpenOptions(rawValue: SQLITE_OPEN_CREATE)

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

public typealias RowIterator = Database.RowIterator
public typealias OpenOptions = Database.OpenOptions

typealias DatabaseWorkItem = (Database) -> Void

/// About transaction
typealias Rollback = () -> Void
typealias TransactionWorkItem = (Database, Rollback) -> Void
typealias TransactionMode = Base.TransactionMode
