//
//  Statement.swift
//  SBDB
//
//  Created by SadJason on 2019/11/22.
//  Copyright © 2019 SadJason. All rights reserved.
//

import Foundation

// MARK: - Statement Protocol

public enum Stmt {}

protocol Statement: ParameterExpression { }

extension Statement {
    public func exec(in db: Database) throws {
        try db.exec(sql: sql, withParams: params)
    }
}

// MARK: - Create Table

extension Expr.Column {
    
    /// Column Definition
    ///
    /// - See Also: https://www.sqlite.org/syntax/column-def.html
    final public class Definition {
        
        enum Constraint {
            case primaryKey(Expr.Order?, Expr.Conflict?, Bool?)
            case notNull(Expr.Conflict?)
            case unique(Expr.Conflict?)
            case collate(Expr.Collate)
            
            var sql: String {
                let onConflictPhrase = "on conflict"

                switch self {
                case let .primaryKey(order, conflictResolution, autoIncrement):
                    var str = "primary key"
                    if let r = order {
                        str += " \(r.sql)"
                    }
                    if let c = conflictResolution {
                        str += " \(onConflictPhrase) \(c.sql)"
                    }
                    if let a = autoIncrement, a {
                        str += " autoIncrement"
                    }
                    return str
                case let .notNull(conflictResolution):
                    var str = "not null"
                    if let c = conflictResolution {
                        str += " \(onConflictPhrase) \(c.sql)"
                    }
                    return str
                case let .unique(conflictResolution):
                    var ret = "unique"
                    if let c = conflictResolution {
                        ret += " \(onConflictPhrase) \(c.sql)"
                    }
                    return ret
                case .collate:
                    return "collate"
                }
            }
        }
        
        enum ConstraintType: Int, Comparable {
            static func < (lhs: ConstraintType, rhs: ConstraintType) -> Bool {
                lhs.rawValue < rhs.rawValue
            }

            case primary, notNull, unique, `default`, collate
        }
        
        let name: String
        let type: Expr.AffinityType
        var constraints = [ConstraintType : Constraint]()
        
        var sql: String {
            var ret = "\(name) \(type.rawValue)"
            
            constraints.keys.sorted().forEach { key in
                if case .unique = key, constraints.keys.contains(.primary) {
                    return
                }
                ret += " \(constraints[key]!.sql)"
            }
            return ret
        }
        
        init(_ name: String, _ type: Expr.AffinityType) {
            self.name = name
            self.type = type
        }
        
        @discardableResult
        public func setPrimary(
            autoIncrement: Bool = false,
            onConflict: Expr.Conflict? = nil,
            order: Expr.Order? = nil
        ) -> Self
        {
            if autoIncrement {
                guard type == .integer else {
                    assert(false, "AUTOINCREMENT is only allowed on an INTEGER PRIMARY KEY without DESC")
                    return self
                }
                guard order == nil || order! == .asc else {
                    assert(false, "AUTOINCREMENT is only allowed on an INTEGER PRIMARY KEY without DESC")
                    return self
                }
            }
            constraints[.primary] = .primaryKey(order, onConflict, autoIncrement)
            // set `not null` for primary key
            if constraints[.notNull] == nil {
                _ = setNotNull()
            }
            return self
        }
        
        @discardableResult
        public func setPrimary(autoIncrement: Bool) -> Self {
            setPrimary(autoIncrement: autoIncrement, onConflict: nil, order: nil)
        }

        @discardableResult
        public func setNotNull(onConflict: Expr.Conflict? = nil) -> Self {
            constraints[.notNull] = .notNull(onConflict)
            return self
        }

        @discardableResult
        public func setUnique(onConflict: Expr.Conflict? = nil) -> Self {
            constraints[.unique] = .unique(onConflict)
            return self
        }

        @discardableResult
        public func setCollate(name: Expr.Collate? = nil) -> Self {
            constraints[.collate] = .collate(name!)
            return self
        }
    }
}

extension Stmt {
    
    /// Create Table Statement
    ///
    /// - See Also: https://www.sqlite.org/lang_createtable.html
    public struct CreateTable: Statement {
        
        // MARK: Contraint

        public enum Constraint: Expression {
            case primaryKey(Array<Expr.IndexedColumn>, Expr.Conflict?)
            case unique(Array<Expr.IndexedColumn>, Expr.Conflict?)

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
        var columns: [Expr.Column.Definition] = []
        var constraints: [Constraint] = []

        public var ifNotExists: Bool?
        public var withoutRowId: Bool?

        public init(name: String) {
            self.name = name
        }

        @discardableResult
        mutating public func addColumn(
            _ name: String,
            type: Expr.AffinityType = .blob
        ) -> Expr.Column.Definition
        {
            let column = Expr.Column.Definition(name, type)
            columns.append(column)
            return column
        }
        
        public func column(forName name: String) -> Expr.Column.Definition? {
            for col in columns {
                if col.name == name {
                    return col
                }
            }
            return nil
        }

        mutating public func setPrimaryKey(
            withColumns columns: Array<Expr.IndexedColumn>,
            onConflict: Expr.Conflict?
        ) {
            constraints.append(.primaryKey(columns, onConflict))
        }

        mutating public func setUnique(
            withColumns columns: Array<Expr.IndexedColumn>,
            onConflict: Expr.Conflict?
        ) {
            constraints.append(.unique(columns, onConflict))
        }
    }

}

extension Stmt.CreateTable.Constraint {
    
    var sql: String {
        let command: String
        let indexedColumns: Array<Expr.IndexedColumn>
        let onConflict: Expr.Conflict?
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

extension Stmt.CreateTable {

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

    var params: [ColumnValueConvertible]? { nil }
}

// MARK: Drop Table

extension Stmt {
    
    /// Drop Table Statement
    ///
    /// - See Also: https://www.sqlite.org/lang_droptable.html
    public struct DropTable: Statement {

        let sql: String
        let params: [ColumnValueConvertible]? = nil
        init(_ tableName: String, ifExists: Bool) {
            sql = "drop table\(ifExists ? " if exists " : " ")\(tableName)"
        }
    }
}

// MARK: Create Index

extension Stmt {
    
    /// Create Index Statement
    ///
    /// - See Also: // https://www.sqlite.org/lang_createindex.html
    public struct CreateIndex: Statement {
        
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
        let params: [ColumnValueConvertible]?  = nil
        
        var columns: [Expr.IndexedColumn] = []
        init(name indexName: String, table tableName: String, options: Options) {
            
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
}

// MARK: Drop Index

extension Stmt {
 
    /// Drop Index Statement
    ///
    /// - See Also: https://www.sqlite.org/lang_dropindex.html
    public struct DropIndex: Statement {
        let sql: String
        let params: [ColumnValueConvertible]? = nil
        
        init(name: String) {
            sql = "drop index if exists \(name)"
        }
    }
}

// MARK: Insert

extension Stmt {
    
    /// Insert Statement
    ///
    /// - See Also:https://www.sqlite.org/lang_insert.html
    public struct Insert: Statement {
        
        public enum Mode {
            case insert
            case replace
            case insertOr(Expr.Conflict)
        }

        let sql: String
        let params: [ColumnValueConvertible]?

        init(
            table tableName: String,
            row: RowStorage,
            mode: Mode = .insert)
        {
            var chunk = "\(mode.sql) into \(tableName) "
            var keys = [String]()
            var values = [ColumnValueConvertible]()
            for (key, value) in row {
                keys.append(key)
                values.append(value)
            }
            chunk += "(\(keys.joined(separator: ",")))"
            chunk += " values (\(Array(repeating: paramPlaceholder, count: keys.count).joined(separator: ",")))"
            
            sql = chunk
            params = values
        }
    }
}

extension Stmt.Insert.Mode : Expression {
    var sql: String {
        switch self {
        case .insert: return "insert"
        case .replace: return "replace"
        case .insertOr(let onConflict): return "insert or \(onConflict.sql)"
        }
    }
}

// MARK: Delete

extension Stmt {
    
    /// Delete Statement
    ///
    /// - See Also: https://www.sqlite.org/lang_delete.html
    public struct Delete: Statement {

        let sql: String
        let params: [ColumnValueConvertible]?

        init(table tableName: String, where condition: Expr.Condition? = nil) {
            var chunk = "delete from \(tableName)"
            if let cond = condition {
                chunk += " where \(cond.sql)"
            }
            
            sql = chunk
            params = condition?.params
        }
    }
}

// MARK: Update

extension Stmt {
    
    /// Update Statement
    ///
    /// - See Also: https://www.sqlite.org/lang_update.html
    public struct Update: Statement {
        
        public enum Mode: Expression {
            case update
            case updateOr(Expr.Conflict)
        }
        
        private let tableName: String
        private let mode: Mode
        private let whereCondition: Expr.Condition?
        private let assignment: UpdateAssignment
        
        init(
            table tableName: String,
            assigment: UpdateAssignment,
            mode: UpdateMode = .update,
            where condition: Expr.Condition? = nil)
        {
            self.tableName = tableName
            self.assignment = assigment
            self.mode = mode
            self.whereCondition = condition
        }
    }
}

extension UpdateMode {
    var sql: String {
        switch self {
        case .update: return "update"
        case .updateOr(let conflict): return "update or \(conflict.sql)"
        }
    }
}

extension Stmt.Update {
    
    var sql: String {
        var chunk = "\(mode.sql) \(tableName)"

        let assigns = assignment.keys
            .sorted()
            .map { "\($0) = \(paramPlaceholder)" }
            .joined(separator: ",")
        chunk += " set \(assigns)"

        if let cond = whereCondition {
            chunk += " where \(cond.sql)"
        }

        return chunk
    }

    var params: [ColumnValueConvertible]? {
        assignment.keys.sorted().map { assignment[$0]! } + (whereCondition?.params ?? [])
    }
}

// MARK: Select

extension Stmt {
    
    /// Select Statement
    ///
    /// - See Also: https://www.sqlite.org/lang_select.html
    public struct Select: Statement {

        public enum Mode: String, Expression {
            case distinct
            case all
        }

        let tableName: String
        let resultColumns: [SelectTermConvertiable]
        var groupColumns: [Expr.Column]? = nil
        var orderTerms: [OrderTermConvertiable]?
        var whereCondtion: Expr.Condition?
        var limit: Int?
        var offset: Int?
        var mode: Mode?

        init(from tableName: String, on columns: [SelectTermConvertiable]) {
            self.tableName = tableName
            self.resultColumns = columns
        }

    }
}

extension Stmt.Select {
    
    var sql: String {
        
        var chunk = "select"
        if let mode = mode {
            chunk += " \(mode.sql)"
        }
        chunk += " \(resultColumns.map { $0.asSelect().sql }.joined(separator: ","))"
        chunk += " from \(tableName)"
        if let cond = whereCondtion {
            chunk += " where \(cond.sql)"
        }
        if let group = groupColumns, group.count > 0 {
            chunk += " group by \(group.map { $0.sql }.joined(separator: ","))"
        }
        if let orderTerms = orderTerms, orderTerms.count > 0 {
            chunk += " order by \(orderTerms.map { $0.asOrder().sql }.joined(separator: ","))"
        }
        if let limit = limit {
            chunk += " limit \(limit)"
        }
        if let offset = offset {
            chunk += " offset \(offset)"
        }
        return chunk
    }
    
    var params: [ColumnValueConvertible]? { whereCondtion?.params }
}

extension Expr.Column {
    
    static var all = Expr.Column("*")
}

public typealias CreateTableColumn = Expr.IndexedColumn
public typealias CreateTableConstraint = Stmt.CreateTable.Constraint
public typealias CreateTableOptions = Stmt.CreateTable.Options

public typealias CreateIndexOptions = Stmt.CreateIndex.Options

public typealias SelectMode = Stmt.Select.Mode

public typealias InsertMode = Stmt.Insert.Mode

public typealias UpdateAssignment = RowStorage

public typealias UpdateMode = Stmt.Update.Mode
