//
//  ColumnDefinitionTests.swift
//  SQLiteTests
//
//  Created by zhangwei on 2019/10/18.
//  Copyright © 2019 ByteDance. All rights reserved.
//

import XCTest
@testable import SQLite

class ColumnDefinitionTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testColumnName() {
        XCTAssert("id" == ColumnDefinition("id").sql.lowercased())
    }

    func testColumnDataType() {
        XCTAssert("id \(ColumnDefinition.DataType.text.rawValue)" == ColumnDefinition("id", .text).sql)
        XCTAssert("id \(ColumnDefinition.DataType.numeric.rawValue)" == ColumnDefinition("id", .numeric).sql)
        XCTAssert("id \(ColumnDefinition.DataType.integer.rawValue)" == ColumnDefinition("id", .integer).sql)
        XCTAssert("id \(ColumnDefinition.DataType.real.rawValue)" == ColumnDefinition("id", .real).sql)
        XCTAssert("id \(ColumnDefinition.DataType.blob.rawValue)" == ColumnDefinition("id", .blob).sql)
    }

    func testColumnPrimaryKey() {
        XCTAssert("id \(ColumnDefinition.DataType.integer.rawValue) PRIMARY KEY NOT NULL" == ColumnDefinition("id", .integer).primaryKey().sql)
        XCTAssert("id \(ColumnDefinition.DataType.integer.rawValue) PRIMARY KEY AUTOINCREMENT NOT NULL" == ColumnDefinition("id", .integer).primaryKey(autoIncrement: true).sql)
        XCTAssert("id \(ColumnDefinition.DataType.integer.rawValue) PRIMARY KEY ASC AUTOINCREMENT NOT NULL" == ColumnDefinition("id", .integer).primaryKey(autoIncrement: true, onConflict: nil, order: .asc).sql)
    }

//    func testColumnUnique() {
//        XCTAssert("id \(Column.DataType.integer.rawValue) PRIMARY KEY" == Column.Definition("id", .integer).primaryKey().sql)
//        XCTAssert("id \(Column.DataType.integer.rawValue) PRIMARY KEY AUTOINCREMENT" == Column.Definition("id", .integer).primaryKey(autoIncrement: true).sql)
//        XCTAssert("id \(Column.DataType.integer.rawValue) PRIMARY KEY ASC AUTOINCREMENT" == Column.Definition("id", .integer).primaryKey(order: .asc, onConflict: nil, autoIncrement: true).sql)
//    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
