//
//  Expression.swift
//  SQLite
//
//  Created by zhangwei on 2019/10/24.
//  Copyright © 2019 ByteDance. All rights reserved.
//

import Foundation

let ParameterPlaceholder = "?"

/// https://www.sqlite.org/lang_expr.html

// MARK: - Expression

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


// MARK: - ParameterExpression

protocol ParameterExpression: Expression {
    var params: [BaseValueConvertible]? { get }
}

extension ParameterExpression {
    // replace all placeholder with parameters

    public var debugDescription: String {
        sql.enumerated().map { (index, ch) -> String in
            let s = String(ch)
            if s == ParameterPlaceholder,
                index < (params?.count ?? 0),
                let param = params?[index] {
                return param.baseValue.debugDescription
            }
            return s
        }.joined()
    }

    func debugCheckParameterValid() -> Bool {
        sql.enumerated().filter { String($1) == ParameterPlaceholder }.count == (params?.count ?? 0)
    }
 }

// MARK: - SingleParameterExpression

protocol SingleParameterExpression : ParameterExpression {
    var baseValue: BaseValueConvertible { get }
}

extension SingleParameterExpression {
    var params: [BaseValueConvertible]? {
        [self.baseValue]
    }
}

// MARK: - Condition

struct Condition: ParameterExpression {
    var sql: String
    var params: [BaseValueConvertible]?
}

// MARK: Condition Operators

private let NotConditionPrefix = "not "

extension Condition {

    private var hasNot: Bool {
        let s = sql.trimmingCharacters(in: .whitespaces)
        return s.lowercased().hasPrefix(NotConditionPrefix)
    }

    // `and` operator for Condition
    static func && (lhs: Condition, rhs: Condition) -> Condition {
        let sql = "\(lhs.sql) and \(rhs.sql)"
        var params: [BaseValueConvertible]? = nil
        if lhs.params != nil || rhs.params != nil {
            params = (lhs.params ?? []) + (rhs.params ?? [])
        }
        return Condition(sql: sql, params: params)
    }

    // `or` operator for Condition
    static func || (lhs: Condition, rhs: Condition) -> Condition {
        let sql = "\(lhs.sql) or \(rhs.sql)"
        var params: [BaseValueConvertible]? = nil
        if lhs.params != nil || rhs.params != nil {
            params = (lhs.params ?? []) + (rhs.params ?? [])
        }
        return Condition(sql: sql, params: params)
    }

    // `not` operator for Condition
    static prefix func !(_ cond: Condition) -> Condition {
        if cond.hasNot {
            let sql = cond.sql.trimmingCharacters(in: .whitespaces)
            let index = sql.index(sql.startIndex, offsetBy: 5)
            let newSql = sql.suffix(from: index).trimmingCharacters(in: .whitespaces)
            return Condition(sql: newSql, params: cond.params)
        } else {
            return Condition(sql: NotConditionPrefix + cond.sql, params: cond.params)
        }
    }
}

