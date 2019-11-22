//
//  DeleteStatement.swift
//  SBDB
//
//  Created by zhangwei on 2019/10/24.
//  Copyright © 2019 ByteDance. All rights reserved.
//

import Foundation

/// https://www.sqlite.org/lang_delete.html

struct DeleteStatement {

    let whereCondition: Condition?
    let tableName: String

    init(tableName: String, where condition: Condition? = nil) {
        self.tableName = tableName
        whereCondition = condition
    }
}

extension DeleteStatement: ParameterExpression {
    
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
