//
//  Table.swift
//  SBDB
//
//  Created by zhangwei on 2019/10/20.
//  Copyright © 2019 ByteDance. All rights reserved.
//

import Foundation

public enum Table {
    
    // MARK: IndexedColumn

    /// https://www.sqlite.org/syntax/indexed-column.html
    public struct IndexedColumn: Expression {
        let columnName: Base.ColumnName
        let collate: Base.Collate?
        let order: Base.Order?
        
        init(_ name: String) {
            columnName = name
            collate = nil
            order = nil
        }

        var sql: String {
            var str = columnName
            str += (collate != nil ? " collate \(collate!.sql)" : "")
            str += (order != nil ? order!.sql : "")
            return str
        }
    }
    
    // MARK: Contraint

    public enum Constraint: Expression {
        case primaryKey(Array<IndexedColumn>, Base.Conflict?)
        case unique(Array<IndexedColumn>, Base.Conflict?)

        // TODO: support foreign key
        // TODO: support check

        var sql: String {
            let command: String
            let indexedColumns: Array<IndexedColumn>
            let onConflict: Base.Conflict?
            switch self {
            case let .primaryKey(value1, value2):
                (command, indexedColumns, onConflict) = ("primary key", value1, value2)
            case let .unique(value1, value2):
                (command, indexedColumns, onConflict) = ("unique", value1, value2)
            }
            let indexedColumnStr = indexedColumns.map { $0.sql }.joined(separator: ",")
            var str = "\(command) (\(indexedColumnStr))"
            if let onConflict = onConflict {
                str += "on conflict \(onConflict.sql)"
            }
            return str
        }
    }
    
    public struct CreateOptions: OptionSet {
        public let rawValue: Int32
        public init(rawValue: Int32) {
            self.rawValue = rawValue
        }
        
        public static let ifNotExists = CreateOptions(rawValue: 1)
        public static let withoutRowId = CreateOptions(rawValue: 1<<1)
    }
}

extension Table {

    // https://www.sqlite.org/lang_createtable.html
    public struct CreateStatement: ParameterExpression {
        
        let name: String
        var columns: [ColumnDefinition] = []
        var constraints: [Table.Constraint] = []

        public var ifNotExists: Bool?
        public var withoutRowId: Bool?

        public init(name: String) {
            self.name = name
        }

        @discardableResult
        mutating public func addColumn(_ name: String, type: ColumnDefinition.DataType = .blob) -> ColumnDefinition {
            let column = ColumnDefinition(name, type)
            columns.append(column)
            return column
        }

        mutating public func setPrimaryKey(_ indexedColumns: Array<IndexedColumn>, onConflict: Base.Conflict?) {
            constraints.append(.primaryKey(indexedColumns, onConflict))
        }

        mutating public func setUnique(_ indexedColumns: Array<IndexedColumn>, onConflict: Base.Conflict?) {
            constraints.append(.primaryKey(indexedColumns, onConflict))
        }
    }
}

extension Table.CreateStatement {

    var sql: String {
        var str = "create table"
        if let yesOrNo = ifNotExists, yesOrNo {
            str += " if not exists"
        }
        str += "  \(name) ("
        str += columns.map { $0.sql }.joined(separator: ",")
        if constraints.count > 0 {
            str += ","
            str += constraints.map { $0.sql }.joined(separator: ",")
        }
        str += ")"
        if let yesOrNo = withoutRowId, yesOrNo {
            str += " without rowId"
        }
        return str
    }

    var params: [BaseValueConvertible]? { nil }
}

extension Table {
    
    // https://www.sqlite.org/lang_droptable.html
    public struct DropStatement: ParameterExpression {

        let tableName: String
        init(name: String) {
            tableName = name
        }

        var sql: String { "drop table \(tableName)" }

        var params: [BaseValueConvertible]? = nil
    }
}

public typealias CreateTableStatement = Table.CreateStatement
public typealias DropTableStatement = Table.DropStatement
