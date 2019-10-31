//
//  DatabasePool.swift
//  SQLite
//
//  Created by zhangwei on 2019/10/29.
//  Copyright © 2019 ByteDance. All rights reserved.
//

import Foundation

final class DatabasePool {

    fileprivate lazy var databasePool = Set<Database>()
    fileprivate lazy var poolLock = UnfairLock()
    lazy fileprivate var writeQueue: DatabaseQueue = _initWriteQueue()

    let path: String
    let options: OpenOptions?

    init(path: String, options: OpenOptions? = nil) {
        self.path = path
        self.options = options
    }

    func _initWriteQueue() -> DatabaseQueue {
        let queue = DatabaseQueue(path: path, options: options)
        try? queue.inDatabasae { (db) in
            try? setupDatabase(db)
        }
        return queue
    }
}

extension DatabasePool {
    fileprivate func setupDatabase(_ db: Database) throws {

        // 1. set wal mode
        // https://www.sqlite.org/wal.html

        var ret: Base.RowStorage?
        try db.exec(sql: "pragma journal_mode=wal;", withParams: nil) { (_, row, stop) in
            ret = row
            stop = true
        }
        guard let retValue = ret?["journal_mode"]?.baseValue else {
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

// MARK: Manage Database

extension DatabasePool {

    func popReadDatabase() throws -> Database {
        poolLock.lock(); defer { poolLock.unlock() }

        if let db = databasePool.popFirst() {
            return db
        }
        let db = try Database(path: path, options: options)
        try setupDatabase(db)
        return db
    }

    func pushReadDatabase(_ db: Database) {
        poolLock.lock(); defer { poolLock.unlock() }

        databasePool.insert(db)
    }
}

extension DatabasePool {
    func read(_ workItem: DatabaseWorkItem) throws {
        let db = try popReadDatabase()
        defer {
            DispatchQueue.global().async { [weak self] in
                self?.pushReadDatabase(db)
            }
        }
        workItem(db)
    }

    func write(_ workItem: DatabaseWorkItem) throws {
        try writeQueue.inDatabasae(execute: workItem)
    }
}
