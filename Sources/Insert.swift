//
//  Insert.swift
//  SQLite
//
//  Created by zhangwei on 2019/10/23.
//  Copyright © 2019 ByteDance. All rights reserved.
//

import Foundation

/// https://www.sqlite.org/lang_insert.html
class InsertStatement<T: TableEncodable> {

    enum `Type`: String, Expression {
        case insert = "insert"
        case replace = "replace"
        case insertOrReplace = "insert or replace"
        case insertOrRollback = "insert or rollback"
        case insertOrAbort = "insert or abort"
        case insertOrFail = "insert or fail"
        case insertOrIgnore = "insert or ignore"
    }

    let target: T
    let type: `Type`
    fileprivate var _encoded: TableEncoder.Storage?

    init(_ target: T, withType type: Type = .insert) {
        self.target = target
        self.type = type
    }
}

extension InsertStatement: WriteExecutable {

    var sql: String {
        var chunk = "\(type.sql) into \(T.tableName) "

        if _encoded == nil {
            _encoded = try? TableEncoder.encode(target)
        }

        let keys: Array<String> = _encoded?.keys.sorted() ?? []
        chunk += "(\(keys.joined(separator: ",")))"
        chunk += " values (\(Array(repeating: ParameterPlaceholder, count: keys.count).joined(separator: ",")))"

        return chunk
    }

    var params: [BaseValueConvertible]? {
        if _encoded == nil {
            _encoded = try? TableEncoder.encode(target)
        }
        guard let encoded = _encoded else {
            assert(false, "record failed")
            return nil
        }
        return encoded.keys.sorted().map { encoded[$0]! }
    }

    func exec(in database: Database) throws {

        print("exec insert: \(sql)")

        var stmt = try RawStatement(sql: sql, db: database.db)

        var index: RawStatement.ColumnIndex = 1
        for param in params ?? [] {
            try stmt?.bind(param.baseValue, to: index)
            index += 1
        }

        try stmt?.step()

        stmt?.finalize()
    }
}

extension TableEncodable {

    func insert() throws -> InsertStatement<Self> {
        InsertStatement(self)
    }

    func insertOrReplace() throws -> InsertStatement<Self> {
        InsertStatement(self, withType: .insertOrReplace)
    }
}
