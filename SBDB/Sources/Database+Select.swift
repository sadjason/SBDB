//
//  Database+Select.swift
//  SBDB
//
//  Created by zhangwei on 2019/11/22.
//  Copyright © 2019 ByteDance. All rights reserved.
//

import Foundation

extension Database {
    
    private func _select<T: TableDecodable>(
        _ type: T.Type,
        where condition: Expr.Condition?,
        orderBy orderTerms: [OrderTermConvertiable]?,
        limit: Int?,
        offset: Int?
    ) throws -> [T]
    {
        var stmt = Stmt.Select(from: type.tableName, on: [Expr.Column.all])
        stmt.whereCondtion = condition
        stmt.orderTerms = orderTerms
        stmt.limit = limit
        stmt.offset = offset

        var objects = [T]()
        try exec(sql: stmt.sql, withParams: stmt.params) { (_, row, _) in
            if let obj = try? TableDecoder.default.decode(type, from: row) {
                objects.append(obj)
            }
        }

        return objects
    }
    
    private func _selectColumns(
        from tableName: String,
        on columns: [SelectTermConvertiable],
        where condition: Expr.Condition?,
        orderBy orderTerms: [OrderTermConvertiable]?,
        limit: Int?,
        offset: Int?
    ) throws -> Array<RowStorage>
    {
        var stmt = Stmt.Select(from: tableName, on: columns)
        stmt.whereCondtion = condition
        stmt.orderTerms = orderTerms
        stmt.limit = limit
        stmt.offset = offset

        var rows = [RowStorage]()
        try exec(sql: stmt.sql, withParams: stmt.params) { (_, row, _) in
            rows.append(row)
        }

        return rows
    }
    
    private func _selectOneColumn(
        from tableName: String,
        on column: SelectTermConvertiable,
        where condition: Expr.Condition?,
        orderBy orderTerms: [OrderTermConvertiable]?,
        limit: Int?,
        offset: Int?
    ) throws -> Array<RowStorage>
    {
        try _selectColumns(from: tableName,
                           on: [column],
                           where: condition,
                           orderBy: orderTerms,
                           limit: limit,
                           offset: offset)
    }
}

// MARK: Select Records

extension Database {
    
    public func select<T: TableDecodable>(
        from tableType: T.Type,
        where condition: Expr.Condition? = nil,
        orderBy orderTerms: [OrderTermConvertiable]? = nil,
        limit: Int? = nil,
        offset: Int? = nil
    ) throws -> [T]
    {
        try _select(tableType, where: condition, orderBy: orderTerms, limit: limit, offset: offset)
    }
    
    public func select<T: TableDecodable>(
        from tableType: T.Type,
        where condition: Expr.Condition,
        orderBy orderTerms: OrderTermConvertiable...
    ) throws -> [T]
    {
        try _select(tableType, where: condition, orderBy: orderTerms, limit: nil, offset: nil)
    }
    
    public func select<T: TableDecodable>(
        from tableType: T.Type,
        orderBy orderTerms: OrderTermConvertiable...
    ) throws -> [T]
    {
        try _select(tableType, where: nil, orderBy: orderTerms, limit: nil, offset: nil)
    }
    
    public func select<T: TableDecodable>(
        from tableType: T.Type
    ) throws -> [T]
    {
        try _select(tableType, where: nil, orderBy: nil, limit: nil, offset: nil)
    }
}

// MARK: Select One Row

extension Database {
    
    public func selectOne<T: TableDecodable>(
        from tableType: T.Type,
        where condition: Expr.Condition? = nil,
        orderBy orderTerms: [OrderTermConvertiable]? = nil
    ) throws -> T?
    {
        try _select(tableType, where: condition, orderBy: orderTerms, limit: 1, offset: nil).first
    }
    
    public func selectOne<T: TableDecodable>(
        from tableType: T.Type,
        where condition: Expr.Condition,
        orderBy orderTerms: OrderTermConvertiable...
    ) throws -> T?
    {
        try _select(tableType, where: condition, orderBy: orderTerms, limit: 1, offset: nil).first
    }
    
    public func selectOne<T: TableDecodable>(
        from tableType: T.Type,
        orderBy orderTerms: OrderTermConvertiable...
    ) throws -> T?
    {
        try _select(tableType, where: nil, orderBy: orderTerms, limit: 1, offset: nil).first
    }
    
    public func selectOne<T: TableDecodable>(
        from tableType: T.Type
    ) throws -> T?
    {
        try _select(tableType, where: nil, orderBy: nil, limit: 1, offset: nil).first
    }
}

// MARK: Select Columns

extension Database {
    
    public func selectColumns(
        from tableName: String,
        on columns: [SelectTermConvertiable],
        where condition: Expr.Condition? = nil,
        orderBy orderTerms: [OrderTermConvertiable]? = nil,
        limit: Int? = nil,
        offset: Int? = nil
    ) throws -> [RowStorage]
    {
        try _selectColumns(from: tableName,
                           on: columns,
                           where: condition,
                           orderBy: orderTerms,
                           limit: limit,
                           offset: offset)
    }
    
    public func selectColumns<T: TableDecodable>(
        from tableType: T.Type,
        on columns: [SelectTermConvertiable],
        where condition: Expr.Condition? = nil,
        orderBy orderTerms: [OrderTermConvertiable]? = nil,
        limit: Int? = nil,
        offset: Int? = nil
    ) throws -> [RowStorage]
    {
        try _selectColumns(from: tableType.tableName,
                           on: columns,
                           where: condition,
                           orderBy: orderTerms,
                           limit: limit,
                           offset: offset)
    }
    
    public func selectColumns<T: TableDecodable>(
        from tableType: T.Type,
        on columns: [SelectTermConvertiable],
        where condition: Expr.Condition,
        orderBy orderTerms: OrderTermConvertiable...
    ) throws -> [RowStorage]
    {
        try _selectColumns(from: tableType.tableName,
                           on: columns,
                           where: condition,
                           orderBy: orderTerms,
                           limit: nil,
                           offset: nil)
    }
    
    public func selectColumns<T: TableDecodable>(
        from tableType: T.Type,
        on columns: [SelectTermConvertiable],
        orderBy orderTerms: OrderTermConvertiable...
    ) throws -> [RowStorage]
    {
        try _selectColumns(from: tableType.tableName,
                           on: columns,
                           where: nil,
                           orderBy: orderTerms,
                           limit: nil,
                           offset: nil)
    }
    
    public func selectColumns<T: TableDecodable>(
        from tableType: T.Type,
        on columns: [SelectTermConvertiable]
    ) throws -> [RowStorage]
    {
        try _selectColumns(from: tableType.tableName,
                           on: columns,
                           where: nil,
                           orderBy: nil,
                           limit: nil,
                           offset: nil)
    }
}

extension Database {
    
    public func selectOneColumn(
        from tableName: String,
        on column: SelectTermConvertiable,
        where condition: Expr.Condition? = nil,
        orderBy orderTerms: [OrderTermConvertiable]? = nil,
        limit: Int? = nil,
        offset: Int? = nil
    ) throws -> [ColumnValueConvertible]
    {
        let rows = try _selectOneColumn(from: tableName,
                                        on: column,
                                        where: condition,
                                        orderBy: orderTerms,
                                        limit: limit,
                                        offset: offset)
        return rows.map { $0.values.first ?? ColumnValue.null }
    }
    
    public func selectOneColumn<T: TableDecodable>(
        from tableType: T.Type,
        on column: SelectTermConvertiable,
        where condition: Expr.Condition? = nil,
        orderBy orderTerms: [OrderTermConvertiable]? = nil,
        limit: Int? = nil,
        offset: Int? = nil
    ) throws -> [ColumnValueConvertible]
    {
        let rows = try _selectOneColumn(from: tableType.tableName,
                                        on: column,
                                        where: condition,
                                        orderBy: orderTerms,
                                        limit: limit,
                                        offset: offset)
        return rows.map { $0.values.first ?? ColumnValue.null }
    }
    
    public func selectOneColumn<T: TableDecodable>(
        from tableType: T.Type,
        on column: SelectTermConvertiable,
        where condition: Expr.Condition,
        orderBy orderTerms: OrderTermConvertiable...
    ) throws -> [ColumnValueConvertible]
    {
        try selectOneColumn(from: tableType.tableName, on: column, where: condition, orderBy: orderTerms)
    }
    
    public func selectOneColumn<T: TableDecodable>(
        from tableType: T.Type,
        on column: SelectTermConvertiable,
        where condition: Expr.Condition
    ) throws -> [ColumnValueConvertible]
    {
        try selectOneColumn(from: tableType.tableName, on: column, where: condition, orderBy: nil)
    }
    
    public func selectOneColumn<T: TableDecodable>(
        from tableType: T.Type,
        on column: SelectTermConvertiable
    ) throws -> [ColumnValueConvertible]
    {
        try selectOneColumn(from: tableType.tableName, on: column, where: nil, orderBy: nil)
    }
}
