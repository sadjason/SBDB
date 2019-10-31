//
//  Update.swift
//  SQLite
//
//  Created by zhangwei on 2019/10/23.
//  Copyright © 2019 ByteDance. All rights reserved.
//

import Foundation

/// https://www.sqlite.org/lang_update.html

public class UpdateStatement<T: TableEncodable>: ParameterExpression {

    enum IndexedStrategy: Expression {
        case none
        case indexed(String)

        var sql: String {
            switch self {
            case .none:
                return "not indexed"
            case .indexed(let name):
                return "indexed by \(name)"
            }
        }
    }

    private let onConflict: Base.Conflict?
    private var indexedStrategy: IndexedStrategy = .none
    private var whereCondition: Condition?
    private var assignments = [String: ColumnAssignment]()

    var sql: String {
        var conflictStr = ""
        if let conflict = onConflict {
            conflictStr = "or \(conflict.sql)"
        }
        var chunk = "update \(conflictStr) \(T.tableName)"

        let assigns = assignments.keys.sorted().map { "\($0) = ?" }.joined(separator: ",")
        chunk += " set \(assigns)"

        if let cond = whereCondition {
            chunk += " where \(cond.sql)"
        }

        return chunk
    }

    var params: [BaseValueConvertible]? {
        let columnValues = assignments.keys.sorted().map { assignments[$0]!.baseValue }
        return columnValues + (whereCondition?.params ?? [])
    }

    init(onConflict: Base.Conflict? = nil) {
        self.onConflict = onConflict
    }

    @discardableResult
    func indexed(by name: String) -> Self {
        indexedStrategy = .indexed(name)
        return self
    }

    @discardableResult
    func `where`(_ cond: Condition) -> Self {
        precondition(whereCondition == nil, "You can only invoke `where` once")

        whereCondition = cond
        return self
    }

    func assign(_ value: BaseValueConvertible, toColumn name: String) {
        assignments[name] = ColumnAssignment(name: name, value: value)
    }

    func exec(in database: Database) throws {

        print("exec update sql: \(sql)")

        let stmt = try RawStatement(sql: sql, database: database.pointer)

        var index: Base.ColumnIndex = 1
        for param in params ?? [] {
            try stmt.bind(param.baseValue, to: index)
            index += 1
        }

        try stmt.step()
    }
}

extension TableEncodable {

    public typealias ColumnValueMap = Dictionary<String, BaseValueConvertible>

    public static func update(closure: (inout ColumnValueMap) -> Void) -> UpdateStatement<Self> {
        let stmt = UpdateStatement<Self>()
        var map = ColumnValueMap()
        closure(&map)
        for (name, value) in map {
            stmt.assign(value, toColumn: name)
        }
        return stmt
    }
    
    public static func update(or conflictStrategy: Base.Conflict, closure: (inout ColumnValueMap) -> Void) -> UpdateStatement<Self> {
        let stmt = UpdateStatement<Self>(onConflict: conflictStrategy)
        var map = ColumnValueMap()
        closure(&map)
        for (name, value) in map {
            stmt.assign(value, toColumn: name)
        }
        return stmt
    }
}
