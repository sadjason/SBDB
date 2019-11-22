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
    
    init(type: T.Type, options: Table.CreateOptions) throws {
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

extension TableCreation where T: KeyPathToColumnNameConvertiable {
    
    public mutating func setPrimaryKey(_ keyPaths: PartialKeyPath<T>...) {
        let indexedColumns = keyPaths
            .map { T.columnName(of: $0) }
            .filter { $0 != nil }
            .map { Table.IndexedColumn($0!) }
        
        guard indexedColumns.count == keyPaths.count else {
            assert(false, "some error happend")
            return
        }
        
        stmt.setPrimaryKey(indexedColumns, onConflict: nil)
    }
    
    public mutating func setUnique(_ keyPaths: PartialKeyPath<T>...) {
        let indexedColumns = keyPaths
            .map { T.columnName(of: $0) }
            .filter { $0 != nil }
            .map { Table.IndexedColumn($0!) }
        
        guard indexedColumns.count == keyPaths.count else {
            assert(false, "some error happend")
            return
        }
        
        stmt.setUnique(indexedColumns, onConflict: nil)
    }
}

extension Database {
    
    public func createTable<T: TableDecodable>(
        _ tableType: T.Type,
        options: Table.CreateOptions = [],
        closure: ((inout TableCreation<T>) -> Void)? = nil
    ) throws
    {
        var creation = try TableCreation(type: tableType.self, options: options)
        closure?(&creation)
        try creation.stmt.exec(in: self)
    }
    
    public func createTable(_ tableName: String, closure: (inout CreateTableStatement) -> Void) throws {
        var statement = CreateTableStatement(name: tableName)
        closure(&statement)
        try statement.exec(in: self)
    }
    
}

// MARK: Drop Table

extension Database {
    
    public func dropTable<T: CustomTableNameConvertible>(_ tableType: T.Type) throws {
        try DropTableStatement(name: tableType.tableName).exec(in: self)
    }
    
    public func dropTable(_ tableName: String) throws {
        try DropTableStatement(name: tableName).exec(in: self)
    }
}

// MARK: Create Index

extension Database {
    
    public func createIndex(
        _ name: String,
        on table: String,
        columns: [Table.IndexedColumn],
        options: Table.CreateIndexOptions = [.ifNotExists, .unique]
    ) throws
    {
        var stmt = CreateTableIndexStatement(name: name, table: table, options: options)
        stmt.columns = columns
        try exec(sql: stmt.sql, withParams: stmt.params)
    }
    
    public func dropIndex(_ name: String) throws {
        try DropTableIndexStatement(name: name).exec(in: self)
    }
}

extension Database {
    
    public func createIndex<T: CustomTableNameConvertible & KeyPathToColumnNameConvertiable>(
        _ name: String,
        on table: T.Type,
        keyPaths: [PartialKeyPath<T>],
        options: Table.CreateIndexOptions = [.ifNotExists, .unique]
    ) throws {
        var stmt = CreateTableIndexStatement(name: name, table: table.tableName, options: options)
        
        let columns = keyPaths.map { table.columnName(of: $0) ?? "" }
            .filter { $0.count > 0 }
            .map { Table.IndexedColumn($0) }
        guard columns.count == keyPaths.count else {
            throw SQLiteError.misuse("can not map string from keyPath")
        }
        
        stmt.columns = columns
        try stmt.exec(in: self)
    }
}
