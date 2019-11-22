//
//  Index.swift
//  SBDB
//
//  Created by zhangwei on 2019/11/21.
//  Copyright © 2019 ByteDance. All rights reserved.
//

import Foundation

extension Table {
    
    // https://www.sqlite.org/lang_createindex.html
    public struct CreateIndexOptions: OptionSet {
        public let rawValue: Int32
        public init(rawValue: Int32) {
            self.rawValue = rawValue
        }
        
        public static let ifNotExists = CreateIndexOptions(rawValue: 1)
        public static let unique = CreateIndexOptions(rawValue: 1<<1)
    }
    
    public struct CreateIndexStatement {
        
        var options: CreateIndexOptions
        var indexName: String
        var tableName: String
        var columns: [Table.IndexedColumn] = []
        init(name indexName: String, table tableName: String, options: CreateIndexOptions) {
            self.indexName = indexName
            self.tableName = tableName
            self.options = options
        }
    }
}

extension Table.CreateIndexStatement: ParameterExpression {
    
    var sql: String {
        var chunk = "create"
        if options.contains(.unique) {
            chunk += " unique"
        }
        chunk += " index"
        if options.contains(.ifNotExists) {
            chunk += " if not exists"
        }
        chunk += " \(indexName) on \(tableName)"
        chunk += " (\(columns.map { $0.sql }.joined(separator: ",")))"
        return chunk
    }
    
    var params: [BaseValueConvertible]? {
        nil
    }
}

extension Table {
    
    // https://www.sqlite.org/lang_dropindex.html
    public struct DropIndexStatement: ParameterExpression {
        let sql: String
        let params: [BaseValueConvertible]? = nil
        
        init(name: String) {
            sql = "drop index if exists \(name)"
        }
    }
}

public typealias CreateTableIndexStatement = Table.CreateIndexStatement
public typealias DropTableIndexStatement = Table.DropIndexStatement
