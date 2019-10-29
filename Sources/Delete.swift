//
//  Delete.swift
//  SQLite
//
//  Created by zhangwei on 2019/10/24.
//  Copyright © 2019 ByteDance. All rights reserved.
//

import Foundation

class DeleteStatement {

    var whereCondition: Condition?

    let tableName: String

    init(tableName: String) {
        self.tableName = tableName
    }

    var sql: String {
        var chunk = "delete from \(tableName)"

        if let cond = whereCondition {
            chunk += " where \(cond.sql)"
        }

        return chunk
    }

    var params: [BaseValueConvertible]? {
        return whereCondition?.params
    }
}

extension TableEncodable {

    static func delete(
        in database: Database,
        where condition: Condition? = nil) throws
    {
        let deleteStmt = DeleteStatement(tableName: Self.tableName)
        if let cond = condition {
            deleteStmt.whereCondition = cond
        }
        try database.exec(sql: deleteStmt.sql, withParams: deleteStmt.params)
    }
}
