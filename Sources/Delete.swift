//
//  Delete.swift
//  SQLite
//
//  Created by zhangwei on 2019/10/24.
//  Copyright © 2019 ByteDance. All rights reserved.
//

import Foundation

class DeleteStatement<T: TableEncodable> {

    private var whereExpr: WhereExpression?

    var sql: String {
        var chunk = "delete from \(T.tableName)"

        if let whereExpr = whereExpr {
            chunk += " \(whereExpr.sql)"
        }

        return chunk
    }

    var params: [BaseValueConvertible]? {
        return whereExpr?.params
    }

    @discardableResult
    func `where`(_ cond: ConditionExpression) -> Self {
        precondition(whereExpr == nil, "You can only invoke `where`/`whereNot` once")

        whereExpr = WhereExpression(condition: cond)
        return self
    }

    @discardableResult
    func whereNot(_ cond: ConditionExpression) -> Self {
        precondition(whereExpr == nil, "You can only invoke `where`/`whereNot` once")
        whereExpr = WhereExpression(condition: cond, notFlag: true)
        return self
    }
}

extension DeleteStatement: Executable {

    func exec(in database: Database) throws {

        print("exec delete sql: \(sql)")

        var stmt = try RawStatement(sql: sql, db: database.db)

        var index: RawStatement.ColumnIndex = 1
        for param in params ?? [] {
            try stmt?.bind(param.baseValue, to: index)
            index += 1
        }

        try stmt?.step()

        stmt?.finalize()
    }
}

extension TableEncodable {

    static var delete: DeleteStatement<Self> {
        DeleteStatement<Self>()
    }
}
