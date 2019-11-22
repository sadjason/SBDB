//
//  Database+Update.swift
//  SBDB
//
//  Created by zhangwei on 2019/11/22.
//  Copyright © 2019 ByteDance. All rights reserved.
//

import Foundation

// MARK: Insert

extension Database {
    
    func insert<T: TableEncodable>(_ objects: Array<T>, withMode mode: InsertMode) throws {
        
        guard objects.count > 0 else {
            return
        }

        let encoder = TableEncoder.default
        let rows = try objects.map { try encoder.encode($0) }
        let stmt = InsertStatement(tableName: T.tableName, rows: rows, mode: mode)
        try stmt.exec(in: self)
    }
    
    func insert<T: TableEncodable>(_ objects: T...) throws {
        try insert(objects, withMode: .insert)
    }
    
    func insert<T: TableEncodable>(_ objects: Array<T>) throws {
        try insert(objects, withMode: .insert)
    }
    
    func upsert<T: TableEncodable>(_ objects: T...) throws {
        try insert(objects, withMode: .insertOr(Base.Conflict.replace))
    }
    
    func upsert<T: TableEncodable>(_ objects: Array<T>) throws {
        try insert(objects, withMode: .insertOr(Base.Conflict.replace))
    }
}

// MARK: Update

public typealias AssignHandler<Root> = (PartialKeyPath<Root>, BaseValueConvertible) -> Void

extension Database {
    
    public func update(
        table tableName: String,
        withMode mode: UpdateMode,
        assignment: UpdateAssignment,
        where condition: Condition?
    ) throws
    {
        try UpdateStatement(tableName: tableName,
                            assigment: assignment,
                            mode: mode,
                            where: condition)
            .exec(in: self)
    }
    
    public func update<T: TableEncodable & KeyPathToColumnNameConvertiable>(
        table tableType: T.Type,
        withMode mode: UpdateMode,
        where condition: Condition? = nil,
        assign: (AssignHandler<T>) -> Void
    ) throws
    {
        var assignment = UpdateAssignment()
        
        let handler: AssignHandler<T> = { (k, v) in
            guard let key = k.hashString() else {
                return
            }
            assignment[key] = v
        }
        assign(handler)
        
        try update(table: tableType.tableName, withMode: mode, assignment: assignment, where: condition)
    }
    
    public func update<T: TableEncodable & KeyPathToColumnNameConvertiable>(
        _ tableType: T.Type,
        where condition: Condition? = nil,
        assign: (AssignHandler<T>) -> Void
    ) throws
    {
        try update(table: tableType, withMode: .update, where: condition, assign: assign)
    }
}

// MARK: Delete

extension Database {
    
    func delete(from tableName: String, where condition: Condition? = nil) throws {
        try DeleteStatement(tableName: tableName, where: condition).exec(in: self)
    }
    
    func delete(from table: CustomTableNameConvertible.Type, where condition: Condition? = nil) throws {
        try DeleteStatement(tableName: table.tableName, where: condition).exec(in: self)
    }
}

// MARK: 
