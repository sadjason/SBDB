//
//  UpdateTests.swift
//  SBDBTests
//
//  Created by zhangwei on 2019/10/26.
//  Copyright © 2019 ByteDance. All rights reserved.
//

import XCTest
@testable import SBDB
import SQLite3

/// Update 相关 cases，包括 create, drop, insert、delete、update 等
class UpdateTests: XCTestCase {
    
    // MARK: Creating & Droping Table
    
    func _createStudentTable(in db: Database, ifNotExists: Bool = true) throws {
        try Student.create(in: db, ifNotExists: ifNotExists)
    }
    
    func _deleteStudentTable(from db: Database) throws {
        try? Student.drop(from: db)
    }
    
    /// 首次创建 table
    func testCreateTableAtFirstTime() throws {
        print("dataPath: \(Util.databasePath)")
        let db = try Util.openDatabase()
        try _deleteStudentTable(from: db)
        
        try _createStudentTable(in: db, ifNotExists: false)
    }
    
    /// 多次重复创建 table
    func testCreateTableMultiTimes() throws {
        let db = try Util.openDatabase()
        try _deleteStudentTable(from: db)
        
        try _createStudentTable(in: db, ifNotExists: false)
        do {
            try _createStudentTable(in: db, ifNotExists: false)
            deadCode()
        } catch let SQLiteError.ExecuteError.stepFailed(desc, code) {
            print("create table failed: \(desc)")
            XCTAssert(code == SQLITE_ERROR)
        } catch {
            deadCode()
        }
        try _createStudentTable(in: db, ifNotExists: true)
    }
    
    /// 删除已经存在的 table
    func testDropExistingTable() throws {
        let db = try Util.openDatabase()
        
        try _createStudentTable(in: db, ifNotExists: true)
        
        try _deleteStudentTable(from: db)
    }
    
    /// 删除不存在的 table
    func testDropMissingTable() throws {
        let db = try Util.openDatabase()
        try? _deleteStudentTable(from: db)
        
        try _deleteStudentTable(from: db)
    }
    
    // MARK: Inserting
    
    func _prepareDatabase() throws -> Database {
        let db = try Util.openDatabase()
        try? _deleteStudentTable(from: db)
        try _createStudentTable(in: db)
        return db
    }
    
    /// 单个插入，然后从数据库取出，前后数据相等
    func testOneInsert() throws {
        let db = try _prepareDatabase()
        let s = Util.generateStudent()
        try s.save(in: db)
        guard let f_s = try Student.fetchObject(from: db) else {
            deadCode()
            return
        }
        XCTAssert(f_s == s)
    }
    
    /// 批量插入，然后从数据库取出，前后数据全部相等
    func testBatchInsert() throws {
        let db = try _prepareDatabase()
        
        let students = (0..<100).map { (index) -> Student in
            var s = Util.generateStudent()
            s.age = UInt8(index + 1)
            return s
        }
        try Student.save(students, in: db)
        
        let orderTerm = Base.OrderTerm(columnName: "age", strategy: .asc)
        let f_students = try Student.fetchObjects(from: db, orderBy: [orderTerm])
        XCTAssert(f_students.count == students.count)
        (0..<students.count).forEach { (index) in
            XCTAssert(f_students[index] == students[index])
        }
    }
    
    // MARK: Deleting
    
    func testDelete() throws {
        let db = try _prepareDatabase()
        
        var s1 = Util.generateStudent()
        s1.name = "s1"
        var s2 = Util.generateStudent()
        s2.name = "s2"
        
        do {
            try Student.save([s1, s2], in: db)
            
            XCTAssert(try Student.fetchObjects(from: db).count == 2)
            try Student.delete(in: db)
            XCTAssert(try Student.fetchObjects(from: db).count == 0)
            
            // 无效删除也是 ok 的
            try Student.delete(in: db)
        }
        
        do {
            try Student.save([s1, s2], in: db)
            
            XCTAssert(try Student.fetchObjects(from: db).count == 2)
            try Student.delete(in: db, where: Column("name") == "s1")
            let f_s = try Student.fetchObjects(from: db)
            XCTAssert(f_s.count == 1 && f_s.first! == s2)
            
            // 无效删除也是 ok 的
            try Student.delete(in: db, where: Column("name") == "s1")
        }
    }
    
    // MARK: Updating
    
    func testOneUpdate() throws {
        let db = try _prepareDatabase()
    
        var students = (0..<50).map { (index) -> Student in
            var s = Util.generateStudent()
            s.age = UInt8(index)
            return s
        }
        
        var specialOne = Util.generateStudent()
        specialOne.name = "special one"
        specialOne.age = 50
        specialOne.extra = Data([0,2,3])
        students.append(specialOne)
        
        let appendings = (51..<100).map { (index) -> Student in
            var s = Util.generateStudent()
            s.age = UInt8(index)
            return s
        }
        
        students.append(contentsOf: appendings)
        
        try Student.save(students, in: db)
        
        try Student.update(in: db, where: Column("name") == specialOne.name) { (assignment) in
            assignment["married"] = !specialOne.married
            assignment["extra"] = Base.null
            assignment["gpa"] = specialOne.gpa + 0.1
        }
        
        let orderTerm = Base.OrderTerm(columnName: "age", strategy: .asc)
        let dbStudents = try Student.fetchObjects(from: db, orderBy: [orderTerm])
        
        XCTAssert(dbStudents.count == students.count)
        
        // 目标数据按照预期发生变化
        let dbSpecialOne = dbStudents[50]
        XCTAssert(dbSpecialOne.name == specialOne.name)
        XCTAssert(dbSpecialOne.age == specialOne.age)
        XCTAssert(dbSpecialOne.extra == nil)
        XCTAssert(dbSpecialOne.gpa == specialOne.gpa + 0.1)
        XCTAssert(dbSpecialOne.married == !specialOne.married)
        
        // 其他数据都没变
        (0..<50).forEach { (index) in
            XCTAssert(students[index] == dbStudents[index])
        }
        
        (51..<100).forEach { (index) in
            XCTAssert(students[index] == dbStudents[index])
        }
    }
}
