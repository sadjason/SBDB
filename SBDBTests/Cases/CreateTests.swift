//
//  CreateTests.swift
//  SBDBTests
//
//  Created by zhangwei on 2019/11/25.
//  Copyright © 2019 ByteDance. All rights reserved.
//

import XCTest
@testable import SBDB

/// 测试 create/drop table、create/drop index
class CreateTests: XCTestCase {

    struct T1: TableCodable {
        var id: Int
        var name: String?
        var age: Int
    }
    
    func testCreateTableWithT1() throws {
        let db = try Util.openDatabase()
        try db.dropTable(T1.self)
        print(Util.databasePath)
        try db.createTable(T1.self, options: .ifNotExists) { tb in
            tb.column(forName: "id")?.primaryKey().notNull().unique()
            tb.column(forName: "age")?.notNull().unique()
            tb.column(forName: "name")?.notNull()
        }
    }
    
    struct T2: TableCodable, TableCodingKeyConvertiable {
        var id: Int
        var name: String?
        var age: Int
        
        static func codingKey(forKeyPath keyPath: PartialKeyPath<Self>) -> CodingKey {
            switch keyPath {
            case \T2.id: return CodingKeys.id
            case \T2.name: return CodingKeys.name
            case \T2.age: return CodingKeys.age
            default:
                fatalError()
            }
        }
    }
    
    func testCreateTableWithT2() throws {
        let db = try Util.openDatabase()
        try db.dropTable(T2.self)
        print(Util.databasePath)
        try db.createTable(T2.self, options: .ifNotExists) { tb in
            tb.column(forKeyPath: \T2.id)?.primaryKey(autoIncrement: true)
        }
    }
    
    struct Message: TableCodable, TableCodingKeyConvertiable {
        var id: String
        var convId: String
        var content: String
        static func codingKey(forKeyPath keyPath: PartialKeyPath<Self>) -> CodingKey {
            switch keyPath {
            case \Message.id: return CodingKeys.id
            case \Message.convId: return CodingKeys.convId
            case \Message.content: return CodingKeys.content
            default: fatalError()
            }
        }
    }
    
    func testCreateIndex() throws {
        
        let db = try Util.openDatabase()
        try db.dropTable(Message.self)
        try db.dropIndex("id_convid")
        try db.createTable(Message.self, options: .ifNotExists)
        
        try db.createIndex("id_convid", on: Message.self, keyPaths: [\Message.id, \Message.convId])
    }
}
