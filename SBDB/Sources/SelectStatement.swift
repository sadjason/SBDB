//
//  SelectStatement.swift
//  SBDB
//
//  Created by zhangwei on 2019/10/24.
//  Copyright © 2019 ByteDance. All rights reserved.
//

import Foundation
import SQLite3

// MARK: Result Column

enum ResultColumn: Expression {
    typealias Alias = String

    case all
    case normal(Column, Alias?)
    case aggregate(Base.AggregateFunction, Alias?)

    var sql: String {
        switch self {
        case .all: return "*"
        case let .normal(col, alias):
            return alias != nil ? "\(col.sql) as \(alias!)" : col.sql
        case let .aggregate(fun, alias):
            return alias != nil ? "\(fun.sql) as \(alias!)" : fun.sql
        }
    }
}

/// 简单的 select 语句，支持聚合查询、非聚合查询
/// https://www.sqlite.org/lang_select.html
struct SelectStatement: Expression {

    enum Mode: String, Expression {
        case distinct
        case all
    }

    let tableName: String
    let resultColumns: [ResultColumn]
    var groupColumns: [Column]? = nil
    var orderTerms: [Base.OrderTerm]?
    var whereCondtion: Condition?
    var limit: Int?
    var offset: Int?
    var mode: Mode?

    init(from tableName: String, on columns: [ResultColumn]) {
        self.tableName = tableName
        self.resultColumns = columns
    }

    var sql: String {
        var chunk = "select"
        if let mode = mode {
            chunk += " \(mode.sql)"
        }
        chunk += " \(resultColumns.map { $0.sql }.joined(separator: ","))"
        chunk += " from \(tableName)"
        if let cond = whereCondtion {
            chunk += " where \(cond.sql)"
        }
        if let group = groupColumns, group.count > 0 {
            chunk += " group by \(group.map { $0.sql }.joined(separator: ","))"
        }
        if let orderTerms = orderTerms, orderTerms.count > 0 {
            chunk += " order by \(orderTerms.map { $0.sql }.joined(separator: ","))"
        }
        if let limit = limit {
            chunk += " limit \(limit)"
        }
        if let offset = offset {
            chunk += " offset \(offset)"
        }
        return chunk
    }
    var params: [BaseValueConvertible]? {
        whereCondtion?.params
    }
}
