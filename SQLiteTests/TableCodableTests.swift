//
//  TableCodableTests.swift
//  SQLiteTests
//
//  Created by zhangwei on 2019/10/25.
//  Copyright © 2019 ByteDance. All rights reserved.
//

import XCTest
@testable import SQLite

class TableCodableTests: XCTestCase {

    let encoder = TableEncoder()
    let decoder = TableDecoder()

    override func setUp() {

    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    /// test encode: 确保 encoding 无错误
    func testEncoding() throws {
        for i in 1...100 {
            let ret = try encoder.encode(generateStudent())
            let str = ret.sorted { $0.0 < $1.0 }.map { (name, value) -> String in
                "\(name): \(value)"
            }.joined(separator: ",")
            print("testEncoding() result \(i): [\(str)]")
        }
    }

    ///  test encode & decode：构建实例，先 encode，然后 decode，最终结果和原先实例完全一致
    func testEncodeAndDecode() throws {
        for i in 1...100 {
            let s = generateStudent()
            let encoded_s = try encoder.encode(s)
            let decoded_s = try decoder.decode(Student.self, from: encoded_s)
            XCTAssert(s == decoded_s)
            print("testEncodeAndDecode() result \(i): \(s)")
        }
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
