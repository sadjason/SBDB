//
//  PoolTests.swift
//  SBDBTests
//
//  Created by SadJason on 2019/11/29.
//  Copyright © 2019 SadJason. All rights reserved.
//

import XCTest
@testable import SBDB

class PoolTests: XCTestCase {

    func testPool() throws {
        let pool = DatabasePool(path: Util.databasePath)
        let (userId, name, age) = (\Participant.userId, \Participant.name, \Participant.age)
        
        try pool.read { db in
            print(try db.select(from: Participant.self, where: age > 80))
        }
        try pool.write { (db, _) in
            if let p = try db.selectOne(from: Participant.self) {
                try db.update(Participant.self, where: userId == p.userId) { assign in
                    assign(name, "the one")
                }
            }
        }
    }
}
