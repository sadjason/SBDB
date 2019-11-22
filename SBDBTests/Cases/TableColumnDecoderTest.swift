//
//  TableColumnDecoderTest.swift
//  SBDBTests
//
//  Created by zhangwei on 2019/11/21.
//  Copyright © 2019 ByteDance. All rights reserved.
//

import XCTest
@testable import SBDB

class TableColumnDecoderTest: XCTestCase {
    
    struct T1: TableCodable {
        var blob: Data
        var string: String
        var bool: Bool
        var int8: Int8
        var int16: Int16
        var int32: Int32
        var int: Int
        var int64: Int64
        var uint8: UInt8
        var uint16: UInt16
        var uint32: UInt32
        var uint: UInt
        var uint64: UInt64
        var float: Float
        var double: Double
    }

    func testT1() throws {
        let container = try TableColumnDecoder.default.decode(T1.self)
        XCTAssert(container.keys.count == 15)
        
        let s_blob = container["blob"]!
        XCTAssert(s_blob.name == "blob" && s_blob.type == .blob && s_blob.nonnull)
        
        let s_string = container["string"]!
        XCTAssert(s_string.name == "string" && s_string.type == .text && s_string.nonnull)
        
        let integerNames = ["bool", "int8", "int16", "int32", "int", "int64", "uint8", "uint16", "uint32", "uint", "uint64"]
        for name in integerNames {
            let s = container[name]!
            XCTAssert(s.name == name && s.type == .integer && s.nonnull)
        }
        
        let floatNames = ["float", "double"]
        for name in floatNames {
            let s = container[name]!
            XCTAssert(s.name == name && s.type == .real && s.nonnull)
        }
    }
    
    struct T2: TableCodable {
        var blob: Data?
        var string: String?
        var bool: Bool?
        var int8: Int8?
        var int16: Int16?
        var int32: Int32?
        var int: Int?
        var int64: Int64?
        var uint8: UInt8?
        var uint16: UInt16?
        var uint32: UInt32?
        var uint: UInt?
        var uint64: UInt64?
        var float: Float?
        var double: Double?
    }
    
    func testT2() throws {
        let container = try TableColumnDecoder.default.decode(T2.self)
        XCTAssert(container.keys.count == 15)
        
        let s_blob = container["blob"]!
        XCTAssert(s_blob.name == "blob" && s_blob.type == .blob && !s_blob.nonnull)
        
        let s_string = container["string"]!
        XCTAssert(s_string.name == "string" && s_string.type == .text && !s_string.nonnull)
        
        let integerNames = ["bool", "int8", "int16", "int32", "int", "int64", "uint8", "uint16", "uint32", "uint", "uint64"]
        for name in integerNames {
            let s = container[name]!
            XCTAssert(s.name == name && s.type == .integer && !s.nonnull)
        }
        
        let floatNames = ["float", "double"]
        for name in floatNames {
            let s = container[name]!
            XCTAssert(s.name == name && s.type == .real && !s.nonnull)
        }
    }
}
