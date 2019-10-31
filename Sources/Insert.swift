//
//  Insert.swift
//  SQLite
//
//  Created by zhangwei on 2019/10/23.
//  Copyright © 2019 ByteDance. All rights reserved.
//

import Foundation
import SQLite3

/// https://www.sqlite.org/lang_insert.html

public struct InsertStatement {
    public enum Mode {
        case insert
        case replace
        case insertOr(Base.Conflict)
    }

    let tableName: String
    let mode: Mode

    var rows: [Base.RowStorage]

    init(
        tableName: String,
        rows: [Base.RowStorage] = [],
        mode: Mode = .insert
    ) {
        self.tableName = tableName
        self.rows = rows
        self.mode = mode
    }

    mutating func append(_ rows: [Base.RowStorage]) {
        self.rows.append(contentsOf: rows)
    }
}

public typealias InsertMode = InsertStatement.Mode

extension InsertStatement.Mode : Expression {
    var sql: String {
        switch self {
        case .insert: return "insert"
        case .replace: return "replace"
        case .insertOr(let onConflict): return "insert or \(onConflict.sql)"
        }
    }
}

extension InsertStatement {

    private func sqlAndParams(at index: Int) -> (String, [BaseValueConvertible]?) {
        let row = rows[index]
        let keys = row.keys.sorted()

        var sql = "\(mode.sql) into \(tableName) "
        sql += "(\(keys.joined(separator: ",")))"
        sql += " values (\(Array(repeating: ParameterPlaceholder, count: keys.count).joined(separator: ",")))"

        let params = keys.map { row[$0]! }
        return (sql, params)
    }

    func exec(in database: Database) throws {
        try rows.enumerated().forEach { (index, _) in
            let (sql, params) = sqlAndParams(at: index)
            try database.exec(sql: sql, withParams: params)
        }
    }
}

extension TableEncodable {

    static func save(
        _ objects: [Self],
        in database: Database,
        withMode mode: InsertMode = .insert
    ) throws
    {
        guard objects.count > 0 else {
            return
        }

        if objects.count == 1 {
            try objects.first!.save(in: database, withMode: mode)
            return
        }

        let encoder = TableEncoder.default
        let rows = try objects.map { try encoder.encode($0) }
        let stmt = InsertStatement(tableName: self.tableName, rows: rows, mode: mode)
        try stmt.exec(in: database)
    }

    func save(in database: Database, withMode mode: InsertMode = .insert) throws {
        let encoder = TableEncoder.default
        let row = try encoder.encode(self)
        let stmt = InsertStatement(tableName: Self.tableName, rows: [row], mode: mode)
        try stmt.exec(in: database)
    }
}
