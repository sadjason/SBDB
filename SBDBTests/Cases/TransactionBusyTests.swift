//
//  TransactionBusyTests.swift
//  SBDBTests
//
//  Created by zhangwei on 2019/11/1.
//  Copyright © 2019 ByteDance. All rights reserved.
//

import XCTest
@testable import SBDB

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
    
}
