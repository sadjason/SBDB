//
//  Table.swift
//  SBDB
//
//  Created by zhangwei on 2019/10/20.
//  Copyright © 2019 ByteDance. All rights reserved.
//

import Foundation

public enum Table {

    public enum Constraint: Expression {
        case primaryKey(Array<ColumnIndexed>, Base.Conflict?)
        case unique(Array<ColumnIndexed>, Base.Conflict?)

        // TODO: support foreign key
        // TODO: support check
        // TOOD: support index

        var sql: String {
            let command: String
            let indexedColumns: Array<ColumnIndexed>
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

    public class Definition: ParameterExpression {

        let name: String
        var columns: [ColumnDefinition] = []
        var constraints: [Constraint] = []

        public var ifNotExists: Bool?
        public var withoutRowId: Bool?

        public init(name: String) {
            self.name = name
        }

        @discardableResult
        public func column(_ name: String, type: ColumnDefinition.DataType = .blob) -> ColumnDefinition {
            let column = ColumnDefinition(name, type)
            columns.append(column)
            return column
        }

        public func setPrimaryKey(_ indexedColumns: Array<ColumnIndexed>, onConflict: Base.Conflict?) {
            constraints.append(.primaryKey(indexedColumns, onConflict))
        }

        public func unique(_ indexedColumns: Array<ColumnIndexed>, onConflict: Base.Conflict?) {
            constraints.append(.primaryKey(indexedColumns, onConflict))
        }
    }
}

extension Table.Definition {

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

struct TableDropStatement: ParameterExpression {

    let tableName: String
    init(name: String) {
        tableName = name
    }

    var sql: String { "drop table \(tableName)" }

    var params: [BaseValueConvertible]? = nil
}

public extension TableEncodable {
    static func create(in database: Database, closure: (Table.Definition) -> Void) throws {
        let definition = Table.Definition(name: tableName)
        closure(definition)
        try database.exec(sql: definition.sql, withParams: definition.params)
    }
}

public extension CustomTableNameConvertible {
    static func drop(from database: Database) throws {
        let drop = TableDropStatement(name: self.tableName)
        try database.exec(sql: drop.sql, withParams: drop.params)
    }
}


public extension TableDecodable {
    static func create(in database: Database, ifNotExists: Bool = true) throws {
        let columnStructures = try TableColumnDecoder.default.decode(Self.self)
        let definition = Table.Definition(name: tableName)
        definition.ifNotExists = true
        for structure in columnStructures.values {
            let col = definition.column(structure.name, type: structure.type)
            if structure.nonnull {
                col.notNull()
            }
        }
        try database.exec(sql: definition.sql, withParams: definition.params)
    }
}
