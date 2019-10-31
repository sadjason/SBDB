//
//  Base.swift
//  SQLite
//
//  Created by zhangwei on 2019/10/23.
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

    /// https://www.sqlite.org/lang_transaction.html
    public enum TransactionMode: String, Expression {
        case defered
        case immediate
        case exclusive
    }
}

extension Base {

    public typealias ColumnName = String
    public typealias ColumnValue = BaseValueConvertible
    public typealias ColumnIndex = Int32

    public typealias RowStorage = Dictionary<ColumnName, ColumnValue>
}

extension Base {

    /// https://www.sqlite.org/lang_aggfunc.html
    enum AggregateFunction {
        case avg(Expression)
        case count(Expression)
        case countAll
        case max(Expression)
        case min(Expression)
        case sum(Expression)
        case total(Expression)
    }
}

extension Base.AggregateFunction: Expression {
    
    var sql: String {
        switch self {
        case .avg(let exp): return "avg(\(exp.sql))"
        case .count(let exp): return "count(\(exp.sql))"
        case .countAll: return "count(*)"
        case .max(let exp): return "max(\(exp.sql))"
        case .min(let exp): return "min(\(exp.sql))"
        case .sum(let exp): return "sum(\(exp.sql))"
        case .total(let exp): return "total(\(exp.sql))"
        }
    }
}

/// https://www.sqlite.org/syntax/ordering-term.html
extension Base {

    public struct OrderTerm: Expression {

        enum NullStratery: String, Expression {
            case nullsFirst
            case nullsLast
        }

        var column: Column
        var strategy: Base.Order? = nil
        var nullStrategy: NullStratery? = nil
        init(columnName: Base.ColumnName) {
            self.column = Column(columnName)
        }
        // 暂时不支持 onCollation，似乎用不到
        // var onCollation: Base.Collate? = nil

        var sql: String {
            var chunk = "\(column.sql)"
            if let strategy = strategy {
                chunk += " \(strategy.sql)"
            }
            if let nullStrategy = nullStrategy {
                chunk += " \(nullStrategy.sql)"
            }
            return chunk
        }
    }
}

// MARK: SQLite Result Code

/// https://www.sqlite.org/c3ref/c_abort.html

public typealias SQLiteCode = Int32
// public let SQLiteOK = SQLITE_OK
// public let SQLiteDone = SQLITE_DONE
// public let SQLiteRow = SQLITE_ROW
