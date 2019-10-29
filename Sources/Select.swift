//
//  Select.swift
//  SQLite
//
//  Created by zhangwei on 2019/10/24.
//  Copyright © 2019 ByteDance. All rights reserved.
//

import Foundation
import SQLite3

/**
 简单的 select 语句有两种类型：聚合查询、非聚合查询

 https://github.com/Tencent/wcdb/wiki/Swift-%e5%a2%9e%e5%88%a0%e6%9f%a5%e6%94%b9
 */

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

/**
 什么时候 from 语句可以省略
 */

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

extension TableDecodable {

    private static func _statement(
        in database: Database,
        with sql: String,
        params: [BaseValueConvertible]?) throws -> RawStatement
    {
        let stmt: RawStatement
        if let s = database.popStatement(forKey: sql) {
            try s.reset()
            stmt = s
        } else {
            stmt = try RawStatement(sql: sql, database: database.db)
        }

        defer {
            database.pushStatement(stmt, forKey: sql)
        }

        try params?.enumerated().forEach { (index, param) in
            try stmt.bind(param.baseValue, to: Base.ColumnIndex(index + 1))
        }
        return stmt
    }

    static func fetchObjects(
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

        let (sql, params) = (query.sql, query.params)
        let stmt = try _statement(in: database, with: sql, params: params)
        defer {
            database.pushStatement(stmt, forKey: sql)
        }

        var objects = [Self]()
        var ret: SQLiteExecuteCode
        repeat {
            ret = try stmt.step()
            if ret == SQLITE_ROW,
                let row = stmt.readRow(),
                let obj: Self = try? TableDecoder.default.decode(Self.self, from: row)
            {
                objects.append(obj)
            }
        } while ret == SQLITE_ROW

        return objects
    }

    static func fetchObject(
        from database: Database,
        on columns: [ResultColumn] = [ResultColumn.all],
        where condition: Condition? = nil,
        orderBy orderTerms:[Base.OrderTerm]? = nil) throws -> Self?
    {
        try fetchObjects(from: database, on: columns, where: condition, orderBy: orderTerms, limit: 1, offset: nil).first
    }

    static func fetchColumn(
        from database: Database,
        on column: ResultColumn,
        where condition: Condition? = nil,
        orderBy orderTerms:[Base.OrderTerm]? = nil,
        limit: Int? = nil,
        offset: Int? = nil) throws -> [BaseValueConvertible]
    {
        if case .all = column {
            throw SQLiteError.ParameterError.notValid
        }

        var query = Select(from: self.tableName, on: [column])
        query.whereCondtion = condition
        query.orderTerms = orderTerms
        query.limit = limit
        query.offset = offset

        let (sql, params) = (query.sql, query.params)
        let stmt = try _statement(in: database, with: sql, params: params)
        defer {
            database.pushStatement(stmt, forKey: sql)
        }

        var values = [BaseValueConvertible]()
        var ret: SQLiteExecuteCode
        repeat {
            ret = try stmt.step()
            if ret == SQLITE_ROW, let col = stmt.readColumn(at: 0) {
                values.append(col)
            }
        } while ret == SQLITE_ROW

        return values
    }
}
