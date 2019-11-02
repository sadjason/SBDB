//
//  Update.swift
//  SBDB
//
//  Created by zhangwei on 2019/10/23.
//  Copyright © 2019 ByteDance. All rights reserved.
//

import Foundation

/// https://www.sqlite.org/lang_update.html

public enum UpdateMode: Expression {
    case update
    case updateOr(Base.Conflict)
    
    var sql: String {
        switch self {
        case .update: return "update"
        case .updateOr(let conflict): return "update or \(conflict.sql)"
        }
    }
}

struct UpdateStatement {
    
    private let tableName: String
    private let mode: UpdateMode
    private let whereCondition: Condition?
    private let assignment: UpdateAssignment
    
    init(
        tableName: String,
        assigment: UpdateAssignment,
        mode: UpdateMode = .update,
        where condition: Condition? = nil)
    {
        self.tableName = tableName
        self.assignment = assigment
        self.mode = mode
        self.whereCondition = condition
    }
}

extension UpdateStatement: ParameterExpression {
    var sql: String {
        var chunk = "\(mode.sql) \(tableName)"

        let assigns = assignment.keys.sorted().map { "\($0) = \(ParameterPlaceholder)" }.joined(separator: ",")
        chunk += " set \(assigns)"

        if let cond = whereCondition {
            chunk += " where \(cond.sql)"
        }

        return chunk
    }

    var params: [BaseValueConvertible]? {
        assignment.keys.sorted().map { assignment[$0]! } + (whereCondition?.params ?? [])
    }
}

public typealias UpdateAssignment = Dictionary<String, BaseValueConvertible>

extension TableEncodable {
    
    static func update(
        in db: Database,
        assignment: UpdateAssignment,
        withMode mode: UpdateMode = .update,
        where condition: Condition? = nil
    ) throws {
        let stmt = UpdateStatement(tableName: tableName, assigment: assignment, mode: mode, where: condition)
        try db.exec(sql: stmt.sql, withParams: stmt.params)
    }
    
    static func update(
        in db: Database,
        where condition: Condition,
        assign: (inout UpdateAssignment) -> Void
    ) throws {
        var assignment = UpdateAssignment()
        assign(&assignment)
        try update(in: db, assignment: assignment, withMode: .update, where: condition)
    }
}
