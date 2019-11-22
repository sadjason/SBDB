//
//  Statement.swift
//  SBDB
//
//  Created by zhangwei on 2019/11/22.
//  Copyright © 2019 ByteDance. All rights reserved.
//

import Foundation

protocol Statement: ParameterExpression { }

extension Statement {
    public func exec(in db: Database) throws {
        try db.exec(sql: sql, withParams: params)
    }
}

// MARK: Create Table

/// Create Table Statement
///
/// - See Also: https://www.sqlite.org/lang_createtable.html
public struct CreateTableStatement: Statement {
    
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
    }
    
    // MARK: Contraint

    public enum Constraint: Expression {
        case primaryKey(Array<IndexedColumn>, Base.Conflict?)
        case unique(Array<IndexedColumn>, Base.Conflict?)

        // TODO: support foreign key
        // TODO: support check
    }
    
    public struct Options: OptionSet {
        public let rawValue: Int32
        public init(rawValue: Int32) {
            self.rawValue = rawValue
        }
        
        public static let ifNotExists = Self.init(rawValue: 1)
        public static let withoutRowId = Self.init(rawValue: 1<<1)
    }
    
    let name: String
    var columns: [ColumnDefinition] = []
    var constraints: [Constraint] = []

    public var ifNotExists: Bool?
    public var withoutRowId: Bool?

    public init(name: String) {
        self.name = name
    }

    @discardableResult
    mutating public func addColumn(
        _ name: String,
        type: ColumnDefinition.DataType = .blob
    ) -> ColumnDefinition
    {
        let column = ColumnDefinition(name, type)
        columns.append(column)
        return column
    }

    mutating public func setPrimaryKey(
        withColumns columns: Array<IndexedColumn>,
        onConflict: Base.Conflict?
    ) {
        constraints.append(.primaryKey(columns, onConflict))
    }

    mutating public func setUnique(
        withColumns columns: Array<IndexedColumn>,
        onConflict: Base.Conflict?
    ) {
        constraints.append(.unique(columns, onConflict))
    }
}

public typealias IndexedColumn = CreateTableStatement.IndexedColumn
public typealias CreateTableConstraint = CreateTableStatement.Constraint
public typealias CreateTableOptions = CreateTableStatement.Options

extension CreateTableStatement.IndexedColumn {
    
    var sql: String {
        var str = columnName
        str += (collate != nil ? " collate \(collate!.sql)" : "")
        str += (order != nil ? order!.sql : "")
        return str
    }
}

extension CreateTableStatement.Constraint {
    
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

extension CreateTableStatement {

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

// MARK: Drop Table

/// Drop Table Statement
/// - See Also: https://www.sqlite.org/lang_droptable.html
public struct DropTableStatement: Statement {

    let sql: String
    let params: [BaseValueConvertible]? = nil
    init(_ tableName: String) {
        sql = "drop table \(tableName)"
    }
}

// MARK: Create Index

/// Create Index Statement
///
/// - See Also: // https://www.sqlite.org/lang_createindex.html
public struct CreateIndexStatement: Statement {
    
    public struct Options: OptionSet {
        public let rawValue: Int32
        public init(rawValue: Int32) {
            self.rawValue = rawValue
        }
        
        public static let ifNotExists = Self.init(rawValue: 1)
        public static let unique = Self.init(rawValue: 1<<1)
    }
    
    private let _unfinishedSql: String
    var sql: String { "\(_unfinishedSql) (\(columns.map { $0.sql }.joined(separator: ",")))" }
    let params: [BaseValueConvertible]?  = nil
    
    var columns: [IndexedColumn] = []
    init(name indexName: String, table tableName: String, options: CreateIndexStatement.Options) {
        
        var chunk = "create"
        if options.contains(.unique) {
            chunk += " unique"
        }
        chunk += " index"
        if options.contains(.ifNotExists) {
            chunk += " if not exists"
        }
        chunk += " \(indexName) on \(tableName)"
        
        _unfinishedSql = chunk
    }
}

public typealias CreateIndexOptions = CreateIndexStatement.Options

// MARK: Drop Index

/// Drop Index Statement
/// - See Also: https://www.sqlite.org/lang_dropindex.html
public struct DropIndexStatement: Statement {
    let sql: String
    let params: [BaseValueConvertible]? = nil
    
    init(name: String) {
        sql = "drop index if exists \(name)"
    }
}

// MARK: Insert

/// Insert Statement
///
/// - See Also:https://www.sqlite.org/lang_insert.html
public struct InsertStatement: Statement {
    
    public enum Mode {
        case insert
        case replace
        case insertOr(Base.Conflict)
    }

    let sql: String
    let params: [BaseValueConvertible]?

    init(
        table tableName: String,
        row: Base.RowStorage,
        mode: Mode = .insert)
    {
        var chunk = "\(mode.sql) into \(tableName) "
        var keys = [String]()
        var values = [BaseValueConvertible]()
        for (key, value) in row {
            keys.append(key)
            values.append(value)
        }
        chunk += "(\(keys.joined(separator: ",")))"
        chunk += " values (\(Array(repeating: ParameterPlaceholder, count: keys.count).joined(separator: ",")))"
        
        sql = chunk
        params = values
    }
}

typealias InsertMode = InsertStatement.Mode

extension InsertMode : Expression {
    var sql: String {
        switch self {
        case .insert: return "insert"
        case .replace: return "replace"
        case .insertOr(let onConflict): return "insert or \(onConflict.sql)"
        }
    }
}

// MARK: Delete

/// Delete Statement
///
/// - See Also: https://www.sqlite.org/lang_delete.html
public struct DeleteStatement: Statement {

    let sql: String
    let params: [BaseValueConvertible]?

    init(table tableName: String, where condition: Condition? = nil) {
        var chunk = "delete from \(tableName)"
        if let cond = condition {
            chunk += " where \(cond.sql)"
        }
        
        sql = chunk
        params = condition?.params
    }
}

// MARK: Update

public typealias UpdateAssignment = Dictionary<String, BaseValueConvertible>

/// Update Statement
///
/// - See Also: https://www.sqlite.org/lang_update.html
public struct UpdateStatement: Statement {
    
    public enum Mode: Expression {
        case update
        case updateOr(Base.Conflict)
    }
    
    private let tableName: String
    private let mode: Mode
    private let whereCondition: Condition?
    private let assignment: UpdateAssignment
    
    init(
        table tableName: String,
        assigment: UpdateAssignment,
        mode: UpdateMode = .update,
        where condition: Condition? = nil)
    {
        self.tableName = tableName
        self.assignment = assigment
        self.mode = mode
        self.whereCondition = condition
    }
}

public typealias UpdateMode = UpdateStatement.Mode

extension UpdateMode {
    var sql: String {
        switch self {
        case .update: return "update"
        case .updateOr(let conflict): return "update or \(conflict.sql)"
        }
    }
}

extension UpdateStatement {
    
    var sql: String {
        var chunk = "\(mode.sql) \(tableName)"

        let assigns = assignment.keys.sorted().map { "\($0) = \(ParameterPlaceholder)" }.joined(separator: ",")
        chunk += " set \(assigns)"

        if let cond = whereCondition {
            chunk += " where \(cond.sql)"
        }

        return chunk
    }

    var params: [BaseValueConvertible]? {
        assignment.keys.sorted().map { assignment[$0]! } + (whereCondition?.params ?? [])
    }
}

// MARK: Select

/// Select Statement
/// - See Also: https://www.sqlite.org/lang_select.html
public struct SelectStatement: Statement {
    
    public enum ResultColumn: Expression {
        public typealias Alias = String

        case all
        case normal(Column, Alias?)
        case aggregate(Base.AggregateFunction, Alias?)

        var sql: String {
            switch self {
            case .all: return "*"
            case let .normal(col, alias):
                return alias != nil ? "\(col.sql) as \(alias!)" : col.sql
            case let .aggregate(fun, alias):
                return alias != nil ? "\(fun.sql) as \(alias!)" : fun.sql
            }
        }
    }

    public enum Mode: String, Expression {
        case distinct
        case all
    }

    let tableName: String
    let resultColumns: [ResultColumn]
    var groupColumns: [Column]? = nil
    var orderTerms: [Base.OrderTerm]?
    var whereCondtion: Condition?
    var limit: Int?
    var offset: Int?
    var mode: Mode?

    init(from tableName: String, on columns: [ResultColumn]) {
        self.tableName = tableName
        self.resultColumns = columns
    }

}

public typealias SelectMode = SelectStatement.Mode
public typealias SelectColumn = SelectStatement.ResultColumn

extension SelectStatement {
    
    var sql: String {
        var chunk = "select"
        if let mode = mode {
            chunk += " \(mode.sql)"
        }
        chunk += " \(resultColumns.map { $0.sql }.joined(separator: ","))"
        chunk += " from \(tableName)"
        if let cond = whereCondtion {
            chunk += " where \(cond.sql)"
        }
        if let group = groupColumns, group.count > 0 {
            chunk += " group by \(group.map { $0.sql }.joined(separator: ","))"
        }
        if let orderTerms = orderTerms, orderTerms.count > 0 {
            chunk += " order by \(orderTerms.map { $0.sql }.joined(separator: ","))"
        }
        if let limit = limit {
            chunk += " limit \(limit)"
        }
        if let offset = offset {
            chunk += " offset \(offset)"
        }
        return chunk
    }
    
    var params: [BaseValueConvertible]? { whereCondtion?.params }
}
