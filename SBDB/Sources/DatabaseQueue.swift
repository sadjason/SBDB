//
//  DatabaseQueue.swift
//  SBDB
//
//  Created by zhangwei on 2019/10/29.
//  Copyright © 2019 ByteDance. All rights reserved.
//

import Foundation

final public class DatabaseQueue {
    // 非 serialized mode 下，对 Database 的访问使用 queue 保护
    fileprivate let path: String
    fileprivate let options: OpenOptions?

    private let queue: DispatchQueue
    private let queueKey: DispatchSpecificKey<String>

    private var database: Database?
    
    public let label: String?

    init(path: String, options: OpenOptions? = nil, label: String? = nil) {
        self.path = path
        self.options = options
        self.label = label

        queueKey = DispatchSpecificKey<String>()
        queue = DispatchQueue(label: "database.queue.\(UUID.init().uuidString)")
        queue.setSpecific(key: queueKey, value: queue.label)
    }

    private func checkDatabase() throws -> Database {
        if let db = database {
            return db
        }
        database = try Database(path: path, options: options)
        return database!
    }

    private func checkQueue() throws {
        guard DispatchQueue.getSpecific(key: queueKey) != queue.label else {
            // 死锁，很可能是重入造成的
            throw SQLiteError.misuse("avoid deadlock")
        }
    }

    /// 非事务访问数据库
    ///
    /// - Parameter workItem: The work item to be invoked on the queue
    func inDatabasae(execute workItem: DatabaseWorkItem) throws {
        try checkQueue()

        try queue.sync {
            let database = try checkDatabase()
            try workItem(database)
        }
    }

    /// 基于事务访问数据库
    ///
    /// - Parameter mode: transaction mode
    /// - Parameter workItem: The work item to be invoked on the queue
    /// - See also: https://www.sqlite.org/lang_transaction.html
    func inTransaction(
        mode: TransactionMode = .deferred,
        execute workItem: TransactionWorkItem
    ) throws
    {
        try checkQueue()

        try queue.sync {
            let database = try checkDatabase()

            var shouldRollback = false
            let rollback: Rollback = { shouldRollback = true }

            try database.beginTransaction(withMode: mode)
            try workItem(database, rollback)
            if shouldRollback {
                try database.rollbackTransaction()
            } else {
                try database.endTransaction()
            }
        }
    }
}
