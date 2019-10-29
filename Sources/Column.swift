//
//  Column.swift
//  SQLite
//
//  Created by zhangwei on 2019/10/17.
//  Copyright © 2019 ByteDance. All rights reserved.
//

import Foundation

// MARK: - Column

struct Column: Expression {
    let name: String
    var sql: String { name }

    init(_ name: String) {
        self.name = name
    }
}

// MARK: Comparable & Equable Operators

let kParam = ParameterPlaceholder

extension Column {

    static func > (column: Column, value: BaseValueConvertible) -> Condition {
        Condition(sql: "\(column.name) > \(kParam)", params: [value])
    }

    static func >= (column: Column, value: BaseValueConvertible) -> Condition {
        Condition(sql: "\(column.name) >= \(kParam)", params: [value])
    }

    static func < (column: Column, value: BaseValueConvertible) -> Condition {
        Condition(sql: "\(column.name) < \(kParam)", params: [value])
    }

    static func <= (column: Column, value: BaseValueConvertible) -> Condition {
        Condition(sql: "\(column.name) <= \(kParam)", params: [value])
    }

    static func == (column: Column, value: BaseValueConvertible) -> Condition {
        Condition(sql: "\(column.name) == \(kParam)", params: [value])
    }

    static func != (column: Column, value: BaseValueConvertible) -> Condition {
        Condition(sql: "\(column.name) != \(kParam)", params: [value])
    }
}

extension Column {

    static func > (lhs: Column, rhs: Column) -> Condition {
        Condition(sql: "\(lhs.name) > \(rhs.name)")
    }

    static func >= (lhs: Column, rhs: Column) -> Condition {
        Condition(sql: "\(lhs.name) >= \(rhs.name)")
    }

    static func < (lhs: Column, rhs: Column) -> Condition {
        Condition(sql: "\(lhs.name) < \(rhs.name)")
    }

    static func <= (lhs: Column, rhs: Column) -> Condition {
        Condition(sql: "\(lhs.name) <= \(rhs.name)")
    }

    static func == (lhs: Column, rhs: Column) -> Condition {
        Condition(sql: "\(lhs.name) == \(rhs.name)")
    }

    static func != (lhs: Column, rhs: Column) -> Condition {
        Condition(sql: "\(lhs.name) != \(rhs.name)")
    }
}

// MARK: Basic Column Operators

extension Column {
    func `in`(_ values: [BaseValueConvertible]) -> Condition {
        let paramPlaceholders = Array<String>(repeating: kParam, count: values.count).joined(separator: ",")
        let sql = "\(name) in (\(paramPlaceholders))"
        return Condition(sql: sql, params: values)
    }

    func notIn(_ values: [BaseValueConvertible]) -> Condition {
        let paramPlaceholders = Array<String>(repeating: kParam, count: values.count).joined(separator: ",")
        let sql = "\(name) not in (\(paramPlaceholders))"
        return Condition(sql: sql, params: values)
    }

    func between(_ value1: BaseValueConvertible, and value2: BaseValueConvertible) -> Condition {
        Condition(sql: "\(name) between \(kParam) and \(kParam)", params: [value1, value2])
    }

    func notBetween(_ value1: BaseValueConvertible, and value2: BaseValueConvertible) -> Condition {
        Condition(sql: "\(name) not between \(kParam) and \(kParam)", params: [value1, value2])
    }

    func isNull() -> Condition {
        Condition(sql: "\(name) isnull")
    }

    func notNull() -> Condition {
        Condition(sql: "\(name) notnull")
    }
}

// MARK: - ColumnIndexed

/// https://www.sqlite.org/syntax/indexed-column.html
public struct ColumnIndexed: Expression {
    let columnName: Base.ColumnName
    let collate: Base.Collate?
    let order: Base.Order?

    var sql: String {
        var str = columnName
        str += (collate != nil ? " collate \(collate!.sql)" : "")
        str += (order != nil ? order!.sql : "")
        return str
    }
}

// MARK: - ColumnDefinition

/// https://www.sqlite.org/syntax/column-def.html
public final class ColumnDefinition {

    enum Constraint {
        case primaryKey(Base.Order?, Base.Conflict?, Bool?)
        case notNull(Base.Conflict?)
        case unique(Base.Conflict?)
        case collate(Base.Collate)
        // TODO: support check
        // TODO: support foreign key
    }

    public typealias DataType = Base.AffinityType

    fileprivate enum ConstraintType: Int, Comparable {
        static func < (lhs: ConstraintType, rhs: ConstraintType) -> Bool {
            lhs.rawValue < rhs.rawValue
        }

        case primary, notNull, unique, `default`, collate
    }

    fileprivate var constraints = [ConstraintType : Constraint]()
    fileprivate let name: String
    fileprivate let type: DataType?

    // TODO: 对于默认值，是写在定义式里，还是在构造器中，哪个更合适？
    init(_ name: String, _ type: DataType? = nil) {
        self.name = name
        self.type = type
    }

    @discardableResult
    public func primaryKey(
        autoIncrement: Bool = false,
        onConflict: Base.Conflict? = nil,
        order: Base.Order? = nil) -> Self
    {
        if autoIncrement {
            guard let t = type, t == .integer else {
                assert(false, "AUTOINCREMENT is only allowed on an INTEGER PRIMARY KEY without DESC")
                return self
            }
            guard order == nil || order! == .asc else {
                assert(false, "AUTOINCREMENT is only allowed on an INTEGER PRIMARY KEY without DESC")
                return self
            }
        }
        constraints[.primary] = .primaryKey(order, onConflict, autoIncrement)
        // set `not null` for primary key
        if constraints[.notNull] == nil {
            _ = notNull()
        }
        return self
    }

    @discardableResult
    public func notNull(onConflict: Base.Conflict? = nil) -> Self {
        constraints[.notNull] = .notNull(onConflict)
        return self
    }

    @discardableResult
    public func unique(onConflict: Base.Conflict? = nil) -> Self {
        constraints[.unique] = .unique(onConflict)
        return self
    }

    @discardableResult
    public func collate(name: Base.Collate? = nil) -> Self {
        constraints[.collate] = .collate(name!)
        return self
    }
}

extension ColumnDefinition.Constraint: Expression {
    var sql: String {
        let onConflictPhrase = "on conflict"

        switch self {
        case let .primaryKey(order, conflictResolution, autoIncrement):
            var str = "primary key"
            if let r = order {
                str += " \(r.sql)"
            }
            if let c = conflictResolution {
                str += " \(onConflictPhrase) \(c.sql)"
            }
            if let a = autoIncrement, a {
                str += " autoIncrement"
            }
            return str
        case let .notNull(conflictResolution):
            var str = "not null"
            if let c = conflictResolution {
                str += " \(onConflictPhrase) \(c.sql)"
            }
            return str
        case let .unique(conflictResolution):
            var ret = "unique"
            if let c = conflictResolution {
                ret += " \(onConflictPhrase) \(c.sql)"
            }
            return ret
        case .collate:
            return "collate"
        }
    }
}

extension ColumnDefinition : Expression {
    var sql: String {
        var ret = name
        if let type = type {
            ret += " \(type.rawValue)"
        }

        constraints.keys.sorted().forEach { key in
            if case .unique = key, constraints.keys.contains(.primary) {
                return
            }
            ret += " \(constraints[key]!.sql)"
        }
        return ret
    }
}

// MARK: - ColumnAssignment

struct ColumnAssignment : SingleParameterExpression {
    let name: String
    let baseValue: BaseValueConvertible

    var sql: String { "\(name) = ? " }
    init(name: String, value: BaseValueConvertible) {
        self.name = name
        self.baseValue = value
    }
}

