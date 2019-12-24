//
//  DatabasePool.swift
//  SBDB
//
//  Created by SadJason on 2019/10/29.
//  Copyright © 2019 SadJason. All rights reserved.
//

import Foundation

final class DatabasePool {

    private lazy var readDatabasPoolLock = UnfairLock()
    private lazy var readDatabasPool = Set<Database>()
    private lazy var writeQueue: DatabaseQueue = _initWriteQueue()

    private let readOptions: OpenOptions = [.readonly, .noMutex]
    private let writeOptions: OpenOptions = [.readwrite, .createIfNotExists, .noMutex]

    let path: String

    init(path: String) {
        self.path = path
    }
}

// MARK: Writing Queue

extension DatabasePool {

    private func _initWriteQueue() -> DatabaseQueue {
        let queue = DatabaseQueue(path: path, options: writeOptions)
        try? queue.execute { (db) in
            try? _setupWalMode(db)
        }
        return queue
    }

    private func _setupWalMode(_ db: Database) throws {

        /// Set WAL mode
        /// - See Also: https://www.sqlite.org/wal.html

        var ret: RowStorage?
        try db.exec(sql: "pragma journal_mode=wal;", withParams: nil) { (_, row, stop) in
            ret = row
            stop = true
        }
        guard let retValue = ret?["journal_mode"]?.columnValue else {
            throw SQLiteError.ResultError.unexpectedRow(ret)
        }
        guard let modeStr = String(from: retValue) else {
            throw SQLiteError.ResultError.unexpectedValue(retValue)
        }
        guard modeStr.lowercased() == "wal" else {
            throw SQLiteError.SetUpError.setWalModeFailed
        }
    }
}

// MARK: Reading Pool

extension DatabasePool {

    func popReadDatabase() throws -> Database {
        readDatabasPoolLock.lock(); defer { readDatabasPoolLock.unlock() }

        if let db = readDatabasPool.popFirst() {
            return db
        }
        return try Database(path: path, options: readOptions)
    }

    func pushReadDatabase(_ db: Database) {
        readDatabasPoolLock.lock(); defer { readDatabasPoolLock.unlock() }

        readDatabasPool.insert(db)
    }
}

extension DatabasePool {

    /// 通过该方法访问 database 能获取到更高的读效率，需要注意的是，
    /// 此时获取的 database connection 是只读的，如果尝试进行写操作，会报错
    ///
    /// - Parameter workItem: 访问 database
    func read(workItem: DatabaseWorkItem) throws {
        let db = try popReadDatabase()
        defer {
            DispatchQueue.global().async { [weak self] in
                self?.pushReadDatabase(db)
            }
        }
        try workItem(db)
    }

    /// 以显式事务的方式访问数据库
    ///
    /// - Parameter mode: 事务模式
    /// - Parameter workItem: 访问 database
    func write(
        mode: Expr.TransactionMode,
        workItem: TransactionWorkItem
    ) throws {
        try writeQueue.executeTransaction(mode: mode, workItem: workItem)
    }
    
    /// 以显式事务的方式访问数据库，使用 immediate 事务
    ///
    /// - Parameter workItem: 访问 database
    func write(workItem: TransactionWorkItem) throws {
        try writeQueue.executeTransaction(mode: .immediate, workItem: workItem)
    }
}
