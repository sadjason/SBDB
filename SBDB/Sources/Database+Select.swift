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
        orderBy orderTerms: [Expr.OrderTerm]?,
        limit: Int?,
        offset: Int?
    ) throws -> [T]
    {
        var stmt = Stmt.Select(from: type.tableName, on: [.all])
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
        on columns: [SelectColumn],
        where condition: Expr.Condition?,
        orderBy orderTerms: [Expr.OrderTerm]?,
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
}

// MARK: Select Records

extension Database {

    public func select<T: TableDecodable>(from tableType: T.Type) throws -> [T] {
        try _select(tableType, where: nil, orderBy: nil, limit: nil, offset: nil)
    }
    
    public func select<T: TableDecodable>(
        from tableType: T.Type,
        where condition: Expr.Condition
    ) throws -> [T]
    {
        try _select(tableType, where: condition, orderBy: nil, limit: nil, offset: nil)
    }
    
    public func select<T: TableDecodable>(
        from tableType: T.Type,
        orderBy orderTerms: [Expr.OrderTerm]
    ) throws -> [T]
    {
        try _select(tableType, where: nil, orderBy: orderTerms, limit: nil, offset: nil)
    }
    
    public func select<T: TableDecodable>(
        from tableType: T.Type,
        orderBy orderTerms: Expr.OrderTerm...
    ) throws -> [T]
    {
        try _select(tableType, where: nil, orderBy: orderTerms, limit: nil, offset: nil)
    }
    
    public func select<T: TableDecodable>(
        from tableType: T.Type,
        where condition: Expr.Condition,
        orderBy orderTerms: [Expr.OrderTerm]
    ) throws -> [T]
    {
        try _select(tableType, where: condition, orderBy: orderTerms, limit: nil, offset: nil)
    }
    
    public func select<T: TableDecodable>(
        from tableType: T.Type,
        where condition: Expr.Condition,
        orderBy orderTerms: Expr.OrderTerm...
    ) throws -> [T]
    {
        try _select(tableType, where: condition, orderBy: orderTerms, limit: nil, offset: nil)
    }
    
    public func select<T: TableDecodable & TableCodingKeyConvertiable>(
        from tableType: T.Type,
        orderBy keyPaths: PartialKeyPath<T>...
    ) throws -> [T]
    {
        let orderTerms = keyPaths.map { Expr.OrderTerm(column: $0.stringValue) }
        return try _select(tableType, where: nil, orderBy: orderTerms, limit: nil, offset: nil)
    }
    
    public func select<T: TableDecodable & TableCodingKeyConvertiable>(
        from tableType: T.Type,
        where condition: Expr.Condition,
        orderBy keyPaths: PartialKeyPath<T>...
    ) throws -> [T]
    {
        let orderTerms = keyPaths.map { Expr.OrderTerm(column: $0.stringValue) }
        return try _select(tableType, where: condition, orderBy: orderTerms, limit: nil, offset: nil)
    }
}

// MARK: Select One Record

extension Database {
    
    public func selectOne<T: TableDecodable>(from tableType: T.Type) throws -> T? {
        try _select(tableType, where: nil, orderBy: nil, limit: 1, offset: nil).first
    }
    
    public func selectOne<T: TableDecodable>(
        from tableType: T.Type,
        where condition: Expr.Condition
    ) throws -> T?
    {
        try _select(tableType, where: condition, orderBy: nil, limit: 1, offset: nil).first
    }
    
    public func selectOne<T: TableDecodable>(
        from tableType: T.Type,
        orderBy orderTerms: [Expr.OrderTerm]
    ) throws -> T?
    {
        try _select(tableType, where: nil, orderBy: orderTerms, limit: 1, offset: nil).first
    }
    
    public func selectOne<T: TableDecodable>(
        from tableType: T.Type,
        orderBy orderTerms: Expr.OrderTerm...
    ) throws -> T?
    {
        try _select(tableType, where: nil, orderBy: orderTerms, limit: 1, offset: nil).first
    }
    
    public func selectOne<T: TableDecodable>(
        from tableType: T.Type,
        where condition: Expr.Condition,
        orderBy orderTerms: [Expr.OrderTerm]
    ) throws -> T?
    {
        try _select(tableType, where: condition, orderBy: orderTerms, limit: 1, offset: nil).first
    }
    
    public func selectOne<T: TableDecodable>(
        from tableType: T.Type,
        where condition: Expr.Condition,
        orderBy orderTerms: Expr.OrderTerm...
    ) throws -> T?
    {
        try _select(tableType, where: condition, orderBy: orderTerms, limit: 1, offset: nil).first
    }
    
    public func selectOne<T: TableDecodable & TableCodingKeyConvertiable>(
        from tableType: T.Type,
        orderBy keyPaths: [PartialKeyPath<T>]
    ) throws -> T?
    {
        let orderTerms = keyPaths.map { Expr.OrderTerm(column: $0.stringValue) }
        return try _select(tableType, where: nil, orderBy: orderTerms, limit: 1, offset: nil).first
    }
    
    public func selectOne<T: TableDecodable & TableCodingKeyConvertiable>(
        from tableType: T.Type,
        orderBy keyPaths: PartialKeyPath<T>...
    ) throws -> T?
    {
        let orderTerms = keyPaths.map { Expr.OrderTerm(column: $0.stringValue) }
        return try _select(tableType, where: nil, orderBy: orderTerms, limit: 1, offset: nil).first
    }
    
    public func selectOne<T: TableDecodable & TableCodingKeyConvertiable>(
        from tableType: T.Type,
        where condition: Expr.Condition,
        orderBy keyPaths: [PartialKeyPath<T>]
    ) throws -> T?
    {
        let orderTerms = keyPaths.map { Expr.OrderTerm(column: $0.stringValue) }
        return try _select(tableType, where: condition, orderBy: orderTerms, limit: 1, offset: nil).first
    }
    
    public func selectOne<T: TableDecodable & TableCodingKeyConvertiable>(
        from tableType: T.Type,
        where condition: Expr.Condition,
        orderBy keyPaths: PartialKeyPath<T>...
    ) throws -> T?
    {
        let orderTerms = keyPaths.map { Expr.OrderTerm(column: $0.stringValue) }
        return try _select(tableType, where: condition, orderBy: orderTerms, limit: 1, offset: nil).first
    }
}

// MARK: Select Columns

extension Database {
    
    public func selectColumns(
        from tableName: String,
        on columns: [SelectColumn]
    ) throws ->  [RowStorage] {
        try _selectColumns(from: tableName, on: columns, where: nil, orderBy: nil, limit: nil, offset: nil)
    }
    
    public func selectColumns(
        from tableName: String,
        on columns: [SelectColumn],
        where condition: Expr.Condition
    ) throws -> [RowStorage]
    {
        try _selectColumns(from: tableName, on: columns, where: condition, orderBy: nil, limit: nil, offset: nil)
    }
    
    public func selectColumns(
        from tableName: String,
        on columns: [SelectColumn],
        orderBy orderTerms: [Expr.OrderTerm]
    ) throws -> [RowStorage]
    {
        try _selectColumns(from: tableName, on: columns, where: nil, orderBy: orderTerms, limit: nil, offset: nil)
    }
    
    public func selectColumns(
        from tableName: String,
        on columns: [SelectColumn],
        orderBy orderTerms: Expr.OrderTerm...
    ) throws -> [RowStorage]
    {
        try _selectColumns(from: tableName, on: columns, where: nil, orderBy: orderTerms, limit: nil, offset: nil)
    }
    
    public func selectColumns(
        from tableName: String,
        on columns: [SelectColumn],
        where condition: Expr.Condition,
        orderBy orderTerms: [Expr.OrderTerm]
    ) throws -> [RowStorage]
    {
        try _selectColumns(from: tableName, on: columns, where: condition, orderBy: orderTerms, limit: nil, offset: nil)
    }
 
    public func selectColumns<T: TableDecodable & TableCodingKeyConvertiable>(
        from tableType: T.Type,
        on columns: [SelectColumn],
        where condition: Expr.Condition
    ) throws -> [RowStorage]
    {
        try _selectColumns(from: tableType.tableName, on: columns, where: condition, orderBy: nil, limit: nil, offset: nil)
    }
    
    public func selectColumns<T: TableDecodable & TableCodingKeyConvertiable>(
        from tableType: T.Type,
        on columns: [SelectColumn],
        orderBy keyPaths: [PartialKeyPath<T>]
    ) throws -> [RowStorage]
    {
        let orderTerms = keyPaths.map { Expr.OrderTerm(column: $0.stringValue) }
        return try _selectColumns(from: tableType.tableName, on: columns, where: nil, orderBy: orderTerms, limit: nil, offset: nil)
    }
    
    public func selectColumns<T: TableDecodable & TableCodingKeyConvertiable>(
        from tableType: T.Type,
        on columns: [SelectColumn],
        orderBy keyPaths: PartialKeyPath<T>...
    ) throws -> [RowStorage]
    {
        let orderTerms = keyPaths.map { Expr.OrderTerm(column: $0.stringValue) }
        return try _selectColumns(from: tableType.tableName, on: columns, where: nil, orderBy: orderTerms, limit: nil, offset: nil)
    }
    
    public func selectColumns<T: TableDecodable & TableCodingKeyConvertiable>(
        from tableType: T.Type,
        on columns: [SelectColumn],
        where condition: Expr.Condition,
        orderBy keyPaths: [PartialKeyPath<T>]
    ) throws -> [RowStorage]
    {
        let orderTerms = keyPaths.map { Expr.OrderTerm(column: $0.stringValue) }
        return try _selectColumns(from: tableType.tableName, on: columns, where: condition, orderBy: orderTerms, limit: nil, offset: nil)
    }
    
    public func selectColumns<T: TableDecodable & TableCodingKeyConvertiable>(
        from tableType: T.Type,
        on columns: [SelectColumn],
        where condition: Expr.Condition,
        orderBy keyPaths: PartialKeyPath<T>...
    ) throws -> [RowStorage]
    {
        let orderTerms = keyPaths.map { Expr.OrderTerm(column: $0.stringValue) }
        return try _selectColumns(from: tableType.tableName, on: columns, where: condition, orderBy: orderTerms, limit: nil, offset: nil)
    }
}
