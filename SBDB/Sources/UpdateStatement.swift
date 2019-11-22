//
//  UpdateStatement.swift
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

public typealias UpdateAssignment = Dictionary<String, BaseValueConvertible>

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

//extension TableEncodable {
//    
//    static func update(
//        in db: Database,
//        assignment: UpdateAssignment,
//        withMode mode: UpdateMode = .update,
//        where condition: Condition? = nil
//    ) throws {
//        let stmt = UpdateStatement(tableName: tableName, assigment: assignment, mode: mode, where: condition)
//        try db.exec(sql: stmt.sql, withParams: stmt.params)
//    }
//    
//}
//
//extension TableEncodable where Self: KeyPathToColumnNameConvertiable  {
//    
//    static func update(
//        in db: Database,
//        where condition: Condition,
//        assign: (AssignHandler<Self>) -> Void
//    ) throws {
//        var assignment = UpdateAssignment()
//        
//        let handler: AssignHandler<Self> = { (k, v) in
//            guard let key = k.hashString() else {
//                return
//            }
//            assignment[key] = v
//        }
//        assign(handler)
//        
//        try update(in: db, assignment: assignment, withMode: .update, where: condition)
//    }
//}
