//
//  Base.swift
//  SBDB
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
        /// Means that the transaction does not actually start until the database is first accessed.
        case deferred

        /// Cause the database connection to start a new write immediately, without waiting for a writes statement.
        case immediate

        /// `exclusive` is similar to `immediate` in that a write transaction is started immediately.
        /// `exclusive` and `immediate` are the same in WAL mode, but in other journaling modes,
        /// `exclusive` prevents other database connections from reading the database while the transaction is underway.
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
    public enum AggregateFunction {
        case avg(Column)
        case count(Column)
        case countAll
        case max(Column)
        case min(Column)
        case sum(Column)
        case total(Column)
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
        init(column columnName: Base.ColumnName) {
            self.column = Column(columnName)
        }
        
        init(column columnName: Base.ColumnName, strategy: Base.Order) {
            self.column = Column(columnName)
            self.strategy = strategy
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
        
        mutating func nullsFirst() {
            nullStrategy = .nullsFirst
        }
        
        mutating func nullsLast() {
            nullStrategy = .nullsLast
        }
        
        mutating func asc() {
            strategy = .asc
        }
        
        mutating func desc() {
            strategy = .desc
        }
    }
}

extension Base {
    
    enum IndexedStrategy: Expression {
        case none
        case indexed(String)

        var sql: String {
            switch self {
            case .none:
                return "not indexed"
            case .indexed(let name):
                return "indexed by \(name)"
            }
        }
    }
}

// MARK: SQLite Result Code

/// https://www.sqlite.org/c3ref/c_abort.html

public typealias SQLiteCode = Int32
// public let SQLiteOK = SQLITE_OK
// public let SQLiteDone = SQLITE_DONE
// public let SQLiteRow = SQLITE_ROW
