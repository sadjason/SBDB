//
//  Database+Create.swift
//  SBDB
//
//  Created by zhangwei on 2019/11/21.
//  Copyright © 2019 ByteDance. All rights reserved.
//

import Foundation

// MARK: Create Table

public struct TableCreation<T: TableDecodable> {
    
    private let type: T.Type
    fileprivate var stmt: CreateTableStatement
    
    init(type: T.Type, options: CreateTableOptions) throws {
        self.type = type
        stmt = CreateTableStatement(name: type.tableName)
        stmt.ifNotExists = options.contains(.ifNotExists)
        stmt.withoutRowId = options.contains(.withoutRowId)
        try TableColumnDecoder.default.decode(type.self).values.forEach { structure in
            let col = stmt.addColumn(structure.name, type: structure.type)
            if structure.nonnull {
                col.notNull()
            }
        }
    }
}

extension TableCreation {
    public mutating func setPrimaryKey(withColumns columns: [IndexedColumn], onConflict: Base.Conflict?) {
        stmt.setPrimaryKey(withColumns: columns, onConflict: onConflict)
    }
    
    public mutating func setUnique(withColumns columns: [IndexedColumn], onConflict: Base.Conflict?) {
        stmt.setUnique(withColumns: columns, onConflict: onConflict)
    }
}

extension TableCreation where T: TableCodingKeyConvertiable {
    
    public mutating func setPrimaryKey(_ keyPaths: PartialKeyPath<T>...) {
        let indexedColumns = keyPaths.map { IndexedColumn($0.stringValue) }
        
        guard indexedColumns.count == keyPaths.count else {
            assert(false, "some error happend")
            return
        }
        
        stmt.setPrimaryKey(withColumns: indexedColumns, onConflict: nil)
    }
    
    public mutating func setUnique(_ keyPaths: PartialKeyPath<T>...) {
        let indexedColumns = keyPaths.map { IndexedColumn($0.stringValue) }
        
        guard indexedColumns.count == keyPaths.count else {
            assert(false, "some error happend")
            return
        }
        
        stmt.setUnique(withColumns: indexedColumns, onConflict: nil)
    }
}

extension Database {
    
    public func createTable<T: TableDecodable>(
        _ tableType: T.Type,
        options: CreateTableOptions = [],
        closure: ((inout TableCreation<T>) -> Void)? = nil
    ) throws
    {
        var creation = try TableCreation(type: tableType.self, options: options)
        closure?(&creation)
        try creation.stmt.exec(in: self)
    }
    
}

// MARK: Drop Table

extension Database {
    
    public func dropTable<T: CustomTableNameConvertible>(_ tableType: T.Type) throws {
        try DropTableStatement(tableType.tableName).exec(in: self)
    }
    
    public func dropTable(_ tableName: String) throws {
        try DropTableStatement(tableName).exec(in: self)
    }
}

// MARK: Create Index

extension Database {
    
    public func createIndex(
        _ name: String,
        on table: String,
        columns: [IndexedColumn],
        options: CreateIndexOptions = [.ifNotExists, .unique]
    ) throws
    {
        var stmt = CreateIndexStatement(name: name, table: table, options: options)
        stmt.columns = columns
        try exec(sql: stmt.sql, withParams: stmt.params)
    }
    
    public func dropIndex(_ name: String) throws {
        try DropIndexStatement(name: name).exec(in: self)
    }
}

extension Database {
    
    public func createIndex<T: CustomTableNameConvertible & TableCodingKeyConvertiable>(
        _ name: String,
        on table: T.Type,
        keyPaths: [PartialKeyPath<T>],
        options: CreateIndexOptions = [.ifNotExists, .unique]
    ) throws {
        var stmt = CreateIndexStatement(name: name, table: table.tableName, options: options)
        
        let columns = keyPaths.map { IndexedColumn($0.stringValue) }
        guard columns.count == keyPaths.count else {
            throw SQLiteError.misuse("can not map string from keyPath")
        }
        
        stmt.columns = columns
        try stmt.exec(in: self)
    }
}
