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

// MARK: - ConditionExpression

struct ConditionExpression: ParameterExpression {
    var sql: String
    var params: [BaseValueConvertible]?
}

// MARK: ConditionExpression Operators

extension ConditionExpression {

    // `and` operator for Condition
    static func && (lhs: ConditionExpression, rhs: ConditionExpression) -> ConditionExpression {
        let sql = "\(lhs.sql) and \(rhs.sql)"
        var params: [BaseValueConvertible]? = nil
        if lhs.params != nil || rhs.params != nil {
            params = (lhs.params ?? []) + (rhs.params ?? [])
        }
        return ConditionExpression(sql: sql, params: params)
    }

    // `or` operator for Condition
    static func || (lhs: ConditionExpression, rhs: ConditionExpression) -> ConditionExpression {
        let sql = "\(lhs.sql) or \(rhs.sql)"
        var params: [BaseValueConvertible]? = nil
        if lhs.params != nil || rhs.params != nil {
            params = (lhs.params ?? []) + (rhs.params ?? [])
        }
        return ConditionExpression(sql: sql, params: params)
    }
}

// MARK: - WhereExpression

struct WhereExpression: ParameterExpression {
    let notFlag: Bool
    let cond: ConditionExpression

    init(condition: ConditionExpression, notFlag yesOrNo: Bool = false) {
        cond = condition
        notFlag = yesOrNo
    }

    var sql: String {
        "where \(notFlag ? "not" : "") \(cond.sql)"
    }
    var params: [BaseValueConvertible]? {
        cond.params
    }
}

