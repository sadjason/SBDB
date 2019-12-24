//
//  Database+Update.swift
//  SBDB
//
//  Created by SadJason on 2019/11/22.
//  Copyright © 2019 SadJason. All rights reserved.
//

import Foundation

// MARK: Insert

extension Database {
    
    public func insert<T: TableEncodable>(_ objects: Array<T>, withMode mode: InsertMode) throws {
        
        let encoder = TableEncoder.default
        for object in objects {
            let row = try encoder.encode(object)
            let stmt = Stmt.Insert(table: T.tableName, row: row, mode: mode)
            try stmt.exec(in: self)
        }
    }
    
    public func insert<T: TableEncodable>(_ objects: T...) throws {
        try insert(objects, withMode: .insert)
    }
    
    public func insert<T: TableEncodable>(_ objects: Array<T>) throws {
        try insert(objects, withMode: .insert)
    }
    
    public func upsert<T: TableEncodable>(_ objects: T...) throws {
        try insert(objects, withMode: .insertOr(Expr.Conflict.replace))
    }
    
    public func upsert<T: TableEncodable>(_ objects: Array<T>) throws {
        try insert(objects, withMode: .insertOr(Expr.Conflict.replace))
    }
}

// MARK: Update

extension Stmt.Update {
    
    public typealias AssignHandler<Root> = (PartialKeyPath<Root>, ColumnValueConvertible) -> Void
}

extension Database {
    
    public func update(
        table tableName: String,
        withMode mode: UpdateMode,
        assignment: UpdateAssignment,
        where condition: Expr.Condition?
    ) throws
    {
        try Stmt.Update(table: tableName,
                        assigment: assignment,
                        mode: mode,
                        where: condition)
            .exec(in: self)
    }
    
    public func update<T: TableEncodable & TableCodingKeyConvertiable>(
        table tableType: T.Type,
        withMode mode: UpdateMode,
        where condition: Expr.Condition? = nil,
        assign: (Stmt.Update.AssignHandler<T>) -> Void
    ) throws {
        var assignment = UpdateAssignment()
        
        let handler: Stmt.Update.AssignHandler<T> = { assignment[$0.stringValue] = $1}
        assign(handler)
        
        try update(table: tableType.tableName, withMode: mode, assignment: assignment, where: condition)
    }
    
    public func update<T: TableEncodable & TableCodingKeyConvertiable>(
        _ tableType: T.Type,
        where condition: Expr.Condition? = nil,
        assign: (Stmt.Update.AssignHandler<T>) -> Void
    ) throws
    {
        try update(table: tableType, withMode: .update, where: condition, assign: assign)
    }
}

// MARK: Delete

extension Database {
    
    public func delete(from tableName: String, where condition: Expr.Condition? = nil) throws {
        try Stmt.Delete(table: tableName, where: condition).exec(in: self)
    }
    
    public func delete(
        from table: CustomTableNameConvertible.Type,
        where condition: Expr.Condition? = nil
    ) throws {
        try Stmt.Delete(table: table.tableName, where: condition).exec(in: self)
    }
}
