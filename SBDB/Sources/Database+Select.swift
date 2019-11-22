//
//  Database+Select.swift
//  SBDB
//
//  Created by zhangwei on 2019/11/22.
//  Copyright © 2019 zhangwei. All rights reserved.
//

import Foundation

extension Database {
    
    private func _select<T: TableDecodable>(
        _ type: T.Type,
        on columns: [SelectColumn],
        where condition: Condition?,
        orderBy orderTerms: [Base.OrderTerm]?,
        limit: Int?,
        offset: Int?
    ) throws -> [T]
    {
        var stmt = SelectStatement(from: type.tableName, on: columns)
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
}

// MARK: Select Records

extension Database {

    public func select<T: TableDecodable>(from tableType: T.Type) throws -> [T] {
        try _select(tableType, on: [.all], where: nil, orderBy: nil, limit: nil, offset: nil)
    }
    
    public func select<T: TableDecodable>(
        from tableType: T.Type,
        where condition: Condition
    ) throws -> [T]
    {
        try _select(tableType, on: [.all], where: condition, orderBy: nil, limit: nil, offset: nil)
    }
    
    public func select<T: TableDecodable>(
        from tableType: T.Type,
        orderBy orderTerms: [Base.OrderTerm]
    ) throws -> [T]
    {
        try _select(tableType, on: [.all], where: nil, orderBy: orderTerms, limit: nil, offset: nil)
    }
    
    public func select<T: TableDecodable>(
        from tableType: T.Type,
        orderBy orderTerms: Base.OrderTerm...
    ) throws -> [T]
    {
        try _select(tableType, on: [.all], where: nil, orderBy: orderTerms, limit: nil, offset: nil)
    }
    
    public func select<T: TableDecodable>(
        from tableType: T.Type,
        where condition: Condition,
        orderBy orderTerms: [Base.OrderTerm]
    ) throws -> [T]
    {
        try _select(tableType, on: [.all], where: condition, orderBy: orderTerms, limit: nil, offset: nil)
    }
    
    public func select<T: TableDecodable>(
        from tableType: T.Type,
        where condition: Condition,
        orderBy orderTerms: Base.OrderTerm...
    ) throws -> [T]
    {
        try _select(tableType, on: [.all], where: condition, orderBy: orderTerms, limit: nil, offset: nil)
    }
    
    public func select<T: TableDecodable & TableCodingKeyConvertiable>(
        from tableType: T.Type,
        orderBy keyPaths: PartialKeyPath<T>...
    ) throws -> [T]
    {
        let orderTerms = keyPaths.map { Base.OrderTerm(column: $0.stringValue) }
        return try _select(tableType, on: [.all], where: nil, orderBy: orderTerms, limit: nil, offset: nil)
    }
    
    public func select<T: TableDecodable & TableCodingKeyConvertiable>(
        from tableType: T.Type,
        where condition: Condition,
        orderBy keyPaths: PartialKeyPath<T>...
    ) throws -> [T]
    {
        let orderTerms = keyPaths.map { Base.OrderTerm(column: $0.stringValue) }
        return try _select(tableType, on: [.all], where: condition, orderBy: orderTerms, limit: nil, offset: nil)
    }
}

// MARK: Select One Record

extension Database {
    
    public func selectOne<T: TableDecodable>(from tableType: T.Type) throws -> T? {
        try _select(tableType, on: [.all], where: nil, orderBy: nil, limit: 1, offset: nil).first
    }
    
    public func selectOne<T: TableDecodable>(
        from tableType: T.Type,
        where condition: Condition
    ) throws -> T?
    {
        try _select(tableType, on: [.all], where: condition, orderBy: nil, limit: 1, offset: nil).first
    }
    
    public func selectOne<T: TableDecodable>(
        from tableType: T.Type,
        orderBy orderTerms: [Base.OrderTerm]
    ) throws -> T?
    {
        try _select(tableType, on: [.all], where: nil, orderBy: orderTerms, limit: 1, offset: nil).first
    }
    
    public func selectOne<T: TableDecodable>(
        from tableType: T.Type,
        where condition: Condition,
        orderBy orderTerms: [Base.OrderTerm]
    ) throws -> T?
    {
        try _select(tableType, on: [.all], where: condition, orderBy: orderTerms, limit: 1, offset: nil).first
    }
    
    public func selectOne<T: TableDecodable & TableCodingKeyConvertiable>(
        from tableType: T.Type,
        orderBy keyPaths: PartialKeyPath<T>...
    ) throws -> T?
    {
        let orderTerms = keyPaths.map { Base.OrderTerm(column: $0.stringValue) }
        return try _select(tableType, on: [.all], where: nil, orderBy: orderTerms, limit: 1, offset: nil).first
    }
    
    public func selectOne<T: TableDecodable & TableCodingKeyConvertiable>(
        from tableType: T.Type,
        where condition: Condition,
        orderBy keyPaths: PartialKeyPath<T>...
    ) throws -> T?
    {
        let orderTerms = keyPaths.map { Base.OrderTerm(column: $0.stringValue) }
        return try _select(tableType, on: [.all], where: condition, orderBy: orderTerms, limit: 1, offset: nil).first
    }
}
