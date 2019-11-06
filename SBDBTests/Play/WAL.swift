//
//  WAL.swift
//  SBDBTests
//
//  Created by zhangwei on 2019/10/31.
//  Copyright © 2019 ByteDance. All rights reserved.
//

import XCTest
@testable import SBDB
import SQLite3

/// 研究分析 wal 模式
/// 多了两个问题件：
///  - .wal 文件
///  - .shm 文件
/// 多了一个操作：checkpoint
/// wal -> rollback
/// rollback -> wal
class WAL: XCTestCase {

    override func setUp() {
        try? Util.createStudentTable()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testConfiguringWalMode() throws {
        let db = try Util.openDatabase(options: [.readwrite, .create, .noMutex])
        print("dataPath = \(Util.databasePath)")
        // try Util.setJournalMode("wal", for: db)
        try Util.setJournalMode("delete", for: db)
        
        try db.beginTransaction()
        try (0..<10000).forEach { (_) in
            try Util.generateStudent().save(in: db)
        }
        try db.endTransaction()
        
        print("完成 10000 条数据的写入")
        
        Thread.sleep(forTimeInterval: 1)
    }
    
    // 变长记录存储: https://www.cnblogs.com/liaocheng/p/6182976.html
    // sqlite 采用的是变长纪录存储，当你从Sqlite删除数据后，未使用的磁盘空间被添加到一个内在的”空闲列表”中用于存储你下次插入的数据，
    // 用于提高效率，磁盘空间并没有丢失，但也不向操作系统返回磁盘空间，这就导致删除数据乃至清空整个数据库后，数据文件大小还是没有任何变化，还是很大
    
    func testDeleteWalMode() throws {
        let db = try Util.openDatabase(options: [.readwrite, .create, .noMutex])
        print("dataPath = \(Util.databasePath)")
        try? Util.setJournalMode("delete", for: db)
        
        try Student.delete(in: db)
        
//        print("完成 10000 条数据的写入")
//
//        Thread.sleep(forTimeInterval: 20)
    }
    
    /// wal 模式是如何保证事务的呢？
    
    
    /// 从 wal 模式切换到 rollback
    func testWalToRollback() throws {
        
    }
    
    /// 从 rollback 切换到 wal
    func testRollbackToWal() throws {
        
    }
    
    /// 测试 checkpoinit
    func testCheckPointing() throws {
        // Moving the WAL file transactions back into the database is called a "checkpoint".
    }
    
    /// wal is too big
    /// 测试 wal 过大对 read 的影响
    func testWalTooBig() throws {
        
    }
    
    /// 为什么 wal 模式下的数据库，无法再使用 delete 等模式打开
    func testSelect() throws {
        let db = try Util.openDatabase()
        do {
            try Util.setJournalMode("delete", for: db)
        } catch {
            print(error)
        }
        print("dataPath = \(Util.databasePath)")
        try db.beginTransaction()
        let count = try Student.fetchObjects(from: db).count
        print("渠道了 \(count) 条数据")
    }
    
    /// checkpoint 要注意的事情
    
    /// checkpoint 似乎不会减小 wal 文件的大小？但写操作会...
    /// Whenever a write operation occurs, the writer checks how much progress
    /// the checkpointer has made, and if the entire WAL has been transferred
    /// into the database and synced and if no readers are making use of the
    /// WAL, then the writer will rewind the WAL back to the beginning and start
    /// putting new transactions at the beginning of the WAL. This mechanism
    /// prevents a WAL file from growing without bound.


    /// checkpoint & read
    
    /// checkpoint & write
    
    /// write & write
    /// 并发写会导致什么
    
    /// read 在什么情况下会 SQLITE_BUSY
    
    /// write 在什么情况下会 SQLITE_BUSY？
    
    /// iOS 默认 wal 模式？
    
    /// wal 模式会牺牲耐用性？
}
