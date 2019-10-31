//
//  Select.swift
//  SQLite
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
struct Select: Expression {

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

// MARK: - Query

extension TableDecodable {

    private static func _fetchObjects(
        from database: Database,
        on columns: [ResultColumn] = [ResultColumn.all],
        where condition: Condition? = nil,
        orderBy orderTerms:[Base.OrderTerm]? = nil,
        limit: Int? = nil,
        offset: Int? = nil) throws -> [Self]
    {
        var query = Select(from: self.tableName, on: columns)
        query.whereCondtion = condition
        query.orderTerms = orderTerms
        query.limit = limit
        query.offset = offset

        var objects = [Self]()
        try database.exec(sql: query.sql, withParams: query.params) { (_, row, _) in
            if let obj = try? TableDecoder.default.decode(Self.self, from: row) {
                objects.append(obj)
            }
        }

        return objects
    }

    // MARK: Query Multi Objects

    static func fetchObjects(from database: Database) throws -> [Self] {
        try _fetchObjects(from: database)
    }

    static func fetchObjects(from database: Database, where condition: Condition) throws -> [Self] {
        try _fetchObjects(from: database, where: condition)
    }

    static func fetchObjects(from database: Database, orderBy orderTerms:[Base.OrderTerm])throws -> [Self] {
        try _fetchObjects(from: database, orderBy: orderTerms)
    }

    static func fetchObjects(
        from database: Database,
        where condition: Condition,
        orderBy orderTerms:[Base.OrderTerm]
    ) throws -> [Self]
    {
        try _fetchObjects(from: database, where: condition, orderBy: orderTerms)
    }

    // MARK: Query One Object

    static func fetchObject(
        from database: Database,
        on columns: [ResultColumn] = [ResultColumn.all],
        where condition: Condition? = nil,
        orderBy orderTerms:[Base.OrderTerm]? = nil) throws -> Self?
    {
        try _fetchObjects(from: database, on: columns, where: condition, orderBy: orderTerms, limit: 1, offset: nil).first
    }

    // MARK: Query One Column

    static func fetchColumn(
        from database: Database,
        on column: ResultColumn,
        where condition: Condition? = nil,
        orderBy orderTerms:[Base.OrderTerm]? = nil,
        limit: Int? = nil,
        offset: Int? = nil
    ) throws -> [BaseValueConvertible]
    {
        if case .all = column {
            throw SQLiteError.misuse("ResultColumn should not be `.all`")
        }

        var query = Select(from: self.tableName, on: [column])
        query.whereCondtion = condition
        query.orderTerms = orderTerms
        query.limit = limit
        query.offset = offset

        var values = [BaseValueConvertible]()
        try database.exec(sql: query.sql, withParams: query.params) { (_, row, _) in
            if let value = row.values.first {
                values.append(value)
            }
        }

        return values
    }

    // MARK: Query Multi Columns

    // To be continue...
}
