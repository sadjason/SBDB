//
//  Participant.swift
//  Pods-SQLite
//
//  Created by zhangwei on 2019/10/23.
//

import Foundation

struct Participant: Identifiable {
    let id: String
    let userId: Int64
    let alias: String?
    let role: Int
    let orderInConversation: Int
    let conversationId: Int64
}

extension Participant : TableCodable, Equatable { }
