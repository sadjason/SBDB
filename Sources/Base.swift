//
//  Base.swift
//  SQLite
//
//  Created by zhangwei on 2019/10/17.
//  Copyright © 2019 ByteDance. All rights reserved.
//

import Foundation

public enum Base { }

extension Base {

    /// https://www.sqlite.org/syntax/conflict-clause.html
    public enum Conflict: String, Expression {
        case rollback
        case abort
        case replace
        case fail
        case ignore
    }
}

extension Base {

    /// https://www.sqlite.org/datatype3.html#collation
    public enum Collate: String, Expression {
        case binary
        case nocase
        case rtrim
    }
}

extension Base {

    public enum Order: String, Expression {
        case asc
        case desc
    }
}

extension Base {

    // https://www.sqlite.org/datatype3.html
    public enum AffinityType: String, Expression {
        case text
        case numeric
        case integer
        case real
        case blob
    }
}

extension Base {

    public enum TransactionMode: String, Expression {
        case defered
        case immediate
        case exclusive
    }
}

extension Base {

    public typealias ColumnName = String
    public typealias ColumnValue = BaseValueConvertible

    public typealias RowStorage = Dictionary<ColumnName, ColumnValue>
}
