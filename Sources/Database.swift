//
//  Database.swift
//  SQLite
//
//  Created by zhangwei on 2019/10/20.
//  Copyright © 2019 ByteDance. All rights reserved.
//

import Foundation
import SQLite3

public class Database: Identifiable {
    public var id = UUID.init().uuidString
    var pointer: OpaquePointer! = nil
    lazy var statementLock = UnfairLock()
    lazy var transactionLock = UnfairLock()
    var inTransaction: Bool = false
    private var cachedStatements = [String: RawStatement]()
    public var disableCacheStatement: Bool = false

    /// TODO: 暂时不支持 tempory 数据库的建立，也不支持 flags

    // https://www.sqlite.org/c3ref/open.html
    init(path: String, options: OpenOptions? = nil) throws {
        let ret = options != nil ? sqlite3_open_v2(path, &pointer, options!.rawValue, nil) : sqlite3_open(path, &pointer)
        if ret == SQLITE_OK {
            print("database is opened successfully, path: \(path)")
        } else {
            // calling `sqlite3_close` with a NULL pointer argument is a harmless no-op.
            sqlite3_close(pointer)
            throw SQLiteError.ConnectionError.openFailed("Open database at \(path) failed: \(lastErrorMessage(of: pointer))", ret)
        }
    }

    deinit {
        sqlite3_close(pointer)
    }

    func exec(sql: String, withParams params: [BaseValueConvertible]?) throws {
        let stmt: RawStatement
        if let s = popStatement(forKey: sql) {
            try s.reset()
            stmt = s
        } else {
            stmt = try RawStatement(sql: sql, database: pointer)
        }

        defer {
            pushStatement(stmt, forKey: sql)
        }

        try params?.enumerated().forEach { (index, param) in
            try stmt.bind(param.baseValue, to: Base.ColumnIndex(index + 1))
        }

        try stmt.step()
    }

    /// 遍历 sql 的执行结果（前提是正确执行了）
    ///
    /// - Parameter .0: index, starting from `0`
    /// - Parameter .1: row
    /// - Parameter .2: 指示是否结束遍历
    public typealias RowIterator = (Int, Base.RowStorage, inout Bool) -> Void

    func exec(sql: String, withParams params: [BaseValueConvertible]?, forEach rowIterator: RowIterator) throws {
        let stmt: RawStatement
        if let s = popStatement(forKey: sql) {
            try s.reset()
            stmt = s
        } else {
            stmt = try RawStatement(sql: sql, database: pointer)
        }

        defer {
            pushStatement(stmt, forKey: sql)
        }

        try params?.enumerated().forEach { (index, param) in
            try stmt.bind(param.baseValue, to: Base.ColumnIndex(index + 1))
        }

        var index: Int = 0
        var stop = !(try stmt.step() == SQLITE_ROW)
        while !stop {
            rowIterator(index, stmt.readRow(), &stop)
            index += 1
            stop = try stop || !(stmt.step() == SQLITE_ROW)
        }
    }
}

public typealias RowIterator = Database.RowIterator

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
        if disableCacheStatement {
            return
        }
        statementLock.protect {
            guard cachedStatements[key] == nil else {
                return
            }
            cachedStatements[key] = statement
        }
    }

    func popStatement(forKey key: String) -> RawStatement? {
        if disableCacheStatement {
            return nil
        }
        return statementLock.protect { () -> RawStatement? in
            if let ret = cachedStatements[key] {
                cachedStatements.removeValue(forKey: key)
                return ret
            }
            return nil
        }
    }
}

typealias DatabaseWorkItem = (Database) -> Void
typealias TransactionWorkItem = (Database, inout Bool) -> Void
typealias TransactionMode = Base.TransactionMode

// MARK: Transaction

extension Database {

    public func beginTransaction(withMode mode: Base.TransactionMode = .defered) throws {
        try exec(sql: "begin transaction \(mode.sql)", withParams: nil)
    }

    public func endTransaction() throws {
        if sqlite3_get_autocommit(pointer) == 0 {
            try exec(sql: "commit transaction", withParams: nil)
        }
    }

    public func rollbackTransaction() throws {
        try exec(sql: "rollback transaction", withParams: nil)
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

public typealias OpenOptions = Database.OpenOptions
