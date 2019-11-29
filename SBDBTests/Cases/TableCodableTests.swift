//
//  TableCodableTests.swift
//  SBDBTests
//
//  Created by SadJason on 2019/10/25.
//  Copyright © 2019 SadJason. All rights reserved.
//

import XCTest
@testable import SBDB

/// 测试 TableCodable，确保逻辑正确
class TableCodableTests: XCTestCase {

    let encoder = TableEncoder.default
    let decoder = TableDecoder.default

    /// test encode: 确保 encoding 无错误
    func testEncoding() throws {
        for i in 1...100 {
            let ret = try encoder.encode(Util.generateStudent())
            let str = ret.sorted { $0.0 < $1.0 }.map { (name, value) -> String in
                "\(name): \(value)"
            }.joined(separator: ",")
            print("testEncoding() result \(i): [\(str)]")
        }
    }

    ///  test encode & decode：构建实例，先 encode，然后 decode，最终结果和原先实例完全一致
    func testEncodeAndDecode() throws {
        for i in 1...100 {
            let s = Util.generateStudent()
            let encoded_s = try encoder.encode(s)
            let decoded_s = try decoder.decode(Student.self, from: encoded_s)
            XCTAssert(s == decoded_s)
            print("testEncodeAndDecode() result \(i): \(s)")
        }
    }

}
