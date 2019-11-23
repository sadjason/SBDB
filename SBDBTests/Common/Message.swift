//
//  Message.swift
//  SBDBTests
//
//  Created by zhangwei on 2019/11/25.
//  Copyright © 2019 ByteDance. All rights reserved.
//

import Foundation
@testable import SBDB

/// 会话
struct Conversation: TableCodable, TableCodingKeyConvertiable {
    var id: String      // 会话 ID
    var name: String    // 会话名
    
    static func codingKey(forKeyPath keyPath: PartialKeyPath<Self>) -> CodingKey {
        switch keyPath {
        case \Self.id: return CodingKeys.id
        case \Self.name: return CodingKeys.name
        default: fatalError()
        }
    }
}

/// 成员
struct Participant: TableCodable, TableCodingKeyConvertiable {
    var userId: String  // 用户 ID
    var convId: String  // 会话 ID
    var name: String    // 成员名
    var age: Int        // 年龄
    
    static func codingKey(forKeyPath keyPath: PartialKeyPath<Self>) -> CodingKey {
        switch keyPath {
        case \Self.userId: return CodingKeys.userId
        case \Self.convId: return CodingKeys.convId
        case \Self.name: return CodingKeys.name
        case \Self.age: return CodingKeys.age
        default: fatalError()
        }
    }
}
