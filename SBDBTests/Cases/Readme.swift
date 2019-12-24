//
//  Readme.swift
//  SBDBTests
//
//  Created by SadJason on 2019/11/25.
//  Copyright © 2019 SadJason. All rights reserved.
//

import XCTest
@testable import SBDB

/// for README.md
class Readme: XCTestCase {

    func testCreatingTable() throws {
        let db = try Util.openDatabase()
        print(Util.databasePath)
        
        try db.createTable(Conversation.self, options: .ifNotExists) { tb in
            // set primary: single comumn
            tb.column(forKeyPath: \Conversation.id)?.setPrimary().setUnique()
            // set not null
            tb.column(forKeyPath: \Conversation.name)?.setNotNull()
        }

        try db.createTable(Participant.self, options: .ifNotExists) { tb in
            // set primary: multiple column
            tb.setPrimaryKey(withKeyPath: \Participant.userId, \Participant.convId)
        }
    }
    
//    func testDropingTable() throws {
//        let db = try Util.openDatabase()
//
//        try db.dropTable(Conversation.self)
//        try db.dropTable(Participant.self, ifExists: true)
//    }
    
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
//        let db = try Util.openDatabase()
//        let (age, name, userId, convId) = (\Participant.age, \Participant.name, \Participant.userId, \Participant.convId)
        
//        print(try db.select(from: Participant.self))
//        print(try db.select(from: Participant.self, where: age >= 30))
//        print(try db.select(from: Participant.self, where: age >= 60, orderBy: age))
//        print(try db.select(from: Participant.self, where: age >= 60, orderBy: age.desc()))
//        print(try db.select(from: Participant.self, where: age >= 60 && age <= 70, orderBy: age))
        
//        print(try db.selectOne(from: Participant.self, orderBy: age.desc()))
        
//        print(try db.selectColumns(from: Participant.self, on: Expr.Column.all, where: age >= 18 && age <= 60).count)
//        print(try db.selectColumns(from: Participant.self, on: [name, age], where: convId == "conv_0"))
        
//        print(try db.selectOneColumn(from: Participant.self, on: Expr.Column.all, where: age >= 18 && age <= 60).count)
//        print(try db.selectOneColumn(from: Participant.self, on: convId.count(), where: convId == "conv_0"))
//        print(try db.selectOneColumn(from: Participant.self, on: age.min()))
    }
}
