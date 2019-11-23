//
//  Expression.swift
//  SBDB
//
//  Created by zhangwei on 2019/10/24.
//  Copyright © 2019 ByteDance. All rights reserved.
//

import Foundation

public enum Expr {}

let ParameterPlaceholder = "?"

/// https://www.sqlite.org/lang_expr.html

// MARK: - Expression Protocols

protocol Expression: CustomDebugStringConvertible, CustomStringConvertible {
    var sql: String { get }
}

extension Expression {
    public var description: String { sql }
    public var debugDescription: String { sql }
}

extension Expression where Self: RawRepresentable, Self.RawValue == String {
    var sql: String { rawValue }
}

protocol ParameterExpression: Expression {
    var params: [ColumnValueConvertible]? { get }
}

extension ParameterExpression {
    
    public var debugDescription: String {
        sql.enumerated().map { (index, ch) -> String in
            let s = String(ch)
            // replace placeholder with parameter
            if s == ParameterPlaceholder,
                index < (params?.count ?? 0),
                let param = params?[index]
            {
                return param.columnValue.debugDescription
            }
            return s
        }.joined()
    }

    func debugCheckParameterValid() -> Bool {
        sql.enumerated().filter { String($1) == ParameterPlaceholder }.count == (params?.count ?? 0)
    }
}

// MARK: - Condition

extension Expr {
    
    public struct Condition: ParameterExpression {
        var sql: String
        var params: [ColumnValueConvertible]?
        
        static var `true`: Condition = Condition(sql: "true", params: nil)
    }
}

private let notPrefix = "not "

extension Expr.Condition {

    private var hasNot: Bool {
        sql.trimmingCharacters(in: .whitespaces).lowercased().hasPrefix(notPrefix)
    }

    // `and` operator for Condition
    static func && (lhs: Self, rhs: Self) -> Self {
        let sql = "\(lhs.sql) and \(rhs.sql)"
        var params: [ColumnValueConvertible]? = nil
        if lhs.params != nil || rhs.params != nil {
            params = (lhs.params ?? []) + (rhs.params ?? [])
        }
        return Self.init(sql: sql, params: params)
    }

    // `or` operator for Condition
    static func || (lhs: Self, rhs: Self) -> Self {
        let sql = "\(lhs.sql) or \(rhs.sql)"
        var params: [ColumnValueConvertible]? = nil
        if lhs.params != nil || rhs.params != nil {
            params = (lhs.params ?? []) + (rhs.params ?? [])
        }
        return Self.init(sql: sql, params: params)
    }

    // `not` operator for Condition
    static prefix func !(_ cond: Self) -> Self {
        if cond.hasNot {
            let sql = cond.sql.trimmingCharacters(in: .whitespaces)
            let index = sql.index(sql.startIndex, offsetBy: 5)
            let newSql = sql.suffix(from: index).trimmingCharacters(in: .whitespaces)
            return Self.init(sql: newSql, params: cond.params)
        } else {
            return Self.init(sql: notPrefix + cond.sql, params: cond.params)
        }
    }
}

// MARK: Order

extension Expr {
    
    public enum Order: String, Expression {
        case asc
        case desc
    }
}

// MARK: OrderTerm

extension Expr {
 
    /// - See Also: https://www.sqlite.org/syntax/ordering-term.html
    public struct OrderTerm: Expression {

        enum NullStratery: String, Expression {
            case nullsFirst
            case nullsLast
        }

        var column: Column
        var strategy: Order? = nil
        var nullStrategy: NullStratery? = nil
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
        
        init(column columnName: ColumnName) {
            self.column = Column(columnName)
        }
        
        init(column columnName: ColumnName, strategy: Order) {
            self.column = Column(columnName)
            self.strategy = strategy
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

// MARK: Column

extension Expr {
    
    public struct Column: Expression {
        let name: String
        var sql: String { name }

        init(_ name: String) {
            self.name = name
        }
    }

}

// MARK: Aggregate Function

extension Expr {
    
    /// - See Also: https://www.sqlite.org/lang_aggfunc.html
    public enum AggregateFunction: Expression {
        case avg(Column)
        case count(Column)
        case countAll
        case max(Column)
        case min(Column)
        case sum(Column)
        case total(Column)
        
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
}

// MARK: Transaction Mode

extension Expr {
    
    /// - See Also: https://www.sqlite.org/lang_transaction.html
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

// MARK: Conflict

extension Expr {
    
    /// https://www.sqlite.org/syntax/conflict-clause.html
    public enum Conflict: String, Expression {
        case rollback, abort, replace, fail, ignore
    }
}

// MARK: Affinity Type

extension Expr {
    
    /// - See Also: https://www.sqlite.org/datatype3.html
    public enum AffinityType: String, Expression {
        case text, numeric, integer, real, blob
    }
}

// MARK: Collate

extension Expr {
    
    /// - See Also: https://www.sqlite.org/datatype3.html#collation
    public enum Collate: String, Expression {
        case binary
        case nocase
        case rtrim
    }
}

// MARK: Comparable & Equable Operators

extension Expr.Column {

    static func > (column: Self, value: ColumnValueConvertible) -> Expr.Condition {
        Expr.Condition(sql: "\(column.name) > \(ParameterPlaceholder)", params: [value])
    }

    static func >= (column: Self, value: ColumnValueConvertible) -> Expr.Condition {
        Expr.Condition(sql: "\(column.name) >= \(ParameterPlaceholder)", params: [value])
    }

    static func < (column: Self, value: ColumnValueConvertible) -> Expr.Condition {
        Expr.Condition(sql: "\(column.name) < \(ParameterPlaceholder)", params: [value])
    }

    static func <= (column: Self, value: ColumnValueConvertible) -> Expr.Condition {
        Expr.Condition(sql: "\(column.name) <= \(ParameterPlaceholder)", params: [value])
    }

    static func == (column: Self, value: ColumnValueConvertible) -> Expr.Condition {
        Expr.Condition(sql: "\(column.name) == \(ParameterPlaceholder)", params: [value])
    }

    static func != (column: Self, value: ColumnValueConvertible) -> Expr.Condition {
        Expr.Condition(sql: "\(column.name) != \(ParameterPlaceholder)", params: [value])
    }
}

extension Expr.Column {

    static func > (lhs: Self, rhs: Self) -> Expr.Condition {
        Expr.Condition(sql: "\(lhs.name) > \(rhs.name)")
    }

    static func >= (lhs: Self, rhs: Self) -> Expr.Condition {
        Expr.Condition(sql: "\(lhs.name) >= \(rhs.name)")
    }

    static func < (lhs: Self, rhs: Self) -> Expr.Condition {
        Expr.Condition(sql: "\(lhs.name) < \(rhs.name)")
    }

    static func <= (lhs: Self, rhs: Self) -> Expr.Condition {
        Expr.Condition(sql: "\(lhs.name) <= \(rhs.name)")
    }

    static func == (lhs: Self, rhs: Self) -> Expr.Condition {
        Expr.Condition(sql: "\(lhs.name) == \(rhs.name)")
    }

    static func != (lhs: Self, rhs: Self) -> Expr.Condition {
        Expr.Condition(sql: "\(lhs.name) != \(rhs.name)")
    }
}

// MARK: Basic Column Operators

extension Expr.Column {
    func `in`(_ values: [ColumnValueConvertible]) -> Expr.Condition {
        let paramPlaceholders = Array<String>(repeating: ParameterPlaceholder, count: values.count).joined(separator: ",")
        let sql = "\(name) in (\(paramPlaceholders))"
        return Expr.Condition(sql: sql, params: values)
    }

    func notIn(_ values: [ColumnValueConvertible]) -> Expr.Condition {
        let paramPlaceholders = Array<String>(repeating: ParameterPlaceholder, count: values.count).joined(separator: ",")
        let sql = "\(name) not in (\(paramPlaceholders))"
        return Expr.Condition(sql: sql, params: values)
    }

    func between(_ value1: ColumnValueConvertible, and value2: ColumnValueConvertible) -> Expr.Condition {
        Expr.Condition(sql: "\(name) between \(ParameterPlaceholder) and \(ParameterPlaceholder)", params: [value1, value2])
    }

    func notBetween(_ value1: ColumnValueConvertible, and value2: ColumnValueConvertible) -> Expr.Condition {
        Expr.Condition(sql: "\(name) not between \(ParameterPlaceholder) and \(ParameterPlaceholder)", params: [value1, value2])
    }

    func isNull() -> Expr.Condition {
        Expr.Condition(sql: "\(name) isnull")
    }

    func notNull() -> Expr.Condition {
        Expr.Condition(sql: "\(name) notnull")
    }
}

// MARK: Indexed Column

extension Expr {
    
    /// https://www.sqlite.org/syntax/indexed-column.html
    public struct IndexedColumn: Expression {
        let name: ColumnName
        var collate: Expr.Collate?
        var order: Expr.Order?
        
        init(_ name: String) {
            self.name = name
            collate = nil
            order = nil
        }
        
        var sql: String {
            var str = name
            str += (collate != nil ? " collate \(collate!.sql)" : "")
            str += (order != nil ? order!.sql : "")
            return str
        }
    }
}
