//
//  TransactionBusyTests.swift
//  SBDBTests
//
//  Created by zhangwei on 2019/11/1.
//  Copyright © 2019 ByteDance. All rights reserved.
//

import XCTest
@testable import SBDB
import SQLite3

/// 研究 busy 相关
class TransactionBusyTests: XCTestCase {

    /// 并发访问可能会导致 Busy 错误
    func testBusyProblem() throws {
        
        try! Util.createStudentTable()
        
        let db = try! Util.openDatabase(options: [.readwrite, .create, .fullMutex])
        try! Student.delete(in: db)
        
        // 异步线程写操作
        DispatchQueue.global().async {
            let db = try! Util.openDatabase(options: [.readwrite, .create, .fullMutex])
            (0..<1000).forEach { _ in try? Util.generateStudent().save(in: db) }
        }
        
        // 主线程读操作，干扰异步线程的写操作
        (0..<1000).forEach { _ in _ = try? Student.fetchObject(from: db) }
        
        Thread.sleep(forTimeInterval: 1.0)
        
        
        let savedCount = try! Student.fetchObjects(from: db).count
        print(savedCount)
        XCTAssert(savedCount == 1000)
    }
    
    /// https://www.sqlite.org/c3ref/busy_handler.html
    /// PRAGMA busy_timeout; 设置超时时间
    /// https://www.sqlite.org/pragma.html#pragma_busy_timeout
    /// https://www.sqlite.org/c3ref/busy_timeout.html
    /// 注册超时处理
    /// https://www.sqlite.org/c3ref/busy_handler.html
    /// 超时函数里包括哪些东西
    func tetest() {
        // sqlite3_busy_handler(<#T##OpaquePointer!#>, <#T##((UnsafeMutableRawPointer?, Int32) -> Int32)!##((UnsafeMutableRawPointer?, Int32) -> Int32)!##(UnsafeMutableRawPointer?, Int32) -> Int32#>, <#T##UnsafeMutableRawPointer!#>)
    }
    
}
