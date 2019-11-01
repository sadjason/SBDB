//
//  Util.swift
//  SQLiteTests
//
//  Created by zhangwei on 2019/10/26.
//  Copyright © 2019 ByteDance. All rights reserved.
//

import Foundation
import UIKit
@testable import SQLite

enum Util {
    public static func openDatabase(options: Database.OpenOptions? = nil) throws -> Database {
        let userDir = NSSearchPathForDirectoriesInDomains(
            .documentDirectory,
            .userDomainMask,
            true
        ).first!
        let path = "\(userDir)/tests.sqlite3"
        return try Database(path: path, options: options)
    }

    public static func createDatabaseQueue(options: OpenOptions? = nil, label: String? = nil) -> DatabaseQueue {
        let userDir = NSSearchPathForDirectoriesInDomains(
            .documentDirectory,
            .userDomainMask,
            true
        ).first!
        let path = "\(userDir)/tests.sqlite3"
        return DatabaseQueue(path: path, options: options)
    }
    
    public static func setJournalMode(_ mode: String, for queue: DatabaseQueue) throws {
        var modeStr = "unknown"
        try queue.inDatabasae { (db) in
            var ret: Base.RowStorage?
            try? db.exec(sql: "pragma journal_mode=\(mode);", withParams: nil) { (_, row, stop) in
                ret = row
                stop = true
            }
            guard let retValue = ret?["journal_mode"]?.baseValue else {
                return
            }
            guard let mode = String(from: retValue) else {
                return
            }
            modeStr = mode.lowercased()
        }
        if modeStr != mode.lowercased() {
            throw SQLiteError.SetUpError.setWalModeFailed
        }
    }
    
    public static func setJournalMode(_ mode: String, for database: Database) throws {
        var ret: Base.RowStorage?
        try? database.exec(sql: "pragma journal_mode=\(mode);", withParams: nil) { (_, row, stop) in
            ret = row
            stop = true
        }
        guard let retValue = ret?["journal_mode"]?.baseValue else {
            throw SQLiteError.SetUpError.setWalModeFailed
        }
        guard let modeStr = String(from: retValue) else {
            throw SQLiteError.SetUpError.setWalModeFailed
        }
        guard modeStr.lowercased() == mode.lowercased() else {
            throw SQLiteError.SetUpError.setWalModeFailed
        }
        return
    }
}
