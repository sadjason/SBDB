//
//  DatabaseQueue.swift
//  SQLite
//
//  Created by zhangwei on 2019/10/29.
//  Copyright © 2019 ByteDance. All rights reserved.
//

import Foundation

final public class DatabaseQueue {
    // 非 serialized mode 下，对 Database 的访问使用 queue 保护
    let queue: DispatchQueue
    let queueKey: DispatchSpecificKey<String>
    private var database: Database?
    let path: String
    let options: OpenOptions?

    init(path: String, options: OpenOptions? = nil) {
        self.path = path
        self.options = options
        let label = "database.queue.\(UUID.init().uuidString)"
        queueKey = DispatchSpecificKey<String>()
        queue = DispatchQueue(label: label)
        queue.setSpecific(key: queueKey, value: label)
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
            throw SQLiteError.misuse("avoid deadlock")
        }
    }

    func inDatabasae(execute workItem: DatabaseWorkItem) throws {

        try checkQueue()

        try queue.sync {
            let database = try checkDatabase()
            workItem(database)
        }
    }

    func inTransaction(mode: TransactionMode = .defered, execute workItem: TransactionWorkItem) throws {
        try checkQueue()

        try queue.sync {
            let database = try checkDatabase()

            var shouldRollback = false
            try database.beginTransaction(withMode: mode)
            workItem(database, &shouldRollback)
            if shouldRollback {
                try database.rollbackTransaction()
            } else {
                try database.endTransaction()
            }
        }
    }
}

extension DatabaseQueue {

    func async(execute workItem: @escaping DatabaseWorkItem) {
        DispatchQueue.global().async { [weak self] in
            try? self?.inDatabasae(execute: workItem)
        }
    }

    func sync(execute workItem: @escaping DatabaseWorkItem) {
        try? inDatabasae(execute: workItem)
    }

    func async(transaction mode: TransactionMode = .defered, execute workItem: @escaping TransactionWorkItem) {
        DispatchQueue.global().async { [weak self] in
            try? self?.inTransaction(mode: mode, execute: workItem)
        }
    }

    func sync(transaction mode: TransactionMode = .defered, execute workItem: TransactionWorkItem) {
        try? inTransaction(mode: mode, execute: workItem)
    }
}
