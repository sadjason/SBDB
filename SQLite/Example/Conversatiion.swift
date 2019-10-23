//
//  Conversatiion.swift
//  SQLite
//
//  Created by zhangwei on 2019/10/21.
//  Copyright © 2019 ByteDance. All rights reserved.
//

import Foundation

// MARK: Conversation Types

public extension Conversation {

    // MARK: Conversation Type

    enum `Type`: Int, Codable {
        internal typealias DataType = Int
        case oneToOne = 1 // 单聊
        case group    = 2 // 群聊
    }

    // MARK: Conversation Status

    enum Status: Int, Codable {
        internal typealias DataType = Int
        case normal     = 0 // 正常
        case dissolved  = 1 // 被解散
    }

    // typealias DraftContent = Message.Content
    typealias DraftContent = Dictionary<String, String>

    typealias LocalInfo = Dictionary<String, String>
    typealias CoreExtInfo = Dictionary<String, String>
    typealias SettingExtInfo = Dictionary<String, String>

    typealias ID = String
}

// TODO: 如何知道某个类型是否是枚举类型

// MARK: Conversation

public struct Conversation: Identifiable {
    typealias ShortID = Int64

    public let id: ID // 唯一标识符
    public let type: `Type` // 会话类型
    public let inbox: Int
    public var status: Status = .normal // 会话状态
    public var localInfo: LocalInfo? // 本地信息
    public var isParticipant: Bool = false // 当前用户是否是会话成员
    public var updatedAt: Date? // 会话更新时间
    public var unreadCount: Int64 = 0 // 未读数
    public var draft: DraftContent? = nil // 草稿
    public var draftedAt: Date? = nil // 草稿时间
    public var participantCount: Int = 0 // 会话成员数量
//    public var participant: Participant? = nil // 当前成员在会话的信息
//    public var someParticipants: [Participant]? = nil // 会话成员（可能是部分）

    var shortId: ShortID? = nil // shortId，由 server 赋值
    var ticket: String? // 票据
    var minIndex: Int64 = 0 // 当前成员在会话的 minIndex，用来设置消息挡板

    init(id: ID, type: `Type`, inbox: Int = 0) {
        self.id = id
        self.type = type
        self.inbox = inbox
    }

    // MARK: Core
    struct Core: Identifiable {
        let id: Conversation.ID
        let name: String?
        let desc: String?
        let iconUrl: String?
        let notice: String?
        let version: Int64
        let ownerId: Int64
        let extInfo: CoreExtInfo?
    }

    // MARK: Setting
    struct Setting: Identifiable {
        let id: Conversation.ID
        let isMute: Bool = false
        let isFavorite: Bool = false
        let isSticky: Bool = false
        let version: Int64 = 0
        let extInfo: SettingExtInfo?
    }
}

extension Conversation: Codable {

    enum CodingKeys: String, CodingKey {
        case id
        case shortId
        case type
        case inbox
        case ticket
        case localInfo
        case isParticipant
        case status
        case minIndex
        case updatedAt
        case unreadCount
        case draft
        case draftedAt
        case participantCount
//        case participant
//        case someParticipants
    }
}

extension Conversation.Core: Codable {
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case desc
        case notice
        case ownerId
        case iconUrl
        case extInfo
        case version
    }
}

extension Conversation.Setting: Codable {
    enum CodingKeys: String, CodingKey {
        case id
        case isMute
        case isFavorite
        case isSticky
        case extInfo
        case version
    }
}

