//
//  SelectTests.swift
//  SQLiteTests
//
//  Created by zhangwei on 2019/10/28.
//  Copyright © 2019 ByteDance. All rights reserved.
//

import XCTest
@testable import SQLite

class SelectTests: XCTestCase {

    var database: Database!

    override func setUp() {
        database = try! Util.openDatabase()
        try! Student.delete(in: database)
    }

    override func tearDown() {

    }

    /// 插入一条数据，然后取出，前后二者是相等的
    func testInsertOne() throws {
        let s1 = generateStudent()
        try s1.save(in: database)
        let s2 = try Student.fetchObject(from: database)
        print(s1)
        print(s2!)
        XCTAssert(s1 == s2)
    }

    /// 测试 where：插入多条数据，然后能根据条件将其选出来
    func testWhere() throws {
        let students = (1...100).map { (index) -> Student in
            var s = generateStudent()
            s.age = UInt8(index)
            s.isBoy = (index % 2 == 1)
            return s
        }
        try students.forEach { try $0.save(in: database) }

        let result1 = try Student.fetchObjects(from: database, where: Column("age") > 50)
        XCTAssert(result1.count == 50)
        result1.forEach { XCTAssert($0.age > 50) }

        let result2 = try Student.fetchObjects(from: database, where: Column("age") > 50 && Column("isBoy") == 1 )
        XCTAssert(result2.count == 25)
        result2.forEach { XCTAssert($0.age > 50 && $0.isBoy!) }
    }

    /// 测试 order：确保返回值的顺序是正确的
    func testOrder() throws {
        let students = (1...100).map { (index) -> Student in
            var s = generateStudent()
            s.age = UInt8(index)
            s.isBoy = (index % 2 == 1)
            return s
        }
        try students.forEach { try $0.save(in: database) }

        // 正序
        var order1 = Base.OrderTerm(columnName: "age")
        order1.strategy = .asc
        let result1 = try Student.fetchObjects(from: database, orderBy: [order1])
        XCTAssert(result1.count == students.count)
        students.enumerated().forEach { (index, r) in
            XCTAssert(result1[index] == r)
        }

        // 逆序
        var order2 = Base.OrderTerm(columnName: "age")
        order2.strategy = .desc
        let result2 = try Student.fetchObjects(from: database, orderBy: [order2])
        XCTAssert(result2.count == students.count)
        students.enumerated().forEach { (index, r) in
            XCTAssert(result2[students.count - 1 - index] == r)
        }
    }
}
