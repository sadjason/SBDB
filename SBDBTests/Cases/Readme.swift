//
//  Readme.swift
//  SBDBTests
//
//  Created by zhangwei on 2019/11/25.
//  Copyright © 2019 ByteDance. All rights reserved.
//

import XCTest
@testable import SBDB

class Readme: XCTestCase {

    func testCreatingTable() throws {
        let db = try Util.openDatabase()
        print(Util.databasePath)
        
        // try db.createTable(Conversation.self)
        
        try db.createTable(Conversation.self, options: .ifNotExists) { tb in
            // set primary: single comumn
            tb.column(forKeyPath: \Conversation.id)?.primaryKey().unique()
            // set not null
            tb.column(forKeyPath: \Conversation.name)?.notNull()
        }

        try db.createTable(Participant.self, options: .ifNotExists) { tb in
            // set primary: multiple column
            tb.setPrimaryKey(withKeyPath: \Participant.userId, \Participant.convId)
        }
    }
    
    func testDropingTable() throws {
        let db = try Util.openDatabase()
        
        try db.dropTable(Conversation.self)
        try db.dropTable(Participant.self, ifExists: true)
    }
    
    func buildConversation(name: String) -> Conversation {
        Conversation.init(id: UUID().uuidString, name: name)
    }
    
    func buildParticipant(name: String, age: Int, convId: String) -> Participant {
        Participant(userId: UUID().uuidString, convId: convId, name: name, age: age)
    }
    
    func testInserting() throws {
        let db = try Util.openDatabase()
        
        let conv = buildConversation(name: "conv_0")
        try db.insert(conv)
        
        try db.insert((1...100).map { index in buildParticipant(name: "name_\(index)", age: index, convId: conv.id) })
    }
    
    func testDeleing() throws {
        let db = try Util.openDatabase()
        
        try db.delete(from: Conversation.self)
        try db.delete(from: Participant.self, where: \Participant.age >= 80 && \Participant.age < 18)
        try db.delete(from: Participant.self, where: (\Participant.age).in([32, 100]))
        try db.delete(from: Participant.self, where: (\Participant.age).between(65, and: 70))
        try db.delete(from: Participant.self, where: (\Participant.name).isNull())
    }
    
    func testUpdate() throws {
        let db = try Util.openDatabase()
        
        try db.update(Participant.self, where: \Participant.name == "name_42"){ assign in
            assign(\Participant.age, "24")
        }
    }
    
    func testSelecting() throws {
        let db = try Util.openDatabase()
        
//        _ = try db.select(from: Participant.self)
//        _ = try db.select(from: Participant.self, where: \Participant.age >= 30)
//        _ = try db.select(from: Participant.self, where: \Participant.age >= 60, orderBy: \Participant.age)
//        print(try db.select(from: Participant.self, where: \Participant.age >= 60, orderBy: Expr.desc(\Participant.age)))
        print(try db.select(from: Participant.self, where: \Participant.age >= 50 && \Participant.age <= 60, orderBy: Expr.desc(\Participant.age)))
        print(try db.selectColumns(from: Participant.self, on: [.aggregate(.countAll, nil)], where: \Participant.age >= 50 && \Participant.age <= 60))
        
//        print(try db.selectOne(from: Participant.self))
//        print(try db.selectOne(from: Participant.self, where: \Participant.age >= 30))
//        print(try db.selectOne(from: Participant.self, where: \Participant.age >= 30, orderBy: [Expr.desc(\Participant.age)]))
    }
}
