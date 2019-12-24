//
//  Util.swift
//  SBDBTests
//
//  Created by SadJason on 2019/10/26.
//  Copyright © 2019 SadJason. All rights reserved.
//

import Foundation
import UIKit
@testable import SBDB
import XCTest

enum Util {
    public static func openDatabase(options: Database.OpenOptions? = nil) throws -> Database {
        return try Database(path: databasePath, options: options)
    }
    
    public static var databasePath: String {
        let userDir = NSSearchPathForDirectoriesInDomains(
            .documentDirectory,
            .userDomainMask,
            true
        ).first!
        let path = "\(userDir)/tests.sqlite3"
        return path
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
        try queue.execute { (db) in
            var ret: RowStorage?
            try? db.exec(sql: "pragma journal_mode=\(mode);", withParams: nil) { (_, row, stop) in
                ret = row
                stop = true
            }
            guard let retValue = ret?["journal_mode"]?.columnValue else {
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
    
    public static func journalMode(of db: Database) -> String {
        var ret: RowStorage?
        try? db.exec(sql: "pragma journal_mode", withParams: nil) { (_, row, stop) in
            ret = row
            stop = true
        }
        guard let retValue = ret?["journal_mode"]?.columnValue else {
            return ""
        }
        return String(from: retValue) ?? ""
    }
    
    public static func setJournalMode(_ mode: String, for database: Database) throws {
        var ret: RowStorage?
        try? database.exec(sql: "pragma journal_mode=\(mode);", withParams: nil) { (_, row, stop) in
            ret = row
            stop = true
        }
        guard let retValue = ret?["journal_mode"]?.columnValue else {
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

extension XCTestCase {
    func deadCode() {
        XCTFail()
    }
    func noError() {
        XCTFail()
    }
    func neverExecute() {
        XCTFail()
    }
}
