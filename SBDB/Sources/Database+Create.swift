//
//  Database+Create.swift
//  SBDB
//
//  Created by SadJason on 2019/11/21.
//  Copyright © 2019 SadJason. All rights reserved.
//

import Foundation

// MARK: Create Table

public struct TableCreation<T: TableDecodable> {
    
    private let type: T.Type
    fileprivate var stmt: Stmt.CreateTable
    
    init(type: T.Type, options: CreateTableOptions) throws {
        self.type = type
        stmt = Stmt.CreateTable(name: type.tableName)
        stmt.ifNotExists = options.contains(.ifNotExists)
        stmt.withoutRowId = options.contains(.withoutRowId)
        try TableColumnDecoder.default.decode(type.self).values.forEach { structure in
            let col = stmt.addColumn(structure.name, type: structure.type)
            if structure.nonnull {
                col.notNull()
            }
        }
    }
    
    func column(forName name: String) -> Expr.Column.Definition? {
        stmt.column(forName: name)
    }
    
}

extension TableCreation {
    
    public mutating func setPrimaryKey(
        withColumns columns: [CreateTableColumn],
        onConflict: Expr.Conflict?
    ) {
        stmt.setPrimaryKey(withColumns: columns, onConflict: onConflict)
    }
    
    public mutating func setPrimaryKey(withColumns columnNames: [String]) {
        stmt.setPrimaryKey(withColumns: columnNames.map { CreateTableColumn($0) }, onConflict: nil)
    }
    
    public mutating func setUnique(
        withColumns columns: [CreateTableColumn],
        onConflict: Expr.Conflict?
    ) {
        stmt.setUnique(withColumns: columns, onConflict: onConflict)
    }
    
    public mutating func setUnique(withColumns columnNames: [String]) {
        stmt.setUnique(withColumns: columnNames.map { CreateTableColumn($0) }, onConflict: nil)
    }
}

extension TableCreation where T: TableCodingKeyConvertiable {
    
    public func column(forKeyPath keyPath: PartialKeyPath<T>) -> Expr.Column.Definition? {
        stmt.column(forName: T.codingKey(forKeyPath: keyPath).stringValue)
    }
    
    public mutating func setPrimaryKey(withKeyPath keyPaths: PartialKeyPath<T>...) {
        let indexedColumns = keyPaths.map { CreateTableColumn($0.stringValue) }
        
        guard indexedColumns.count == keyPaths.count else {
            assert(false, "some error happend")
            return
        }
        
        stmt.setPrimaryKey(withColumns: indexedColumns, onConflict: nil)
    }
    
    public mutating func setUnique(withKeyPath keyPaths: PartialKeyPath<T>...) {
        let indexedColumns = keyPaths.map { CreateTableColumn($0.stringValue) }
        
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
    ) throws {
        var creation = try TableCreation(type: tableType.self, options: options)
        closure?(&creation)
        try creation.stmt.exec(in: self)
    }
    
}

// MARK: Drop Table

extension Database {
    
    public func dropTable<T: CustomTableNameConvertible>(
        _ tableType: T.Type, ifExists: Bool = true
    ) throws {
        try Stmt.DropTable(tableType.tableName, ifExists: ifExists).exec(in: self)
    }
    
    public func dropTable(_ tableName: String, ifExists: Bool = true) throws {
        try Stmt.DropTable(tableName, ifExists: ifExists).exec(in: self)
    }
}

// MARK: Create Index

extension Database {
    
    public func createIndex(
        _ name: String,
        on table: String,
        columns: [CreateTableColumn],
        options: CreateIndexOptions = [.ifNotExists, .unique]
    ) throws {
        var stmt = Stmt.CreateIndex(name: name, table: table, options: options)
        stmt.columns = columns
        try exec(sql: stmt.sql, withParams: stmt.params)
    }
    
    public func dropIndex(_ name: String) throws {
        try Stmt.DropIndex(name: name).exec(in: self)
    }
}

extension Database {
    
    public func createIndex<T: CustomTableNameConvertible & TableCodingKeyConvertiable>(
        _ name: String,
        on table: T.Type,
        keyPaths: [PartialKeyPath<T>],
        options: CreateIndexOptions = [.ifNotExists, .unique]
    ) throws {
        var stmt = Stmt.CreateIndex(name: name, table: table.tableName, options: options)
        
        let columns = keyPaths.map { CreateTableColumn($0.stringValue) }
        guard columns.count == keyPaths.count else {
            throw SQLiteError.misuse("can not map string from keyPath")
        }
        
        stmt.columns = columns
        try stmt.exec(in: self)
    }
}
