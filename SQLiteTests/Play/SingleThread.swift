//
//  SingleThread.swift
//  SQLiteTests
//
//  Created by zhangwei on 2019/10/30.
//  Copyright © 2019 ByteDance. All rights reserved.
//

import XCTest
@testable import SQLite
import SQLite3

/// 这种模式下，SQLite3 内部没有线程保护逻辑，需要业务层自己进行线程保护
/// 说明：
///   * 应用场景有哪些？
///   * 如果有多个线程访问 connection，会如何？
///   * 如何调整到该模式？
///     * 编译时指定 `SQLITE_THREADSAFE=0`
///     * `sqlite3_config` 指定，这三种都能指定
///     * runtime 指定，noMutex，multi-thread；fullMutex，serialized mode，如果都不指定，则由编译或 sqlite3_config 指定
///         runtime 貌似指定不了 single-thread
class SingleThread: XCTestCase {

    var database: Database!

    override func setUp() {
        let ret = Base.configThreadMode(.multiThread)
        if SQLITE_OK == ret {
            print("set single-thread succeed")
        } else {
            print("set single-thread failed: \(ret)")
        }
        database = try? Util.openDatabase(options: [.create, .readwrite, .noMutex])
    }

    override func tearDown() {

    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
